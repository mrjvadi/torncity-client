class_name CentrifugoProtocol
extends RefCounted
## The Centrifugo bidirectional client protocol, JSON encoding — the pure part.
##
## Follows https://centrifugal.dev/docs/transports/client_protocol and the
## schema in centrifugal/protocol definitions/client.proto:
##   * a Command is {"id": n, "<method>": {...}}; a Reply echoes the id with a
##     result under the same method name, or an "error" {code,message,temporary};
##   * a Reply without id (id == 0) is an async push: {"push": {"channel", "pub"|
##     "join"|"leave"|"unsubscribe"|"subscribe"|"message"|"disconnect"|...}};
##   * an empty object {} from the server is a ping; the client answers with an
##     empty command {} when the connect result said "pong": true;
##   * several messages may share one frame, joined with "\n".
## No I/O here: realtime.gd owns the socket. Unit-tested in tests/test_centrifugo.gd.

enum Kind { PING, REPLY, PUSH, INVALID }

const ERR_TOKEN_EXPIRED := 109
const ERR_ALREADY_SUBSCRIBED := 105
const UNSUB_RESUBSCRIBE_FROM := 2500

var _next_id := 0


func next_id() -> int:
	_next_id += 1
	return _next_id


func reset_ids() -> void:
	_next_id = 0


# -- encoding ------------------------------------------------------------------------

## Several commands -> one text frame (newline-delimited JSON).
static func encode(commands: Array) -> String:
	var parts := PackedStringArray()
	for c in commands:
		parts.append(JSON.stringify(c))
	return "\n".join(parts)


func connect_cmd(token: String, name := "godot", version := "") -> Dictionary:
	var req := {"name": name.substr(0, 16)}
	if token != "":
		req["token"] = token
	if version != "":
		req["version"] = version.substr(0, 64)
	return {"id": next_id(), "connect": req}


func subscribe_cmd(channel: String, token := "", recover_from := {}) -> Dictionary:
	var req := {"channel": channel}
	if token != "":
		req["token"] = token
	if not recover_from.is_empty():
		req["recover"] = true
		req["epoch"] = recover_from.get("epoch", "")
		req["offset"] = recover_from.get("offset", 0)
	return {"id": next_id(), "subscribe": req}


func unsubscribe_cmd(channel: String) -> Dictionary:
	return {"id": next_id(), "unsubscribe": {"channel": channel}}


func refresh_cmd(token: String) -> Dictionary:
	return {"id": next_id(), "refresh": {"token": token}}


func sub_refresh_cmd(channel: String, token: String) -> Dictionary:
	return {"id": next_id(), "sub_refresh": {"channel": channel, "token": token}}


## The answer to a server ping: an empty command.
static func pong() -> Dictionary:
	return {}


# -- decoding ------------------------------------------------------------------------

## One text frame -> an Array of Dictionaries (invalid lines are dropped).
static func decode(frame: String) -> Array:
	var out := []
	for line in frame.strip_edges().split("\n", false):
		line = line.strip_edges()
		if line.is_empty():
			continue
		var v = JSON.parse_string(line)
		if v is Dictionary:
			out.append(v)
	return out


static func kind(msg: Dictionary) -> Kind:
	if msg.is_empty():
		return Kind.PING
	if int(msg.get("id", 0)) > 0:
		return Kind.REPLY
	if msg.has("push"):
		return Kind.PUSH
	return Kind.INVALID


## The push type name: "pub", "join", "leave", "unsubscribe", "subscribe",
## "message", "disconnect", "connect" or "refresh"; "" when none is set.
static func push_type(push: Dictionary) -> String:
	for t in ["pub", "join", "leave", "unsubscribe", "subscribe", "message", "disconnect", "connect", "refresh"]:
		if push.has(t):
			return t
	return ""


## The data of a publication. In the JSON protocol `data` is embedded raw JSON.
static func pub_data(pub: Dictionary) -> Variant:
	var d = pub.get("data")
	if d is String:
		var parsed = JSON.parse_string(d)
		return parsed if parsed != null else d
	return d


# -- decisions -------------------------------------------------------------------------

## Whether to reconnect after the WebSocket closed with this code.
## Centrifugo: 3000-3499 and 4000-4499 reconnect; 3500-3999 and 4500-4999 are
## terminal (invalid token, bad request, force disconnect...). Anything else
## (1000-2999: transport-level) reconnects.
static func should_reconnect(close_code: int) -> bool:
	if close_code >= 3500 and close_code < 4000:
		return false
	if close_code >= 4500 and close_code < 5000:
		return false
	return true


## Unsubscribe pushes with code >= 2500 must be followed by a resubscribe.
static func should_resubscribe(unsub_code: int) -> bool:
	return unsub_code >= UNSUB_RESUBSCRIBE_FROM


## Whether an error reply is worth retrying as-is.
static func is_temporary(error: Dictionary) -> bool:
	return bool(error.get("temporary", false)) or int(error.get("code", 0)) in [100, 111, 113]


## Exponential backoff with full jitter (as the official SDKs do):
## a uniformly random delay in [0, min(max, min_delay * 2^attempt)], floored at min_delay.
static func backoff(attempt: int, min_delay: float, max_delay: float, rnd: float) -> float:
	var cap := minf(max_delay, min_delay * pow(2.0, clampi(attempt, 0, 31)))
	return maxf(min_delay, cap * clampf(rnd, 0.0, 1.0))


## When to refresh a token that expires in `ttl` seconds: a little early, with jitter.
static func refresh_delay(ttl: float, rnd: float) -> float:
	if ttl <= 0:
		return -1.0
	var early := minf(ttl * 0.2, 30.0)
	return maxf(1.0, ttl - early - rnd * minf(5.0, early))


## How long to wait for any frame before calling the link dead: ping + slack.
static func ping_deadline(ping_interval: float, slack := 10.0) -> float:
	if ping_interval <= 0:
		return 0.0
	return ping_interval + slack

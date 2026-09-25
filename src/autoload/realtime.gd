extends Node
## Realtime events over Centrifugo (bidirectional JSON protocol on a WebSocket).
##
##   1. GET /api/v1/realtime/token -> connection JWT. The server subscribes the
##      connection to the personal channel player:<id> itself (server-side
##      subscription: it arrives in the connect reply's "subs").
##   2. connect {token}; answer every ping {} with a pong {} when asked to.
##   3. subscribe to city:<code> with a token from /api/v1/realtime/subscribe.
##   4. refresh the connection token before `ttl`, and the subscription token
##      with sub_refresh; reconnect with exponential backoff + full jitter
##      unless the server said not to (terminal close codes).
## Messages: {type:"notice", kind, text, view?} on the personal channel,
##           {type:"announce", text} on the city channel.

signal state_changed(state: String)
signal message(channel: String, data: Dictionary)
signal notice(data: Dictionary)
signal announce(data: Dictionary)

enum State { OFF, CONNECTING, CONNECTED }

const BACKOFF_MIN := 0.5
const BACKOFF_MAX := 20.0
const CONNECT_TIMEOUT := 12.0

var state := State.OFF
var proto := CentrifugoProtocol.new()
var transport: RealtimeTransports.Transport
var client_id := ""
var subs := {}            # channel -> {state: "subscribed"|"subscribing", server_side: bool, expires_in: float}
var channel_ids := {}     # numeric channel id (Push.id optimisation) -> channel
var city_channel := ""

var _want := false
var _attempt := 0
var _reconnect_in := -1.0
var _pending := {}        # command id -> {method, channel?}
var _ping_interval := 0.0
var _pong := false
var _since_frame := 0.0
var _refresh_in := -1.0
var _connect_sent := false
var _open_timer := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	set_process(true)


func _state_name() -> String:
	return ["off", "connecting", "connected"][state]


func _set_state(s: State) -> void:
	if state != s:
		state = s
		state_changed.emit(_state_name())


## Start (or keep) a connection. Safe to call repeatedly.
func start() -> void:
	_want = true
	if state == State.OFF and _reconnect_in < 0:
		_open()


func stop() -> void:
	_want = false
	_reconnect_in = -1
	if transport:
		transport.close(1000, "client stop")
	transport = null
	subs.clear()
	_set_state(State.OFF)


## Follow the player to another city: leave the old city channel, join the new one.
func set_city(code: String) -> void:
	var ch := "city:" + code if code != "" else ""
	if ch == city_channel:
		return
	if city_channel != "" and state == State.CONNECTED and subs.has(city_channel):
		_send([proto.unsubscribe_cmd(city_channel)])
		subs.erase(city_channel)
	city_channel = ch
	if ch != "" and state == State.CONNECTED:
		_subscribe(ch)


# -- connection -----------------------------------------------------------------------------
func _make_transport() -> RealtimeTransports.Transport:
	if Config.mock:
		var t := RealtimeTransports.MockTransport.new()
		t.server = Mock
		return t
	return RealtimeTransports.WsTransport.new()


func _open() -> void:
	_set_state(State.CONNECTING)
	var token := await Api.realtime_token()
	if not _want:
		return
	if token == "":
		_schedule_reconnect()
		return
	proto.reset_ids()
	_pending.clear()
	transport = _make_transport()
	_connect_sent = false
	_open_timer = 0.0
	_pending_token = token
	if transport.open(Config.realtime_url) != OK:
		_schedule_reconnect()


var _pending_token := ""


func _send(cmds: Array) -> void:
	if transport and transport.state() == RealtimeTransports.Transport.State.OPEN:
		for c in cmds:
			if c.has("id"):
				for m in ["connect", "subscribe", "unsubscribe", "refresh", "sub_refresh"]:
					if c.has(m):
						_pending[int(c["id"])] = {"method": m, "channel": c[m].get("channel", "")}
		transport.send_text(CentrifugoProtocol.encode(cmds))


func _schedule_reconnect() -> void:
	if not _want:
		_set_state(State.OFF)
		return
	_reconnect_in = CentrifugoProtocol.backoff(_attempt, BACKOFF_MIN, BACKOFF_MAX, _rng.randf())
	_attempt += 1
	_set_state(State.CONNECTING)


func _drop(code: int, reason: String) -> void:
	# The link is gone: keep the subscriptions we want, to restore on reconnect.
	for ch in subs:
		subs[ch]["state"] = "subscribing"
	transport = null
	_refresh_in = -1
	if CentrifugoProtocol.should_reconnect(code):
		_schedule_reconnect()
	else:
		push_warning("realtime: terminal disconnect %d %s" % [code, reason])
		_want = false
		_set_state(State.OFF)


func _process(delta: float) -> void:
	if _reconnect_in >= 0:
		_reconnect_in -= delta
		if _reconnect_in < 0:
			_open()
		return
	if transport == null:
		return
	var frames := transport.poll()
	var st := transport.state()
	if st == RealtimeTransports.Transport.State.OPEN and not _connect_sent:
		_connect_sent = true
		_send([proto.connect_cmd(_pending_token, "torncity-godot", Config.VERSION)])
	if st == RealtimeTransports.Transport.State.CONNECTING or (st == RealtimeTransports.Transport.State.OPEN and state != State.CONNECTED):
		_open_timer += delta
		if _open_timer > CONNECT_TIMEOUT:
			transport.close(3000, "connect timeout")
			_drop(3000, "connect timeout")
			return
	for f in frames:
		_since_frame = 0.0
		for msg in CentrifugoProtocol.decode(f):
			_handle(msg)
	if transport == null:
		return
	if st == RealtimeTransports.Transport.State.CLOSED:
		_drop(transport.close_code(), transport.close_reason())
		return
	# Liveness: no frame at all for ping + slack means a dead link.
	if state == State.CONNECTED and _ping_interval > 0:
		_since_frame += delta
		if _since_frame > CentrifugoProtocol.ping_deadline(_ping_interval):
			transport.close(3012, "no ping")
			_drop(3012, "no ping")
			return
	if _refresh_in >= 0:
		_refresh_in -= delta
		if _refresh_in < 0:
			_refresh_connection()
	for ch in subs:
		var s: Dictionary = subs[ch]
		if s.get("refresh_in", -1.0) >= 0:
			s["refresh_in"] -= delta
			if s["refresh_in"] < 0:
				_refresh_sub(ch)


# -- protocol handling --------------------------------------------------------------------------
func _handle(msg: Dictionary) -> void:
	match CentrifugoProtocol.kind(msg):
		CentrifugoProtocol.Kind.PING:
			if _pong:
				_send([CentrifugoProtocol.pong()])
		CentrifugoProtocol.Kind.REPLY:
			_on_reply(msg)
		CentrifugoProtocol.Kind.PUSH:
			_on_push(msg["push"])


func _on_reply(msg: Dictionary) -> void:
	var id := int(msg["id"])
	var p: Dictionary = _pending.get(id, {})
	_pending.erase(id)
	if msg.has("error"):
		var err: Dictionary = msg["error"]
		var code := int(err.get("code", 0))
		match p.get("method", ""):
			"connect":
				if code == CentrifugoProtocol.ERR_TOKEN_EXPIRED or CentrifugoProtocol.is_temporary(err):
					transport.close(3000, "reconnect")
					_drop(3000, "reconnect")
				else:
					transport.close(3500, "connect refused")
					_drop(3500, str(err.get("message", "")))
			"subscribe":
				var ch: String = p.get("channel", "")
				if code == CentrifugoProtocol.ERR_ALREADY_SUBSCRIBED:
					subs[ch] = {"state": "subscribed", "server_side": true}
				elif code == CentrifugoProtocol.ERR_TOKEN_EXPIRED or CentrifugoProtocol.is_temporary(err):
					get_tree().create_timer(CentrifugoProtocol.backoff(1, 1.0, 10.0, _rng.randf())).timeout.connect(func(): _subscribe(ch))
				else:
					subs.erase(ch)
			"refresh":
				if code == CentrifugoProtocol.ERR_TOKEN_EXPIRED or CentrifugoProtocol.is_temporary(err):
					_refresh_in = 5.0
		return
	if msg.has("connect"):
		_on_connected(msg["connect"])
	elif msg.has("subscribe"):
		var ch: String = p.get("channel", "")
		var r: Dictionary = msg["subscribe"]
		subs[ch] = {"state": "subscribed", "server_side": false,
			"refresh_in": CentrifugoProtocol.refresh_delay(float(r.get("ttl", 0)), _rng.randf()) if r.get("expires", false) else -1.0}
		if r.has("id"):
			channel_ids[int(r["id"])] = ch
		for pub in r.get("publications", []):
			_publication(ch, pub)
	elif msg.has("refresh"):
		var r: Dictionary = msg["refresh"]
		_refresh_in = CentrifugoProtocol.refresh_delay(float(r.get("ttl", 0)), _rng.randf()) if r.get("expires", false) else -1.0
	elif msg.has("sub_refresh"):
		var r: Dictionary = msg["sub_refresh"]
		var ch: String = p.get("channel", "")
		if subs.has(ch):
			subs[ch]["refresh_in"] = CentrifugoProtocol.refresh_delay(float(r.get("ttl", 0)), _rng.randf()) if r.get("expires", false) else -1.0


func _on_connected(r: Dictionary) -> void:
	client_id = str(r.get("client", ""))
	_ping_interval = float(r.get("ping", 0))
	_pong = bool(r.get("pong", false))
	_since_frame = 0.0
	_attempt = 0
	_refresh_in = CentrifugoProtocol.refresh_delay(float(r.get("ttl", 0)), _rng.randf()) if r.get("expires", false) else -1.0
	# Server-side subscriptions (the personal channel) come with the reply.
	var server_subs: Dictionary = r.get("subs", {}) if r.get("subs") is Dictionary else {}
	for ch in server_subs:
		subs[ch] = {"state": "subscribed", "server_side": true}
		var sr = server_subs[ch]
		if sr is Dictionary:
			if sr.has("id"):
				channel_ids[int(sr["id"])] = ch
			for pub in sr.get("publications", []):
				_publication(ch, pub)
	_set_state(State.CONNECTED)
	# Restore client-side subscriptions and the city channel.
	var want := []
	for ch in subs:
		if not subs[ch].get("server_side", false):
			want.append(ch)
	if city_channel != "" and not want.has(city_channel) and not server_subs.has(city_channel):
		want.append(city_channel)
	for ch in want:
		_subscribe(ch)


func _subscribe(ch: String) -> void:
	if state != State.CONNECTED:
		return
	subs[ch] = {"state": "subscribing", "server_side": false}
	var token := await Api.subscription_token(ch)
	if state != State.CONNECTED:
		return
	_send([proto.subscribe_cmd(ch, token)])


func _refresh_connection() -> void:
	var token := await Api.realtime_token()
	if token == "":
		_refresh_in = CentrifugoProtocol.backoff(2, 2.0, 30.0, _rng.randf())
		return
	_send([proto.refresh_cmd(token)])


func _refresh_sub(ch: String) -> void:
	subs[ch]["refresh_in"] = -1.0
	var token := await Api.subscription_token(ch)
	if token != "" and subs.has(ch):
		_send([proto.sub_refresh_cmd(ch, token)])


func _on_push(push: Dictionary) -> void:
	var ch := str(push.get("channel", ""))
	if ch == "" and push.has("id"):
		ch = channel_ids.get(int(push["id"]), "")
	match CentrifugoProtocol.push_type(push):
		"pub":
			_publication(ch, push["pub"])
		"subscribe":
			subs[ch] = {"state": "subscribed", "server_side": true}
		"unsubscribe":
			var code := int(push["unsubscribe"].get("code", 0))
			if CentrifugoProtocol.should_resubscribe(code) and not subs.get(ch, {}).get("server_side", false):
				_subscribe(ch)
			else:
				subs.erase(ch)
		"message":
			_dispatch("", CentrifugoProtocol.pub_data(push["message"]))
		"disconnect":
			var d: Dictionary = push["disconnect"]
			var code := int(d.get("code", 3000))
			if transport:
				transport.close(1000, "server disconnect")
			_drop(code if d.get("reconnect", CentrifugoProtocol.should_reconnect(code)) else 3500, str(d.get("reason", "")))


func _publication(ch: String, pub: Dictionary) -> void:
	_dispatch(ch, CentrifugoProtocol.pub_data(pub))


func _dispatch(ch: String, data) -> void:
	if not (data is Dictionary):
		return
	message.emit(ch, data)
	match str(data.get("type", "")):
		"notice":
			notice.emit(data)
		"announce":
			announce.emit(data)

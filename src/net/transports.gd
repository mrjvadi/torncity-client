class_name RealtimeTransports
extends RefCounted
## The byte pipes under the Centrifugo client: a real WebSocket, or a loopback
## into the mock server that speaks the same JSON frames.


class Transport:
	extends RefCounted
	enum State { CLOSED, CONNECTING, OPEN, CLOSING }

	func open(_url: String) -> int:
		return OK

	func send_text(_text: String) -> void:
		pass

	## Frames received since the last poll.
	func poll() -> PackedStringArray:
		return PackedStringArray()

	func state() -> State:
		return State.CLOSED

	func close(_code := 1000, _reason := "") -> void:
		pass

	func close_code() -> int:
		return -1

	func close_reason() -> String:
		return ""


class WsTransport:
	extends Transport
	var ws := WebSocketPeer.new()
	var _was_open := false

	func open(url: String) -> int:
		ws = WebSocketPeer.new()
		ws.inbound_buffer_size = 1 << 20
		ws.heartbeat_interval = 0.0  # Centrifugo pings at the protocol level
		_was_open = false
		return ws.connect_to_url(url)

	func send_text(text: String) -> void:
		if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			ws.send_text(text)

	func poll() -> PackedStringArray:
		ws.poll()
		var out := PackedStringArray()
		while ws.get_available_packet_count() > 0:
			var pkt := ws.get_packet()
			out.append(pkt.get_string_from_utf8())
		return out

	func state() -> Transport.State:
		match ws.get_ready_state():
			WebSocketPeer.STATE_CONNECTING: return Transport.State.CONNECTING
			WebSocketPeer.STATE_OPEN: return Transport.State.OPEN
			WebSocketPeer.STATE_CLOSING: return Transport.State.CLOSING
		return Transport.State.CLOSED

	func close(code := 1000, reason := "") -> void:
		ws.close(code, reason)

	func close_code() -> int:
		return ws.get_close_code()

	func close_reason() -> String:
		return ws.get_close_reason()


## Loopback to the mock Centrifugo inside src/mock/mock_server.gd.
class MockTransport:
	extends Transport
	var _state := Transport.State.CLOSED
	var _inbox := PackedStringArray()
	var _code := -1
	var _reason := ""
	var server: Object

	func open(_url: String) -> int:
		_state = Transport.State.OPEN
		_code = -1
		server.rt_attach(self)
		return OK

	func send_text(text: String) -> void:
		if _state == Transport.State.OPEN:
			server.rt_receive(text)

	## Called by the mock server.
	func deliver(text: String) -> void:
		_inbox.append(text)

	func server_close(code: int, reason: String) -> void:
		_code = code
		_reason = reason
		_state = Transport.State.CLOSED

	func poll() -> PackedStringArray:
		var out := _inbox
		_inbox = PackedStringArray()
		return out

	func state() -> Transport.State:
		return _state

	func close(code := 1000, reason := "") -> void:
		_code = code
		_reason = reason
		_state = Transport.State.CLOSED
		server.rt_detach(self)

	func close_code() -> int:
		return _code

	func close_reason() -> String:
		return _reason

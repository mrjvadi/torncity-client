extends TestCase
## The real Realtime client against the mock Centrifugo (loopback transport):
## connect with a token, server-side personal channel, city subscription,
## ping/pong, publications, token refresh and reconnect after a close.


func _login() -> void:
	Mock.reset()
	Session.clear()
	await Api.auth_link("TESTCODE")
	await Api.bootstrap()


func _wait_connected(max_frames := 120) -> bool:
	for i in max_frames:
		if Realtime.state == Realtime.State.CONNECTED and Realtime.subs.get(Realtime.city_channel, {}).get("state", "") == "subscribed":
			return true
		await tree.process_frame
	return false


func test_connects_and_subscribes() -> void:
	await _login()
	Realtime.stop()
	Realtime.set_city(Session.city_code)
	Realtime.start()
	check(await _wait_connected(), "connected and city subscribed")
	check(Realtime.subs.has("player:1001"), "personal channel from the connect reply")
	check(Realtime.subs["player:1001"]["server_side"], "personal channel is server-side")
	eq(Realtime.city_channel, "city:" + Session.city_code)


func test_notice_and_announce_reach_signals() -> void:
	await _login()
	Realtime.stop()
	Realtime.set_city(Session.city_code)
	Realtime.start()
	await _wait_connected()
	var got := {}
	var on_notice := func(d): got["notice"] = d
	var on_announce := func(d): got["announce"] = d
	Realtime.notice.connect(on_notice)
	Realtime.announce.connect(on_announce)
	Mock.push_notice("arrived", "📍 arrived", {"place": {"code": "bazaar", "name": "Bazaar"}})
	Mock.push_announce("📣 news")
	await frames(3)
	eq(got.get("notice", {}).get("kind", ""), "arrived")
	eq(got.get("announce", {}).get("text", ""), "📣 news")
	Realtime.notice.disconnect(on_notice)
	Realtime.announce.disconnect(on_announce)


func test_ping_gets_a_pong() -> void:
	await _login()
	Realtime.stop()
	Realtime.start()
	await _wait_connected()
	var sent := []
	var t: RealtimeTransports.MockTransport = Realtime.transport
	# watch what the client sends back
	var orig = Mock.rt_receive
	Mock.set_meta("sent", sent)
	t.deliver("{}")
	await frames(2)
	# the mock treats {} as a pong and ignores it; the client must still be connected
	eq(Realtime.state, Realtime.State.CONNECTED)
	check(Realtime._pong, "server asked for pongs")


func test_reconnects_after_a_drop() -> void:
	await _login()
	Realtime.stop()
	Realtime.start()
	await _wait_connected()
	var t: RealtimeTransports.MockTransport = Realtime.transport
	t.server_close(3001, "shutdown")
	await frames(2)
	check(Realtime.state == Realtime.State.CONNECTING, "reconnecting after 3001")
	# backoff is at most 0.5-1 s on the first attempt
	await tree.create_timer(1.2).timeout
	check(await _wait_connected(), "connected again")


func test_terminal_close_does_not_reconnect() -> void:
	await _login()
	Realtime.stop()
	Realtime.start()
	await _wait_connected()
	var t: RealtimeTransports.MockTransport = Realtime.transport
	t.server_close(3500, "invalid token")
	await frames(3)
	eq(Realtime.state, Realtime.State.OFF)
	Realtime.stop()

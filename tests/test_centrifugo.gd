extends TestCase


func test_encode_batches_with_newlines() -> void:
	var p := CentrifugoProtocol.new()
	var frame := CentrifugoProtocol.encode([p.subscribe_cmd("ch1"), p.subscribe_cmd("ch2")])
	eq(frame, '{"id":1,"subscribe":{"channel":"ch1"}}\n{"id":2,"subscribe":{"channel":"ch2"}}')


func test_decode_batch_and_kinds() -> void:
	var msgs := CentrifugoProtocol.decode('{"id":1,"connect":{"client":"c","ping":25,"pong":true}}\n{}\n{"push":{"channel":"city:x","pub":{"data":{"type":"announce","text":"hi"}}}}\nnot json\n')
	eq(msgs.size(), 3)
	eq(CentrifugoProtocol.kind(msgs[0]), CentrifugoProtocol.Kind.REPLY)
	eq(CentrifugoProtocol.kind(msgs[1]), CentrifugoProtocol.Kind.PING)
	eq(CentrifugoProtocol.kind(msgs[2]), CentrifugoProtocol.Kind.PUSH)
	eq(CentrifugoProtocol.push_type(msgs[2]["push"]), "pub")
	eq(CentrifugoProtocol.pub_data(msgs[2]["push"]["pub"])["text"], "hi")


func test_pub_data_as_string_json() -> void:
	eq(CentrifugoProtocol.pub_data({"data": '{"type":"notice"}'})["type"], "notice")


func test_connect_command() -> void:
	var p := CentrifugoProtocol.new()
	var c := p.connect_cmd("tok", "a-very-long-client-name", "0.1.0")
	eq(c["id"], 1)
	eq(c["connect"]["token"], "tok")
	eq(c["connect"]["name"].length(), 16, "name is capped at 16")
	eq(p.refresh_cmd("t2")["refresh"]["token"], "t2")
	eq(p.sub_refresh_cmd("city:a", "t3")["sub_refresh"]["channel"], "city:a")
	eq(CentrifugoProtocol.encode([CentrifugoProtocol.pong()]), "{}")


func test_reconnect_rules() -> void:
	check(CentrifugoProtocol.should_reconnect(1006), "abnormal closure reconnects")
	check(CentrifugoProtocol.should_reconnect(3001), "shutdown reconnects")
	check(CentrifugoProtocol.should_reconnect(3012), "no pong reconnects")
	check(not CentrifugoProtocol.should_reconnect(3500), "invalid token is terminal")
	check(not CentrifugoProtocol.should_reconnect(3503), "force disconnect is terminal")
	check(CentrifugoProtocol.should_reconnect(4000), "4000-4499 reconnect")
	check(not CentrifugoProtocol.should_reconnect(4500), "4500-4999 terminal")
	check(CentrifugoProtocol.should_resubscribe(2500))
	check(not CentrifugoProtocol.should_resubscribe(2000))
	check(CentrifugoProtocol.is_temporary({"code": 100}))
	check(not CentrifugoProtocol.is_temporary({"code": 103}))


func test_backoff_full_jitter() -> void:
	near(CentrifugoProtocol.backoff(0, 0.5, 20.0, 1.0), 0.5)
	near(CentrifugoProtocol.backoff(3, 0.5, 20.0, 1.0), 4.0)
	near(CentrifugoProtocol.backoff(10, 0.5, 20.0, 1.0), 20.0, 0.001, "capped")
	near(CentrifugoProtocol.backoff(10, 0.5, 20.0, 0.0), 0.5, 0.001, "floored")
	for i in 50:
		var d := CentrifugoProtocol.backoff(i % 12, 0.5, 20.0, randf())
		check(d >= 0.5 and d <= 20.0, "within bounds")


func test_refresh_timing() -> void:
	eq(CentrifugoProtocol.refresh_delay(0, 0.5), -1.0)
	var d := CentrifugoProtocol.refresh_delay(600, 1.0)
	check(d < 600 and d >= 565, "refresh a little before ttl: %s" % d)
	near(CentrifugoProtocol.ping_deadline(25), 35.0)

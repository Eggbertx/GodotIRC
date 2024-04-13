class_name IRCClient extends Node

## emitted by when the client receives a message type it recognizes, with the message parameters stored in an array
signal message_received(client:IRCClient, msg_type:String, data: Array[String])

## emitted when the client receives a message from the server it doesn't recognize/understand
signal unhandled_message_received(client:IRCClient, msg:String)

## disconnected is emitted when the client disconnects from the server
signal disconnected()

enum {
	STATE_DISCONNECTED,
	STATE_FAILURE,
	STATE_CONNECTED,
	STATE_CONNECTION_REGISTERED,
	STATE_JOINED
}

var _opts:IRCOptions = null
var _profile:IRCProfile = null

var connection_state = STATE_DISCONNECTED

var _incoming_lines: Array[String] = []

var host: String:
	get:
		return _opts.host

var port: int:
	get:
		return _opts.port

var ssl: bool:
	get:
		return _opts.ssl

var server_password: String:
	get:
		return _opts.server_password

var channels: Array[String]:
	get:
		return _opts.channels

var nick: String:
	get:
		return _profile.nick

var username: String:
	get:
		return _profile.username

var real_name: String:
	get:
		return _profile.real_name

var _client = StreamPeerTCP.new()

func _init(opts:IRCOptions, profile:IRCProfile):
	_opts = opts
	_profile = profile

func is_connection_started() -> bool:
	return _client.get_connected_host() != ""

func start_connection() -> String:
	var success := await _client.connect_to_host(host, port)
	assert(success == OK)
	if success != OK:
		return error_string(success)
	var status = StreamPeerTCP.STATUS_CONNECTING
	
	while status == StreamPeerTCP.STATUS_CONNECTING:
		success = _client.poll()
		if success != OK:
			return error_string(success)
		status = _client.get_status()
	connection_state = STATE_CONNECTED

	success = await send_lines([
		"PASS %s" % server_password,
		"NICK %s" % nick,
		("USER %s 8 *" % real_name) + ((" :%s" % real_name) if real_name != "" else "")
	])
	if success != OK:
		return error_string(success)
	connection_state = STATE_CONNECTION_REGISTERED
	return ""

func _process(delta:float):
	if is_connection_started():
		_check_incoming()


func _check_incoming():
	var available_bytes := _client.get_available_bytes()
	var next_line := _incoming_lines.pop_front()
	if next_line != null:
		_process_line(next_line)

	if available_bytes < 1:
		# incoming bytes
		return

	_incoming_lines.append_array(_client.get_utf8_string(available_bytes).split("\r\n", false))

func _process_line(line: String):
	if line == "":
		return
	var payload := ""
	var parts := line.split(" ", true, 3)
	if line.find(IRCMessageTypes.PING_MESSAGE) == 0:
		parts.remove_at(0)
		send_line("PONG " + " ".join(parts))
		message_received.emit(self, IRCMessageTypes.PING_MESSAGE, [payload])
		return

	var line_noprefix = line.substr(1) if line.find(":") == 0 else line
	
	
	unhandled_message_received.emit(self, line)

## Sends multiple messages to the server sequentially, each terminated by CRLF and limited to 512 bytes
func send_lines(lines: Array[String]) -> int:
	var success := OK
	for line in lines:
		success = await send_line(line)
		if success != OK:
			print("failed sending line %s: %s" % [line, error_string(success)])
			break
	return success
		

## Sends a raw message to the server, limited to 512 bytes and terminated by CRLF.
## It returns OK if it succeeded and an Error code otherwise
func send_line(line: String) -> int:
	line = line.trim_suffix("\r\n")

	# max size of a message is 512, as defined by RFC 1459
	if line.length() > 510:
		line = line.substr(0, 510)
	print("-> %d: %s" % [line.length()+2, line])
	line += "\r\n"
	return _client.put_data(line.to_utf8_buffer())

func end_connection():
	if connection_state >= STATE_CONNECTION_REGISTERED:
		send_line("QUIT")
	_client.disconnect_from_host()
	disconnected.emit()

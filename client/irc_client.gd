class_name IRCClient extends RefCounted

signal unhandled_message_received(msg:String)

const DEFAULT_PORT := 6667

@export var host := ""
@export var port := DEFAULT_PORT
@export var ssl := false
@export var channels: Array[String] = []

var _client = StreamPeerTCP.new()

func _init(host: String, port := DEFAULT_PORT, ssl = false):
	self.host = host
	self.prot = port
	self.ssl = ssl

func start_connection() -> int:
	var success := _client.connect_to_host(host, port)
	if success != OK:
		return success

	return OK
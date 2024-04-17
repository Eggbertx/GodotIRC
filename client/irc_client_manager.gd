class_name IRCClientManager extends Node

signal client_connected(client: IRCClient)
signal unhandled_message_received(client:IRCClient, msg:String)
signal raw_message_received(client:IRCClient, data:String)
signal server_message_received(client:IRCClient, msg_type:String, motd_msg:String)
signal channel_joined(server:String, channel:String)
signal privmsg_received(client:IRCClient, channel:String, )

var profile := IRCProfile.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func disconnect_clients():
	var children := get_children()
	for child in children:
		var client = child as IRCClient
		client.end_connection()
		_disconnect_client_signals(client)

func get_server_conn(server: String) -> IRCClient:
	var children := get_children()
	for child in children:
		var client = child as IRCClient
		if client.host == server:
			return client
	return null

func add_server(opts:IRCOptions, profile: IRCProfile) -> String:
	var client := IRCClient.new(opts, profile)
	_connect_client_signals(client)
	var err := await client.start_connection()
	if err != "":
		return err
	add_child(client)
	client_connected.emit(client)
	client.name = client.host
	return ""

func join_channel(server: String, channel: String):
	var client = get_server_conn(server)
	if client == null:
		print("Couldn't find server %s in scene tree" % server)
		return
	
	await client.join_channel(channel)
	channel_joined.emit(server, channel)

func _connect_client_signals(client:IRCClient):
	client.raw_message_received.connect(_on_raw_message_received)
	client.server_message_received.connect(_on_server_message_received)
	client.unhandled_message_received.connect(_on_unhandled_message)

func _disconnect_client_signals(client:IRCClient):
	client.raw_message_received.disconnect(_on_raw_message_received)
	client.server_message_received.disconnect(_on_server_message_received)
	client.unhandled_message_received.disconnect(_on_unhandled_message)

func _notification(what:int):
	match what:
		NOTIFICATION_EXIT_TREE or NOTIFICATION_WM_CLOSE_REQUEST or NOTIFICATION_CRASH:
			disconnect_clients()		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta:float):
	pass

func _on_raw_message_received(client:IRCClient, data:String):
	raw_message_received.emit(client, data)

func _on_unhandled_message(client:IRCClient, msg: String):
	unhandled_message_received.emit(client, msg)

func _on_server_message_received(client:IRCClient, msg_type:String, msg:String):
	server_message_received.emit(client, msg_type, msg)

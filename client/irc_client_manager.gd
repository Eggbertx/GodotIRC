extends Node

signal unhandled_message_received(client:IRCClient, msg:String)

var profile := IRCProfile.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	profile.nick = "GodotIRC"
	profile.username = "godotirc"
	profile.real_name = "Godot IRC"

	var client_opts = IRCOptions.new()
	client_opts.host = "irc.rizon.net"
	client_opts.server_password = "test"
	client_opts.channels.append("#codefest")

	var client := IRCClient.new(client_opts, profile)
	client.unhandled_message_received.connect(_on_unhandled_message)
	var err := await client.start_connection()
	assert(err == "")
	add_child(client)
	client.name = client.host


func disconnect_clients():
	var children := get_children()
	for child in children:
		var client = child as IRCClient
		client.end_connection()
		client.unhandled_message_received.disconnect(_on_unhandled_message)

func _notification(what:int):
	match what:
		NOTIFICATION_EXIT_TREE or NOTIFICATION_WM_CLOSE_REQUEST or NOTIFICATION_CRASH:
			disconnect_clients()		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta:float):
	pass

func _on_unhandled_message(client:IRCClient, msg: String):
	print("<- %s: %s" % [client.host, msg])

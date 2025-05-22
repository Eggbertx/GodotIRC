# GodotIRC
A simple IRC client (and possibly eventually server) for Godot 4.0

To use it, add the repository as a submodule to your projectby running `git submodule add https://github.com/Eggbertx/GodotIRC.git addons/GodotIRC` from the root directory of your project.

In your Godot project, add an instance of the IRCClientManager node to your scene tree. This node will manage all IRC connections and channels.

Here is a simple example of how to connect to an IRC server and join a channel. The API is still a work in progress, so it may change in the future.

```gdscript
@onready var client_mgr:IRCClientManager = $IRCClientManager

func _ready():
	client_mgr.client_state_changed.connect(_on_client_state_changed)

	var opts := ServerOptions.new()
	opts.host = "irc.example.com"
	opts.port = 6667
	opts.nick = "MyNick"
	opts.username = "myusername"
	opts.realname = "My Real Name"
	opts.channels = ["#channel1", "#channel2"]
	var err_str := await client_mgr.add_server(server)
	if err_str != "":
		print("Error adding server: ", err_str)
		return


func _on_client_state_changed(client: IRCClient, state: int):
	match state:
		IRCMessageTypes.RPL_ENDOFMOTD:
			print("End of MOTD received")
			for channel in client.channels:
				print("Joining channel: ", channel)
				client.join_channel(channel)
```
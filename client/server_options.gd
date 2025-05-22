class_name ServerOptions extends Node

const DEFAULT_PORT := 6667

var host := ""
var port := DEFAULT_PORT
var ssl := false
var nick := ""
var real_name := ""
var username := ""
var server_password := ""
var nickserv_password := ""
var channels: Array[String] = []

func validate_data() -> String:
	if host == "":
		return "Host is required"
	if port == 0:
		port = DEFAULT_PORT
	if port < 0 or port > 65535:
		return "Invalid data for %s, port must be between 1 and 65535 (default is %d)" % [host, DEFAULT_PORT]
	return ""
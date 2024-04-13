class_name IRCOptions extends Node

const DEFAULT_PORT := 6667

var host := ""
var port := DEFAULT_PORT
var ssl := false
var server_password := ""
var channels: Array[String] = []

extends Node
var device_count
var data = preload("res://JoyCons/joycon.gdns").new()

func init_devices():
	device_count = data.connect_devices()
	return device_count

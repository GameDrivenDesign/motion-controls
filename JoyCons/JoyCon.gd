extends Node2D

signal button_pressed(button_name)
signal button_released(button_name)

var velocity := Vector3(0, 0, 0)
export var beta_accel = 0.025
export var beta_rot = 0.025

const time_constant = 0.015
var gravity = Vector3()
var smooth_linear_accel = Vector3()

var beta = 0
var alpha = 0
var gamma = 0
const bias = 0.96
var rotationQ = Quat()

var vel1 = Vector3(0, 0, 0)
var vel2 = Vector3(0, 0, 0)

var xRotation = 0
var moveUp = 0

var device_count = 0

var joycon_color

var last_emitted = {
	left = false,
	right = false,
	top = false,
	down = false,
}

var inverted = 1 #don't invert
var joycon_type # 1 = right, 2 = left
var controller
var color

var setup = false
var data

func init():
	data = preload("res://JoyCons/joycon.gdns").new()
	device_count = data.connect_devices()
	print("Found " + str(device_count) + " devices")

func _ready():
	set_process(false)

func get_controller_index():
	return controller

func get_joycon_color_for_index(index):
	return get_joycon_color(data.get_color(index))

func get_joycon_color_as_string_for_index(index):
	return get_joycon_color_as_string(data.get_color(index))

func get_joycon_color(current = color):
	if current == null:
		return Color.white
	return Color((current << 8) | 0xFF)

func get_joycon_color_as_string(current = color):
	if current == 702950:
		return "blue"
	elif current == 2022400:
		return "green"
	elif current == 16724600:
		return "pink"
	elif current == 16727080:
		return "orange"
	else:
		return "unknown color"

func show_indicator():
	if not setup:
		print("not set up yet!")
		return
	var indicator = ColorRect.new()
	indicator.rect_size = Vector2(50, 50)
	indicator.color = get_joycon_color()
	get_tree().get_root().add_child(indicator)
	indicator.rect_global_position = Vector2.ZERO

func set_controller(number):
	_set_up(number)

func _set_up(device_number):
	if device_count <= device_number:
		print("Controller not found")
		return
	controller = device_number
	color = data.get_color(controller)
	joycon_type = data.get_controller_type(controller)
	inverted = -1 if joycon_type == 1 else 1
	print("Using JoyCon with color: " + get_joycon_color_as_string())
	setup = true
	set_process(true)

func maybe_emit_buttons(buttons):
	var buttons_pressed = {
		top = bool(buttons & 1 << 14) || bool(buttons & 1 << 3),
		right = bool(buttons & 1 << 15) || bool(buttons & 1 << 1),
		down = bool(buttons & 1 << 13) || bool(buttons & 1 << 2),
		left = bool(buttons & 1 << 12) || bool(buttons & 1 << 0)
	}
	if (buttons_pressed.hash() == last_emitted.hash()):
		return
	for i in buttons_pressed:
		if buttons_pressed[i] != last_emitted[i]:
			if buttons_pressed[i]:
				emit_signal("button_pressed", i)
			else:
				emit_signal("button_released", i)
	last_emitted = buttons_pressed

func any_button_pressed(index = controller):
	return data.get_buttons(index) > 0

func get_joystick():
	if not setup:
		return Vector2()
	var stick = data.get_joysticks(controller)[joycon_type % 2]
	return stick * inverted

func _process(delta):
	if data == null:
		return
	var raw_accel: Vector3 = data.get_accel(controller)
	var raw_gyro: Vector3 = data.get_gyro(controller)
	
	if raw_accel == Vector3.ZERO or raw_gyro == Vector3.ZERO:
		return
	
	raw_gyro = Vector3(deg2rad(raw_gyro.x), deg2rad(raw_gyro.y), deg2rad(raw_gyro.z))
	
	maybe_emit_buttons(data.get_buttons(controller))
	
	if gravity == Vector3(0, 0, 0):
		gravity = raw_accel
	
	# low pass filter to isolate the gravity
	var lpf_bias = time_constant / (time_constant + delta)
	gravity = lpf_bias * gravity + (1 - lpf_bias) * raw_accel
	
	# isolate linear acceleration and smooth
	var linear_accel = raw_accel - gravity
	smooth_linear_accel = smooth_linear_accel - (beta_accel * (smooth_linear_accel - linear_accel))
	
	# apply linear acceleration
	var bias2 = 0.9
	velocity = bias2 * velocity + (1 - bias2) * (velocity + smooth_linear_accel)
	
	# fuse gyro and accelerometer to obtain orientation
	var gyroDeltaQ := Quat(Vector3(raw_gyro.x, raw_gyro.y, raw_gyro.z).normalized(), raw_gyro.length() * delta)
	rotationQ *= gyroDeltaQ
	var estimatedGravity = rotationQ.inverse().xform(Vector3(0, 1, 0))
	var gravityDelta = quatFromVectors(gravity, estimatedGravity)
	rotationQ = (rotationQ * gravityDelta).slerp(rotationQ, bias)
	
	var computed_gravity = rotationQ.inverse().xform(Vector3(0, 1.01, 0))
	
	var accel1 = (raw_accel - computed_gravity) * 100
	vel1 += accel1 * delta
	var accel2 = (raw_accel - gravity) * 100
	vel2 += accel2 * delta
	
	moveUp = accel1.y
	xRotation = -rotationQ.get_euler().x * 180 * inverted

# http://lolengine.net/blog/2013/09/18/beautiful-maths-quaternion-from-vectors
func quatFromVectors(u: Vector3, v: Vector3) -> Quat:
	var cos_theta := u.normalized().dot(v.normalized())
	var angle := acos(cos_theta)
	var w := u.cross(v).normalized()
	return Quat(w, angle)

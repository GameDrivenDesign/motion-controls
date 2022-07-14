extends Node

signal button_pressed(button_name)
signal button_released(button_name)

var raw_accel: Vector3 	# raw acceleration in m/s², NOTE: this includes gravity!
var linear_accel: Vector3 	# estimation of acceleration without gravity in m/s²
var raw_rotation: Vector3 	# raw rotation in radians/s
var orientation: Quat 	# estimation of the current absolute orientation of the joycon
var rotation: Vector3 setget , get_rotation

var color: Color 		# color of the controller
var is_left: bool 		# whether this controller is left or right
var joystick: Vector2	# current position of the joystick in [(-1;-1);(1;1)]
var buttons_pressed: Dictionary # whether a button is held

##################################################

const time_constant = 0.015
const bias = 0.96

var gravity = Vector3()
#var smooth_linear_accel = Vector3()
#var velocity := Vector3(0, 0, 0)
export var beta_accel = 0.025
var rotationQ = Quat()

var device_count = 0

var last_emitted = {
	left = false,
	right = false,
	top = false,
	down = false,
	math = false,
	joystick = false,
	shoulder = false,
	special = false,
	sl = false,
	sr = false,
	z = false,
}

var controller_index
var data

func _ready():
	set_process(false)

func get_controller_index():
	return controller_index

func get_joycon_color():
	return Color((data.get_color(controller_index) << 8) | 0xFF)

func get_joycon_color_as_string():
	var c = data.get_color(controller_index)
	if c == 702950:
		return "blue"
	elif c == 2022400:
		return "green"
	elif c == 16724600:
		return "pink"
	elif c == 16727080:
		return "orange"
	else:
		return "unknown color"

#A helper method that shows a rectangle the color of the configured controller in the upper left corner
func show_indicator():
	var indicator = ColorRect.new()
	indicator.rect_size = Vector2(50, 50)
	indicator.color = color
	get_tree().get_root().add_child(indicator)
	indicator.rect_global_position = Vector2.ZERO

func set_controller(number, manager):
	data = manager.data
	controller_index = number
	color = data.get_color(controller_index)
	is_left = data.get_controller_type(controller_index) == 1
	print("Using JoyCon with color: " + get_joycon_color_as_string())
	set_process(true)

func rumble(freq, intensity):
	data.rumble(controller_index, freq, intensity)

func get_buttons_pressed(buttons):
	return {
		#left, right, top and down are the orientations when holding the controller sideways
		top = bool(buttons & 1 << 14) || bool(buttons & 1 << 3),
		right = bool(buttons & 1 << 15) || bool(buttons & 1 << 1),
		down = bool(buttons & 1 << 13) || bool(buttons & 1 << 2),
		left = bool(buttons & 1 << 12) || bool(buttons & 1 << 0),
		math = bool(buttons & 1 << 4) || bool(buttons & 1 << 5), # + / -
		joystick = bool(buttons & 1 << 7) || bool(buttons & 1 << 6),
		shoulder = bool(buttons & 1 << 9) || bool(buttons & 1 << 8), # L / R
		special = bool(buttons & 1 << 16) || bool(buttons & 1 << 17), # home / screenshot
		sl = bool(buttons & 1 << 18),
		sr = bool(buttons & 1 << 19),
		z = bool(buttons & 1 << 11) || bool(buttons & 1 << 10), # zl / zr
	}

func maybe_emit_buttons():
	if (buttons_pressed.hash() == last_emitted.hash()):
		return
	for i in buttons_pressed:
		if buttons_pressed[i] != last_emitted[i]:
			if buttons_pressed[i]:
				emit_signal("button_pressed", i)
			else:
				emit_signal("button_released", i)
	last_emitted = buttons_pressed

func get_rotation():
	return Vector3(rotationQ.get_euler().x, rotationQ.get_euler().y, rotationQ.get_euler().z)

func _process(delta):
	if data == null:
		return
	raw_accel = data.get_accel(controller_index)
	var raw_gyro: Vector3 = data.get_gyro(controller_index)
	
	if raw_accel == Vector3.ZERO or raw_gyro == Vector3.ZERO:
		return
	
	raw_gyro = Vector3(deg2rad(raw_gyro.x), deg2rad(raw_gyro.y), deg2rad(raw_gyro.z))
	raw_rotation = raw_gyro
	
	#calculate which buttons are pressed, and emit a signal if the set of pressed buttons changed
	buttons_pressed = get_buttons_pressed(data.get_buttons(controller_index))
	maybe_emit_buttons()
	
	# invert values if needed so coordinates are same if controller is held sideways
	joystick = data.get_joysticks(controller_index)[1 if is_left else 0] * (-1 if is_left else 1)
	
	if gravity == Vector3(0, 0, 0):
		gravity = raw_accel
	
	# low pass filter to isolate the gravity
	var lpf_bias = time_constant / (time_constant + delta)
	gravity = lpf_bias * gravity + (1 - lpf_bias) * raw_accel
	
	# isolate linear acceleration and smooth
	linear_accel = raw_accel - gravity
	#smooth_linear_accel = smooth_linear_accel - (beta_accel * (smooth_linear_accel - linear_accel))
	
	# apply linear acceleration
	#var bias2 = 0.9
	#velocity = bias2 * velocity + (1 - bias2) * (velocity + smooth_linear_accel)
	
	# fuse gyro and accelerometer to obtain orientation
	var gyroDeltaQ := Quat(Vector3(raw_gyro.x, raw_gyro.y, raw_gyro.z).normalized(), raw_gyro.length() * delta)
	rotationQ *= gyroDeltaQ
	var estimatedGravity = rotationQ.inverse().xform(Vector3(0, 1, 0))
	var gravityDelta = quatFromVectors(gravity, estimatedGravity)
	rotationQ = (rotationQ * gravityDelta).slerp(rotationQ, bias)
	orientation = rotationQ
	
	#var computed_gravity = rotationQ.inverse().xform(Vector3(0, 1.01, 0))
	#var accel1 = (raw_accel - computed_gravity) * 100
	#vel1 += accel1 * delta
	#var accel2 = (raw_accel - gravity) * 100
	#vel2 += accel2 * delta

# http://lolengine.net/blog/2013/09/18/beautiful-maths-quaternion-from-vectors
func quatFromVectors(u: Vector3, v: Vector3) -> Quat:
	var cos_theta := u.normalized().dot(v.normalized())
	var angle := acos(cos_theta)
	var w := u.cross(v).normalized()
	return Quat(w, angle)

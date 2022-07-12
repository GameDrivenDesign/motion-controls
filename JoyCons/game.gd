extends Spatial

var devices := 0
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

func _ready():
	devices = data.connect_devices()

func _process(delta):
	var raw_accel: Vector3 = data.get_accel(0)
	var raw_gyro: Vector3 = data.get_gyro(0)
	raw_gyro = Vector3(deg2rad(raw_gyro.x), deg2rad(raw_gyro.y), deg2rad(raw_gyro.z))
	
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
	#if smooth_linear_accel.length() < 0.1:
	#velocity *= 0.9
	var vel = velocity * 100
	if vel.length() > 1000:
		$obj/x.translation.x = 1 + vel.x
		$obj/y.translation.y = 1 + vel.y
		$obj/z.translation.z = 1 + vel.z
	
	# fuse gyro and accelerometer to obtain orientation
	var gyroDeltaQ := Quat(Vector3(raw_gyro.x, raw_gyro.y, raw_gyro.z).normalized(), raw_gyro.length() * delta)
	rotationQ *= gyroDeltaQ
	var estimatedGravity = rotationQ.inverse().xform(Vector3(0, 1, 0))
	var gravityDelta = quatFromVectors(gravity, estimatedGravity)
	rotationQ = (rotationQ * gravityDelta).slerp(rotationQ, bias)
	
	# $obj.rotation = Vector3(-rotationQ.get_euler().x, rotationQ.get_euler().y, -rotationQ.get_euler().z)
	$obj.rotation = Vector3(rotationQ.get_euler().x, rotationQ.get_euler().y, rotationQ.get_euler().z)
	
	$pos.translation += velocity * 100 * delta
	
	var computed_gravity = rotationQ.inverse().xform(Vector3(0, 1.01, 0))
	
	var accel1 = (raw_accel - computed_gravity) * 100
	vel1 += accel1 * delta
	var accel2 = (raw_accel - gravity) * 100
	vel2 += accel2 * delta

	
	$Camera/plot.add(vel1 * 5)
	$Camera/plot2.add(velocity * 100000)

# http://lolengine.net/blog/2013/09/18/beautiful-maths-quaternion-from-vectors
func quatFromVectors(u: Vector3, v: Vector3) -> Quat:
	var cos_theta := u.normalized().dot(v.normalized())
	var angle := acos(cos_theta)
	var w := u.cross(v).normalized()
	return Quat(w, angle)

onready var data = preload("res://JoyCons/joycon.gdns").new()

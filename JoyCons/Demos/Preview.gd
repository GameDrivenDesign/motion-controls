extends Spatial

var manager = preload("res://JoyCons/JoyConManager.gd").new()

func _ready():
	var devices = manager.init_devices()
	if devices > 0:
		$JoyCon.set_controller(0, manager)
		$JoyCon.rumble(5, 1)

func _process(_delta):
	var acceleration = $JoyCon.linear_accel * 100
	if acceleration.length() > 1000:
		$Indicator/x.translation.x = 1 + acceleration.x
		$Indicator/y.translation.y = 1 + acceleration.y
		$Indicator/z.translation.z = 1 + acceleration.z
	
	$Indicator.rotation = $JoyCon.rotation
	
	$Camera/Plot.add(acceleration * 5)

# http://lolengine.net/blog/2013/09/18/beautiful-maths-quaternion-from-vectors
func quatFromVectors(u: Vector3, v: Vector3) -> Quat:
	var cos_theta := u.normalized().dot(v.normalized())
	var angle := acos(cos_theta)
	var w := u.cross(v).normalized()
	return Quat(w, angle)

onready var data = preload("res://JoyCons/joycon.gdns").new()

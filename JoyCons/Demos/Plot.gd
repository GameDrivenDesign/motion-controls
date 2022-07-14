extends Node2D

var t = 0
func add(v: Vector3):
	$x.add_point(Vector2(t, v.x))
	$y.add_point(Vector2(t, v.y))
	$z.add_point(Vector2(t, v.z))
	t = t + 1
	
	if t > 1000:
		t = 0
		$x.clear_points()
		$y.clear_points()
		$z.clear_points()

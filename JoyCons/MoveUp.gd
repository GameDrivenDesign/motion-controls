extends TextureProgress

func _process(_delta):
	if (value >= max_value):
		tint_progress = Color(0, 1, 0)
	else:
		tint_progress = Color(1, 0, 0)

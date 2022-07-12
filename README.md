# motion-controls


## How to use the library

### Using `JoyCon.gd`

You can subscribe to button events using the following code snippet:

```gdscript
var joycon

func _ready():
	joycon = load("res://JoyCons/JoyCon.gd").new()
	joycon.init()
	joycon.set_controller(0)
	print(joycon.get_joycon_color_as_string())
	
	joycon.connect("button_pressed", self, "_on_joycon_button_click")

func _on_joycon_button_click(name):
	print(name)
	
func _process(delta):
	joycon._process(delta)
```

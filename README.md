# motion-controls


## Installation

### Linux (Ubuntu-like)

1. Install godot (*Caution*: The flatpak version does *not* work) `sudo apt install godot3`
2. Install the required dependencies: `sudo apt install libhidapi-hidraw0`
3. Clone this repository: `git clone https://github.com/GameDrivenDesign/motion-controls.git`
4. `cd` into the repository: `cd motion-controls`
5. Run godot like so: `sudo LD_LIBRARY_PATH=$(pwd)/JoyCons godot3 -e` (If you are using a standalone installation, replace the *godot3* with that binary; *sudo* is required because we use raw bluetooth)

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

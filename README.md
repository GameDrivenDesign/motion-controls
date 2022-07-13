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

## Design Draft
(not currently implemented but planned)

1. add joycon.tscn as a child of your player.tscn (or where you want to receive and react to events)
2. now you can connect to the pressed/released events
```gdscript
button_pressed(button: string)
button_released(button: string)

# where button is one of
['top', 'right', 'left', 'down', 'math', 'joystick', 'shoulder', 'special', 'sl', 'sr', 'z']
```

3. additionally, you can read a number of values from the accelerometer, gyroscope and device properties:
```gdscript
# READ/WRITE
$joycon.controller_number: int	# index from 0 which controller this joycon.tscn instance represents
				# by default, it will simply increase with each new global(!) instance
$joycon.bias: float		# value you can try tweaking if the orientation values (see below) are
				# too noisy. Lower values mean slower but more stable response to rotation
$joycon.rumble			# FIXME vibration engine input value, maybe also a method like
				# add_rumble(frequency,duration)?
$joycon.leds: Array[bool]	# an array of exactly four bools, indicating which LEDs are turned on

# READ ONLY
$joycon.raw_accel: Vector3 	# raw acceleration in m/s², NOTE: this includes gravity!
$joycon.linear_accel: Vector3 	# estimation of acceleration without gravity in m/s²
$joycon.raw_rotation: Vector3 	# raw rotation in radians/s
$joycon.orientation: Quat 	# estimation of the current absolute orientation of the joycon

$joycon.color: Color 		# color of the controller
$joycon.is_left: bool 		# whether this controller is left or right
$joycon.joystick: Vector2	# current position of the joystick in [(-1;-1);(1;1)]
$joycon.buttons_pressed: Dict[string,bool]
				# whether a button is held, use the button names from (2.) above
```
4. to control joining, use
```gdscript

var manager = preload("res://JoyCons/joycon_manager.gd").new()

func spawn_player(controller_number: number):
	var player = preload("res://my_player.tscn").instance()
	# should set the nested joycon.tscn's controller_number
	player.set_controller(controller_number)

func _ready():
	for index in manager.get_connected_controller_indices():
		spawn_player(index)

func run_this_with_a_timer_every_couple_seconds():
	# queries the system for new controllers. If any where found since the last
	# time you called this, all new indices are returned.
	for index in manager.pop_new_controller_indices():
		spawn_player(index)
```

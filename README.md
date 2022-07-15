# motion-controls

## Installation

### Linux (Ubuntu-like)

1. Install godot (_Caution_: The flatpak version does _not_ work) `sudo apt install godot3`
2. Install the required dependencies: `sudo apt install libhidapi-hidraw0`
3. Clone this repository: `git clone https://github.com/GameDrivenDesign/motion-controls.git`
4. `cd` into the repository: `cd motion-controls`
5. Grant user access to the bluetooth devices using `sudo chmod 0666 /dev/hidraw*`. You need to rerun whenever you connect new devices or reboot your machine.
6. Run godot like so: `LD_LIBRARY_PATH=$(pwd)/JoyCons godot3 -e` (If you are using a standalone installation, replace the _godot3_ with that binary)

## How to use the library

1. add joycon.tscn as a child of your player.tscn (or where you want to receive and react to events)
2. now you can connect to the pressed/released events

```gdscript
button_pressed(button: string)
button_released(button: string)

# where button is one of
['top', 'right', 'left', 'down', 'math', 'joystick', 'shoulder', 'special', 'sl', 'sr', 'z']
# directional buttons are named after their orientation when holding the JoyCons sideways.
```

3. additionally, you can read a number of values from the accelerometer, gyroscope and device properties:

```gdscript
# READ/WRITE
$joycon.set_controller(index: int, manager: JoyConManager)
				# index from 0 which controller this joycon.tscn instance represents
				# and an instance of the joyconmanager that you used for init_devices (see below)
$joycon.bias: float		# value you can try tweaking if the orientation values (see below) are
				# too noisy. Lower values mean slower but more stable response to rotation

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

# FUNCTIONS
$joycon.rumble(frequency, intensity)

# Future Work
$joycon.dead_zone: number	# dead zone for the joystick in distancen from 0,0
$joycon.leds: Array[bool]	# an array of exactly four bools, indicating which LEDs are turned on
```

4. to control joining, use

```gdscript

var manager = preload("res://JoyCons/JoyConManager.gd").new()

func spawn_player(controller_number: number):
	var player = preload("res://MyPlayer.tscn").instance()
	# should set the nested joycon.tscn's controller_number
	player.get_node("JoyCon").set_controller(controller_number, manager)

func _ready():
	#all devices must be connected as this point, we do not support late joining
	for index in manager.init_devices():
		spawn_player(index)

```

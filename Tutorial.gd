extends RichTextLabel

var keyboard_movement = "[center]⌨️ WASD or arrows: move the blocks.[/center]"
var keyboard_rotate = "[center]⌨️ __rotate__: rotate blocks.[/center]"
var keyboard_attach = "[center]⌨️ __lock__: place blocks.[/center]"
var keyboard_match3 = "[center]Match 3 colors or more.[/center]"

var controller_movement = "[center]🎮 Left stick: move the blocks.[/center]"
var controller_rotate = "[center]🎮 X / Square: rotate blocks.[/center]"
var controller_attach = "[center]🎮 A / Cross: place blocks.[/center]"
var controller_match3 = "[center]Match 3 colors or more.[/center]"

enum {MOVEMENT, ROTATE, ATTACH, MATCH3, FINISHED}

var state = MOVEMENT

func _ready():
	text = keyboard_rotate if Global.keyboard_mode else controller_rotate
	translate()

func translate():
	for action in InputMap.get_actions():
		var keys = []
		for event in InputMap.action_get_events(action):

			if event is InputEventKey and Global.keyboard_mode:
				var key_name = OS.get_keycode_string(event.unicode).to_upper()

				if key_name == "":
					key_name = event.as_text()

				keys.append(key_name)

		if len(keys) > 0:
			text = text.replace("__%s__" % action, " or ".join(keys))


func _process(delta):
	if state == MOVEMENT and Input.is_action_just_pressed("up"):
		state = ROTATE
		text = keyboard_rotate if Global.keyboard_mode else controller_rotate
		translate()

	if state == MOVEMENT and Input.is_action_just_pressed("down"):
		state = ROTATE
		text = keyboard_rotate if Global.keyboard_mode else controller_rotate
		translate()

	if state == MOVEMENT and Input.is_action_just_pressed("left"):
		state = ROTATE
		text = keyboard_rotate if Global.keyboard_mode else controller_rotate
		translate()

	if state == MOVEMENT and Input.is_action_just_pressed("right"):
		state = ROTATE
		text = keyboard_rotate if Global.keyboard_mode else controller_rotate
		translate()

	if state == ROTATE and Input.is_action_just_pressed("rotate"):
		state = ATTACH
		text = keyboard_attach if Global.keyboard_mode else controller_attach
		translate()

	if state == ATTACH and Input.is_action_just_pressed("lock"):
		state = MATCH3
		text = keyboard_match3 if Global.keyboard_mode else controller_match3
		translate()

	if state == MATCH3 and Global.first_match:
		state = FINISHED
		visible = false
		translate()

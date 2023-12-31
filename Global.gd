extends Node

var _bus := AudioServer.get_bus_index("Master")
var sound : float = db_to_linear(AudioServer.get_bus_volume_db(_bus))

var current_scene = null
var loading = false
var GRID_SIZE = 11
var LOCK_TIME = 0.01
var COMBO_TIME = 0.5
var ACTION_TIME = 0.1
var PENDING_TIME = 1.0
var COMBO_TIMEOUT = 5.0
var score = 0
var time = 0
var first_match = false

var keyboard_mode = true

func get_fill_cooldown():
	return 2.0

func get_spawn_count():
	var count = log(score+1) / 2 + 1

	if score > 1000.0:
		count += score / 1000

	return count

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() -1)

func goto_scene(path):
	call_deferred("_deferred_goto_scene", path)

func _deferred_goto_scene(s):
	if is_instance_valid(current_scene):
		# Immediately free the current scene,
		# there is no risk here.
		current_scene.free()

		# Instance the new scene.
		current_scene = s.instantiate()

		# Add it to the active scene, as child of root.
		get_tree().get_root().add_child(current_scene)

		# Optional, to make it compatible with the SceneTree.change_scene() API.
		get_tree().set_current_scene(current_scene)
		loading = false

func camera_shake(intensity = 1, duration = 1):
	var camera = get_node("/root/game/Camera2D")

	for i in range(duration):
		camera.position.x += intensity
		camera.position.y += intensity
		await get_tree().create_timer(0.1).timeout
		camera.position.x -= intensity
		camera.position.y -= intensity
		await get_tree().create_timer(0.1).timeout


func _unhandled_input(event):
	if (event is InputEventJoypadButton) or (event is InputEventJoypadMotion):
		keyboard_mode = false
	else:
		keyboard_mode = true

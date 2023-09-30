extends Node

var _bus := AudioServer.get_bus_index("Master")
var sound : float = db_to_linear(AudioServer.get_bus_volume_db(_bus))

var current_scene = null
var loading = false
var GRID_SIZE = 17
var LOCK_TIME = 0.01
var COMBO_TIME = 0.5
var ACTION_TIME = 0.05
var IDLE_TIME = 1.0
var COOLDOWN_VALUE = 3.0

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

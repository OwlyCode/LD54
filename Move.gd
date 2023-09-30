extends Node2D


@export var source: Vector2
@export var target: Vector2

var t = 0.0
var speed = 8.0

# Called when the node enters the scene tree for the first time.
func _ready():
	set_as_top_level(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	t += delta * speed

	position = source.lerp(target, clampf(t, 0, 1.0))

	if t > 2.0 * speed:
		queue_free()

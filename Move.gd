extends Node2D

var RED = Color.from_string("ecab11", Color.WHITE)
var BLUE = Color.from_string("2890dc", Color.WHITE)
var GREEN = Color.from_string("08b23b", Color.WHITE)
var VIOLET = Color.from_string("f78d8d", Color.WHITE)

var color = Block.BLUE

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

	match color:
		Block.RED:
			modulate = RED
		Block.BLUE:
			modulate = BLUE
		Block.GREEN:
			modulate = GREEN
		Block.VIOLET:
			modulate = VIOLET

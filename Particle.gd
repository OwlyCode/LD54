extends Sprite2D

@onready var target = get_node("/root/game/ParticleTarget").position
var color = Block.RED
var score = 0.0

var RED = Color.from_string("ecab11", Color.WHITE)
var BLUE = Color.from_string("2890dc", Color.WHITE)
var GREEN = Color.from_string("08b23b", Color.WHITE)
var VIOLET = Color.from_string("f78d8d", Color.WHITE)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = position.lerp(target, 0.1)

	match color:
		Block.RED:
			self_modulate = RED
		Block.BLUE:
			self_modulate = BLUE
		Block.GREEN:
			self_modulate = GREEN
		Block.VIOLET:
			self_modulate = VIOLET

	if position.distance_squared_to(target) < 2.0:
		Global.score += score
		queue_free()

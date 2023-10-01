extends Sprite2D

var fade_speed = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self_modulate.a -= delta * fade_speed

	if self_modulate.a < 0.0:
		queue_free()
	
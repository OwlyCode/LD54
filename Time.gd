extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var minutes = Global.time / 60
	var seconds = fmod(Global.time, 60)

	text = "%02d:%02d" % [minutes, seconds]

extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var grid = get_node("/root/game/GameGrid")
	var c = grid.combo_multiplier

	self_modulate.a = grid.combo_timeout / Global.COMBO_TIMEOUT

	visible = c > 1.0

	if c >= 16.0:
		text = "[center][b][wave][rainbow]COMBO x%d!!![/rainbow][/wave][/b][/center]" % c
	elif c >= 8.0:
		text = "[center][wave][b]COMBO x%d!!![/b][/wave][/center]" % c
	elif c >= 4.0:
		text = "[center][wave][b]COMBO x%d[/b][/wave][/center]" % c
	elif c >= 2.0:
		text = "[center][wave]COMBO x%d[/wave][/center]" % c

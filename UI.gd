extends TileMap

var direction = Block.DOWN

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var new_direction = get_node("/root/game/GameGrid").direction

	if direction != new_direction:
		direction = new_direction
		redraw()

func redraw():
	for i in range(0, Global.GRID_SIZE):
		for j in range(0, Global.GRID_SIZE):
			set_cell(0, Vector2i(i, j), -1, Vector2i(-1, -1))

	if direction == Block.DOWN:
		for i in range(0, Global.GRID_SIZE):
			for j in range(0, Global.GRID_SIZE / 2):
				set_cell(0, Vector2i(i, j), 1, Vector2i(0, 3))

	elif direction == Block.LEFT:
		for i in range(Global.GRID_SIZE / 2 + 1, Global.GRID_SIZE):
			for j in range(0, Global.GRID_SIZE):
				set_cell(0, Vector2i(i, j), 1, Vector2i(0, 3))

	elif direction == Block.UP:
		for i in range(0, Global.GRID_SIZE):
			for j in range(Global.GRID_SIZE / 2 + 1, Global.GRID_SIZE):
				set_cell(0, Vector2i(i, j), 1, Vector2i(0, 3))

	elif direction == Block.RIGHT:
		for i in range(0, Global.GRID_SIZE / 2):
			for j in range(0, Global.GRID_SIZE):
				set_cell(0, Vector2i(i, j), 1, Vector2i(0, 3))
extends TileMap

var GRID_SIZE = 16
var COOLDOWN_VALUE = 0.5

var state = []


var active_cells = []

var direction = Block.DOWN

var cooldown = COOLDOWN_VALUE

# Called when the node enters the scene tree for the first time.
func _ready():
	state = blank_state()

	state[5][15] = Block.new_blue()

	spawn_piece()

func blank_state():
	var new_state = []

	for i in range(GRID_SIZE):
		new_state.append([])
		new_state[i].resize(GRID_SIZE)

	return new_state


func can_move_down():
	for cell in active_cells:
		if cell[1] >= GRID_SIZE-1:
			return false

		if state[cell[0]][cell[1]+1] != null:
			return false

	return true

func move_down():
	for cell in active_cells:
		cell[1] += 1

func lock():
	for cell in active_cells:
		state[cell[0]][cell[1]] = cell[2]

	spawn_piece()


func spawn_piece():
	active_cells = [[5, 5, Block.new()], [6, 5, Block.new_blue()]]

func update_state():
	if direction == Block.DOWN:
		if can_move_down():
			move_down()
		else:
			lock()

func draw():
	clear()

	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if state[i][j] != null:
				set_cell(0, Vector2i(i, j), 1, state[i][j].get_color())

	for cell in active_cells:
		set_cell(0, Vector2i(cell[0], cell[1]), 1, cell[2].get_color())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	cooldown -= delta

	if cooldown < 0:
		cooldown = COOLDOWN_VALUE

		update_state()

	draw()

extends TileMap

var GRID_SIZE = 16
var COOLDOWN_VALUE = 0.5

var state = []

var active_cells = []

var direction = Block.UNDECIDED

var cooldown = COOLDOWN_VALUE
var action_cooldown = 0.05
var interacted = false
var push = []

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

func can_move_left():
	for cell in active_cells:
		if cell[0] == 0:
			return false

		if state[cell[0]-1][cell[1]] != null:
			return false

	return true

func move_left():
	for cell in active_cells:
		cell[0] -= 1


func can_move_right():
	for cell in active_cells:
		if cell[0] >= GRID_SIZE-1:
			return false

		if state[cell[0]+1][cell[1]] != null:
			return false

	return true

func move_right():
	for cell in active_cells:
		cell[0] += 1

func lock():
	for cell in active_cells:
		state[cell[0]][cell[1]] = cell[2]

	spawn_piece()


func spawn_piece():
	active_cells = [[7, 7, Block.new()], [8, 7, Block.new_blue()]]
	direction = Block.UNDECIDED

func update_state():
	if direction == Block.DOWN:
		if can_move_down():
			move_down()
		else:
			lock()

func interact():
	for p in push:
		if p == Block.LEFT and can_move_left():
			move_left()

		if p == Block.RIGHT and can_move_right():
			move_right()

		if p == Block.DOWN and can_move_down():
			move_down()

	push = []

func draw():
	clear()

	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if state[i][j] != null:
				set_cell(0, Vector2i(i, j), 1, state[i][j].get_color())

	for cell in active_cells:
		set_cell(0, Vector2i(cell[0], cell[1]), 1, cell[2].get_color())


func _process(_delta):
	draw()



func is_speedup():
	if Input.is_action_just_pressed("down") and direction == Block.DOWN:
		return true

	return false


func _physics_process(delta):
	if Input.is_action_just_pressed("down") or (Input.is_action_pressed("down") and action_cooldown < 0):
		if direction == Block.UNDECIDED:
			direction = Block.DOWN

		push.append(Block.DOWN)
		interacted = true

	if Input.is_action_just_pressed("left") or (Input.is_action_pressed("left") and action_cooldown < 0):
		push.append(Block.LEFT)
		interacted = true

	if Input.is_action_just_pressed("right") or (Input.is_action_pressed("right") and action_cooldown < 0):
		push.append(Block.RIGHT)
		interacted = true


	if interacted:
		action_cooldown = 0.1

	cooldown -= delta
	action_cooldown -= delta

	interact()
	interacted = false

	if cooldown < 0:
		cooldown = COOLDOWN_VALUE
		update_state()

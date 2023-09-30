extends TileMap

var GRID_SIZE = 24
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

	spawn_piece()

func blank_state():
	var new_state = []

	for i in range(GRID_SIZE):
		new_state.append([])
		new_state[i].resize(GRID_SIZE)

	return new_state


func can_move_up():
	for cell in active_cells:
		if cell[1] == 0:
			return false

		if state[cell[0]][cell[1]-1] != null:
			return false

	return true

func move_up():
	for cell in active_cells:
		cell[1] -= 1


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

func get_neighbors(cell):
	var n = []

	if cell[0] > 0:
		n.append([cell[0]-1, cell[1]])

	if cell[0] < GRID_SIZE - 1:
		n.append([cell[0]+1, cell[1]])

	if cell[1] > 0:
		n.append([cell[0], cell[1]-1])

	if cell[1] < GRID_SIZE - 1:
		n.append([cell[0], cell[1]+1])

	return n

func detect_match(cell):
	var color = cell[2].color
	var matched = []
	var visited = blank_state()
	var open = [[cell[0], cell[1]]]
	visited[cell[0]][cell[1]] = true

	while len(open) > 0:
		var current = open.pop_front()
		var neighbors = get_neighbors(current)

		if state[current[0]][current[1]] != null and state[current[0]][current[1]].color == color:
			matched.append(current)

			for n in neighbors:
				if visited[n[0]][n[1]] == null:
					open.append(n)
					visited[n[0]][n[1]] = true

	if len(matched) >= 3:
		return matched

	return []


func lock():
	for cell in active_cells:
		state[cell[0]][cell[1]] = cell[2]

	for cell in active_cells:
		for c in detect_match(cell):
			state[c[0]][c[1]] = null

	spawn_piece()


func spawn_piece():
	active_cells = [[11, 11, Block.new_random()], [12, 11, Block.new_random()]]
	direction = Block.UNDECIDED

func update_state():
	if direction == Block.DOWN:
		if can_move_down():
			move_down()
		else:
			lock()

	if direction == Block.UP:
		if can_move_up():
			move_up()
		else:
			lock()

	if direction == Block.LEFT:
		if can_move_left():
			move_left()
		else:
			lock()

	if direction == Block.RIGHT:
		if can_move_right():
			move_right()
		else:
			lock()

func interact():
	for p in push:
		if p == Block.LEFT and can_move_left() and direction != Block.RIGHT:
			move_left()

		if p == Block.RIGHT and can_move_right() and direction != Block.LEFT:
			move_right()

		if p == Block.DOWN and can_move_down() and direction != Block.UP:
			move_down()

		if p == Block.UP and can_move_up() and direction != Block.DOWN:
			move_up()

	push = []

func draw():
	clear()

	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if state[i][j] != null:
				set_cell(0, Vector2i(i, j), 1, state[i][j].get_color())
			else:
				set_cell(0, Vector2i(i, j), 1, Vector2i(1, 1))

	for cell in active_cells:
		set_cell(0, Vector2i(cell[0], cell[1]), 1, cell[2].get_color())


func _process(_delta):
	draw()

func _physics_process(delta):
	if Input.is_action_just_pressed("down") or (Input.is_action_pressed("down") and action_cooldown < 0):
		if direction == Block.UNDECIDED:
			direction = Block.DOWN

		push.append(Block.DOWN)
		interacted = true

	if Input.is_action_just_pressed("left") or (Input.is_action_pressed("left") and action_cooldown < 0):
		if direction == Block.UNDECIDED:
			direction = Block.LEFT

		push.append(Block.LEFT)
		interacted = true

	if Input.is_action_just_pressed("right") or (Input.is_action_pressed("right") and action_cooldown < 0):
		if direction == Block.UNDECIDED:
			direction = Block.RIGHT

		push.append(Block.RIGHT)
		interacted = true

	if Input.is_action_just_pressed("up") or (Input.is_action_pressed("up") and action_cooldown < 0):
		if direction == Block.UNDECIDED:
			direction = Block.UP

		push.append(Block.UP)
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

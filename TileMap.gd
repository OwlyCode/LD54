extends TileMap

var GRID_SIZE = 16
var COOLDOWN_VALUE = 0.5

var state = []
var gravity = []

var active_cells = []

var fluid_cells = []

var direction = Block.RIGHT

var cooldown = COOLDOWN_VALUE
var action_cooldown = 0.05
var interacted = false
var push = []


var drop_cooldown = COOLDOWN_VALUE
var lock_cooldown = COOLDOWN_VALUE

enum { DROPPING, LOCKING, COMBOING }

var game_state = DROPPING

func _ready():
	state = blank_state()
	gravity = blank_state()

	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			var left_dist = i
			var up_dist = j
			var right_dist = GRID_SIZE-1-i
			var down_dist = GRID_SIZE-1-j

			var min_val = GRID_SIZE * 2

			if left_dist < min_val:
				min_val = left_dist
				gravity[i][j] = Block.LEFT

			if right_dist < min_val:
				min_val = right_dist
				gravity[i][j] = Block.RIGHT

			if down_dist < min_val:
				min_val = down_dist
				gravity[i][j] = Block.DOWN

			if up_dist < min_val:
				min_val = up_dist
				gravity[i][j] = Block.UP

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

	var matched = []

	for cell in active_cells:
		for c in detect_match(cell):
			matched.append(c)
			change_state(c[0], c[1], null)

	if matched:
		pass # TODO effect

func change_state(x, y, block):
	state[x][y] = block

	for n in get_neighbors([x, y]):
		if state[n[0]][n[1]] != null:
			fluid_cells.append([n[0], n[1]])

	print(fluid_cells)

func pack():
	var lookup = [] + fluid_cells

	fluid_cells = []

	for cell in lookup:
		var i = cell[0]
		var j = cell[1]

		if state[i][j] != null:
			var with_color = state[i][j]

			for c in detect_match([i, j, with_color]):
				change_state(c[0], c[1], null)

			if gravity[i][j] == Block.DOWN:
				if j < GRID_SIZE - 1 and  state[i][j+1] == null:
					change_state(i, j+1, state[i][j])
					change_state(i, j, null)

			if gravity[i][j] == Block.UP:
				if j > 0 and  state[i][j-1] == null:
					change_state(i, j-1, state[i][j])
					change_state(i, j, null)

			if gravity[i][j] == Block.LEFT:
				if i > 0 and  state[i-1][j] == null:
					change_state(i-1, j, state[i][j])
					change_state(i, j, null)

			if gravity[i][j] == Block.RIGHT:
				if i < GRID_SIZE - 1 and  state[i+1][j] == null:
					change_state(i+1, j, state[i][j])
					change_state(i, j, null)


func spawn_piece():
	active_cells = [[GRID_SIZE/2, GRID_SIZE/2, Block.new_random()], [GRID_SIZE/2-1, GRID_SIZE/2, Block.new_random()]]

	if direction == Block.DOWN:
		direction = Block.LEFT
	elif direction == Block.UP:
			direction = Block.RIGHT
	elif direction == Block.RIGHT:
			direction = Block.DOWN
	elif direction == Block.LEFT:
			direction = Block.UP

func update_state():
	if direction == Block.DOWN:
		if can_move_down():
			move_down()
			set_game_state(DROPPING)
		else:
			set_game_state(LOCKING)

	if direction == Block.UP:
		if can_move_up():
			move_up()
			set_game_state(DROPPING)
		else:
			set_game_state(LOCKING)

	if direction == Block.LEFT:
		if can_move_left():
			move_left()
			set_game_state(DROPPING)
		else:
			set_game_state(LOCKING)

	if direction == Block.RIGHT:
		if can_move_right():
			move_right()
			set_game_state(DROPPING)
		else:
			set_game_state(LOCKING)

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


func rotate_piece():
	if len(active_cells) < 2:
		return

	var root_cell = active_cells[0]

	if active_cells[1][0] == root_cell[0] - 1: # LEFT
		if root_cell[1] > 0 and state[root_cell[0]][root_cell[1]-1] == null:
			active_cells[1][0] = root_cell[0]
			active_cells[1][1] = root_cell[1] - 1

	elif active_cells[1][0] == root_cell[0] + 1: # RIGHT
		if root_cell[1] < GRID_SIZE - 1 and state[root_cell[0]][root_cell[1]+1] == null:
			active_cells[1][0] = root_cell[0]
			active_cells[1][1] = root_cell[1] + 1

	elif active_cells[1][1] == root_cell[1] - 1: # UP
		if root_cell[0] < GRID_SIZE - 1 and state[root_cell[0]+1][root_cell[1]] == null:
			active_cells[1][0] = root_cell[0] + 1
			active_cells[1][1] = root_cell[1]

	elif active_cells[1][1] == root_cell[1] + 1: # DOWN
		if root_cell[0] > 0 and state[root_cell[0]-1][root_cell[1]] == null:
			active_cells[1][0] = root_cell[0] - 1
			active_cells[1][1] = root_cell[1]

func set_game_state(s):
	if s != game_state:
		if s == LOCKING:
			lock_cooldown = COOLDOWN_VALUE

	game_state = s

func _physics_process(delta):
	if game_state == LOCKING:
		lock_cooldown -= delta

		if lock_cooldown < 0:
			lock()
			lock_cooldown = COOLDOWN_VALUE
			set_game_state(DROPPING)
			spawn_piece()

	pack()

	if Input.is_action_just_pressed("down") or (Input.is_action_pressed("down") and action_cooldown < 0):
		if direction == Block.DOWN:
			cooldown = COOLDOWN_VALUE

		push.append(Block.DOWN)
		interacted = true

	if Input.is_action_just_pressed("left") or (Input.is_action_pressed("left") and action_cooldown < 0):
		if direction == Block.LEFT:
			cooldown = COOLDOWN_VALUE

		push.append(Block.LEFT)
		interacted = true

	if Input.is_action_just_pressed("right") or (Input.is_action_pressed("right") and action_cooldown < 0):
		if direction == Block.RIGHT:
			cooldown = COOLDOWN_VALUE

		push.append(Block.RIGHT)
		interacted = true

	if Input.is_action_just_pressed("up") or (Input.is_action_pressed("up") and action_cooldown < 0):
		if direction == Block.UP:
			cooldown = COOLDOWN_VALUE

		push.append(Block.UP)
		interacted = true



	if Input.is_action_just_pressed("rotate") or (Input.is_action_pressed("rotate") and action_cooldown < 0):
		rotate_piece()
		interacted = true


	if interacted:
		action_cooldown = 0.1

	action_cooldown -= delta

	interact()
	interacted = false

	if game_state == DROPPING:
		cooldown -= delta

		if cooldown < 0:
			cooldown = COOLDOWN_VALUE
			update_state()

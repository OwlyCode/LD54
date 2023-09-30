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

# Called when the node enters the scene tree for the first time.
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

	spawn_piece()


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
		push.append(Block.DOWN)
		interacted = true

	if Input.is_action_just_pressed("left") or (Input.is_action_pressed("left") and action_cooldown < 0):
		push.append(Block.LEFT)
		interacted = true

	if Input.is_action_just_pressed("right") or (Input.is_action_pressed("right") and action_cooldown < 0):
		push.append(Block.RIGHT)
		interacted = true

	if Input.is_action_just_pressed("up") or (Input.is_action_pressed("up") and action_cooldown < 0):
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

	pack()

extends TileMap

var state = []
var gravity = []

var active_cells = []

var next_pieces = [[Block.new_colored(Block.GREEN), Block.new_colored(Block.BLUE)]]

var fluid_cells = []
var matching_cells = []

var action_cooldown = Global.ACTION_TIME
var interacted = false
var push = []


var lock_cooldown = Global.LOCK_TIME
var combo_cooldown = Global.COMBO_TIME
var fill_cooldown = Global.FILL_COOLDOWN

enum { DROPPING, LOCKING, MATCHING }

var game_state = DROPPING

func _ready():
	state = blank_state()
	gravity = blank_state()

	for i in range(Global.GRID_SIZE):
		for j in range(Global.GRID_SIZE):
			var left_dist = i
			var up_dist = j
			var right_dist = Global.GRID_SIZE-1-i
			var down_dist = Global.GRID_SIZE-1-j

			var min_val = Global.GRID_SIZE * 2

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

	populate()

	spawn_piece()

func populate():
	for i in range(0, Global.GRID_SIZE):
		for j in range(0, 3):
			state[i][j] = Block.new_random()
			state[j][i] = Block.new_random()
			state[i][Global.GRID_SIZE - 1 - j] = Block.new_random()
			state[Global.GRID_SIZE - 1 - j][i] = Block.new_random()

func test_scenario():
	state[6][16] = Block.new_colored(Block.RED)

	state[8][16] = Block.new_colored(Block.GREEN)
	state[7][16] = Block.new_colored(Block.GREEN)
	state[7][15] = Block.new_colored(Block.BLUE)
	state[6][15] = Block.new_colored(Block.BLUE)
	state[7][14] = Block.new_colored(Block.RED)
	state[7][13] = Block.new_colored(Block.RED)

func blank_state():
	var new_state = []

	for i in range(Global.GRID_SIZE):
		new_state.append([])
		new_state[i].resize(Global.GRID_SIZE)

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
		if cell[1] >= Global.GRID_SIZE-1:
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
		if cell[0] >= Global.GRID_SIZE-1:
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

	if cell[0] < Global.GRID_SIZE - 1:
		n.append([cell[0]+1, cell[1]])

	if cell[1] > 0:
		n.append([cell[0], cell[1]-1])

	if cell[1] < Global.GRID_SIZE - 1:
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
		fluid_cells.append([cell[0], cell[1]])

	var matched = []

	for cell in active_cells:
		for c in detect_match(cell):
			matched.append(c)
			change_state(c[0], c[1], null)

	active_cells = []

	return matched

func change_state(x, y, block):
	state[x][y] = block

	for n in get_neighbors([x, y]):
		if state[n[0]][n[1]] != null:
			fluid_cells.append([n[0], n[1]])

func pack():
	var all_moved = []

	while len(fluid_cells) > 0:
		var lookup = [] + fluid_cells
		all_moved += fluid_cells

		fluid_cells = []

		for cell in lookup:
			var i = cell[0]
			var j = cell[1]

			if state[i][j] != null:
				if gravity[i][j] == Block.DOWN:
					if j < Global.GRID_SIZE - 1 and  state[i][j+1] == null:
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
					if i < Global.GRID_SIZE - 1 and  state[i+1][j] == null:
						change_state(i+1, j, state[i][j])
						change_state(i, j, null)

	var matches = []

	for cell in all_moved:
		var i = cell[0]
		var j = cell[1]

		if state[i][j] != null:
			var with_color = state[i][j]
			matches += detect_match([i, j, with_color])

	return matches


func spawn_piece():
	var blocks = next_pieces.pop_front()

	active_cells = [
		[Global.GRID_SIZE/2, Global.GRID_SIZE/2, blocks[0]],
		[Global.GRID_SIZE/2-1, Global.GRID_SIZE/2, blocks[1]]
	]

	next_pieces.append([
		Block.new_random(),
		Block.new_random()
	])

func interact():
	for p in push:
		if p == Block.LEFT and can_move_left():
			move_left()

		if p == Block.RIGHT and can_move_right():
			move_right()

		if p == Block.DOWN and can_move_down():
			move_down()

		if p == Block.UP and can_move_up():
			move_up()

	push = []

var blink_timer = 0.0

func draw(delta):
	clear()

	var active_grid = get_node("/root/game/ActiveGrid")

	active_grid.clear()

	for i in range(Global.GRID_SIZE):
		for j in range(Global.GRID_SIZE):
			if state[i][j] != null:
				set_cell(0, Vector2i(i, j), 1, state[i][j].get_color())

	for cell in active_cells:
		set_cell(0, Vector2i(cell[0], cell[1]), 1, Vector2i(1, 1))
		active_grid.set_cell(0, Vector2i(cell[0], cell[1]), 1, cell[2].get_color())

func _process(delta):
	draw(delta)
	display_debug()

func rotate_piece():
	if len(active_cells) < 2:
		return

	var root_cell = active_cells[0]

	if active_cells[1][0] == root_cell[0] - 1: # LEFT
		if root_cell[1] > 0 and state[root_cell[0]][root_cell[1]-1] == null:
			active_cells[1][0] = root_cell[0]
			active_cells[1][1] = root_cell[1] - 1

	elif active_cells[1][0] == root_cell[0] + 1: # RIGHT
		if root_cell[1] < Global.GRID_SIZE - 1 and state[root_cell[0]][root_cell[1]+1] == null:
			active_cells[1][0] = root_cell[0]
			active_cells[1][1] = root_cell[1] + 1

	elif active_cells[1][1] == root_cell[1] - 1: # UP
		if root_cell[0] < Global.GRID_SIZE - 1 and state[root_cell[0]+1][root_cell[1]] == null:
			active_cells[1][0] = root_cell[0] + 1
			active_cells[1][1] = root_cell[1]

	elif active_cells[1][1] == root_cell[1] + 1: # DOWN
		if root_cell[0] > 0 and state[root_cell[0]-1][root_cell[1]] == null:
			active_cells[1][0] = root_cell[0] - 1
			active_cells[1][1] = root_cell[1]

func set_game_state(s):
	if s != game_state:
		if s == LOCKING:
			lock_cooldown = Global.LOCK_TIME
		if s == MATCHING:
			lock_cooldown = Global.COMBO_TIME

	game_state = s

func _physics_process(delta):
	if game_state == LOCKING:
		lock_cooldown -= delta

		if lock_cooldown < 0:
			matching_cells = lock()
			lock_cooldown = Global.LOCK_TIME

			if len(matching_cells) > 0:
				set_game_state(MATCHING)
			else:
				matching_cells = pack()

				if len(matching_cells) > 0:
					set_game_state(MATCHING)
				else:
					set_game_state(DROPPING)
					spawn_piece()

	if game_state == MATCHING:
		combo_cooldown -= delta

		if combo_cooldown < 0:
			for c in matching_cells:
				change_state(c[0], c[1], null)

			matching_cells = pack()
			combo_cooldown = Global.COMBO_TIME

			if not(matching_cells):
				set_game_state(DROPPING)
				spawn_piece()

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

	if Input.is_action_just_pressed("rotate"):
		rotate_piece()
		interacted = true


	if interacted:
		action_cooldown = Global.ACTION_TIME

	action_cooldown -= delta

	interact()
	interacted = false

	if game_state == DROPPING:
		fill_cooldown -= delta

		if fill_cooldown < 0:
			fill()
			fill_cooldown = Global.FILL_COOLDOWN

		if Input.is_action_just_pressed("lock") and is_touching():
			set_game_state(LOCKING)


func is_touching():
	for x in active_cells:
		for n in get_neighbors(x):
			if state[n[0]][n[1]] != null:
				return true
	return false

func display_debug():
	var debug_ts = get_node("/root/game/Debug")
	debug_ts.clear()

	for x in fluid_cells:
		debug_ts.set_cell(0, Vector2i(x[0], x[1]), 1, Vector2i(2, 3))


func is_column_full(x):
	for i in range(0, Global.GRID_SIZE):
		if state[x][i] == null:
			return false

	return true

func is_line_full(x):
	for i in range(0, Global.GRID_SIZE):
		if state[i][x] == null:
			return false

	return true


func fill():
	var left = 0
	var right = Global.GRID_SIZE - 1
	var top = 0
	var bottom = Global.GRID_SIZE - 1

	while is_column_full(left) and left < Global.GRID_SIZE/2:
		left += 1

	while is_column_full(right) and right > Global.GRID_SIZE/2:
		right -= 1

	while is_line_full(top) and top < Global.GRID_SIZE/2:
		top += 1

	while is_line_full(bottom) and bottom > Global.GRID_SIZE/2:
		bottom -= 1


	for i in range(0, Global.GRID_SIZE):
		if state[left][i] == null:
			state[left][i] = Block.new_random()

	for i in range(0, Global.GRID_SIZE):
		if state[right][i] == null:
			state[right][i] = Block.new_random()


	for i in range(0, Global.GRID_SIZE):
		if state[i][bottom] == null:
			state[i][bottom] = Block.new_random()

	for i in range(0, Global.GRID_SIZE):
		if state[i][top] == null:
			state[i][top] = Block.new_random()

	print([left, right, top, bottom])

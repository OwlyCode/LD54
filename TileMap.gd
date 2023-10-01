extends TileMap

var state = []
var gravity = []
var last_dir = Block.DOWN

var active_cells = []

var next_pieces = [[Block.new_colored(Block.GREEN), Block.new_colored(Block.BLUE)]]

var fluid_cells = []
var matching_cells = []

var action_cooldown = Global.ACTION_TIME
var interacted = false
var push = []


var lock_cooldown = Global.LOCK_TIME
var combo_cooldown = Global.COMBO_TIME
var fill_cooldown = Global.get_fill_cooldown()


var defusals = 0

enum { DROPPING, LOCKING, MATCHING, LOST, PAUSED }

var game_state = DROPPING

var combo_multiplier = 0.0

var combo_timeout = Global.COMBO_TIMEOUT

var MovementFx = preload("res://movement_fx.tscn")
var ExplosionFx = preload("res://explosion.tscn")
var ParticleFx = preload("res://particle.tscn")
var Fader = preload("res://fader.tscn")

var placed_sound_offset = 0

@onready var placed_sound = [
	get_node("/root/game/Audio/Placed1"),
	get_node("/root/game/Audio/Placed2"),
	get_node("/root/game/Audio/Placed3")
]

var match_sequence = 0

@onready var match_sound = [
	get_node("/root/game/Audio/Match1"),
	get_node("/root/game/Audio/Match2"),
	get_node("/root/game/Audio/Match3"),
	get_node("/root/game/Audio/Match4")
]

@onready var rotate_sound = get_node("/root/game/Audio/Rotate")

@onready var denied_sound = get_node("/root/game/Audio/Denied")



func _ready():
	state = blank_state()
	gravity = blank_state()

	Global.score = 0
	Global.time = 0
	Global.first_match = false

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
		for j in range(0, 1):
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
		n.append([cell[0]-1, cell[1], Block.LEFT])

	if cell[0] < Global.GRID_SIZE - 1:
		n.append([cell[0]+1, cell[1], Block.RIGHT])

	if cell[1] > 0:
		n.append([cell[0], cell[1]-1, Block.UP])

	if cell[1] < Global.GRID_SIZE - 1:
		n.append([cell[0], cell[1]+1, Block.DOWN])

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
	if active_border == Block.DOWN:
		for i in range(0, Global.GRID_SIZE):
			for j in range(Global.GRID_SIZE/2, Global.GRID_SIZE):
				if state[i][j] != null:
					fluid_cells.append([i, j])

	if active_border == Block.UP:
		for i in range(0, Global.GRID_SIZE):
			for j in range(0, Global.GRID_SIZE/2+1):
				if state[i][j] != null:
					fluid_cells.append([i, j])

	if active_border == Block.LEFT:
		for i in range(0, Global.GRID_SIZE/2+1):
			for j in range(0, Global.GRID_SIZE):
				if state[i][j] != null:
					fluid_cells.append([i, j])
		print(len(fluid_cells))

	if active_border == Block.RIGHT:
		for i in range(Global.GRID_SIZE/2, Global.GRID_SIZE):
			for j in range(0, Global.GRID_SIZE):
				if state[i][j] != null:
					fluid_cells.append([i, j])

	for cell in active_cells:
		change_state(cell[0], cell[1], cell[2])
		fluid_cells.append([cell[0], cell[1]])

	placed_sound[placed_sound_offset].play()
	placed_sound_offset = (placed_sound_offset + 1) % 3

	var matched = []

	for cell in active_cells:
		for c in detect_match(cell):
			matched.append(c)

	active_cells = []

	if len(matched) == 0:
		combo_multiplier = 0.0
	else:
		Global.first_match = true
		combo_timeout = Global.COMBO_TIMEOUT
		combo_multiplier += 1.0

	return matched

func change_state(x, y, block):
	state[x][y] = block

	for n in get_neighbors([x, y]):
		if state[n[0]][n[1]] != null:
			fluid_cells.append([n[0], n[1]])

func pack():
	var all_moved = []
	var moved = false

	while len(fluid_cells) > 0:
		var lookup = [] + fluid_cells
		all_moved += fluid_cells

		fluid_cells = []

		for cell in lookup:
			var i = cell[0]
			var j = cell[1]

			if active_border == Block.DOWN and j <= Global.GRID_SIZE / 2:
				continue

			if active_border == Block.UP and j >= Global.GRID_SIZE / 2:
				continue

			if active_border == Block.LEFT and i >= Global.GRID_SIZE / 2:
				continue

			if active_border == Block.RIGHT and i <= Global.GRID_SIZE / 2:
				continue

			if state[i][j] != null:
				if active_border == Block.DOWN:
					var o = 1
					var e = false
					while j < Global.GRID_SIZE - o and state[i][j+o] == null:
						e = true
						o += 1

					if e:
						moved = true
						o -= 1
						var movement = MovementFx.instantiate()
						movement.source = map_to_local(Vector2i(i, j))
						movement.target = map_to_local(Vector2i(i, j+o))
						movement.color = state[i][j].color
						add_child(movement)

						change_state(i, j+o, state[i][j])
						change_state(i, j, null)

				if active_border == Block.UP:
					var o = 1
					var e = false

					while j-o >= 0 and  state[i][j-o] == null:
						e = true
						o += 1

					if e:
						moved = true
						o -= 1
						var movement = MovementFx.instantiate()
						movement.source = map_to_local(Vector2i(i, j))
						movement.target = map_to_local(Vector2i(i, j-o))
						movement.color = state[i][j].color
						add_child(movement)

						change_state(i, j-o, state[i][j])
						change_state(i, j, null)

				if active_border == Block.LEFT:
					var o = 1
					var e = false

					while i-o >= 0 and  state[i-o][j] == null:
						e = true
						o += 1

					if e:
						moved = true
						o -= 1
						var movement = MovementFx.instantiate()
						movement.source = map_to_local(Vector2i(i, j))
						movement.target = map_to_local(Vector2i(i-o, j))
						movement.color = state[i][j].color
						add_child(movement)

						change_state(i-o, j, state[i][j])
						change_state(i, j, null)

				if active_border == Block.RIGHT:
					var o = 1
					var e = false

					while i < Global.GRID_SIZE - o and  state[i+o][j] == null:
						e = true
						o += 1

					if e:
						moved = true
						o -= 1
						var movement = MovementFx.instantiate()
						movement.source = map_to_local(Vector2i(i, j))
						movement.target = map_to_local(Vector2i(i+o, j))
						movement.color = state[i][j].color
						add_child(movement)

						change_state(i+o, j, state[i][j])
						change_state(i, j, null)

	if moved:
		placed_sound[placed_sound_offset].play()
		placed_sound_offset = (placed_sound_offset + 1) % 3

	var matches = []

	for cell in all_moved:
		var i = cell[0]
		var j = cell[1]

		if state[i][j] != null:
			var with_color = state[i][j]
			matches += detect_match([i, j, with_color])

	if len(matches) > 0:
		combo_multiplier += 2
		combo_timeout = Global.COMBO_TIMEOUT

	return matches


func spawn_piece():
	var blocks = next_pieces.pop_front()

	var possible_positions = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]

	if state[Global.GRID_SIZE/2][Global.GRID_SIZE/2] != null:
		set_game_state(LOST)
		return

	possible_positions = possible_positions.filter(func (p):
		return state[Global.GRID_SIZE/2 + p.x][Global.GRID_SIZE/2 + p.y] == null
	)

	if len(possible_positions) == 0:
		set_game_state(LOST)
		return

	active_cells = [
		[Global.GRID_SIZE/2, Global.GRID_SIZE/2, blocks[0]],
		[Global.GRID_SIZE/2 + possible_positions[0].x, Global.GRID_SIZE/2 + possible_positions[0].y, blocks[1]]
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

	var ui = get_node("/root/game/UI")

	if len(next_pieces) > 0:
		var next = next_pieces[0]

		ui.set_cell(0, Vector2i(-4, 5), 1, next[0].get_color())
		ui.set_cell(0, Vector2i(-3, 5), 1, next[1].get_color())

	clear()

	alert()

	var active_grid = get_node("/root/game/ActiveGrid")

	var modul = lerpf(0.5, 1.0, (1 + sin(Engine.get_frames_drawn() / 5.0))/2.0)

	active_grid.modulate.a = modul

	active_grid.clear()

	for i in range(Global.GRID_SIZE):
		for j in range(Global.GRID_SIZE):
			if state[i][j] != null:
				set_cell(0, Vector2i(i, j), 1, state[i][j].get_color())

	for cell in active_cells:
		#set_cell(0, Vector2i(cell[0], cell[1]), 1, Vector2i(1, 1))
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
			rotate_sound.play()
			active_cells[1][0] = root_cell[0]
			active_cells[1][1] = root_cell[1] - 1
		else:
			denied_sound.play()

	elif active_cells[1][0] == root_cell[0] + 1: # RIGHT
		if root_cell[1] < Global.GRID_SIZE - 1 and state[root_cell[0]][root_cell[1]+1] == null:
			rotate_sound.play()
			active_cells[1][0] = root_cell[0]
			active_cells[1][1] = root_cell[1] + 1
		else:
			denied_sound.play()

	elif active_cells[1][1] == root_cell[1] - 1: # UP
		if root_cell[0] < Global.GRID_SIZE - 1 and state[root_cell[0]+1][root_cell[1]] == null:
			rotate_sound.play()
			active_cells[1][0] = root_cell[0] + 1
			active_cells[1][1] = root_cell[1]
		else:
			denied_sound.play()

	elif active_cells[1][1] == root_cell[1] + 1: # DOWN
		if root_cell[0] > 0 and state[root_cell[0]-1][root_cell[1]] == null:
			rotate_sound.play()
			active_cells[1][0] = root_cell[0] - 1
			active_cells[1][1] = root_cell[1]
		else:
			denied_sound.play()

func set_game_state(s):
	if s != game_state:
		if s == LOCKING:
			lock_cooldown = Global.LOCK_TIME
		if s == MATCHING:
			lock_cooldown = Global.COMBO_TIME
		if s == LOST:
			get_node("/root/game/GameOverContainer").visible = true
			get_node("/root/game/GameOverContainer/Restart").grab_focus()

	game_state = s

func _physics_process(delta):
	if game_state != LOST:
		Global.time += delta

	if game_state == LOST:
		return

	if game_state == LOCKING:
		lock_cooldown -= delta

		if lock_cooldown < 0:
			matching_cells = lock()
			lock_cooldown = Global.LOCK_TIME

			if len(matching_cells) > 0:
				match_sound[match_sequence].play()
				match_sequence = min(match_sequence + 1, 3)
				Global.camera_shake(1, 2)
				set_game_state(MATCHING)
			else:
				matching_cells = pack()

				if len(matching_cells) > 0:
					match_sound[match_sequence].play()
					match_sequence = min(match_sequence + 1, 3)
					Global.camera_shake(1, 2)
					set_game_state(MATCHING)
				else:
					set_game_state(DROPPING)
					spawn_piece()

	if game_state == MATCHING:
		combo_cooldown -= delta

		if combo_cooldown < 0:
			for c in matching_cells:
				if state[c[0]][c[1]] == null: # quick hack for double color matching twice the same blocks
					continue

				var explosion = ExplosionFx.instantiate()
				explosion.position = map_to_local(Vector2i(c[0], c[1]))
				explosion.emitting = true
				add_child(explosion)

				var particle = ParticleFx.instantiate()
				particle.position = map_to_local(Vector2i(c[0], c[1]))
				particle.color = state[c[0]][c[1]].color
				particle.score = max(1.0, combo_multiplier)
				add_child(particle)

				change_state(c[0], c[1], null)

				for n in get_neighbors(c):
					if state[n[0]][n[1]] != null:
						fluid_cells.append([n[0], n[1]])

			matching_cells = pack()
			combo_cooldown = Global.COMBO_TIME

			if not(matching_cells):
				set_game_state(DROPPING)
				spawn_piece()
				match_sequence = 0
			else:
				match_sound[match_sequence].play()
				match_sequence = min(match_sequence + 1, 3)
				Global.camera_shake(1, 2)

	if Input.is_action_just_pressed("down") or (Input.is_action_pressed("down") and action_cooldown < 0):
		push.append(Block.DOWN)
		last_dir = Block.DOWN
		interacted = true

	if Input.is_action_just_pressed("left") or (Input.is_action_pressed("left") and action_cooldown < 0):
		push.append(Block.LEFT)
		last_dir = Block.LEFT
		interacted = true

	if Input.is_action_just_pressed("right") or (Input.is_action_pressed("right") and action_cooldown < 0):
		push.append(Block.RIGHT)
		last_dir = Block.RIGHT
		interacted = true

	if Input.is_action_just_pressed("up") or (Input.is_action_pressed("up") and action_cooldown < 0):
		push.append(Block.UP)
		last_dir = Block.UP
		interacted = true

	if Input.is_action_just_pressed("rotate"):
		rotate_piece()
		interacted = true

	get_closest_edge()

	if interacted:
		action_cooldown = Global.ACTION_TIME

	action_cooldown -= delta

	interact()
	interacted = false

	if game_state == DROPPING:

		combo_timeout -= delta

		if combo_timeout < 0.0:
			combo_multiplier = 0.0
			combo_timeout = Global.COMBO_TIMEOUT

		fill_cooldown -= delta

		if fill_cooldown < 0 and Global.first_match:
			for i in range(0, Global.get_spawn_count()):
				add_pending()
			fill_cooldown = Global.get_fill_cooldown()

		if Input.is_action_just_pressed("lock"):
			if is_touching():
				set_game_state(LOCKING)
			else:
				denied_sound.play()

		for i in range(pending.size()):
			if i >= pending.size():
				break

			var p = pending[i]

			p[2] -= delta

			var overlapping = active_cells.filter(func (c): return  c[0] == p[0] and c[1] == p[1])

			if p[2] < 0 and len(overlapping) == 0:
				if state[p[0]][p[1]] == null:
					state[p[0]][p[1]] = Block.new_random()

					var fader = Fader.instantiate()
					fader.position = map_to_local(Vector2i(p[0], p[1]))
					add_child(fader)

					# TODO spawn

				pending.remove_at(i)
			else:
				if state[p[0]][p[1]] != null:
					pending.remove_at(i)
				else:
					var attached = false

					if p[0] == 0 or p[1] == 0 or p[0] == Global.GRID_SIZE - 1 or p[1] == Global.GRID_SIZE - 1:
						attached = true

					for n in get_neighbors(p):
						if state[n[0]][n[1]] != null:
							attached = true

					if not attached:
						pending.remove_at(i)


func is_touching():
	for x in active_cells:
		if x[0] == 0:
			return true

		if x[1] == 0:
			return true

		if x[0] == Global.GRID_SIZE - 1:
			return true

		if x[1] == Global.GRID_SIZE - 1:
			return true

		for n in get_neighbors(x):
			if state[n[0]][n[1]] != null:
				return true

	return false

func display_debug():
	var debug_ts = get_node("/root/game/Debug")
	debug_ts.clear()

	# for x in fluid_cells:
	# 	debug_ts.set_cell(0, Vector2i(x[0], x[1]), 1, Vector2i(3, 3))

	for x in matching_cells:
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


func add_pending():
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

	var candidates = []

	for i in range(0, Global.GRID_SIZE):
		if state[left][i] == null:
			candidates.append([left, i])

	for i in range(0, Global.GRID_SIZE):
		if state[right][i] == null:
			candidates.append([right, i])


	for i in range(0, Global.GRID_SIZE):
		if state[i][bottom] == null:
			candidates.append([i, bottom])

	for i in range(0, Global.GRID_SIZE):
		if state[i][top] == null:
			candidates.append([i, top])

	candidates = candidates.filter(func (c):
		for p in pending:
			if p[0] == c[0] and p[1] == c[1]:
				return false

		return true
	)

	if len(candidates) == 0:
		return

	var candidate = candidates[randi() % candidates.size()]
	candidate.append(Global.PENDING_TIME)

	pending.append(candidate)


var pending = []

func alert():
	for p in pending:
		set_cell(0, Vector2i(p[0], p[1]), 1, Vector2i(0, 2))

func get_closest(x, y, color):
	var left = 0
	var right = 0
	var up = 0
	var down = 0

	while x-left >= 0 and (state[x-left][y] == null or left == 0):
		left += 1

	while x+right < Global.GRID_SIZE and (state[x+right][y] == null or right == 0):
		right += 1

	while y-up >= 0 and (state[x][y-up] == null or up == 0):
		up += 1

	while y+down < Global.GRID_SIZE and (state[x][y+down] == null or down == 0):
		down += 1

	left -= 1
	right -= 1
	up -= 1
	down -= 1

	var closest = left
	var closest_point = [x-left, y]

	if right < closest:
		closest = right
		closest_point = [x+right, y]

	if right == closest and state[x+right][y] != null and state[x+right][y].color == color:
		closest = right
		closest_point = [x+right, y]

	if down < closest:
		closest = down
		closest_point = [x, y+down]

	if down == closest and state[x][y+down] != null and state[x][y+down].color == color:
		closest = down
		closest_point = [x, y+down]

	if up < closest:
		closest = up
		closest_point = [x, y-up]

	if up == closest and state[x][y-up] != null and  state[x][y-up].color == color:
		closest = up
		closest_point = [x, y-up]

	return closest_point


var active_border = Block.DOWN

func get_closest_edge():
	draw_gravity()

	var closests = []

	for c in active_cells:
		for n in get_neighbors(c):
			if state[n[0]][n[1]] != null:
				closests.append(n[2])

		# if c[0] < Global.GRID_SIZE / 2:
		# 	closests.append(Block.LEFT)
		# elif c[0] > Global.GRID_SIZE / 2:
		# 	closests.append(Block.RIGHT)
		# if c[1] < Global.GRID_SIZE / 2:
		# 	closests.append(Block.UP)
		# elif c[1] > Global.GRID_SIZE / 2:
		# 	closests.append(Block.DOWN)

	print(closests)

	if closests.find(last_dir) != -1:
		active_border = last_dir


func draw_gravity():
	var ui = get_node("/root/game/UI")

	for i in range(Global.GRID_SIZE + 2):
		ui.set_cell(0, Vector2i(-1, -1 + i), 1, Vector2i(3, 5)) # LEFT
		ui.set_cell(0, Vector2i(-1 + i, -1), 1, Vector2i(3, 5)) # UP
		ui.set_cell(0, Vector2i(-1 + i, 11), 1, Vector2i(3, 5)) # DOWN
		ui.set_cell(0, Vector2i(11, -1 + i), 1, Vector2i(3, 5)) # RIGHT

	if active_border == Block.LEFT:
		for i in range(Global.GRID_SIZE + 2):
			ui.set_cell(0, Vector2i(-1, -1 + i), 1, Vector2i(3, 6)) # LEFT

	if active_border == Block.UP:
		for i in range(Global.GRID_SIZE + 2):
			ui.set_cell(0, Vector2i(-1 + i, -1), 1, Vector2i(3, 6)) # UP

	if active_border == Block.DOWN:
		for i in range(Global.GRID_SIZE + 2):
			ui.set_cell(0, Vector2i(-1 + i, 11), 1, Vector2i(3, 6)) # DOWN

	if active_border == Block.RIGHT:
		for i in range(Global.GRID_SIZE + 2):
			ui.set_cell(0, Vector2i(11, -1 + i), 1, Vector2i(3, 6)) # RIGHT

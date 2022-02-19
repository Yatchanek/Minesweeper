extends TileMap

var flag_positions = []
var mine_positions = []
var grid_size
var flag_count
var first_click

var explosion = preload("res://scenes/explosion.tscn")

signal game_over
signal game_won
signal flag_placed_removed
signal place_label

func generate_grid(size):
	grid_size = size
	first_click = true
	clear()
	flag_positions = []
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			set_cell(x, y, 0)
	

func place_mines(mine_count):
	randomize()
	mine_positions = []
	for _i in range(mine_count):
		var pos = Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y))
		while mine_positions.has(pos):
			pos = Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y))
		mine_positions.append(pos)
	flag_count = mine_count
		
func check_neighbours(cell) -> int:
	var neighbour_mines = 0
	for y in range(cell.y - 1, cell.y + 2):
		for x in range(cell.x - 1, cell.x + 2):
			var neighbour = Vector2(x, y)
			if neighbour == cell or !get_used_cells().has(neighbour):
				continue
			if mine_positions.has(neighbour):
				neighbour_mines += 1	
	return neighbour_mines
	
func change_mine_position(cell):
	mine_positions.erase(cell)
	var pos = Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y))
	while mine_positions.has(pos):
		pos = Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y))		
	mine_positions.append(pos)
	
func mark(cell):
	if !get_used_cells().has(cell):
		return
	var cell_value = get_cellv(cell)
	if ![0, 3, 4].has(cell_value):
		return
	if cell_value == 0:
		if flag_count > 0:
			set_cellv(cell, 3)
			flag_count -= 1
			flag_positions.append(cell)
		else:
			set_cellv(cell, 4)
		
	elif cell_value == 3:
		set_cellv(cell, 4)
		flag_positions.erase(cell)
		flag_count += 1		
	else:
		set_cellv(cell, 0)

	check_for_win()
	emit_signal("flag_placed_removed", flag_count)

func handle_click(cell):
	if !get_used_cells().has(cell) or get_cellv(cell) == 2:
		return
	if mine_positions.has(cell):
		if first_click:
			change_mine_position(cell)
			first_click = false
			reveal(cell)
		else:
			set_cellv(cell, 1)
			explode(cell)
			yield(get_tree().create_timer(0.25), "timeout")
			for mine in mine_positions:
				if mine == cell:
					continue
				var tile_value = get_cellv(mine)
				if tile_value == 3:
					set_cellv(mine, 5)
				else:
					set_cellv(mine, 1)
					explode(mine)
					yield(get_tree(), "idle_frame")	
			emit_signal("game_over")
	else:
		reveal(cell)
		
func reveal(cell):
		if first_click:
			first_click = false

		var neighbour_mines = check_neighbours(cell)
		set_cellv(cell, 2)
		check_for_win()
		
		if neighbour_mines == 0:
			var neighbours = get_valid_neighbours(cell)
			for neighbour in neighbours:
				if !mine_positions.has(neighbour) and get_cellv(neighbour) == 0:
					reveal(neighbour)
		else:
			emit_signal("place_label", map_to_world(cell), str(neighbour_mines))

func check_for_win():
	if flag_count > 0:
		return false
	for cell in get_used_cells():
		if get_cellv(cell) == 0 or get_cellv(cell) == 4:
			return false
	for mine in mine_positions:
		if !flag_positions.has(mine):
			return false
	for mine in mine_positions:
		set_cellv(mine, 5)
	emit_signal("game_won")

func get_valid_neighbours(cell):
	var neighbours = []
	for y in range(cell.y - 1, cell.y + 2):
		for x in range(cell.x - 1, cell.x + 2):
			var neighbour = Vector2(x, y)
			if get_used_cells().has(neighbour) and neighbour != cell:
				neighbours.append(neighbour)
	return neighbours

func explode(cell):
	var ex = explosion.instance()
	add_child(ex)
	ex.position = map_to_world(cell) + cell_size * 0.5
	ex.emitting = true

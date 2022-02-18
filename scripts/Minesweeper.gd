extends Node2D

onready var tilemap = $TileMap
onready var endgame_label = $HUD/Label
onready var label_container = $LabelContainer
onready var file_menu = $HUD/Menu/HBoxContainer/FileMenuButton
onready var options_menu = $HUD/Menu/HBoxContainer/OptionsButton
onready var popup = $HUD/Menu/CustomGridSize
onready var color_popup = $HUD/Menu/ColorPicker
onready var color_selector = $HUD/Menu/ColorPicker/Panel/MarginContainer/ColorSelect
onready var max_mines_input = $HUD/Menu/CustomGridSize/Panel/MarginContainer/VBoxContainer/VBoxContainer2/MaxMines
onready var flag_label = $HUD/Menu/FlagLabel

var number_label = preload("res://scenes/number_label.tscn")
var explosion = preload("res://scenes/explosion.tscn")

var grid_size = Vector2(9, 9)
var custom_grid_size = Vector2(5, 5)
var cell_size = Vector2.ZERO
var label_color = Color(0.1, 0.1, 0.1)

var mine_count
var custom_mine_count
var game_over = false
var in_menu = false
var skill_level = 1
var in_game = false

func _unhandled_input(event):
	if in_menu:
		return
	if event is InputEventMouseButton and event.is_pressed():
		var pos = get_global_mouse_position()
		var cell = tilemap.world_to_map(to_local(pos))
		if event.button_index == BUTTON_LEFT:
			if game_over:
				start_game()
			else:
				tilemap.handle_click(cell)
				
		if event.button_index == BUTTON_RIGHT:
			if game_over:
				return
			tilemap.mark(cell)

func _ready():
	cell_size = tilemap.cell_size
	file_menu.get_popup().connect("id_pressed", self, "_on_File_menu_pressed")
	file_menu.get_popup().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	options_menu.get_popup().connect("id_pressed", self, "_on_Options_menu_pressed")
	options_menu.get_popup().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for color_rect in color_selector.get_children():
		color_rect.get_node("Button").connect("pressed", self, "_on_Color_selected", [color_rect.get_node("Button")])
	
func start_game():
	var ratio = 1.0
	if cell_size.y * grid_size.y > 840:
		ratio = 820 / (cell_size.y * grid_size.y)
	
	if cell_size.x * grid_size.x > 860 and grid_size.x > grid_size.y:
		ratio = 860 / (cell_size * grid_size.x)		
	  
	position = Vector2(0, 40) + Vector2((get_viewport().size.x - cell_size.x * grid_size.x * ratio) / 2, (get_viewport().size.y - 40 - cell_size.y * grid_size.y * ratio) / 2)
	scale = Vector2(ratio, ratio)
	
	if skill_level > 0:
		mine_count = floor(grid_size.x * grid_size.y * (0.135 + skill_level * 0.015))

	flag_label.text = "Flags: %s" % str(mine_count)
	
	tilemap.generate_grid(grid_size)
	tilemap.place_mines(mine_count)
	
	for l in label_container.get_children():
		l.queue_free()
	
	endgame_label.hide()
	in_game = true
	game_over = false
	
func _on_File_menu_pressed(id):
	match id:
		0:
			start_game()
		1:
			get_tree().quit()

func _on_Options_menu_pressed(id):
	match id:
		1:
			grid_size = Vector2(9, 9)
			skill_level = 1
			if in_game:
				start_game()
		2:
			grid_size = Vector2(12, 12)
			skill_level = 2
			if in_game:
				start_game()
		3:
			grid_size = Vector2(20, 20)
			skill_level = 3
			if in_game:
				start_game()
		4:
			popup.popup()
			in_menu = true
			skill_level = 0
		5:
			color_popup.popup()
			in_menu = true

func _on_X_value_changed(value):
	custom_grid_size.x = value
	max_mines_input.min_value = ceil(custom_grid_size.x * custom_grid_size.y * 0.1)
	max_mines_input.max_value = ceil(custom_grid_size.x * custom_grid_size.y * 0.33)
		
func _on_Y_value_changed(value):
	custom_grid_size.y = value
	max_mines_input.min_value = ceil(custom_grid_size.x * custom_grid_size.y * 0.1)
	max_mines_input.max_value = ceil(custom_grid_size.x * custom_grid_size.y * 0.33)
		
func _on_Button_pressed():
	popup.hide()
	grid_size = custom_grid_size
	mine_count = custom_mine_count
	in_menu = false
	if in_game:
		start_game()

func _on_Color_selected(button):
	var color = button.get_parent().color
	tilemap.modulate = color
	color_popup.hide()
	var avg = (color.r + color.g + color.b) / 3
	print(avg)
	if avg < 0.3:
		label_color = Color(0.87, 0.87, 0.87	)
	else:
		label_color = Color(0.13, 0.13, 0.13)
	for l in label_container.get_children():
		l.modulate = label_color
	in_menu = false

func _on_CustomGridSize_about_to_show():
	max_mines_input.min_value = ceil(custom_grid_size.x * custom_grid_size.y * 0.1)
	max_mines_input.max_value = ceil(custom_grid_size.x * custom_grid_size.y * 0.33)
	custom_mine_count = ceil(custom_grid_size.x * custom_grid_size.y * 0.15)
	max_mines_input.value = custom_mine_count

func _on_MaxMines_value_changed(value):
	custom_mine_count = value


func _on_TileMap_flag_placed_removed(value):
	flag_label.text = "Flags: %s" % str(value)

func _on_TileMap_game_over():
	endgame_label.text = "Game Over!"
	endgame_label.show()
	game_over = true

func _on_TileMap_game_won():
	endgame_label.text = "Game Won!"
	endgame_label.show()
	game_over = true
	in_game = false


func _on_TileMap_place_label(pos, text):
	var label = number_label.instance()
	label_container.add_child(label)
	label.rect_position = pos
	label.text = text

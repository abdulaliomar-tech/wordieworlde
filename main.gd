extends Control

const WORD_LENGTH = 5
const MAX_ROWS = 6

var target_words = ["APPLE", "TRAIN", "BEACH", "CHAIR", "PLANT", "SMILE", "WATER", "MALAK", "HAVEN", "GRANT", "FLINT", "MUSIC","DADDY", "FIGHT", "SLEEP", "HOUSE"]
var target_word = ""
var current_row = 0
var current_col = 0
var game_over = false

@onready var grid = $VBoxContainer/Board
@onready var message_label = $VBoxContainer/WORDLE
@onready var play_again_button = $VBoxContainer/restart

var board_state = []
var cell_nodes = []
var default_tile_style = StyleBoxFlat.new()

func _ready() -> void:
	randomize()

	# Default tile look (dark gray with border)
	default_tile_style.bg_color = Color(0.1, 0.1, 0.1)
	default_tile_style.border_width_left = 2
	default_tile_style.border_width_top = 2
	default_tile_style.border_width_right = 2
	default_tile_style.border_width_bottom = 2
	default_tile_style.border_color = Color(0.5, 0.5, 0.5)

	# Connect the restart button safely via code
	if play_again_button:
		if not play_again_button.pressed.is_connected(_on_restart_button_pressed):
			play_again_button.pressed.connect(_on_restart_button_pressed)
	else:
		push_warning("Restart button not found — check node path!")

	target_word = target_words[randi() % target_words.size()]
	setup_board()

func setup_board() -> void:
	for r in range(MAX_ROWS):
		var row_letters = []
		var row_nodes = []
		for c in range(WORD_LENGTH):
			var panel = Panel.new()
			panel.custom_minimum_size = Vector2(55, 55)
			panel.add_theme_stylebox_override("panel", default_tile_style)

			var lbl = Label.new()
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 32)
			lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			panel.add_child(lbl)

			grid.add_child(panel)
			row_nodes.append(lbl)
			row_letters.append("")

		board_state.append(row_letters)
		cell_nodes.append(row_nodes)

func _input(event: InputEvent) -> void:
	if game_over:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var unicode = event.unicode
		var keycode = event.keycode

		if unicode >= 65 and unicode <= 90:
			var letter = char(unicode)
			add_letter(letter)
		elif unicode >= 97 and unicode <= 122:
			var letter = char(unicode - 32)
			add_letter(letter)

		elif keycode == KEY_BACKSPACE:
			remove_letter()

		elif keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
			submit_word()

func add_letter(letter: String) -> void:
	if current_col < WORD_LENGTH:
		board_state[current_row][current_col] = letter
		cell_nodes[current_row][current_col].text = letter

		var panel = cell_nodes[current_row][current_col].get_parent() as Panel
		panel.pivot_offset = panel.size / 2

		var tween = create_tween()
		tween.tween_property(panel, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

		current_col += 1

func remove_letter() -> void:
	if current_col > 0:
		current_col -= 1
		board_state[current_row][current_col] = ""
		cell_nodes[current_row][current_col].text = ""

func submit_word() -> void:
	if current_col < WORD_LENGTH:
		message_label.text = "Not enough letters"
		var anim = grid.get_node_or_null("AnimationPlayer")
		if anim and anim.has_animation("shake"):
			anim.play("shake")
		return

	message_label.text = ""
	var guessed_word = "".join(board_state[current_row])

	var target_chars = target_word.split("")
	var guess_chars = guessed_word.split("")

	for i in range(WORD_LENGTH):
		var panel = cell_nodes[current_row][i].get_parent() as Panel
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.3, 0.3)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.5, 0.5, 0.5)

		if guess_chars[i] == target_chars[i]:
			style.bg_color = Color(0.2, 0.6, 0.2)
			target_chars[i] = "_"
			guess_chars[i] = "*"

		panel.add_theme_stylebox_override("panel", style)

	for i in range(WORD_LENGTH):
		if guess_chars[i] != "*":
			var panel = cell_nodes[current_row][i].get_parent() as Panel
			var style = panel.get_theme_stylebox("panel") as StyleBoxFlat

			if guess_chars[i] in target_chars:
				style.bg_color = Color(0.8, 0.7, 0.2)
				target_chars[target_chars.find(guess_chars[i])] = "_"

			panel.add_theme_stylebox_override("panel", style)

	if guessed_word == target_word:
		message_label.text = "You Win!"
		game_over = true
		return

	current_row += 1
	current_col = 0

	if current_row >= MAX_ROWS:
		message_label.text = "Game Over! Word was: " + target_word
		game_over = true

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
	print("hello")

class_name MainMenu
extends CanvasLayer

signal new_game_requested
signal continue_requested
signal quit_requested


func _ready() -> void:
	$Root.hide()
	$Root/Center/MenuPanel/Layout/NewGameButton.pressed.connect(func(): new_game_requested.emit())
	$Root/Center/MenuPanel/Layout/ContinueButton.pressed.connect(func(): continue_requested.emit())
	$Root/Center/MenuPanel/Layout/QuitButton.pressed.connect(func(): quit_requested.emit())


func show_menu() -> void:
	$Root/Center/MenuPanel/Layout/ContinueButton.disabled = not FileAccess.file_exists(GameState.SAVE_PATH)
	$Root.modulate.a = 0.0
	$Root.show()
	var tween := create_tween()
	tween.tween_property($Root, "modulate:a", 1.0, 0.25)


func hide_menu() -> void:
	$Root.hide()


func is_open() -> bool:
	return $Root.visible


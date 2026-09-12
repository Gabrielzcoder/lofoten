class_name DialogueUI
extends CanvasLayer

signal dialogue_finished

var lines: Array[String] = []
var line_index := 0
var opened_frame := -1
var typing_tween: Tween
var indicator_tween: Tween
var is_typing := false
var is_closing := false
var portrait_side := "left"

@onready var root: Control = $Root
@onready var shade: ColorRect = $Root/Shade
@onready var portrait_stage: Control = $Root/PortraitStage
@onready var portrait: TextureRect = $Root/PortraitStage/Portrait
@onready var accent: ColorRect = $Root/PortraitStage/Accent
@onready var dialogue_box: MarginContainer = $Root/BottomMargin
@onready var speaker_label: Label = $Root/BottomMargin/DialoguePanel/Content/NameRow/Speaker
@onready var progress_label: Label = $Root/BottomMargin/DialoguePanel/Content/NameRow/Progress
@onready var dialogue_text: RichTextLabel = $Root/BottomMargin/DialoguePanel/Content/DialogueText
@onready var continue_indicator: Label = $Root/BottomMargin/DialoguePanel/Content/Footer/ContinueIndicator


func _ready() -> void:
	root.hide()
	$Root/BottomMargin/DialoguePanel/Content/Footer/ContinueButton.pressed.connect(_advance)


func show_dialogue(speaker: String, new_lines: Array[String], portrait_path := "", side := "left") -> void:
	lines = new_lines if not new_lines.is_empty() else ["..."]
	line_index = 0
	opened_frame = Engine.get_process_frames()
	is_closing = false
	portrait_side = side if side == "right" else "left"
	speaker_label.text = speaker
	portrait.texture = load(portrait_path) if not portrait_path.is_empty() else null
	_place_portrait()
	root.show()
	shade.modulate.a = 0.0
	portrait_stage.modulate.a = 0.0
	dialogue_box.modulate.a = 0.0
	var portrait_target := portrait.position
	portrait.position.x += 72.0 if portrait_side == "right" else -72.0
	_show_current_line()
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(shade, "modulate:a", 1.0, 0.25)
	tween.tween_property(portrait_stage, "modulate:a", 1.0, 0.3)
	tween.tween_property(portrait, "position", portrait_target, 0.32)
	tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.2)


func _place_portrait() -> void:
	if portrait_side == "right":
		portrait.anchor_left = 1.0
		portrait.anchor_right = 1.0
		portrait.offset_left = -500.0
		portrait.offset_right = -35.0
		accent.position.x = 1122.0
	else:
		portrait.anchor_left = 0.0
		portrait.anchor_right = 0.0
		portrait.offset_left = 35.0
		portrait.offset_right = 500.0
		accent.position.x = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if root.visible and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if Engine.get_process_frames() != opened_frame:
			_advance()


func _show_current_line() -> void:
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
	if indicator_tween and indicator_tween.is_valid():
		indicator_tween.kill()
	continue_indicator.modulate.a = 1.0
	dialogue_text.text = lines[line_index] if line_index < lines.size() else "..."
	dialogue_text.visible_ratio = 0.0
	progress_label.text = "%02d / %02d" % [line_index + 1, maxi(1, lines.size())]
	continue_indicator.hide()
	is_typing = true
	var duration := clampf(dialogue_text.text.length() * 0.018, 0.38, 2.5)
	typing_tween = create_tween()
	typing_tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)
	typing_tween.finished.connect(_on_typing_finished)


func _on_typing_finished() -> void:
	is_typing = false
	continue_indicator.show()
	indicator_tween = create_tween().set_loops()
	indicator_tween.tween_property(continue_indicator, "modulate:a", 0.45, 0.55)
	indicator_tween.tween_property(continue_indicator, "modulate:a", 1.0, 0.55)


func _advance() -> void:
	if is_closing:
		return
	if is_typing:
		if typing_tween and typing_tween.is_valid():
			typing_tween.kill()
		dialogue_text.visible_ratio = 1.0
		is_typing = false
		continue_indicator.show()
		return
	line_index += 1
	if line_index >= lines.size():
		_close_animated()
	else:
		_show_current_line()


func _close_animated() -> void:
	is_closing = true
	if indicator_tween and indicator_tween.is_valid():
		indicator_tween.kill()
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(shade, "modulate:a", 0.0, 0.16)
	tween.tween_property(portrait_stage, "modulate:a", 0.0, 0.16)
	tween.tween_property(dialogue_box, "modulate:a", 0.0, 0.14)
	await tween.finished
	root.hide()
	is_closing = false
	dialogue_finished.emit()


func is_open() -> bool:
	return root.visible

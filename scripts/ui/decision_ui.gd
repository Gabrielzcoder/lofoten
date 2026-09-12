class_name DecisionUI
extends CanvasLayer

signal decision_selected(decision_id: String, choice_id: String, choice_text: String, effects: Dictionary, event_id: String)
signal closed

var current_decision: Dictionary = {}
var accepting_input := false


func _ready() -> void:
	$Root.hide()
	$Root/Center/DecisionPanel/Layout/Footer/CloseButton.pressed.connect(_close)


func show_decision(decision: Dictionary) -> void:
	current_decision = decision
	var panel: Control = $Root/Center/DecisionPanel
	var layout: VBoxContainer = panel.get_node("Layout")
	layout.get_node("Title").text = String(decision.get("title", "Decisão"))
	layout.get_node("Context").text = String(decision.get("context", ""))
	var choices_container: VBoxContainer = layout.get_node("Choices")
	for child in choices_container.get_children():
		child.queue_free()
	var choices: Array = decision.get("choices", [])
	for choice_data in choices:
		var button := Button.new()
		button.text = String(choice_data.get("text", "Escolher"))
		button.custom_minimum_size = Vector2(0, 68)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_choose.bind(choice_data))
		button.mouse_entered.connect(_animate_choice.bind(button, true))
		button.mouse_exited.connect(_animate_choice.bind(button, false))
		choices_container.add_child(button)
	panel.scale = Vector2(0.97, 0.97)
	panel.modulate.a = 0.0
	var portrait: TextureRect = $Root/DecisionPortrait
	portrait.modulate.a = 0.0
	$Root.modulate.a = 0.0
	$Root.show()
	var portrait_target_x := portrait.position.x
	portrait.position.x = portrait_target_x + 48.0
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property($Root, "modulate:a", 1.0, 0.18)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.24)
	tween.tween_property(portrait, "modulate:a", 1.0, 0.28)
	tween.tween_property(portrait, "position:x", portrait_target_x, 0.32)
	accepting_input = true


func _choose(choice_data: Dictionary) -> void:
	if not accepting_input:
		return
	accepting_input = false
	var result := [
		String(current_decision.get("id", "unknown")),
		String(choice_data.get("id", "unknown_choice")),
		String(choice_data.get("text", "Escolha")),
		choice_data.get("effects", {}),
		String(choice_data.get("event", ""))
	]
	await _hide_animated()
	decision_selected.emit(result[0], result[1], result[2], result[3], result[4])


func _close() -> void:
	if not accepting_input:
		return
	accepting_input = false
	await _hide_animated()
	closed.emit()


func _hide_animated() -> void:
	var panel: Control = $Root/Center/DecisionPanel
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property($Root, "modulate:a", 0.0, 0.15)
	tween.tween_property(panel, "scale", Vector2(0.98, 0.98), 0.15)
	await tween.finished
	$Root.hide()


func _animate_choice(button: Button, hovered: bool) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color(1.04, 0.98, 1.09) if hovered else Color.WHITE, 0.1)


func is_open() -> bool:
	return $Root.visible

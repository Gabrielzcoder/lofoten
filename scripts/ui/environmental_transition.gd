class_name EnvironmentalTransitionUI
extends CanvasLayer

signal transition_finished

var busy := false

@onready var root: Control = $Root
@onready var message_panel: PanelContainer = $Root/Center/MessagePanel
@onready var message_label: Label = $Root/Center/MessagePanel/Layout/Message


func _ready() -> void:
	root.hide()


func play_transition(message: String, midpoint := Callable()) -> void:
	if busy:
		return
	busy = true
	message_label.text = message
	root.modulate.a = 0.0
	message_panel.modulate.a = 0.0
	message_panel.position.y = 18.0
	root.show()
	var fade_in := create_tween()
	fade_in.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_in.tween_property(root, "modulate:a", 1.0, 0.42)
	await fade_in.finished
	if midpoint.is_valid():
		midpoint.call()
	await get_tree().process_frame
	var reveal := create_tween().set_parallel(true)
	reveal.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.tween_property(message_panel, "modulate:a", 1.0, 0.28)
	reveal.tween_property(message_panel, "position:y", 0.0, 0.28)
	await reveal.finished
	await get_tree().create_timer(2.15).timeout
	var fade_out := create_tween()
	fade_out.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_out.tween_property(root, "modulate:a", 0.0, 0.5)
	await fade_out.finished
	root.hide()
	busy = false
	transition_finished.emit()


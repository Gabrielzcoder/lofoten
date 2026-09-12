class_name LoadingScreen
extends CanvasLayer

signal transition_finished

var busy := false
var spin_time := 0.0


func _ready() -> void:
	$Root.show()
	$Root.modulate.a = 1.0


func _process(delta: float) -> void:
	if $Root.visible:
		spin_time += delta
		$Root/Center/Content/OilMark.rotation = spin_time * 1.8
		var pulse := 0.88 + sin(spin_time * 3.0) * 0.08
		$Root/Center/Content/OilMark.scale = Vector2.ONE * pulse


func play_startup() -> void:
	if busy:
		return
	busy = true
	$Root/Center/Content/TravelText.text = "A ilha desperta entre marés e máquinas"
	await get_tree().create_timer(1.05).timeout
	await _fade_out()
	busy = false
	transition_finished.emit()


func transition(message: String, midpoint: Callable) -> void:
	if busy:
		return
	busy = true
	$Root/Center/Content/TravelText.text = message
	$Root.show()
	$Root.modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_in.tween_property($Root, "modulate:a", 1.0, 0.22)
	await fade_in.finished
	midpoint.call()
	await get_tree().process_frame
	await get_tree().create_timer(0.18).timeout
	await _fade_out()
	busy = false
	transition_finished.emit()


func _fade_out() -> void:
	var fade_out := create_tween()
	fade_out.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_out.tween_property($Root, "modulate:a", 0.0, 0.32)
	await fade_out.finished
	$Root.hide()

class_name EndingUI
extends CanvasLayer

signal restart_requested
signal menu_requested


func _ready() -> void:
	$Root.hide()
	$Root/Center/EndingPanel/Layout/Actions/RestartButton.pressed.connect(func(): restart_requested.emit())
	$Root/Center/EndingPanel/Layout/Actions/MenuButton.pressed.connect(func(): menu_requested.emit())


func show_ending(ending: Dictionary) -> void:
	var layout: VBoxContainer = $Root/Center/EndingPanel/Layout
	var title: Label = layout.get_node("Title")
	var summary: Label = layout.get_node("Summary")
	var causes: Label = layout.get_node("Causes")
	var stats: Label = layout.get_node("FinalStats")
	title.text = String(ending.get("title", "FIM"))
	summary.text = String(ending.get("summary", "A história da ilha chegou ao fim."))
	var cause_lines: Array[String] = []
	for cause in ending.get("causes", []):
		cause_lines.append("• %s" % String(cause))
	causes.text = "\n".join(cause_lines)
	stats.text = "DIA %02d   •   CAIXA $%d mi   •   PETRÓLEO %d%%   •   EMPREGO %d%%" % [
		GameState.current_day, GameState.money, GameState.oil, GameState.employment
	]
	$Root.modulate.a = 0.0
	$Root/Center/EndingPanel.scale = Vector2(0.97, 0.97)
	$Root.show()
	await get_tree().process_frame
	var panel: Control = $Root/Center/EndingPanel
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property($Root, "modulate:a", 1.0, 0.35)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.4)


func hide_screen() -> void:
	$Root.hide()


func is_open() -> bool:
	return $Root.visible


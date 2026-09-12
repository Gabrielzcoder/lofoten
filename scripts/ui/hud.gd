class_name GameHUD
extends CanvasLayer

signal region_requested(region_id: String)
signal save_requested
signal load_requested

var notice_tween: Tween


func _ready() -> void:
	$Root/TopMargin/TopBar/SaveButton.pressed.connect(func(): save_requested.emit())
	$Root/TopMargin/TopBar/LoadButton.pressed.connect(func(): load_requested.emit())
	GameState.state_changed.connect(refresh)
	refresh()


func refresh() -> void:
	$Root/TopMargin/TopBar/LedgerPanel/Ledger/DayValue.text = "%02d" % GameState.current_day
	$Root/TopMargin/TopBar/LedgerPanel/Ledger/MoneyValue.text = "$ %d mi" % GameState.money
	$Root/TopMargin/TopBar/LedgerPanel/Ledger/OilValue.text = "%d%%" % GameState.oil


func set_region_name(text: String) -> void:
	$Root/TopMargin/TopBar/LocationPanel/Location/RegionName.text = text


func set_interaction_prompt(text: String) -> void:
	var panel: PanelContainer = $Root/BottomMargin/InteractionPanel
	$Root/BottomMargin/InteractionPanel/InteractionPrompt.text = text
	panel.visible = not text.is_empty()


func show_notice(text: String, duration := 3.2) -> void:
	if notice_tween and notice_tween.is_valid():
		notice_tween.kill()
	var panel: PanelContainer = $Root/NoticeCenter/NoticePanel
	panel.get_node("Notice").text = text
	panel.modulate.a = 0.0
	panel.position.y = -10.0
	panel.show()
	notice_tween = create_tween()
	notice_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	notice_tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	notice_tween.parallel().tween_property(panel, "position:y", 0.0, 0.18)
	notice_tween.tween_interval(duration)
	notice_tween.tween_property(panel, "modulate:a", 0.0, 0.35)
	notice_tween.tween_callback(panel.hide)

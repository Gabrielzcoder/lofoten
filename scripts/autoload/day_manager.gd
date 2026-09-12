extends Node

signal day_started(day: int)
signal day_ended(day: int)

const DECISIONS_PER_DAY := 2
var decisions_today: int = 0


func start_day() -> void:
	if GameState.game_ended:
		return
	decisions_today = 0
	GameState.check_events()
	day_started.emit(GameState.current_day)


func register_decision() -> bool:
	if GameState.game_ended:
		return true
	decisions_today += 1
	return decisions_today >= DECISIONS_PER_DAY


func end_day() -> void:
	if GameState.game_ended:
		return
	day_ended.emit(GameState.current_day)
	var daily_oil_use := maxi(1, roundi(GameState.production / 12.0))
	GameState.apply_effects({
		"oil": -daily_oil_use,
		"money": roundi(GameState.production / 8.0),
		"environment": -maxi(1, roundi(GameState.production / 30.0))
	})
	GameState.current_day += 1
	GameState.check_events()
	GameState.state_changed.emit()

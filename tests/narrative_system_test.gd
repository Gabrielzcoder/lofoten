extends SceneTree

var failures: Array[String] = []
var checks := 0
var main
var game_state


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS | ", description)
	else:
		failures.append(description)
		push_error("FAIL | " + description)


func _decision_by_id(decision_id: String) -> Dictionary:
	for decision in main.decisions:
		if String(decision.get("id", "")) == decision_id:
			return decision
	return {}


func _npc_for_id(npc_id: String):
	for npc in main.active_npcs:
		if npc.npc_id == npc_id:
			return npc
	return null


func _collect_dialogues(npc_id: String, region_id: String, days: int) -> Array[String]:
	var dialogue_ids: Array[String] = []
	main._apply_region(region_id)
	var npc = _npc_for_id(npc_id)
	for day in range(1, days + 1):
		game_state.current_day = day
		npc.get_dialogue()
		dialogue_ids.append(npc.last_selected_dialogue_id)
	return dialogue_ids


func _has_consecutive_duplicate(values: Array[String]) -> bool:
	for index in range(1, values.size()):
		if values[index] == values[index - 1]:
			return true
	return false


func _run() -> void:
	game_state = root.get_node("GameState")
	game_state.reset()
	main = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.7).timeout

	_check(ProjectSettings.get_setting("application/config/name") == "Lofoten", "título da aplicação é Lofoten")
	_check(main.main_menu.get_node("Root/Center/MenuPanel/Layout/Title").text == "LOFOTEN", "menu principal exibe Lofoten")
	_check(main.loading_screen.get_node("Root/Center/Content/Title").text == "LOFOTEN", "tela inicial exibe Lofoten")

	var decision_ids: Dictionary = {}
	var choice_ids: Dictionary = {}
	var repeatable_count := 0
	for decision in main.decisions:
		var decision_id := String(decision.get("id", ""))
		decision_ids[decision_id] = int(decision_ids.get(decision_id, 0)) + 1
		if bool(decision.get("repeatable", false)):
			repeatable_count += 1
		for choice in decision.get("choices", []):
			var choice_id := String(choice.get("id", ""))
			choice_ids[choice_id] = int(choice_ids.get(choice_id, 0)) + 1
	_check(main.decisions.size() == 27, "catálogo contém 27 decisões")
	_check(decision_ids.size() == main.decisions.size(), "todas as decisões têm identificador único")
	_check(choice_ids.size() == 54, "catálogo contém 54 consequências identificadas")
	_check(repeatable_count == 13, "13 decisões usam repetição controlada")

	game_state.reset()
	main._prepare_daily_decisions()
	_check(main.daily_decision_queue.size() == 2, "escritório continua mostrando duas decisões por dia")
	_check(main.daily_decision_queue[0].get("id") != main.daily_decision_queue[1].get("id"), "as duas decisões do dia são diferentes")

	var unique_decision := _decision_by_id("north_sea_export_contract")
	game_state.register_decision("north_sea_export_contract", "accept_export_contract", "factory_expansion")
	game_state.current_day = 2
	_check(not main._is_decision_available(unique_decision), "decisão única concluída sai do catálogo")

	game_state.reset()
	game_state.current_day = 10
	game_state.oil = 60
	var repeatable := _decision_by_id("production_shift_adjustment")
	game_state.register_decision("production_shift_adjustment", "open_extra_shift", "factory_expansion")
	for blocked_day in range(11, 14):
		game_state.current_day = blocked_day
		_check(not main._is_decision_available(repeatable), "cooldown impede retorno no dia %d" % blocked_day)
	game_state.current_day = 14
	_check(main._is_decision_available(repeatable), "decisão repetível retorna somente após três dias completos")

	game_state.production = 70
	game_state.oil = 60
	var growth := _decision_by_id("production_shift_adjustment")
	var slowdown := _decision_by_id("controlled_extraction_slowdown")
	_check(main._decision_weight(slowdown) > main._decision_weight(growth), "produção alta dá mais peso à desaceleração que à expansão")

	game_state.reset()
	var offered_unique: Dictionary = {}
	var offered_categories: Dictionary = {}
	var last_offered_day: Dictionary = {}
	var previous_day_ids: Array[String] = []
	for simulated_day in range(1, 9):
		game_state.current_day = simulated_day
		main._prepare_daily_decisions()
		_check(main.daily_decision_queue.size() == 2, "dia simulado %d oferece duas decisões" % simulated_day)
		var current_day_ids: Array[String] = []
		for queued_value in main.daily_decision_queue:
			var offered_decision: Dictionary = queued_value
			var offered_id := String(offered_decision.get("id", ""))
			current_day_ids.append(offered_id)
			offered_unique[offered_id] = true
			offered_categories[String(offered_decision.get("category", ""))] = true
			_check(not previous_day_ids.has(offered_id), "%s não retorna no dia seguinte" % offered_id)
			if last_offered_day.has(offered_id):
				var required_gap := int(offered_decision.get("cooldown_days", 0)) + 1
				_check(simulated_day - int(last_offered_day[offered_id]) >= required_gap, "%s respeita seu cooldown ao retornar" % offered_id)
			last_offered_day[offered_id] = simulated_day
			var choices: Array = offered_decision.get("choices", [])
			var first_choice: Dictionary = choices[0]
			game_state.apply_effects(first_choice.get("effects", {}))
			game_state.register_decision(offered_id, String(first_choice.get("id", "")), String(first_choice.get("event", "")))
		previous_day_ids = current_day_ids
	_check(offered_unique.size() >= 10, "oito dias apresentam ampla variedade de decisões")
	_check(offered_categories.size() >= 4, "a rotação cobre pelo menos quatro categorias de gestão")

	for npc_spec in [
		{"id": "worker", "region": "lower_city"},
		{"id": "resident", "region": "lower_city"},
		{"id": "adviser", "region": "bridge"},
		{"id": "executive", "region": "upper_city"}
	]:
		game_state.reset()
		var ids := _collect_dialogues(npc_spec["id"], npc_spec["region"], 6)
		var unique_ids: Dictionary = {}
		for dialogue_id in ids:
			unique_ids[dialogue_id] = true
		_check(not _has_consecutive_duplicate(ids), "%s não repete fala em dias consecutivos" % npc_spec["id"])
		_check(unique_ids.size() >= 4, "%s apresenta variedade ao longo de seis dias" % npc_spec["id"])
		var npc = _npc_for_id(npc_spec["id"])
		var same_day_id: String = npc.last_selected_dialogue_id
		npc.get_dialogue()
		_check(npc.last_selected_dialogue_id == same_day_id, "%s mantém a fala coerente durante o mesmo dia" % npc_spec["id"])

	game_state.reset()
	game_state.current_day = 3
	game_state.register_decision("test_factory_expansion", "test_choice", "factory_expansion")
	for npc_spec in [
		{"id": "worker", "region": "lower_city"},
		{"id": "resident", "region": "lower_city"},
		{"id": "adviser", "region": "bridge"},
		{"id": "executive", "region": "upper_city"}
	]:
		main._apply_region(npc_spec["region"])
		var npc = _npc_for_id(npc_spec["id"])
		npc.get_dialogue()
		_check("factory" in npc.last_selected_dialogue_id, "%s comenta a expansão recente" % npc_spec["id"])

	game_state.current_day = 6
	main._apply_region("lower_city")
	var worker = _npc_for_id("worker")
	worker.get_dialogue()
	_check(not ("factory" in worker.last_selected_dialogue_id), "evento antigo perde prioridade depois de dois dias")

	var save_data: Dictionary = game_state.to_dictionary()
	for field in ["last_major_event", "recent_major_events", "npc_dialogue_history", "npc_daily_dialogues"]:
		_check(save_data.has(field), "save inclui %s" % field)

	if failures.is_empty():
		print("TEST_RESULT | %d verificações narrativas aprovadas" % checks)
		quit(0)
	else:
		print("TEST_RESULT | %d falhas em %d verificações" % [failures.size(), checks])
		for failure in failures:
			print(" - ", failure)
		quit(1)

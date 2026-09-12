extends Node

signal state_changed
signal game_loaded
signal game_finished(ending: Dictionary)

const SAVE_PATH := "user://ilha_do_petroleo_save.json"
const ENV_CLEAN := "CLEAN"
const ENV_POLLUTED := "POLLUTED"
const ENV_HEAVILY_POLLUTED := "HEAVILY_POLLUTED"

var money: int = 120
var oil: int = 100
var production: int = 45
var employment: int = 55
var environment: int = 70
var population_approval: int = 55
var company_approval: int = 55
var economy: int = 50
var diversification: int = 10
var current_day: int = 1
var decisions_made: Array[String] = []
var decision_history: Array[Dictionary] = []
var active_events: Array[String] = []
var game_ended := false
var ending_id := ""
var environmental_alerts_seen: Array[String] = []
var last_major_event := ""
var recent_major_events: Array[Dictionary] = []
var npc_dialogue_history: Dictionary = {}
var npc_daily_dialogues: Dictionary = {}


func reset() -> void:
	money = 120
	oil = 100
	production = 45
	employment = 55
	environment = 70
	population_approval = 55
	company_approval = 55
	economy = 50
	diversification = 10
	current_day = 1
	decisions_made.clear()
	decision_history.clear()
	active_events.clear()
	game_ended = false
	ending_id = ""
	environmental_alerts_seen.clear()
	last_major_event = ""
	recent_major_events.clear()
	npc_dialogue_history.clear()
	npc_daily_dialogues.clear()
	state_changed.emit()


func get_environment_stage() -> String:
	if environment < 25:
		return ENV_HEAVILY_POLLUTED
	if environment < 50:
		return ENV_POLLUTED
	return ENV_CLEAN


func environment_stage_rank(stage: String) -> int:
	match stage:
		ENV_POLLUTED: return 1
		ENV_HEAVILY_POLLUTED: return 2
	return 0


func has_seen_environmental_alert(stage: String) -> bool:
	return environmental_alerts_seen.has(stage)


func mark_environmental_alert_seen(stage: String) -> void:
	if stage != ENV_CLEAN and not environmental_alerts_seen.has(stage):
		environmental_alerts_seen.append(stage)


func apply_effects(effects: Dictionary) -> void:
	if game_ended:
		return
	for key in effects:
		var amount := int(effects[key])
		match String(key):
			"money": money += amount
			"oil": oil += amount
			"production": production += amount
			"employment": employment += amount
			"environment": environment += amount
			"population_approval": population_approval += amount
			"company_approval": company_approval += amount
			"economy": economy += amount
			"diversification": diversification += amount
	clamp_values()
	state_changed.emit()


func clamp_values() -> void:
	oil = clampi(oil, 0, 100)
	production = clampi(production, 0, 100)
	employment = clampi(employment, 0, 100)
	environment = clampi(environment, 0, 100)
	population_approval = clampi(population_approval, 0, 100)
	company_approval = clampi(company_approval, 0, 100)
	economy = clampi(economy, 0, 100)
	diversification = clampi(diversification, 0, 100)


func register_decision(decision_id: String, choice_id := "", event_id := "") -> void:
	decisions_made.append(decision_id)
	decision_history.append({
		"day": current_day,
		"decision_id": decision_id,
		"choice_id": choice_id,
		"event_id": event_id
	})
	if not event_id.is_empty():
		last_major_event = event_id
		recent_major_events.append({"id": event_id, "day": current_day})
		invalidate_daily_dialogues()
	_prune_recent_major_events()


func has_completed_decision(decision_id: String) -> bool:
	return decisions_made.has(decision_id)


func get_decision_last_day(decision_id: String) -> int:
	for index in range(decision_history.size() - 1, -1, -1):
		var entry: Dictionary = decision_history[index]
		if String(entry.get("decision_id", "")) == decision_id:
			return int(entry.get("day", -999))
	return -999


func get_recent_event_age(event_id: String, max_age := 2) -> int:
	for index in range(recent_major_events.size() - 1, -1, -1):
		var entry: Dictionary = recent_major_events[index]
		if String(entry.get("id", "")) == event_id:
			var age := current_day - int(entry.get("day", current_day))
			return age if age <= max_age else -1
	return -1


func _prune_recent_major_events() -> void:
	var kept: Array[Dictionary] = []
	for entry in recent_major_events:
		if current_day - int(entry.get("day", current_day)) <= 3:
			kept.append(entry)
	recent_major_events = kept
	if recent_major_events.is_empty():
		last_major_event = ""
	else:
		last_major_event = String(recent_major_events.back().get("id", ""))


func get_daily_dialogue_id(npc_id: String) -> String:
	return String(npc_daily_dialogues.get("%s:%d" % [npc_id, current_day], ""))


func invalidate_daily_dialogues() -> void:
	var day_suffix := ":%d" % current_day
	for key in npc_daily_dialogues.keys():
		if String(key).ends_with(day_suffix):
			npc_daily_dialogues.erase(key)


func record_npc_dialogue(npc_id: String, dialogue_id: String) -> void:
	var day_key := "%s:%d" % [npc_id, current_day]
	npc_daily_dialogues[day_key] = dialogue_id
	var history: Array = npc_dialogue_history.get(npc_id, [])
	history.append({"id": dialogue_id, "day": current_day})
	while history.size() > 12:
		history.pop_front()
	npc_dialogue_history[npc_id] = history
	var oldest_day := current_day - 5
	for key in npc_daily_dialogues.keys():
		var parts := String(key).split(":")
		if parts.size() == 2 and int(parts[1]) < oldest_day:
			npc_daily_dialogues.erase(key)


func get_recent_dialogue_ids(npc_id: String, max_age := 3) -> Array[String]:
	var result: Array[String] = []
	var history: Array = npc_dialogue_history.get(npc_id, [])
	for entry in history:
		if current_day - int(entry.get("day", current_day)) <= max_age:
			result.append(String(entry.get("id", "")))
	return result


func has_seen_dialogue(npc_id: String, dialogue_id: String) -> bool:
	var history: Array = npc_dialogue_history.get(npc_id, [])
	for entry in history:
		if String(entry.get("id", "")) == dialogue_id:
			return true
	return false


func chose(choice_id: String) -> bool:
	for entry in decision_history:
		if String(entry.get("choice_id", "")) == choice_id:
			return true
	return false


func check_events() -> void:
	_prune_recent_major_events()
	active_events.clear()
	if environment < 35:
		active_events.append("Uma assembleia se reúne perto do porto após novas manchas aparecerem na água.")
	if company_approval < 25:
		active_events.append("O conselho convocou uma reunião extraordinária sobre a direção da empresa.")
	if economy < 25 or employment < 25:
		active_events.append("Mais vitrines amanheceram fechadas na Cidade Baixa.")
	if diversification >= 65:
		active_events.append("Novos barcos de turismo e pequenas oficinas começam a ocupar o cais.")


func evaluate_ending() -> Dictionary:
	if oil <= 15 and diversification >= 65 and economy >= 45 and environment >= 35:
		return _sustainable_ending()
	if environment <= 15 and money >= 220 and company_approval >= 55:
		return _corporate_ending()
	if company_approval <= 8:
		return _dismissed_ending()
	if (oil <= 5 and diversification < 45) or economy <= 10 or money <= -50:
		return _collapse_ending()
	return {}


func finalize_ending(ending: Dictionary) -> void:
	if game_ended or ending.is_empty():
		return
	game_ended = true
	ending_id = String(ending.get("id", "unknown"))
	state_changed.emit()
	game_finished.emit(ending)


func _sustainable_ending() -> Dictionary:
	var causes: Array[String] = [
		"As reservas chegaram a %d%%, mas a diversificação alcançou %d%%." % [oil, diversification],
		"A economia permaneceu em %d%% e a qualidade ambiental em %d%%." % [economy, environment]
	]
	if chose("fund_wind_farm") or chose("fund_tourism_program") or chose("release_local_credit"):
		causes.append("Seus investimentos antecipados criaram renda fora da cadeia do petróleo.")
	return {
		"id": "sustainable",
		"title": "O FUTURO DE LOFOTEN",
		"summary": "Os últimos poços desaceleraram sem levar Skarvik com eles. Oficinas, energia limpa e visitantes mantiveram o porto vivo, enquanto a indústria deixou de ser a única resposta.",
		"causes": causes
	}


func _corporate_ending() -> Dictionary:
	var causes: Array[String] = [
		"A empresa encerrou o período com $%d milhões e apoio corporativo de %d%%." % [money, company_approval],
		"A qualidade ambiental caiu para %d%% e restam apenas %d%% das reservas." % [environment, oil]
	]
	if chose("accept_export_contract") or chose("minimize_spill"):
		causes.append("Contratos agressivos e riscos ambientais foram aceitos em nome dos resultados imediatos.")
	return {
		"id": "corporate",
		"title": "O ÚLTIMO BALANÇO",
		"summary": "Os acionistas celebraram o melhor relatório da história. Do outro lado das janelas, o fiorde escureceu e famílias começaram a deixar a ilha que financiou aquele lucro.",
		"causes": causes
	}


func _collapse_ending() -> Dictionary:
	var causes: Array[String] = [
		"Reservas: %d%%. Diversificação: %d%%. Economia: %d%%." % [oil, diversification, economy],
		"O emprego terminou em %d%% e o caixa em $%d milhões." % [employment, money]
	]
	if not chose("fund_wind_farm") and not chose("fund_tourism_program") and not chose("release_local_credit"):
		causes.append("A transição econômica foi adiada até não haver receita suficiente para financiá-la.")
	return {
		"id": "collapse",
		"title": "PORTO SEM LUZES",
		"summary": "Quando as bombas pararam, não havia outro setor pronto para sustentar a ilha. O cais esvaziou, os serviços fecharam e a prefeitura declarou emergência econômica.",
		"causes": causes
	}


func _dismissed_ending() -> Dictionary:
	var causes: Array[String] = [
		"A aprovação da empresa caiu para %d%%." % company_approval,
		"O caixa estava em $%d milhões, com produção de %d%%." % [money, production]
	]
	if chose("fund_wind_farm") or chose("suspend_terminal"):
		causes.append("O conselho considerou seus investimentos e interrupções incompatíveis com as metas trimestrais.")
	return {
		"id": "dismissed",
		"title": "A PORTA DO CONSELHO",
		"summary": "A diretoria votou antes do amanhecer. Seu plano para a ilha terminou junto com seu mandato; outro administrador assumirá as decisões a partir de hoje.",
		"causes": causes
	}


func to_dictionary() -> Dictionary:
	return {
		"money": money,
		"oil": oil,
		"production": production,
		"employment": employment,
		"environment": environment,
		"population_approval": population_approval,
		"company_approval": company_approval,
		"economy": economy,
		"diversification": diversification,
		"current_day": current_day,
		"decisions_made": decisions_made,
		"decision_history": decision_history,
		"active_events": active_events,
		"game_ended": game_ended,
		"ending_id": ending_id,
		"environmental_alerts_seen": environmental_alerts_seen,
		"last_major_event": last_major_event,
		"recent_major_events": recent_major_events,
		"npc_dialogue_history": npc_dialogue_history,
		"npc_daily_dialogues": npc_daily_dialogues
	}


func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(to_dictionary(), "\t"))
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return false
	money = int(parsed.get("money", money))
	oil = int(parsed.get("oil", oil))
	production = int(parsed.get("production", production))
	employment = int(parsed.get("employment", employment))
	environment = int(parsed.get("environment", environment))
	population_approval = int(parsed.get("population_approval", population_approval))
	company_approval = int(parsed.get("company_approval", company_approval))
	economy = int(parsed.get("economy", economy))
	diversification = int(parsed.get("diversification", diversification))
	current_day = int(parsed.get("current_day", current_day))
	decisions_made.assign(parsed.get("decisions_made", []))
	decision_history.assign(parsed.get("decision_history", []))
	active_events.assign(parsed.get("active_events", []))
	game_ended = bool(parsed.get("game_ended", false))
	ending_id = String(parsed.get("ending_id", ""))
	environmental_alerts_seen.assign(parsed.get("environmental_alerts_seen", []))
	last_major_event = String(parsed.get("last_major_event", ""))
	recent_major_events.assign(parsed.get("recent_major_events", []))
	npc_dialogue_history = parsed.get("npc_dialogue_history", {}).duplicate(true)
	npc_daily_dialogues = parsed.get("npc_daily_dialogues", {}).duplicate(true)
	_prune_recent_major_events()
	clamp_values()
	state_changed.emit()
	game_loaded.emit()
	return true

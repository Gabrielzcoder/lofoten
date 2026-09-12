class_name NarrativeNPC
extends Interactable

@export var npc_id := "worker"
@export var character_name := "Morador"
@export var region := "lower_city"
@export var profession := "Morador"
@export var portrait_path := "res://assets/characters/cat_worker.png"
@export var portrait_side := "left"
@export var map_frame := 0

const SIGRID_OVERWORLD := preload("res://assets/characters/sigrid_overworld_single.png")
const DIALOGUE_DATA_PATH := "res://data/dialogues.json"

var idle_time := 0.0
var idle_phase := 0.0
var sprite_base_y := -36.1
var sprite_base_scale := Vector2(0.141, 0.141)
var dialogue_catalog: Array[Dictionary] = []
var last_selected_dialogue_id := ""


func setup(data: Dictionary) -> void:
	npc_id = String(data.get("id", "worker"))
	character_name = String(data.get("name", "Morador"))
	profession = String(data.get("profession", "Morador"))
	region = String(data.get("region", "lower_city"))
	portrait_path = String(data.get("portrait", portrait_path))
	portrait_side = String(data.get("portrait_side", "left"))
	map_frame = int(data.get("map_frame", 0))
	prompt_text = "Conversar com %s" % character_name
	if npc_id == "adviser":
		$Sprite.texture = SIGRID_OVERWORLD
		$Sprite.hframes = 1
		$Sprite.frame = 0
		$Sprite.scale = Vector2(0.085, 0.085)
		$Sprite.position.y = -34.2
	else:
		$Sprite.frame = map_frame
	$Sprite.flip_h = bool(data.get("flip", false))
	sprite_base_y = $Sprite.position.y
	sprite_base_scale = $Sprite.scale
	idle_phase = position.x * 0.013
	_load_dialogue_catalog()


func _process(delta: float) -> void:
	idle_time += delta
	var wave := sin(idle_time * 1.8 + idle_phase)
	var float_amount := 0.75 if npc_id == "adviser" else 0.5
	$Sprite.position.y = sprite_base_y + wave * float_amount
	$Shadow.scale.x = 1.0 + wave * 0.018
	if npc_id == "adviser":
		$Sprite.rotation = wave * 0.008
		$Sprite.scale = sprite_base_scale * Vector2(1.0 + wave * 0.006, 1.0 - wave * 0.006)


func _load_dialogue_catalog() -> void:
	dialogue_catalog.clear()
	var file := FileAccess.open(DIALOGUE_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Não foi possível abrir dialogues.json")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Array):
		push_error("dialogues.json não contém uma lista válida")
		return
	for entry in parsed:
		if entry is Dictionary and String(entry.get("npc", "")) == npc_id:
			dialogue_catalog.append(entry)


func get_dialogue() -> Array[String]:
	var cached_id := GameState.get_daily_dialogue_id(npc_id)
	if not cached_id.is_empty():
		var cached := _find_dialogue(cached_id)
		if not cached.is_empty():
			last_selected_dialogue_id = cached_id
			return _dialogue_lines(cached)

	var valid: Array[Dictionary] = []
	var event_candidates: Array[Dictionary] = []
	for entry in dialogue_catalog:
		if _matches_world_state(entry):
			valid.append(entry)
			if not String(entry.get("event", "")).is_empty():
				event_candidates.append(entry)
	if valid.is_empty():
		return ["O vento mudou desde ontem. Ainda estamos tentando entender o que isso significa."]

	var pool := event_candidates if not event_candidates.is_empty() else valid
	var recent_ids := GameState.get_recent_dialogue_ids(npc_id, 3)
	var fresh: Array[Dictionary] = []
	for entry in pool:
		if not recent_ids.has(String(entry.get("id", ""))):
			fresh.append(entry)
	if not fresh.is_empty():
		pool = fresh
	elif not event_candidates.is_empty():
		for entry in valid:
			if String(entry.get("event", "")).is_empty() and not recent_ids.has(String(entry.get("id", ""))):
				fresh.append(entry)
		if not fresh.is_empty():
			pool = fresh
	else:
		var without_last: Array[Dictionary] = []
		var last_id: String = recent_ids.back() if not recent_ids.is_empty() else ""
		for entry in pool:
			if String(entry.get("id", "")) != last_id:
				without_last.append(entry)
		if not without_last.is_empty():
			pool = without_last

	var chosen := _weighted_dialogue(pool)
	last_selected_dialogue_id = String(chosen.get("id", "fallback"))
	GameState.record_npc_dialogue(npc_id, last_selected_dialogue_id)
	return _dialogue_lines(chosen)


func _find_dialogue(dialogue_id: String) -> Dictionary:
	for entry in dialogue_catalog:
		if String(entry.get("id", "")) == dialogue_id:
			return entry
	return {}


func _dialogue_lines(entry: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for line in entry.get("lines", []):
		result.append(String(line))
	return result if not result.is_empty() else ["..."]


func _matches_world_state(entry: Dictionary) -> bool:
	if GameState.current_day < int(entry.get("min_day", 1)):
		return false
	var event_id := String(entry.get("event", ""))
	if not event_id.is_empty() and GameState.get_recent_event_age(event_id, 2) < 0:
		return false
	var conditions: Dictionary = entry.get("conditions", {})
	for stat_name in conditions.get("min", {}):
		if _game_stat(String(stat_name)) < int(conditions["min"][stat_name]):
			return false
	for stat_name in conditions.get("max", {}):
		if _game_stat(String(stat_name)) > int(conditions["max"][stat_name]):
			return false
	return true


func _weighted_dialogue(pool: Array[Dictionary]) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("dialogue:%s:%d:%d:%d" % [
		npc_id,
		GameState.current_day,
		GameState.decision_history.size(),
		GameState.npc_dialogue_history.get(npc_id, []).size()
	])
	var weights: Array[float] = []
	var total := 0.0
	for entry in pool:
		var weight := maxf(0.05, float(entry.get("weight", 1.0)))
		var dialogue_id := String(entry.get("id", ""))
		if not GameState.has_seen_dialogue(npc_id, dialogue_id):
			weight *= 2.2
		var event_id := String(entry.get("event", ""))
		if not event_id.is_empty():
			var age := GameState.get_recent_event_age(event_id, 2)
			weight *= 4.0 - float(maxi(age, 0))
		weights.append(weight)
		total += weight
	var roll := rng.randf_range(0.0, total)
	for index in range(pool.size()):
		roll -= weights[index]
		if roll <= 0.0:
			return pool[index]
	return pool.back()


func _game_stat(stat_name: String) -> int:
	match stat_name:
		"money": return GameState.money
		"oil": return GameState.oil
		"production": return GameState.production
		"employment": return GameState.employment
		"environment": return GameState.environment
		"population_approval": return GameState.population_approval
		"company_approval": return GameState.company_approval
		"economy": return GameState.economy
		"diversification": return GameState.diversification
	return 0

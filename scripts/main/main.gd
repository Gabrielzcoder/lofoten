extends Node2D

const REGION_DATA := {
	"upper_city": {
		"name": "CIDADE ALTA",
		"travel": "Subindo para a Cidade Alta",
		"clean": "res://assets/backgrounds/high_city_1.jpg",
		"polluted": "res://assets/backgrounds/high_city_2.jpg",
		"ground_y": 700.0,
		"spawn": Vector2(210, 720)
	},
	"bridge": {
		"name": "PONTE",
		"travel": "Cruzando a ponte sobre o fiorde",
		"clean": "res://assets/backgrounds/bridge_1.jpg",
		"polluted": "res://assets/backgrounds/bridge_2.jpg",
		"ground_y": 552.0,
		"spawn": Vector2(600, 500)
	},
	"lower_city": {
		"name": "CIDADE BAIXA",
		"travel": "Descendo em direção ao porto",
		"clean": "res://assets/backgrounds/lower_city_1.jpg",
		"polluted": "res://assets/backgrounds/lower_city_2.jpg",
		"ground_y": 780.0,
		"spawn": Vector2(600, 780)
	}
}

const NPC_SCENE := preload("res://scenes/npc/NPC.tscn")
const OFFICE_SCENE := preload("res://scenes/world/OfficeDoor.tscn")

var current_region := "lower_city"
var decisions: Array = []
var daily_decision_queue: Array = []
var active_npcs: Array[NarrativeNPC] = []
var office_door: OfficeDoor
var player: PlayerController
var pending_spawn_x := -1.0
var pending_environment_alert := ""

@onready var background: Sprite2D = $Background
@onready var atmosphere: CanvasModulate = $Atmosphere
@onready var npc_layer: Node2D = $NPCs
@onready var interaction_layer: Node2D = $Interactables
@onready var bridge_foreground_posts: Node2D = $BridgeForegroundPosts
@onready var dialogue_ui: DialogueUI = $DialogueUI
@onready var decision_ui: DecisionUI = $DecisionUI
@onready var hud: GameHUD = $HUD
@onready var loading_screen: LoadingScreen = $LoadingScreen
@onready var ending_ui: EndingUI = $EndingUI
@onready var main_menu: MainMenu = $MainMenu
@onready var environmental_transition: EnvironmentalTransitionUI = $EnvironmentalTransition
@onready var player_spawn: Marker2D = $PlayerSpawn


func _ready() -> void:
	player = $Player
	_load_decisions()
	player.interaction_target_changed.connect(hud.set_interaction_prompt)
	dialogue_ui.dialogue_finished.connect(_unlock_player)
	decision_ui.decision_selected.connect(_on_decision_selected)
	decision_ui.closed.connect(_unlock_player)
	hud.region_requested.connect(change_region)
	hud.save_requested.connect(_save_game)
	hud.load_requested.connect(_load_game)
	GameState.game_loaded.connect(_on_game_loaded)
	DayManager.day_started.connect(_on_day_started)
	loading_screen.transition_finished.connect(_on_loading_transition_finished)
	ending_ui.restart_requested.connect(_restart_game)
	ending_ui.menu_requested.connect(_return_to_menu)
	main_menu.new_game_requested.connect(_restart_game)
	main_menu.continue_requested.connect(_continue_from_menu)
	main_menu.quit_requested.connect(get_tree().quit)
	_apply_region(current_region)
	DayManager.start_day()
	_lock_player()
	loading_screen.play_startup()
	hud.show_notice("A/D ou ←/→ para caminhar  •  E para interagir", 5.0)


func _unhandled_input(event: InputEvent) -> void:
	if _is_modal_ui_open():
		return
	if event.is_action_pressed("quick_save"):
		_save_game()
	elif event.is_action_pressed("quick_load"):
		_load_game()


func _process(_delta: float) -> void:
	if player.controls_enabled:
		if player.position.x <= 45.0 and Input.is_action_pressed("move_left"):
			_move_to_adjacent_region(-1)
		elif player.position.x >= 1155.0 and Input.is_action_pressed("move_right"):
			_move_to_adjacent_region(1)


func _move_to_adjacent_region(direction: int) -> void:
	var order := ["lower_city", "bridge", "upper_city"]
	var next_index: int = order.find(current_region) + direction
	if next_index < 0 or next_index >= order.size():
		return
	pending_spawn_x = 1150.0 if direction < 0 else 50.0
	change_region(order[next_index])


func change_region(region_id: String) -> void:
	if not REGION_DATA.has(region_id) or region_id == current_region or loading_screen.busy:
		return
	_lock_player()
	loading_screen.transition(String(REGION_DATA[region_id]["travel"]), _apply_region.bind(region_id))


func _apply_region(region_id: String) -> void:
	if not REGION_DATA.has(region_id):
		return
	current_region = region_id
	bridge_foreground_posts.visible = current_region == "bridge"
	player.clear_interactions()
	_clear_region_content()
	_refresh_background()
	_spawn_region_content()
	player.position = player_spawn.position if region_id == "lower_city" else REGION_DATA[region_id]["spawn"]
	if pending_spawn_x >= 0.0:
		player.position.x = pending_spawn_x
		pending_spawn_x = -1.0
	hud.set_region_name(REGION_DATA[region_id]["name"])


func _refresh_background() -> void:
	var stage := GameState.get_environment_stage()
	var state_key := "clean" if stage == GameState.ENV_CLEAN else "polluted"
	background.texture = load(REGION_DATA[current_region][state_key])
	background.position = Vector2(600, 450)
	match stage:
		GameState.ENV_POLLUTED:
			atmosphere.color = Color(0.88, 0.82, 0.77, 1.0)
		GameState.ENV_HEAVILY_POLLUTED:
			atmosphere.color = Color(0.68, 0.61, 0.65, 1.0)
		_:
			atmosphere.color = Color(0.96, 0.98, 1.0, 1.0)


func _clear_region_content() -> void:
	for child in npc_layer.get_children():
		child.queue_free()
	for child in interaction_layer.get_children():
		child.queue_free()
	active_npcs.clear()
	office_door = null


func _spawn_region_content() -> void:
	var npc_definitions := {
		"upper_city": [
			{"id": "executive", "name": "Einar", "profession": "Conselheiro corporativo", "region": "upper_city", "portrait": "res://assets/characters/cat_director.png", "portrait_side": "right", "map_frame": 3, "flip": true, "position": Vector2(612, 720)}
		],
		"bridge": [
			{"id": "adviser", "name": "Sigrid", "profession": "Assessora econômica", "region": "bridge", "portrait": "res://assets/characters/cat_adviser.png", "portrait_side": "left", "map_frame": 2, "position": Vector2(650, 500)}
		],
		"lower_city": [
			{"id": "worker", "name": "Noah", "profession": "Operador da refinaria", "region": "lower_city", "portrait": "res://assets/characters/cat_worker.png", "portrait_side": "left", "map_frame": 0, "position": Vector2(480, 750)},
			{"id": "resident", "name": "Liv", "profession": "Jornalista local", "region": "lower_city", "portrait": "res://assets/characters/cat_reporter.png", "portrait_side": "right", "map_frame": 1, "flip": true, "position": Vector2(890, 750)}
		]
	}
	for data in npc_definitions[current_region]:
		var npc: NarrativeNPC = NPC_SCENE.instantiate()
		npc.position = data["position"]
		npc_layer.add_child(npc)
		npc.setup(data)
		npc.interaction_requested.connect(_on_npc_interaction)
		active_npcs.append(npc)
	if current_region == "upper_city":
		office_door = OFFICE_SCENE.instantiate()
		office_door.position = Vector2(310, 700)
		interaction_layer.add_child(office_door)
		office_door.interaction_requested.connect(_open_office)


func _on_npc_interaction(interactable: Interactable) -> void:
	var npc := interactable as NarrativeNPC
	_lock_player()
	dialogue_ui.show_dialogue(npc.character_name, npc.get_dialogue(), npc.portrait_path, npc.portrait_side)


func _open_office(_interactable: Interactable) -> void:
	if GameState.game_ended:
		return
	if daily_decision_queue.is_empty():
		hud.show_notice("As decisões de hoje já foram concluídas. Explore a ilha.")
		return
	_lock_player()
	decision_ui.show_decision(daily_decision_queue[0])


func _load_decisions() -> void:
	var file := FileAccess.open("res://data/decisions.json", FileAccess.READ)
	if file == null:
		push_error("Não foi possível abrir decisions.json")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		decisions = parsed


func _prepare_daily_decisions() -> void:
	daily_decision_queue.clear()
	if decisions.is_empty():
		return
	var available: Array[Dictionary] = []
	for decision in decisions:
		if decision is Dictionary and _is_decision_available(decision):
			available.append(decision)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("decisions:%d:%d:%d:%d:%d" % [
		GameState.current_day,
		GameState.decision_history.size(),
		GameState.production,
		GameState.environment,
		GameState.diversification
	])
	for _slot in range(mini(DayManager.DECISIONS_PER_DAY, available.size())):
		var selected_index := _weighted_decision_index(available, rng)
		daily_decision_queue.append(available[selected_index])
		available.remove_at(selected_index)


func _is_decision_available(decision: Dictionary) -> bool:
	var decision_id := String(decision.get("id", ""))
	if decision_id.is_empty():
		return false
	var repeatable := bool(decision.get("repeatable", false))
	if not repeatable and GameState.has_completed_decision(decision_id):
		return false
	if repeatable:
		var cooldown_days := int(decision.get("cooldown_days", 4))
		if GameState.current_day - GameState.get_decision_last_day(decision_id) <= cooldown_days:
			return false
	if GameState.current_day < int(decision.get("min_day", 1)):
		return false
	var conditions: Dictionary = decision.get("conditions", {})
	for stat_name in conditions.get("min", {}):
		if _game_stat(String(stat_name)) < int(conditions["min"][stat_name]):
			return false
	for stat_name in conditions.get("max", {}):
		if _game_stat(String(stat_name)) > int(conditions["max"][stat_name]):
			return false
	var required_choice := String(conditions.get("requires_choice", ""))
	if not required_choice.is_empty() and not GameState.chose(required_choice):
		return false
	return true


func _weighted_decision_index(pool: Array[Dictionary], rng: RandomNumberGenerator) -> int:
	var weights: Array[float] = []
	var total := 0.0
	for decision in pool:
		var weight := _decision_weight(decision)
		weights.append(weight)
		total += weight
	var roll := rng.randf_range(0.0, total)
	for index in range(pool.size()):
		roll -= weights[index]
		if roll <= 0.0:
			return index
	return pool.size() - 1


func _decision_weight(decision: Dictionary) -> float:
	var weight := maxf(0.05, float(decision.get("weight", 1.0)))
	var decision_id := String(decision.get("id", ""))
	if GameState.get_decision_last_day(decision_id) > -900:
		weight *= 0.55
	var tags: Array = decision.get("tags", [])
	if tags.has("production_growth"):
		weight *= clampf((82.0 - GameState.production) / 30.0, 0.15, 2.0)
	if tags.has("production_control"):
		weight *= clampf((GameState.production - 25.0) / 30.0, 0.25, 2.1)
	if tags.has("maintenance"):
		weight *= 1.7 if GameState.production >= 60 else 0.8
	if tags.has("environment"):
		weight *= clampf((110.0 - GameState.environment) / 45.0, 0.65, 2.25)
	if tags.has("economy"):
		weight *= 1.7 if GameState.economy < 45 or GameState.money < 75 else 0.9
	if tags.has("society"):
		weight *= 1.65 if GameState.employment < 48 or GameState.population_approval < 45 else 0.95
	if tags.has("diversification"):
		weight *= clampf(0.85 + GameState.diversification / 65.0, 0.85, 2.2)
	if tags.has("oil_crisis"):
		weight *= 2.2 if GameState.oil < 40 else 0.35
	return maxf(weight, 0.05)


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


func _on_day_started(day: int) -> void:
	var ending := GameState.evaluate_ending()
	if not ending.is_empty():
		_trigger_ending(ending)
		return
	_prepare_daily_decisions()
	_refresh_background()
	var event_text := ""
	if not GameState.active_events.is_empty():
		event_text = "\nEVENTO: %s" % GameState.active_events[0]
	hud.show_notice("Dia %d começou. Vá ao escritório na Cidade Alta.%s" % [day, event_text], 5.0)
func _on_decision_selected(decision_id: String, choice_id: String, choice_text: String, effects: Dictionary, event_id: String) -> void:
	var previous_environment_stage := GameState.get_environment_stage()
	GameState.apply_effects(effects)
	GameState.register_decision(decision_id, choice_id, event_id)
	if not daily_decision_queue.is_empty():
		daily_decision_queue.pop_front()
	var day_finished := DayManager.register_decision()
	var current_environment_stage := GameState.get_environment_stage()
	if _is_new_environmental_decline(previous_environment_stage, current_environment_stage):
		GameState.mark_environmental_alert_seen(current_environment_stage)
		_lock_player()
		await environmental_transition.play_transition(
			_environmental_message(current_environment_stage, current_region),
			_refresh_background
		)
	else:
		_refresh_background()
	if day_finished:
		_lock_player()
		loading_screen.transition("A noite passa. A ilha guarda as consequências.", _advance_to_next_day.bind(choice_text))
	else:
		hud.show_notice("A decisão foi registrada. Ainda há um assunto sobre a mesa.", 3.6)
		_unlock_player()


func _advance_to_next_day(_choice_text: String) -> void:
	var previous_environment_stage := GameState.get_environment_stage()
	DayManager.end_day()
	var current_environment_stage := GameState.get_environment_stage()
	if _is_new_environmental_decline(previous_environment_stage, current_environment_stage):
		GameState.mark_environmental_alert_seen(current_environment_stage)
		pending_environment_alert = _environmental_message(current_environment_stage, "lower_city")
	pending_spawn_x = -1.0
	_apply_region("lower_city")
	player.position = player_spawn.position
	DayManager.start_day()
	hud.show_notice("Um novo dia começa. Observe a ilha antes de voltar ao escritório.", 4.5)


func _on_loading_transition_finished() -> void:
	if not pending_environment_alert.is_empty():
		var message := pending_environment_alert
		pending_environment_alert = ""
		await environmental_transition.play_transition(message)
	_unlock_player()


func _is_new_environmental_decline(previous_stage: String, current_stage: String) -> bool:
	return (
		GameState.environment_stage_rank(current_stage) > GameState.environment_stage_rank(previous_stage)
		and not GameState.has_seen_environmental_alert(current_stage)
	)


func _environmental_message(stage: String, region_id: String) -> String:
	if stage == GameState.ENV_HEAVILY_POLLUTED:
		match region_id:
			"upper_city": return "Nem a Cidade Alta escapa mais: a névoa industrial apaga o brilho do fiorde."
			"bridge": return "Da ponte, a extensão da mancha fica impossível de ignorar. A ilha respira com dificuldade."
			_: return "A fuligem cobre as ruas da Cidade Baixa, e o cheiro do petróleo domina o vento."
	match region_id:
		"upper_city": return "Uma névoa incomum alcança a Cidade Alta. O progresso já projeta sua sombra sobre as montanhas."
		"bridge": return "O vento da ponte traz um cheiro pesado. As primeiras marcas da indústria aparecem no fiorde."
		_: return "A brisa do porto mudou. Fumaça e óleo começam a marcar a rotina da Cidade Baixa."


func _is_modal_ui_open() -> bool:
	return (
		dialogue_ui.is_open()
		or decision_ui.is_open()
		or main_menu.is_open()
		or ending_ui.is_open()
		or loading_screen.busy
		or environmental_transition.busy
	)


func _lock_player() -> void:
	player.controls_enabled = false


func _unlock_player() -> void:
	if not GameState.game_ended and not _is_modal_ui_open():
		player.controls_enabled = true


func _save_game() -> void:
	var ok := GameState.save_game()
	hud.show_notice("Jogo salvo." if ok else "Não foi possível salvar.")


func _load_game() -> void:
	var ok := GameState.load_game()
	if not ok:
		hud.show_notice("Nenhum save encontrado.")


func _on_game_loaded() -> void:
	_apply_region(current_region)
	var ending := GameState.evaluate_ending()
	if GameState.game_ended and not ending.is_empty():
		_trigger_ending(ending, false)
	else:
		GameState.game_ended = false
		DayManager.start_day()
		hud.show_notice("Jogo carregado.")


func _trigger_ending(ending: Dictionary, finalize := true) -> void:
	_lock_player()
	daily_decision_queue.clear()
	if finalize:
		GameState.finalize_ending(ending)
	ending_ui.show_ending(ending)


func _restart_game() -> void:
	ending_ui.hide_screen()
	main_menu.hide_menu()
	_lock_player()
	loading_screen.transition("Uma nova história começa em Skarvik", _reset_world)


func _reset_world() -> void:
	GameState.reset()
	current_region = "lower_city"
	pending_spawn_x = -1.0
	_apply_region(current_region)
	DayManager.start_day()


func _return_to_menu() -> void:
	ending_ui.hide_screen()
	_lock_player()
	main_menu.show_menu()


func _continue_from_menu() -> void:
	main_menu.hide_menu()
	if not GameState.load_game():
		_restart_game()

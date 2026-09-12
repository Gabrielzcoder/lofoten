extends SceneTree

var failures: Array[String] = []
var main
var game_state
var day_manager


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS | ", description)
	else:
		failures.append(description)
		push_error("FAIL | " + description)


func _capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/screenshots"))
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png("res://tests/screenshots/%s.png" % name)
	_check(error == OK, "captura visual %s foi salva" % name)


func _run() -> void:
	game_state = root.get_node("GameState")
	day_manager = root.get_node("DayManager")
	game_state.reset()
	main = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.7).timeout

	_check(main.player_spawn is Marker2D, "PlayerSpawn existe como Marker2D")
	_check(main.player_spawn.position == Vector2(600, 708), "PlayerSpawn está no ponto seguro da Cidade Baixa")

	for region in ["lower_city", "bridge", "upper_city"]:
		game_state.reset()
		main._apply_region(region)
		main.player.position = Vector2(1040, 400)
		var previous_day: int = game_state.current_day
		main._advance_to_next_day("")
		_check(main.current_region == "lower_city", "fim do dia em %s retorna à Cidade Baixa" % region)
		_check(main.player.position.distance_to(main.player_spawn.position) < 0.1, "fim do dia em %s usa exatamente PlayerSpawn" % region)
		_check(game_state.current_day == previous_day + 1, "contador avança após retorno de %s" % region)

	var tested_npcs: Array[String] = []
	for region in ["lower_city", "bridge", "upper_city"]:
		main._apply_region(region)
		await process_frame
		for npc in main.active_npcs:
			main._on_npc_interaction(npc)
			await create_timer(0.38).timeout
			tested_npcs.append(npc.npc_id)
			_check(not main.player.controls_enabled, "%s bloqueia movimento durante diálogo" % npc.character_name)
			_check(main.dialogue_ui.portrait.texture != null, "%s exibe portrait" % npc.character_name)
			_check(main.dialogue_ui.portrait.texture.resource_path == npc.portrait_path, "%s usa o portrait correto" % npc.character_name)
			_check(main.dialogue_ui.portrait.size.y >= 600.0, "%s usa portrait grande" % npc.character_name)
			_check(main.dialogue_ui.portrait.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "%s preserva a proporção da arte" % npc.character_name)
			_check(main.dialogue_ui.dialogue_box.global_position.y > 580.0, "texto de %s fica na parte inferior" % npc.character_name)
			if npc.npc_id == "worker" or npc.npc_id == "executive":
				await _capture("dialogue_%s" % npc.npc_id)
			if main.dialogue_ui.typing_tween and main.dialogue_ui.typing_tween.is_valid():
				main.dialogue_ui.typing_tween.kill()
			main.dialogue_ui.is_typing = false
			await main.dialogue_ui._close_animated()
			await process_frame
			_check(main.player.controls_enabled, "controle retorna após falar com %s" % npc.character_name)

	for expected in ["worker", "resident", "adviser", "executive"]:
		_check(tested_npcs.has(expected), "NPC %s foi testado" % expected)

	main.decision_ui.show_decision(main.decisions[0])
	await create_timer(0.35).timeout
	_check(main.decision_ui.is_open(), "interface de escolhas abre")
	_check(main.decision_ui.get_node("Root/DecisionPortrait").visible, "portrait permanece visível com escolhas")
	_check(main.decision_ui.get_node("Root/Center/DecisionPanel/Layout/Choices").get_child_count() > 0, "botões de escolha são apresentados")
	await _capture("decision_with_portrait")
	await main.decision_ui._close()

	game_state.reset()
	main._apply_region("lower_city")
	var clean_stage: String = game_state.get_environment_stage()
	_check(clean_stage == game_state.ENV_CLEAN, "estado ambiental inicial é CLEAN")
	game_state.environment = 45
	var polluted_stage: String = game_state.get_environment_stage()
	_check(main._is_new_environmental_decline(clean_stage, polluted_stage), "primeiro estágio poluído é detectado")
	game_state.mark_environmental_alert_seen(polluted_stage)
	main._refresh_background()
	_check(main.background.texture.resource_path.ends_with("lower_city_2.jpg"), "Cidade Baixa usa cenário poluído")
	_check(not main._is_new_environmental_decline(polluted_stage, polluted_stage), "aviso POLLUTED não se repete")
	main._apply_region("bridge")
	main._apply_region("lower_city")
	_check(main.background.texture.resource_path.ends_with("lower_city_2.jpg"), "cenário poluído persiste ao sair e voltar")

	game_state.environment = 20
	var heavy_stage: String = game_state.get_environment_stage()
	_check(main._is_new_environmental_decline(polluted_stage, heavy_stage), "estágio HEAVILY_POLLUTED gera novo aviso")
	game_state.mark_environmental_alert_seen(heavy_stage)
	main._refresh_background()
	_check(game_state.has_seen_environmental_alert(game_state.ENV_POLLUTED), "aviso POLLUTED permanece registrado")
	_check(game_state.has_seen_environmental_alert(game_state.ENV_HEAVILY_POLLUTED), "aviso grave fica registrado")
	_check(not main._is_new_environmental_decline(heavy_stage, heavy_stage), "aviso grave não se repete")
	_check(game_state.to_dictionary().has("environmental_alerts_seen"), "avisos ambientais fazem parte do save")

	await main.environmental_transition.play_transition(main._environmental_message(heavy_stage, "lower_city"), main._refresh_background)
	_check(not main.environmental_transition.busy, "transição ambiental termina e libera o fluxo")
	await _capture("heavily_polluted_city")

	var theme: Theme = load("res://assets/ui/island_theme.tres")
	var panel_style: StyleBoxFlat = theme.get_stylebox("panel", "Panel")
	var hover_style: StyleBoxFlat = theme.get_stylebox("hover", "Button")
	_check(panel_style.border_color.b > panel_style.border_color.r, "painéis usam bordas roxas")
	_check(hover_style.bg_color.b > hover_style.bg_color.r, "botões destacados usam roxo")
	main.main_menu.show_menu()
	await create_timer(0.3).timeout
	await _capture("main_menu_purple")
	main.main_menu.hide_menu()

	if failures.is_empty():
		print("TEST_RESULT | 20/20 grupos aprovados")
		quit(0)
	else:
		print("TEST_RESULT | falhas: ", failures.size())
		for failure in failures:
			print(" - ", failure)
		quit(1)

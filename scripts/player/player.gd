class_name PlayerController
extends CharacterBody2D

signal interaction_target_changed(text: String)

@export var speed := 230.0
@export var step_frequency := 9.0
@export var step_height := 2.8
@export var body_sway := 0.035
var controls_enabled := true
var nearby: Array[Interactable] = []
var walk_phase := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shadow: Polygon2D = $Shadow

const REST_POSITION := Vector2(0.0, -38.0)
const REST_SCALE := Vector2(0.16, 0.16)


func _ready() -> void:
	$InteractionArea.area_entered.connect(_on_area_entered)
	$InteractionArea.area_exited.connect(_on_area_exited)
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		_update_movement_effects(delta, 0.0)
		return
	var direction := Input.get_axis("move_left", "move_right")
	velocity = Vector2(direction * speed, 0.0)
	move_and_slide()
	if direction != 0.0:
		sprite.flip_h = direction < 0.0
	_update_movement_effects(delta, direction)
	if Input.is_action_just_pressed("interact") and not nearby.is_empty():
		nearby[0].interact()


func _update_movement_effects(delta: float, direction: float) -> void:
	if absf(direction) > 0.01:
		walk_phase = fmod(walk_phase + delta * step_frequency, TAU)
		var stride := sin(walk_phase)
		var bounce := absf(stride)
		var squeeze := cos(walk_phase * 2.0) * 0.018
		sprite.position = REST_POSITION + Vector2(stride * 0.7, -bounce * step_height)
		sprite.rotation = stride * body_sway
		sprite.scale = REST_SCALE * Vector2(1.0 + squeeze, 1.0 - squeeze)
		shadow.scale = Vector2(1.0 - bounce * 0.12, 1.0 - bounce * 0.08)
		shadow.modulate.a = 1.0 - bounce * 0.22
	else:
		walk_phase = 0.0
		var settle := minf(delta * 10.0, 1.0)
		sprite.position = sprite.position.lerp(REST_POSITION, settle)
		sprite.rotation = lerpf(sprite.rotation, 0.0, settle)
		sprite.scale = sprite.scale.lerp(REST_SCALE, settle)
		shadow.scale = shadow.scale.lerp(Vector2.ONE, settle)
		shadow.modulate.a = lerpf(shadow.modulate.a, 1.0, settle)


func _on_area_entered(area: Area2D) -> void:
	if area is Interactable and not nearby.has(area):
		nearby.append(area)
		interaction_target_changed.emit("E — %s" % area.prompt_text)


func _on_area_exited(area: Area2D) -> void:
	if area is Interactable:
		nearby.erase(area)
		if nearby.is_empty():
			interaction_target_changed.emit("")
		else:
			interaction_target_changed.emit("E — %s" % nearby[0].prompt_text)


func clear_interactions() -> void:
	nearby.clear()
	interaction_target_changed.emit("")

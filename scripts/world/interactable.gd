class_name Interactable
extends Area2D

@export var prompt_text := "Interagir"
signal interaction_requested(interactable: Interactable)


func interact() -> void:
	interaction_requested.emit(self)


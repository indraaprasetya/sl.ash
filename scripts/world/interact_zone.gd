class_name InteractZone
extends Area2D

signal triggered(zone: InteractZone, player: Node)

var kind: StringName = &"shrine"
var target_room: StringName = &""
var target_entry: StringName = &"default"
var prompt_text: String = "[F] Interact"


func _ready() -> void:
	collision_layer = 64
	collision_mask = 0
	set_meta("prompt", prompt_text)


func set_prompt(text: String) -> void:
	prompt_text = text
	set_meta("prompt", prompt_text)


func trigger_interact(player: Node) -> void:
	triggered.emit(self, player)

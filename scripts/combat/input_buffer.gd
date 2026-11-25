class_name InputBuffer
extends Node

const BUFFER_WINDOW_MS := 145
const WATCHED_ACTIONS: Array = [
	&"jump",
	&"attack",
	&"heavy",
	&"skill",
	&"dash",
	&"parry",
	&"vault",
	&"weapon_swap",
]

var _timestamps: Dictionary = {}


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	for act in WATCHED_ACTIONS:
		if Input.is_action_just_pressed(act):
			_timestamps[act] = now


func record(action: StringName) -> void:
	_timestamps[action] = Time.get_ticks_msec()


func peek(action: StringName) -> bool:
	if not _timestamps.has(action):
		return false
	return (Time.get_ticks_msec() - int(_timestamps[action])) <= BUFFER_WINDOW_MS


func consume(action: StringName) -> bool:
	if peek(action):
		_timestamps.erase(action)
		return true
	return false


func clear(action: StringName) -> void:
	_timestamps.erase(action)


func clear_all() -> void:
	_timestamps.clear()

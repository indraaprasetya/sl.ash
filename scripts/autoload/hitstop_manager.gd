extends Node

signal shake_requested(trauma: float)
signal punch_requested(dir: Vector2, zoom_bump: float)
signal toast_requested(message: String, color: Color)


func apply_hitstop(targets: Array, frames: int) -> void:
	if frames <= 0:
		return
	var duration := float(frames) / 60.0
	for target in targets:
		if is_instance_valid(target) and target.has_method("apply_hitstop"):
			target.apply_hitstop(duration)


func request_shake(trauma: float) -> void:
	shake_requested.emit(clampf(trauma, 0.0, 1.0))


func request_punch(dir: Vector2, zoom_bump: float = 0.0) -> void:
	punch_requested.emit(dir, clampf(zoom_bump, -0.08, 0.12))


func show_toast(message: String, color: Color = Color(0.95, 0.95, 1.0, 1.0)) -> void:
	toast_requested.emit(message, color)

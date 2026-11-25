class_name BladeTrail
extends Node2D

const MAX_LIFE := 0.15
const MAX_SAMPLES := 28

var _samples: Array = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 22


func add_sample(base_pos: Vector2, tip_pos: Vector2, col: Color) -> void:
	if not _samples.is_empty():
		var last: Dictionary = _samples[_samples.size() - 1]
		var prev_tip: Vector2 = last["tip"]
		if prev_tip.distance_to(tip_pos) < 1.2:
			return
	_samples.append({
		"base": base_pos,
		"tip": tip_pos,
		"age": 0.0,
		"col": col,
	})
	if _samples.size() > MAX_SAMPLES:
		_samples.pop_front()
	queue_redraw()


func add_arc_samples(
	pivot_world: Vector2,
	guard_x: float,
	blade_len: float,
	prev_rad: float,
	cur_rad: float,
	facing_sign: int,
	col: Color,
	substeps: int = 4
) -> void:
	var n := maxi(1, substeps)
	for s in range(1, n + 1):
		var t := float(s) / float(n)
		var ang := lerpf(prev_rad, cur_rad, t)
		var dir := Vector2(cos(ang) * float(facing_sign), sin(ang))
		add_sample(pivot_world + dir * guard_x, pivot_world + dir * blade_len, col)


func clear_trail() -> void:
	_samples.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if _samples.is_empty():
		return
	var kept: Array = []
	for s in _samples:
		var entry: Dictionary = s
		var next_age: float = float(entry["age"]) + delta
		if next_age < MAX_LIFE:
			entry["age"] = next_age
			kept.append(entry)
	_samples = kept
	queue_redraw()


func _draw_tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	if absf((b - a).cross(c - a)) <= 0.5:
		return
	draw_primitive(
		PackedVector2Array([a, b, c]),
		PackedColorArray([col, col, col]),
		PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	)


func _draw() -> void:
	if _samples.size() < 2:
		return
	for i in range(_samples.size() - 1):
		var s0: Dictionary = _samples[i]
		var s1: Dictionary = _samples[i + 1]
		var b0: Vector2 = s0["base"]
		var t0: Vector2 = s0["tip"]
		var b1: Vector2 = s1["base"]
		var t1: Vector2 = s1["tip"]
		if t0.distance_to(t1) < 0.6 or b0.distance_to(t0) < 2.0:
			continue

		var age_ratio: float = clampf(float(s1["age"]) / MAX_LIFE, 0.0, 1.0)
		var seg_frac: float = float(i + 1) / float(_samples.size() - 1)
		var alpha: float = (1.0 - age_ratio) * seg_frac
		if alpha <= 0.02:
			continue

		# Taper tail base slightly toward tip so older trail narrows cleanly
		var taper0: float = lerpf(0.65, 0.08, float(i) / float(_samples.size() - 1))
		var taper1: float = lerpf(0.65, 0.08, seg_frac)
		var ib0: Vector2 = t0.lerp(b0, 1.0 - taper0 * 0.5)
		var ib1: Vector2 = t1.lerp(b1, 1.0 - taper1 * 0.5)

		var c: Color = s1["col"]
		var ink_col := Color(0.05, 0.06, 0.12, alpha * 0.72)
		var fill_col := Color(c.r, c.g, c.b, alpha * 0.70)
		_draw_tri(ib0, t0, t1, fill_col)
		_draw_tri(ib0, t1, ib1, fill_col)

		draw_line(t0, t1, ink_col, maxf(1.8, 3.6 * seg_frac))
		var edge_col := Color(1.0, 1.0, 1.0, alpha * 0.96)
		draw_line(t0, t1, edge_col, maxf(1.2, 2.8 * seg_frac))

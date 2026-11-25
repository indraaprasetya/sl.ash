class_name ScarfRibbon
extends Node2D

const NODE_COUNT := 7
const SEG_LEN := 4.2

var _nodes: Array = []
var _prev_nodes: Array = []
var _anchor: Vector2 = Vector2.ZERO
var _facing: int = 1
var _elem_col: Color = Color(0.95, 0.35, 0.42)
var _boost_glow: bool = false
var _time: float = 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 3
	reset_to(global_position)


func reset_to(world_pos: Vector2) -> void:
	_anchor = world_pos
	_nodes.clear()
	_prev_nodes.clear()
	for i in range(NODE_COUNT):
		var p := world_pos + Vector2(-float(_facing) * float(i) * SEG_LEN, float(i) * 1.2)
		_nodes.append(p)
		_prev_nodes.append(p)
	queue_redraw()


func set_anchor(world_pos: Vector2, dir: int, elem_col: Color, boost_glow: bool = false) -> void:
	_anchor = world_pos
	_facing = dir
	_elem_col = elem_col
	_boost_glow = boost_glow
	if _nodes.is_empty():
		reset_to(world_pos)
	else:
		_nodes[0] = world_pos


func _physics_process(delta: float) -> void:
	if _nodes.size() < NODE_COUNT:
		return
	_time += delta
	var dt := minf(delta, 0.033)
	var flutter := sin(_time * 14.0) * 28.0
	var accel := Vector2(-float(_facing) * 145.0, 140.0 + flutter)

	_nodes[0] = _anchor
	_prev_nodes[0] = _anchor

	for i in range(1, NODE_COUNT):
		var cur: Vector2 = _nodes[i]
		var prev: Vector2 = _prev_nodes[i]
		var vel: Vector2 = (cur - prev) * 0.86
		_prev_nodes[i] = cur
		_nodes[i] = cur + vel + accel * (dt * dt * 22.0)

	# Distance constraint relaxation
	for _iter in range(3):
		_nodes[0] = _anchor
		for i in range(1, NODE_COUNT):
			var p0: Vector2 = _nodes[i - 1]
			var p1: Vector2 = _nodes[i]
			var d: Vector2 = p1 - p0
			var dist := d.length()
			if dist > 0.001:
				var corr := d * ((dist - SEG_LEN) / dist)
				if i == 1:
					_nodes[i] = p1 - corr
				else:
					_nodes[i - 1] = p0 + corr * 0.25
					_nodes[i] = p1 - corr * 0.75

	queue_redraw()


func _draw() -> void:
	if _nodes.size() < 2:
		return
	var col_dark := Color(0.48, 0.10, 0.17, 1.0)
	var col_mid := Color(0.86, 0.19, 0.27, 1.0)
	var col_hi := Color(1.0, 0.48, 0.44, 1.0)
	if _boost_glow:
		col_mid = col_mid.lerp(_elem_col, 0.35)
		col_hi = col_hi.lerp(Color.WHITE, 0.35)

	for i in range(NODE_COUNT - 1):
		var p0: Vector2 = _nodes[i]
		var p1: Vector2 = _nodes[i + 1]
		var frac := float(i) / float(NODE_COUNT - 1)
		var w_outer := lerpf(4.0, 1.8, frac)
		var w_inner := lerpf(2.4, 1.0, frac)
		draw_line(p0, p1, col_dark, w_outer)
		draw_line(p0, p1, col_mid if i < NODE_COUNT - 2 else col_hi, w_inner)
	var tip: Vector2 = _nodes[NODE_COUNT - 1]
	draw_circle(tip, 1.2, col_hi)

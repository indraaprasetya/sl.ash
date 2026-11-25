extends Node2D

var room_builder: RoomBuilder
var player: Player
var cam: Camera2D
var hud: GameHud
var prep_ui: PrepUi
var fade_overlay: ColorRect

var _trauma: float = 0.0
var _cam_punch: Vector2 = Vector2.ZERO
var _zoom_bump: float = 0.0
var _transitioning: bool = false


func _ready() -> void:
	add_to_group(&"game_controller")

	room_builder = RoomBuilder.new()
	add_child(room_builder)

	player = Player.new()
	add_child(player)

	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 11.0
	player.add_child(cam)

	hud = GameHud.new()
	add_child(hud)

	prep_ui = PrepUi.new()
	add_child(prep_ui)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 30
	fade_overlay = ColorRect.new()
	fade_overlay.size = Vector2(640, 360)
	fade_overlay.color = Color(0, 0, 0, 0)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_overlay)
	add_child(fade_layer)

	player.health_changed.connect(hud.update_health)
	player.flux_changed.connect(hud.update_flux)
	player.combo_changed.connect(hud.update_combo)
	player.move_performed.connect(hud.show_move_name)
	player.interact_prompt_changed.connect(hud.set_interact_prompt)
	HitstopManager.shake_requested.connect(_on_shake_requested)
	HitstopManager.punch_requested.connect(_on_punch_requested)

	_load_room(&"room_sanctuary", &"default")


func _process(delta: float) -> void:
	var lead := Vector2(player.facing * 24.0, -14.0) + player.velocity * 0.055
	_cam_punch = _cam_punch.lerp(Vector2.ZERO, clampf(delta * 16.0, 0.0, 1.0))
	_zoom_bump = lerpf(_zoom_bump, 0.0, clampf(delta * 12.0, 0.0, 1.0))
	cam.zoom = Vector2.ONE * (1.0 + _zoom_bump)

	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - delta * 2.4)
		var mag := _trauma * _trauma * 10.0
		cam.offset = Vector2(randf_range(-mag, mag), randf_range(-mag, mag)) + lead + _cam_punch
	else:
		cam.offset = cam.offset.lerp(lead + _cam_punch, clampf(delta * 9.0, 0.0, 1.0))


func _on_shake_requested(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)


func _on_punch_requested(dir: Vector2, zoom_bump: float) -> void:
	_cam_punch += dir
	if absf(zoom_bump) > absf(_zoom_bump):
		_zoom_bump = zoom_bump


func _load_room(room_id: StringName, entry_tag: StringName) -> void:
	var info := room_builder.build_room(room_id, entry_tag)
	var bounds: Rect2 = info["bounds"]
	var in_prep := bool(info["in_prep"])
	var spawn_pos: Vector2 = info["spawn_pos"]

	GameState.set_room_state(room_id, in_prep)
	hud.set_room_title(String(info["title"]))
	hud.set_interact_prompt("")

	player.global_position = spawn_pos
	player.velocity = Vector2.ZERO
	player.clear_trails()

	cam.limit_left = int(bounds.position.x)
	cam.limit_top = int(bounds.position.y)
	cam.limit_right = int(bounds.position.x + bounds.size.x)
	cam.limit_bottom = int(bounds.position.y + bounds.size.y)

	for iz in room_builder.interact_zones:
		(iz as InteractZone).triggered.connect(_on_zone_triggered)

	if in_prep:
		HitstopManager.show_toast("Entered Sanctuary: Kit Unlocked for Preparation.", Color(0.45, 0.95, 0.72))
	else:
		HitstopManager.show_toast("Entered Combat Stage: Deployment Kit LOCKED!", Color(1.0, 0.55, 0.35))


func _on_zone_triggered(zone: InteractZone, _p: Node) -> void:
	if _transitioning:
		return
	match zone.kind:
		&"shrine":
			prep_ui.open_prep()
		&"gate":
			_transition_to_room(zone.target_room, zone.target_entry)
		&"shortcut":
			GameState.stash["unlocked_shortcuts"]["spire_to_sanctuary"] = true
			GameState.save_game()
			HitstopManager.show_toast("Shortcut Unlocked! Fast-traveling back to Sanctuary...", Color(0.55, 1.0, 0.75))
			_transition_to_room(zone.target_room, zone.target_entry)


func _transition_to_room(room_id: StringName, entry_tag: StringName) -> void:
	_transitioning = true
	var tw := create_tween()
	tw.tween_property(fade_overlay, "color:a", 1.0, 0.12)
	await tw.finished
	_load_room(room_id, entry_tag)
	var tw2 := create_tween()
	tw2.tween_property(fade_overlay, "color:a", 0.0, 0.14)
	await tw2.finished
	_transitioning = false


func on_player_defeated() -> void:
	if _transitioning:
		return
	_transitioning = true
	var tw := create_tween()
	tw.tween_property(fade_overlay, "color:a", 1.0, 0.45)
	await tw.finished
	_load_room(&"room_sanctuary", &"default")
	player.revive_at_sanctuary()
	var tw2 := create_tween()
	tw2.tween_property(fade_overlay, "color:a", 0.0, 0.3)
	await tw2.finished
	_transitioning = false

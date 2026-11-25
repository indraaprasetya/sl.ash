class_name MoveData
extends Resource

@export var move_id: StringName = &""
@export var display_name: String = ""
@export var slot_tag: StringName = &"light_1"
@export var required_level: int = 1
@export var startup_frames: int = 4
@export var active_frames: int = 4
@export var recovery_frames: int = 8
@export var cancel_from_frame: int = 6
@export var damage_mult: float = 1.0
@export var poise_damage: float = 14.0
@export var hitstop_frames: int = 3
@export var knockback: Vector2 = Vector2(95.0, -35.0)
@export var self_impulse: Vector2 = Vector2(55.0, 0.0)
@export var hitbox_offset: Vector2 = Vector2(28.0, -24.0)
@export var hitbox_size: Vector2 = Vector2(40.0, 32.0)
@export var is_launcher: bool = false
@export var is_dive: bool = false
@export var is_projectile: bool = false
@export var projectile_speed: float = 420.0
@export var projectile_count: int = 1
@export var projectile_spread_deg: float = 9.0
@export var projectile_pitch_deg: float = 0.0
@export var is_switch_attack: bool = false
@export var is_signature: bool = false
@export var is_ultimate: bool = false
@export var is_dual_combine: bool = false
@export var has_hyper_armor: bool = false
@export var arc_angle_deg: float = 95.0
@export var flux_cost: float = 0.0
@export var flux_gain: float = 8.0
@export var swing_style: StringName = &"down_slash"
@export var multi_hits: int = 1
@export var blink_distance: float = 0.0
@export var aoe_ring_radius: float = 0.0
@export var pull_enemies: float = 0.0


static func make(cfg: Dictionary) -> MoveData:
	var m := MoveData.new()
	for k in cfg.keys():
		m.set(k, cfg[k])
	return m


func total_frames() -> int:
	return startup_frames + active_frames + recovery_frames

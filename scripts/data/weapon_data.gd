class_name WeaponData
extends Resource

enum WeaponType {
	GREATSWORD,
	LONGSWORD,
	KATANA,
	BOW,
	DUAL_PISTOL,
	WAND,
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var weapon_type: int = WeaponType.LONGSWORD
@export var sprite_path: String = ""
@export var phys_mult: float = 1.0
@export var elem_mult: float = 1.0
@export var poise_mult: float = 1.0
@export var speed_mult: float = 1.0
@export var primary_trait: StringName = &""
@export var secondary_modifier: StringName = &""
@export var description: String = ""
@export var counter_role: String = ""
@export var moves: Array = []


func get_type_name() -> String:
	match weapon_type:
		WeaponType.GREATSWORD:
			return "Greatsword"
		WeaponType.LONGSWORD:
			return "Longsword"
		WeaponType.KATANA:
			return "Katana"
		WeaponType.BOW:
			return "Bow"
		WeaponType.DUAL_PISTOL:
			return "Dual Pistol"
		WeaponType.WAND:
			return "Wand"
	return "Weapon"


func get_moves_for_level(level: int) -> Array:
	var out: Array = []
	for m in moves:
		if m is MoveData and m.required_level <= level:
			out.append(m)
	return out


func get_move(tag: StringName, level: int) -> MoveData:
	var best: MoveData = null
	for m in moves:
		if m is MoveData and m.slot_tag == tag and m.required_level <= level:
			if best == null or m.required_level >= best.required_level:
				best = m
	return best

extends Node

const SAMPLE_RATE := 22050
const POOL_SIZE := 10

var _streams: Dictionary = {}
var _players: Array = []
var _next_player: int = 0


func _ready() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_players.append(p)
	_build_all_sounds()


func play_sfx(sound_id: StringName, vol_db: float = -7.0, pitch_min: float = 0.92, pitch_max: float = 1.08) -> void:
	if not _streams.has(sound_id) or _players.is_empty():
		return
	var p: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = _streams[sound_id]
	p.volume_db = vol_db
	p.pitch_scale = randf_range(pitch_min, pitch_max)
	p.play()


func play_weapon_swing(weapon_type: int, is_heavy: bool = false) -> void:
	match weapon_type:
		WeaponData.WeaponType.GREATSWORD:
			play_sfx(&"swing_heavy", -4.5, 0.88, 1.02)
		WeaponData.WeaponType.LONGSWORD, WeaponData.WeaponType.KATANA:
			if is_heavy:
				play_sfx(&"swing_heavy", -6.0, 1.05, 1.18)
			else:
				play_sfx(&"swing_blade", -6.5, 0.94, 1.12)
		WeaponData.WeaponType.BOW:
			play_sfx(&"swing_bow", -6.0, 0.95, 1.08)
		WeaponData.WeaponType.DUAL_PISTOL:
			play_sfx(&"swing_pistol", -7.0, 0.94, 1.12)
		WeaponData.WeaponType.WAND:
			play_sfx(&"swing_wand", -6.5, 0.98, 1.16)
		_:
			play_sfx(&"swing_blade", -7.0, 0.94, 1.08)


func _build_all_sounds() -> void:
	_streams[&"swing_heavy"] = _synth(0.24, func(t: float, prog: float, prev_n: float) -> float:
		var env := pow(1.0 - prog, 1.4) * minf(1.0, prog * 8.0)
		var f := lerpf(195.0, 48.0, prog)
		var noise := prev_n * 0.72 + randf_range(-1.0, 1.0) * 0.28
		return (sin(TAU * f * t) * 0.45 + noise * 0.75) * env
	)
	_streams[&"swing_blade"] = _synth(0.11, func(t: float, prog: float, prev_n: float) -> float:
		var env := pow(1.0 - prog, 1.8) * minf(1.0, prog * 14.0)
		var f := lerpf(1550.0, 420.0, prog)
		var noise := prev_n * 0.35 + randf_range(-1.0, 1.0) * 0.65
		return (sin(TAU * f * t) * 0.28 + noise * 0.72) * env
	)
	_streams[&"swing_bow"] = _synth(0.13, func(t: float, prog: float, prev_n: float) -> float:
		var env := pow(1.0 - prog, 2.0)
		var f := lerpf(640.0, 210.0, prog)
		var noise := prev_n * 0.4 + randf_range(-1.0, 1.0) * 0.6
		return (sin(TAU * f * t) * 0.55 + noise * 0.35) * env
	)
	_streams[&"swing_pistol"] = _synth(0.09, func(t: float, prog: float, prev_n: float) -> float:
		var env := pow(1.0 - prog, 2.6)
		var f := lerpf(420.0, 80.0, prog)
		var crack := randf_range(-1.0, 1.0) * (0.85 if prog < 0.25 else 0.25)
		return clampf((sin(TAU * f * t) * 0.5 + crack + prev_n * 0.1) * env, -1.0, 1.0)
	)
	_streams[&"swing_wand"] = _synth(0.15, func(t: float, prog: float, prev_n: float) -> float:
		var env := pow(1.0 - prog, 1.7) * minf(1.0, prog * 12.0)
		var f_sweep := lerpf(1680.0, 920.0, prog)
		var chime := sin(TAU * 880.0 * t) * 0.34 + sin(TAU * 1320.0 * t) * 0.24 + sin(TAU * f_sweep * t) * 0.18
		return clampf((chime + prev_n * 0.18) * env, -1.0, 1.0)
	)
	_streams[&"hit_light"] = _synth(0.09, func(t: float, prog: float, prev_n: float) -> float:
		var env := pow(1.0 - prog, 2.4)
		var f := lerpf(280.0, 62.0, prog)
		var snap := randf_range(-1.0, 1.0) * (0.7 if prog < 0.18 else 0.12)
		return (sin(TAU * f * t) * 0.65 + snap + prev_n * 0.08) * env
	)
	_streams[&"hit_heavy"] = _synth(0.18, func(t: float, prog: float, prev_n: float) -> float:
		var env := pow(1.0 - prog, 1.9)
		var f := lerpf(185.0, 38.0, prog)
		var crunch := randf_range(-1.0, 1.0) * (0.75 if prog < 0.25 else 0.20)
		return clampf((sin(TAU * f * t) * 0.80 + crunch + prev_n * 0.15) * env, -1.0, 1.0)
	)
	_streams[&"hit_counter"] = _synth(0.20, func(t: float, prog: float, _prev_n: float) -> float:
		var env := pow(1.0 - prog, 1.8)
		var f := lerpf(540.0, 150.0, prog)
		return (sin(TAU * f * t) * 0.5 + sin(TAU * 1080.0 * t) * 0.35) * env
	)
	_streams[&"parry"] = _synth(0.32, func(t: float, prog: float, _prev_n: float) -> float:
		var env := pow(1.0 - prog, 2.1)
		var bell := sin(TAU * 1180.0 * t) * 0.45 + sin(TAU * 1770.0 * t) * 0.32 + sin(TAU * 2640.0 * t) * 0.22
		return bell * env
	)
	_streams[&"reaction"] = _synth(0.30, func(t: float, prog: float, prev_n: float) -> float:
		var env := pow(1.0 - prog, 1.6)
		var sub := sin(TAU * lerpf(145.0, 42.0, prog) * t) * 0.60
		var shimmer := sin(TAU * 880.0 * t) * 0.20 + sin(TAU * 1320.0 * t) * 0.18
		return clampf((sub + shimmer + prev_n * 0.22) * env, -1.0, 1.0)
	)
	_streams[&"jump"] = _synth(0.09, func(t: float, prog: float, _prev_n: float) -> float:
		var env := pow(1.0 - prog, 2.0)
		return sin(TAU * lerpf(210.0, 520.0, prog) * t) * 0.45 * env
	)
	_streams[&"land"] = _synth(0.07, func(t: float, prog: float, prev_n: float) -> float:
		var env := pow(1.0 - prog, 2.4)
		return (sin(TAU * lerpf(115.0, 45.0, prog) * t) * 0.55 + prev_n * 0.25) * env
	)
	_streams[&"dash"] = _synth(0.12, func(_t: float, prog: float, prev_n: float) -> float:
		var env := pow(1.0 - prog, 1.8) * minf(1.0, prog * 12.0)
		var noise := prev_n * 0.45 + randf_range(-1.0, 1.0) * 0.55
		return noise * 0.65 * env
	)
	_streams[&"vault"] = _synth(0.11, func(t: float, prog: float, _prev_n: float) -> float:
		var env := pow(1.0 - prog, 1.9)
		return sin(TAU * lerpf(320.0, 740.0, prog) * t) * 0.42 * env
	)
	_streams[&"swap"] = _synth(0.07, func(t: float, prog: float, _prev_n: float) -> float:
		var env := pow(1.0 - prog, 2.3)
		return (sin(TAU * 880.0 * t) * 0.4 + sin(TAU * 1320.0 * t) * 0.35) * env
	)


func _synth(duration: float, sample_fn: Callable) -> AudioStreamWAV:
	var count := maxi(1, int(duration * float(SAMPLE_RATE)))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var prev_n := 0.0
	for i in range(count):
		var prog := float(i) / float(count)
		var t := float(i) / float(SAMPLE_RATE)
		var v: float = clampf(float(sample_fn.call(t, prog, prev_n)), -1.0, 1.0)
		prev_n = randf_range(-1.0, 1.0) * 0.35 + prev_n * 0.65
		bytes.encode_s16(i * 2, int(v * 26000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	return wav

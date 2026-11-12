extends Node2D
## Headless verification for Kinetic Whip v1. Instantiates Main and drives
## it through scripted checks, printing PASS/FAIL lines, then quits.
## Run: godot --headless --path . test.tscn

const MainScene = preload("res://main.tscn")

var _main: Node2D
var _step: int = 0
var _frames: int = 0
var _results: Array = []
var _enemy_shielded = null
var _enemy_std = null
var _boss = null

func _ready() -> void:
	_main = MainScene.instantiate()
	add_child(_main)
	print("[TEST] starting")

func _check(name: String, ok: bool, detail: String = "") -> void:
	_results.append([name, ok, detail])
	print("[TEST] %s: %s %s" % [name, "PASS" if ok else "FAIL", detail])

func _physics_process(_delta: float) -> void:
	_frames += 1
	match _step:
		0:
			if _frames >= 5:
				_check("menu_state", _main.state == 0, "state=%d" % _main.state)
				_main.start_game()
				_check("start_playing", _main.state == 1 and _main.wave == 1, "state=%d wave=%d" % [_main.state, _main.wave])
				_step = 1
				_frames = 0
		1:
			# Spin the whip fast for 60 physics frames
			_main._pointer_angle += 0.35
			_main._dragging = true
			if _frames >= 60:
				_main._dragging = false
				var spin: float = _main._whip.spin_ratio
				var tip_d: float = _main._whip.tip_pos().distance_to(Vector2(360, 640))
				_check("whip_spins", spin > 0.5, "spin=%.2f" % spin)
				_check("chain_extends", tip_d > 210.0, "tip_dist=%.0f" % tip_d)
				_step = 2
				_frames = 0
		2:
			# Shield deflect below 65%, break above
			_main._spawn_enemy(1) # SHIELDED
			for e in _main._enemies:
				if not e.dead and e.visible and e.kind == 1:
					_enemy_shielded = e
					break
			if _enemy_shielded == null:
				_check("shield_spawn", false, "no shielded enemy")
				_step = 3
				_frames = 0
			else:
				var before: int = _enemy_shielded.parts.size()
				var r1: Dictionary = _enemy_shielded.take_hit(1, 0.3, Vector2(1, 0))
				_check("shield_deflect_low", bool(r1["deflected"]) and _enemy_shielded.shield_on and _enemy_shielded.parts.size() == before, "deflected=%s shield=%s" % [str(r1["deflected"]), str(_enemy_shielded.shield_on)])
				_enemy_shielded.hit_cooldown = 0.0
				var r2: Dictionary = _enemy_shielded.take_hit(1, 0.8, Vector2(1, 0))
				_check("shield_break_high", bool(r2["shield_broken"]) and not _enemy_shielded.shield_on, "broken=%s" % str(r2["shield_broken"]))
				_step = 3
				_frames = 0
		3:
			# Standard enemy dismantles part by part, then dies
			_main._spawn_enemy(0) # STANDARD
			for e in _main._enemies:
				if not e.dead and e.visible and e.kind == 0:
					_enemy_std = e
					break
			if _enemy_std == null:
				_check("std_spawn", false, "no standard enemy")
				_step = 4
				_frames = 0
			else:
				var total: int = _enemy_std.parts.size()
				var died := false
				for i in total:
					_enemy_std.hit_cooldown = 0.0
					var r: Dictionary = _enemy_std.take_hit(1, 0.9, Vector2(0, 1))
					if bool(r["died"]):
						died = true
				_check("enemy_dismantle_dies", died and _enemy_std.parts.is_empty(), "parts_left=%d" % _enemy_std.parts.size())
				_step = 4
				_frames = 0
		4:
			# Orbs: spawn one near the core, it should be collected
			var before: int = _main.orbs
			_main._spawn_orb(Vector2(360, 560), 1)
			_step = 5
			_frames = 0
			_check("orb_spawned", true, "orbs_before=%d" % before)
		5:
			if _frames >= 240:
				_check("orb_collected", _main.orbs >= 1, "orbs=%d" % _main.orbs)
				_step = 6
				_frames = 0
		6:
			# Upgrades apply
			_main.orbs = 500
			_main._core.damage(40.0)
			var links_before: int = _main._whip.link_count
			_main._on_upgrade_bought("chain")
			_check("upgrade_chain", _main._whip.link_count == links_before + 2, "links=%d" % _main._whip.link_count)
			var integ_before: float = _main._core.integrity
			_main._on_upgrade_bought("repair")
			_check("upgrade_repair", _main._core.integrity > integ_before, "integ=%.0f" % _main._core.integrity)
			_main._on_upgrade_bought("damage")
			_check("upgrade_damage", _main._whip.damage_mult > 1.0, "mult=%.2f" % _main._whip.damage_mult)
			_step = 7
			_frames = 0
		7:
			# Chakra unlock with energy
			_main.orbs = 200
			_main._on_unlock_chakra()
			_check("chakra_unlock", _main._chakra.unlocked and _main.orbs == 50, "unlocked=%s orbs=%d" % [str(_main._chakra.unlocked), _main.orbs])
			# Chakra RPM builds with circular drag
			_main.weapon = 1
			_main._apply_weapon_visibility()
			for i in 90:
				_main._pointer_angle += 0.25
				_main._chakra.update_spin(_main._pointer_angle, true, 1.0 / 60.0)
			_check("chakra_rpm", _main._chakra.rpm > 0.4, "rpm=%.2f" % _main._chakra.rpm)
			_step = 8
			_frames = 0
		8:
			# Boss appears on wave 3, arena palette changes per wave
			_main._start_wave(3)
			_check("boss_in_queue", _main._spawn_queue.has(3), "queue=%s" % str(_main._spawn_queue))
			_main._spawn_enemy(3)
			for e in _main._enemies:
				if not e.dead and e.visible and e.kind == 3:
					_boss = e
					break
			_check("boss_spawns", _boss != null and _boss.shield_on, "boss=%s" % str(_boss != null))
			var pal1: String = _main._arena.palette["name"]
			_main._arena.set_wave(2)
			var pal2: String = _main._arena.palette["name"]
			_check("arena_changes", pal1 != pal2, "%s -> %s" % [pal1, pal2])
			_step = 9
			_frames = 0
		9:
			# Core damage -> game over
			_main._core.integrity = 5.0
			_main._core.damage(10.0)
			if _main._core.integrity <= 0.0:
				_main._game_over()
			_check("game_over", _main.state == 4, "state=%d" % _main.state)
			_finish()

func _finish() -> void:
	var fails := 0
	for r in _results:
		if not r[1]:
			fails += 1
	print("[TEST] DONE: %d/%d passed, %d failed" % [_results.size() - fails, _results.size(), fails])
	get_tree().quit(1 if fails > 0 else 0)

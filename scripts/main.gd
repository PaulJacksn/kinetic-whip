extends Node2D
## Kinetic Whip 2D: game controller. State machine, waves, spawning,
## collisions, orbs, upgrades, boss, weapon switching, persistence,
## web debug hook.

const ArenaScript = preload("res://scripts/arena.gd")
const CoreScript = preload("res://scripts/core.gd")
const WhipScript = preload("res://scripts/whip.gd")
const ChakraScript = preload("res://scripts/chakra.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const DebrisScript = preload("res://scripts/debris.gd")
const AudioScript = preload("res://scripts/audio.gd")
const HudScript = preload("res://scripts/hud.gd")

const CORE_POS := Vector2(360, 640)
const SAVE_PATH := "user://kinetic_whip_save.cfg"
const CHAKRA_COST := 150
const ATTUNE_TIME := 2.0
const MAX_ALIVE := 12
const SHIELD_BREAK_SPIN := 0.65

enum State { MENU, PLAYING, UPGRADE, PAUSED, GAMEOVER }
enum Weapon { BLADE, CHAKRA }

var state: int = State.MENU
var weapon: int = Weapon.BLADE
var wave: int = 1
var score: int = 0
var best_score: int = 0
var orbs: int = 0
var kills: int = 0

var chain_level: int = 0
var spin_level: int = 0
var damage_level: int = 0

var _rng := RandomNumberGenerator.new()
var _dragging: bool = false
var _pointer_angle: float = -PI * 0.5
var _time: float = 0.0
var _shake: float = 0.0
var _spawn_queue: Array = []
var _spawn_timer: float = 0.0
var _wave_active: bool = false
var _attuning: bool = false
var _attune_progress: float = 0.0
var _attune_idle: float = 0.0
var _orb_combo: int = 0
var _orb_combo_timer: float = 0.0
var _last_hud_orbs: int = -1
var _last_hud_score: int = -1
var _debug_timer: float = 0.0
var _menu_spin: float = 0.0

var _arena: Node2D
var _core: Node2D
var _whip: Node2D
var _chakra: Node2D
var _audio: Node
var _hud: CanvasLayer
var _world: Node2D
var _enemies: Array = []
var _projectiles: Array = []
var _debris: Array = []

func _ready() -> void:
	_rng.randomize()
	_load_best()
	_world = Node2D.new()
	add_child(_world)
	_arena = ArenaScript.new()
	_world.add_child(_arena)
	_core = CoreScript.new()
	_core.position = CORE_POS
	_world.add_child(_core)
	_whip = WhipScript.new()
	_whip.core_pos = CORE_POS
	_world.add_child(_whip)
	_chakra = ChakraScript.new()
	_chakra.core_pos = CORE_POS
	_world.add_child(_chakra)
	for i in 24:
		var e = EnemyScript.new()
		e.visible = false
		_world.add_child(e)
		_enemies.append(e)
	for i in 16:
		var p = ProjectileScript.new()
		p.visible = false
		_world.add_child(p)
		_projectiles.append(p)
	for i in 48:
		var d = DebrisScript.new()
		d.visible = false
		_world.add_child(d)
		_debris.append(d)
	_audio = AudioScript.new()
	add_child(_audio)
	_hud = HudScript.new()
	add_child(_hud)
	_hud.start_game.connect(start_game)
	_hud.next_wave.connect(_on_next_wave)
	_hud.upgrade_bought.connect(_on_upgrade_bought)
	_hud.unlock_chakra.connect(_on_unlock_chakra)
	_hud.switch_weapon.connect(_on_switch_pressed)
	_hud.pause_game.connect(_on_pause_pressed)
	_hud.resume_game.connect(_on_resume_pressed)
	_hud.restart_game.connect(start_game)
	_hud.set_best(best_score)
	_hud.show_menu()
	_apply_weapon_visibility()

func weapon_condition() -> float:
	return _core.condition()

# ---------------------------------------------------------------- state flow

func start_game() -> void:
	score = 0
	orbs = 0
	kills = 0
	wave = 1
	chain_level = 0
	spin_level = 0
	damage_level = 0
	weapon = Weapon.BLADE
	_attuning = false
	_attune_progress = 0.0
	_core.reset()
	_core.position = CORE_POS
	_chakra.unlocked = false
	_chakra.rpm = 0.0
	_whip.set_link_count(WhipScript.BASE_LINKS)
	_whip.damage_mult = 1.0
	_whip.max_ang_vel = 9.0
	_chakra.max_ang_vel = 9.0
	for e in _enemies:
		e.dead = true
		e.visible = false
	for p in _projectiles:
		p.deactivate()
	for d in _debris:
		d.deactivate()
	_arena.set_wave(1)
	_apply_weapon_visibility()
	_audio.duck_music(false)
	_audio.start_music()
	state = State.PLAYING
	_hud.show_hud()
	_hud.set_wave(1)
	_hud.set_orbs(0)
	_hud.set_score(0)
	_hud.set_integrity(_core.integrity, _core.max_integrity)
	_hud.set_weapon("CHAINED BLADE", false)
	_hud.set_rpm(0.0, false)
	_start_wave(1)

func _game_over() -> void:
	state = State.GAMEOVER
	_attuning = false
	_audio.duck_music(true)
	_shake = 1.2
	if score > best_score:
		best_score = score
		_save_best()
	_hud.set_best(best_score)
	_hud.show_gameover(score, best_score, wave)

func _on_pause_pressed() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		_hud.show_pause()
		_audio.duck_music(true)

func _on_resume_pressed() -> void:
	if state == State.PAUSED:
		state = State.PLAYING
		_hud.hide_pause()
		_audio.duck_music(false)

# ---------------------------------------------------------------- waves

func _start_wave(w: int) -> void:
	wave = w
	_arena.set_wave(w)
	_hud.set_wave(w)
	_spawn_queue.clear()
	var count := 4 + w * 2
	var boss_wave := w % 3 == 0
	if boss_wave:
		_spawn_queue.append(EnemyScript.Kind.BOSS)
		count = 4 + w
	for i in count:
		var roll := _rng.randf()
		if w >= 3 and roll < 0.20:
			_spawn_queue.append(EnemyScript.Kind.RANGED)
		elif w >= 2 and roll < 0.45:
			_spawn_queue.append(EnemyScript.Kind.SHIELDED)
		else:
			_spawn_queue.append(EnemyScript.Kind.STANDARD)
	_spawn_timer = 1.0
	_wave_active = true
	if boss_wave:
		_audio.play_alarm()
		_hud.show_popup("BOSS INCOMING")

func _on_next_wave() -> void:
	state = State.PLAYING
	_hud.show_hud()
	_start_wave(wave + 1)

func _wave_clear() -> void:
	_wave_active = false
	var bonus := 100 * wave
	score += bonus
	_audio.play_wave_clear()
	_hud.show_popup("WAVE %d CLEAR  +%d" % [wave, bonus])
	state = State.UPGRADE
	_hud.show_upgrade(_upgrade_rows(), _chakra.unlocked, CHAKRA_COST, orbs)

func _upgrade_rows() -> Array:
	return [
		{"id": "chain", "name": "Longer Chain", "level": chain_level, "cost": 40 * (chain_level + 1)},
		{"id": "spin", "name": "Faster Spin", "level": spin_level, "cost": 40 * (spin_level + 1)},
		{"id": "damage", "name": "More Damage", "level": damage_level, "cost": 50 * (damage_level + 1)},
		{"id": "repair", "name": "Core Repair +25", "level": 0, "cost": 30},
	]

func _on_upgrade_bought(id: String) -> void:
	var rows := _upgrade_rows()
	var cost := 0
	for r in rows:
		if r["id"] == id:
			cost = int(r["cost"])
	if orbs < cost:
		return
	orbs -= cost
	match id:
		"chain":
			chain_level += 1
			_whip.set_link_count(WhipScript.BASE_LINKS + chain_level * 2)
		"spin":
			spin_level += 1
			var m := 9.0 * (1.0 + 0.12 * spin_level)
			_whip.max_ang_vel = m
			_chakra.max_ang_vel = m
		"damage":
			damage_level += 1
			_whip.damage_mult = 1.0 + 0.25 * damage_level
		"repair":
			_core.repair(25.0)
	_audio.play_upgrade()
	_hud.set_orbs(orbs)
	_hud.set_integrity(_core.integrity, _core.max_integrity)
	_hud.show_upgrade(_upgrade_rows(), _chakra.unlocked, CHAKRA_COST, orbs)

func _on_unlock_chakra() -> void:
	if _chakra.unlocked or orbs < CHAKRA_COST:
		return
	orbs -= CHAKRA_COST
	_chakra.unlocked = true
	_audio.play_unlock()
	_hud.show_popup("CHAKRA UNLOCKED")
	_hud.set_orbs(orbs)
	_hud.set_weapon("CHAINED BLADE", true)
	_hud.show_upgrade(_upgrade_rows(), _chakra.unlocked, CHAKRA_COST, orbs)

# ---------------------------------------------------------------- weapon switching (attune challenge)

func _on_switch_pressed() -> void:
	if state != State.PLAYING:
		return
	if weapon == Weapon.BLADE and not _chakra.unlocked:
		return
	if _attuning:
		return
	_attuning = true
	_attune_progress = 0.0
	_attune_idle = 0.0
	_hud.set_attune(0.0, true)
	_hud.show_popup("ATTUNE: KEEP SPINNING")

func _update_attune(delta: float) -> void:
	if not _attuning:
		return
	var cond_ok := false
	if weapon == Weapon.BLADE:
		cond_ok = _whip.spin_ratio > 0.4
	else:
		cond_ok = _chakra.rpm > 0.4
	if cond_ok:
		_attune_progress += delta
		_attune_idle = 0.0
	else:
		_attune_progress -= delta * 1.5
		_attune_idle += delta
	_hud.set_attune(clampf(_attune_progress / ATTUNE_TIME, 0.0, 1.0), true)
	if _attune_progress >= ATTUNE_TIME:
		_attuning = false
		_hud.set_attune(0.0, false)
		_switch_weapon_now()
	elif _attune_progress <= 0.0 and _attune_idle > 1.0:
		_attuning = false
		_hud.set_attune(0.0, false)
		_hud.show_popup("ATTUNE FAILED")
		_audio.play_deflect()

func _switch_weapon_now() -> void:
	if weapon == Weapon.BLADE:
		weapon = Weapon.CHAKRA
		_hud.set_weapon("CHAKRA", true)
		_hud.set_rpm(_chakra.rpm_percent(), true)
		_hud.show_popup("CHAKRA")
	else:
		weapon = Weapon.BLADE
		_hud.set_weapon("CHAINED BLADE", _chakra.unlocked)
		_hud.set_rpm(0.0, false)
		_hud.show_popup("CHAINED BLADE")
	_apply_weapon_visibility()
	_audio.play_upgrade()

func _apply_weapon_visibility() -> void:
	_whip.visible_weapon = weapon == Weapon.BLADE
	_chakra.visible_weapon = weapon == Weapon.CHAKRA

# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if state == State.PLAYING:
				_dragging = true
				_pointer_angle = (touch.position - CORE_POS).angle()
		else:
			_dragging = false
	elif event is InputEventScreenDrag:
		if state == State.PLAYING and _dragging:
			var drag := event as InputEventScreenDrag
			_pointer_angle = (drag.position - CORE_POS).angle()
	elif event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			match key.keycode:
				KEY_SPACE, KEY_ENTER:
					if state == State.MENU:
						start_game()
					elif state == State.GAMEOVER:
						start_game()
				KEY_P, KEY_ESCAPE:
					if state == State.PLAYING:
						_on_pause_pressed()
					elif state == State.PAUSED:
						_on_resume_pressed()
				KEY_TAB:
					if state == State.PLAYING:
						_on_switch_pressed()

# ---------------------------------------------------------------- per-frame

func _process(delta: float) -> void:
	_time += delta
	if state == State.MENU:
		_menu_spin += delta * 0.5
		_pointer_angle = _menu_spin
	# HUD refresh (cheap, only on change)
	if orbs != _last_hud_orbs:
		_last_hud_orbs = orbs
		_hud.set_orbs(orbs)
	if score != _last_hud_score:
		_last_hud_score = score
		_hud.set_score(score)
	_hud.set_spin(_whip.spin_percent())
	if weapon == Weapon.CHAKRA:
		_hud.set_rpm(_chakra.rpm_percent(), true)
	_debug_timer += delta
	if _debug_timer >= 0.25:
		_debug_timer = 0.0
		_update_debug_hook()
	# Camera shake
	_shake = maxf(0.0, _shake - delta * 2.0)
	_world.position = Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * _shake * 6.0

func _physics_process(delta: float) -> void:
	if state == State.MENU:
		# Idle menu: the whip slowly orbits for vibe.
		_whip.sim_active = true
		_whip.update_spin(_pointer_angle, true, delta)
		return
	if state != State.PLAYING:
		_whip.sim_active = false
		return
	_whip.sim_active = true
	_whip.update_spin(_pointer_angle, _dragging, delta)
	_chakra.update_spin(_pointer_angle, _dragging, delta)
	_update_attune(delta)
	_update_spawning(delta)
	_update_enemies(delta)
	_update_projectiles(delta)
	_update_debris(delta)
	_update_weapon_hits(delta)
	if _core.integrity <= 0.0:
		_game_over()

func _update_spawning(delta: float) -> void:
	if not _wave_active:
		return
	var alive := 0
	for e in _enemies:
		if not e.dead and e.visible:
			alive += 1
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and not _spawn_queue.is_empty() and alive < MAX_ALIVE:
		_spawn_enemy(int(_spawn_queue.pop_front()))
		_spawn_timer = lerpf(1.1, 0.55, clampf(float(wave) / 10.0, 0.0, 1.0)) * _rng.randf_range(0.85, 1.15)
	if _spawn_queue.is_empty() and alive == 0:
		_wave_clear()

func _spawn_enemy(kind: int) -> void:
	for e in _enemies:
		if e.dead or not e.visible:
			var ang := _rng.randf_range(0.0, TAU)
			var pos := CORE_POS + Vector2(cos(ang), sin(ang)) * _rng.randf_range(620.0, 680.0)
			e.setup(kind, pos, CORE_POS, _rng)
			e.visible = true
			return

func _update_enemies(delta: float) -> void:
	for e in _enemies:
		if e.dead or not e.visible:
			continue
		e.update(delta)
		if e.want_shoot:
			e.want_shoot = false
			_fire_projectile(e.position)
		if e.want_minions:
			e.want_minions = false
			_spawn_enemy(EnemyScript.Kind.STANDARD)
			_spawn_enemy(EnemyScript.Kind.STANDARD)
		# Reached the core: kamikaze
		if e.position.distance_to(CORE_POS) < CoreScript.RADIUS + e.radius * 0.6:
			_core.damage(e.damage_to_core)
			_audio.play_core_hit()
			_hud.flash()
			_hud.set_integrity(_core.integrity, _core.max_integrity)
			_shake = maxf(_shake, 0.7)
			_shatter_enemy(e, Vector2.ZERO, 0)
			if _core.integrity <= 0.0:
				return

func _fire_projectile(from: Vector2) -> void:
	for p in _projectiles:
		if not p.active:
			p.fire(from, CORE_POS, 220.0)
			return

func _update_projectiles(delta: float) -> void:
	for p in _projectiles:
		if not p.active:
			continue
		p.update(delta)
		if not p.active:
			continue
		if p.position.distance_to(CORE_POS) < CoreScript.RADIUS + 8.0:
			_core.damage(p.damage)
			_audio.play_core_hit()
			_hud.flash()
			_hud.set_integrity(_core.integrity, _core.max_integrity)
			_shake = maxf(_shake, 0.5)
			p.deactivate()
			if _core.integrity <= 0.0:
				_game_over()
				return
			continue
		# Whip or chakra destroys the bolt
		if weapon == Weapon.BLADE:
			for s in _whip.hit_samples():
				if p.position.distance_to(s["pos"]) < 14.0:
					p.deactivate()
					_audio.play_hit(0.5)
					break
		elif weapon == Weapon.CHAKRA and _chakra.rpm > 0.25:
			if p.position.distance_to(_chakra.disc_pos()) < ChakraScript.DISC_RADIUS + 10.0:
				p.deactivate()
				_audio.play_hit(_chakra.rpm)

func _update_debris(delta: float) -> void:
	_orb_combo_timer = maxf(0.0, _orb_combo_timer - delta)
	if _orb_combo_timer <= 0.0:
		_orb_combo = 0
	for d in _debris:
		if not d.active:
			continue
		if d.update(delta) == "collected":
			orbs += d.value
			score += 5 * d.value
			_orb_combo += 1
			_orb_combo_timer = 1.5
			_audio.play_orb(_orb_combo)

func _update_weapon_hits(_delta: float) -> void:
	if weapon == Weapon.BLADE:
		for s in _whip.hit_samples():
			var speed: float = s["speed"]
			var tip: bool = s["tip"]
			var spin: float = _whip.spin_ratio
			for e in _enemies:
				if e.dead or not e.visible:
					continue
				if e.hit_cooldown > 0.0:
					continue
				if e.position.distance_to(s["pos"]) < e.radius + 12.0:
					var dir: Vector2 = s["dir"]
					var dmg := 1
					if tip and spin >= 0.9:
						dmg = 2
					_apply_hit(e, dmg, spin, dir, speed)
	elif weapon == Weapon.CHAKRA:
		if _chakra.rpm <= 0.25:
			return
		var dp: Vector2 = _chakra.disc_pos()
		var tangent := Vector2(-(dp - CORE_POS).y, (dp - CORE_POS).x).normalized()
		for e in _enemies:
			if e.dead or not e.visible:
				continue
			if e.hit_cooldown > 0.0:
				continue
			if e.position.distance_to(dp) < e.radius + ChakraScript.DISC_RADIUS:
				var dmg := 1
				if _chakra.rpm >= 0.8:
					dmg = 2
				_apply_hit(e, dmg, _chakra.rpm, tangent, _chakra.rpm * 500.0)

func _apply_hit(e, dmg_parts: int, spin_ratio: float, hit_dir: Vector2, hit_speed: float) -> void:
	var res: Dictionary = e.take_hit(dmg_parts, spin_ratio, hit_dir)
	if bool(res["deflected"]):
		_audio.play_deflect()
		_hud.show_popup("SHIELD DEFLECTS — SPIN ABOVE 65%")
		return
	if bool(res["shield_broken"]):
		_audio.play_shield_break()
		_hud.show_popup("SHIELD SHATTERED")
		_shake = maxf(_shake, 0.4)
	for part in res["lost"]:
		_spawn_debris(part, e.position, hit_dir, hit_speed)
	_audio.play_hit(spin_ratio)
	if bool(res["died"]):
		_kill_enemy(e, hit_dir)

func _kill_enemy(e, _hit_dir: Vector2) -> void:
	kills += 1
	score += 10 * (1 + wave / 3)
	_audio.play_shatter()
	_shake = maxf(_shake, 0.35)
	var orb_count := 3
	if e.kind == EnemyScript.Kind.BOSS:
		orb_count = 14
		score += 200
		_hud.show_popup("BOSS DOWN  +200")
		_shake = maxf(_shake, 1.0)
	for i in orb_count:
		_spawn_orb(e.position + Vector2(_rng.randf_range(-30.0, 30.0), _rng.randf_range(-30.0, 30.0)), 3 if e.kind == EnemyScript.Kind.BOSS else 1)
	e.visible = false

func _shatter_enemy(e, hit_dir: Vector2, _speed: float) -> void:
	# Kamikaze: all remaining parts scatter, no orbs.
	for part in e.parts:
		_spawn_debris(part, e.position, hit_dir if hit_dir != Vector2.ZERO else Vector2(0, -1), 200.0)
	e.parts.clear()
	e.dead = true
	e.visible = false
	_audio.play_shatter()

func _spawn_debris(part: Dictionary, enemy_pos: Vector2, hit_dir: Vector2, hit_speed: float) -> void:
	for d in _debris:
		if not d.active:
			var poly: PackedVector2Array = part["poly"]
			var off: Vector2 = part["off"]
			var moved := PackedVector2Array()
			for p in poly:
				moved.append(p + off)
			var power := 240.0 + minf(hit_speed * 0.25, 320.0)
			d.launch(moved, part["col"], enemy_pos + off, hit_dir, power, 1)
			return

func _spawn_orb(pos: Vector2, value: int) -> void:
	for d in _debris:
		if not d.active:
			d.poly = PackedVector2Array()
			d.col = Color(1.0, 0.85, 0.3)
			d.position = pos
			d.vel = Vector2(_rng.randf_range(-60.0, 60.0), _rng.randf_range(-60.0, 60.0))
			d.ang_vel = 0.0
			d.value = value
			d.phase = DebrisScript.Phase.ORB
			d.active = true
			d.visible = true
			return

# ---------------------------------------------------------------- persistence + debug

func _load_best() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_score = int(cfg.get_value("scores", "best", 0))

func _save_best() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "best", best_score)
	cfg.save(SAVE_PATH)

func _state_name() -> String:
	match state:
		State.MENU:
			return "menu"
		State.PLAYING:
			return "playing"
		State.UPGRADE:
			return "upgrade"
		State.PAUSED:
			return "paused"
		State.GAMEOVER:
			return "gameover"
	return "unknown"

func _update_debug_hook() -> void:
	if OS.has_feature("web"):
		var alive := 0
		for e in _enemies:
			if not e.dead and e.visible:
				alive += 1
		var s := "window.__KW=window.__KW||{};window.__KW.state='%s';window.__KW.wave=%d;window.__KW.integrity=%d;window.__KW.orbs=%d;window.__KW.score=%d;window.__KW.best=%d;window.__KW.fps=%d;window.__KW.spin=%.1f;window.__KW.rpm=%.1f;window.__KW.weapon=%d;window.__KW.enemies=%d;window.__KW.chakra=%d;window.__KW.music=%d;" % [_state_name(), wave, int(_core.integrity), orbs, score, best_score, Engine.get_frames_per_second(), _whip.spin_ratio * 100.0, _chakra.rpm * 100.0, weapon, alive, 1 if _chakra.unlocked else 0, 1 if _audio.music_ready else 0]
		JavaScriptBridge.eval(s)

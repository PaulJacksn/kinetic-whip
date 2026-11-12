extends Node2D
## Kinetic Whip arena: bird's-eye backdrop. Palette and layout shift every
## wave: background hue, grid tint, nebula blobs, pylon positions, ring radii.

const PALETTES: Array[Dictionary] = [
	{"name": "Deep Indigo", "bg": Color(0.015, 0.01, 0.05), "grid": Color(0.25, 0.35, 0.9, 0.16), "accent": Color(0.2, 0.9, 1.0), "neb1": Color(0.25, 0.1, 0.6, 0.35), "neb2": Color(0.05, 0.4, 0.6, 0.3), "ring": Color(0.3, 0.6, 1.0, 0.25)},
	{"name": "Teal Bloom", "bg": Color(0.01, 0.05, 0.05), "grid": Color(0.2, 0.9, 0.7, 0.15), "accent": Color(0.3, 1.0, 0.75), "neb1": Color(0.05, 0.5, 0.45, 0.32), "neb2": Color(0.1, 0.3, 0.6, 0.3), "ring": Color(0.3, 1.0, 0.8, 0.22)},
	{"name": "Magenta Dusk", "bg": Color(0.05, 0.01, 0.06), "grid": Color(0.9, 0.3, 0.7, 0.15), "accent": Color(1.0, 0.45, 0.85), "neb1": Color(0.6, 0.1, 0.5, 0.32), "neb2": Color(0.3, 0.1, 0.6, 0.3), "ring": Color(1.0, 0.5, 0.9, 0.22)},
	{"name": "Ember Night", "bg": Color(0.06, 0.02, 0.01), "grid": Color(1.0, 0.55, 0.25, 0.14), "accent": Color(1.0, 0.7, 0.3), "neb1": Color(0.6, 0.2, 0.05, 0.32), "neb2": Color(0.5, 0.1, 0.3, 0.3), "ring": Color(1.0, 0.65, 0.3, 0.22)},
	{"name": "Violet Storm", "bg": Color(0.04, 0.01, 0.09), "grid": Color(0.65, 0.4, 1.0, 0.16), "accent": Color(0.75, 0.55, 1.0), "neb1": Color(0.45, 0.15, 0.8, 0.32), "neb2": Color(0.15, 0.3, 0.8, 0.3), "ring": Color(0.7, 0.5, 1.0, 0.22)},
	{"name": "Aurora Green", "bg": Color(0.01, 0.05, 0.02), "grid": Color(0.45, 1.0, 0.5, 0.14), "accent": Color(0.6, 1.0, 0.55), "neb1": Color(0.1, 0.55, 0.25, 0.32), "neb2": Color(0.05, 0.4, 0.5, 0.3), "ring": Color(0.5, 1.0, 0.6, 0.22)},
]

var wave: int = 1
var palette: Dictionary = PALETTES[0]
var _stars: Array[Vector3] = []
var _pylons: Array[Vector2] = []
var _ring_radii: Array[float] = [210.0, 330.0, 460.0]
var _rot: float = 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	for i in 130:
		_stars.append(Vector3(_rng.randf_range(0.0, 720.0), _rng.randf_range(0.0, 1280.0), _rng.randf_range(0.4, 1.6)))
	_layout_wave(1)

func set_wave(w: int) -> void:
	wave = w
	palette = PALETTES[(w - 1) % PALETTES.size()]
	_layout_wave(w)
	queue_redraw()

func _layout_wave(w: int) -> void:
	_pylons.clear()
	var base := _rng.randf_range(0.0, TAU)
	for i in 4:
		var ang := base + float(i) * PI * 0.5 + _rng.randf_range(-0.25, 0.25)
		var r := 430.0 + _rng.randf_range(-40.0, 60.0)
		_pylons.append(Vector2(360.0, 640.0) + Vector2(cos(ang), sin(ang)) * r)
	_ring_radii = [200.0 + float((w * 17) % 60), 320.0 + float((w * 23) % 70), 450.0 + float((w * 11) % 50)]

func _process(delta: float) -> void:
	_rot += delta * 0.02
	queue_redraw()

func _draw() -> void:
	var c := Vector2(360.0, 640.0)
	# Background
	draw_rect(Rect2(0, 0, 720, 1280), palette["bg"])
	# Nebula blobs (soft layered circles)
	for i in 7:
		var a := _rot * 0.3 + float(i) * 0.9
		var pos := c + Vector2(cos(a), sin(a * 1.3)) * Vector2(240.0, 420.0) * (0.5 + 0.12 * float(i % 3))
		var col: Color = palette["neb1"] if i % 2 == 0 else palette["neb2"]
		_draw_soft_circle(pos, 150.0 + float(i % 3) * 50.0, col)
	# Grid
	var grid_col: Color = palette["grid"]
	for x in range(0, 721, 60):
		draw_line(Vector2(x, 0), Vector2(x, 1280), grid_col, 1.0)
	for y in range(0, 1281, 60):
		draw_line(Vector2(0, y), Vector2(720, y), grid_col, 1.0)
	# Concentric rings around the core
	for r in _ring_radii:
		draw_arc(c, r, 0.0, TAU, 96, palette["ring"], 1.5)
	# Rotating dashed ring
	var dash_col: Color = palette["accent"]
	dash_col.a = 0.35
	for i in 24:
		var a0 := _rot + float(i) * TAU / 24.0
		var a1 := a0 + 0.12
		draw_arc(c, 270.0, a0, a1, 4, dash_col, 3.0)
	# Pylons (decorative glowing pillars)
	for p in _pylons:
		_draw_soft_circle(p, 26.0, Color(palette["accent"], 0.25))
		draw_circle(p, 8.0, Color(palette["accent"], 0.8))
		draw_arc(p, 14.0, 0.0, TAU, 24, Color(palette["accent"], 0.5), 1.5)
	# Stars
	for s in _stars:
		var tw := 0.6 + 0.4 * sin(_rot * 4.0 + s.x * 0.05)
		draw_circle(Vector2(s.x, s.y), s.z * tw, Color(1, 1, 1, 0.55 * tw))

func _draw_soft_circle(pos: Vector2, radius: float, col: Color) -> void:
	for i in range(4, 0, -1):
		var c2 := col
		c2.a = col.a * (0.25 + 0.2 * float(i))
		draw_circle(pos, radius * float(i) / 4.0, c2)

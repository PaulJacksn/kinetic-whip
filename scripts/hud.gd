extends CanvasLayer
## Kinetic Whip HUD: all UI built in code. Menu, HUD, upgrade shop,
## game over, pause. Emits signals; Main owns the game state.

signal start_game
signal next_wave
signal upgrade_bought(id: String)
signal unlock_chakra
signal switch_weapon
signal pause_game
signal resume_game
signal restart_game

var _integrity_bar: ProgressBar
var _integrity_label: Label
var _wave_label: Label
var _orb_label: Label
var _score_label: Label
var _spin_bar: ProgressBar
var _spin_label: Label
var _rpm_bar: ProgressBar
var _rpm_label: Label
var _weapon_label: Label
var _switch_button: Button
var _attune_bar: ProgressBar
var _attune_label: Label
var _menu_panel: PanelContainer
var _menu_wrap: CenterContainer
var _upgrade_panel: PanelContainer
var _upgrade_wrap: CenterContainer
var _upgrade_list: VBoxContainer
var _gameover_panel: PanelContainer
var _gameover_wrap: CenterContainer
var _pause_panel: PanelContainer
var _pause_wrap: CenterContainer
var _hud_root: Control
var _best_label: Label
var _go_score_label: Label
var _go_wave_label: Label
var _flash_rect: ColorRect
var _popup_label: Label
var _popup_timer: float = 0.0
var _panel_tex: Texture2D = null

func _load_ui_assets() -> void:
	if ResourceLoader.exists("res://assets/fonts/KenneyFuture.ttf"):
		var font := load("res://assets/fonts/KenneyFuture.ttf")
		if font is Font:
			ThemeDB.fallback_font = font
	if ResourceLoader.exists("res://assets/art/ui/panel.png"):
		_panel_tex = load("res://assets/art/ui/panel.png")

func _ready() -> void:
	_load_ui_assets()
	_build_hud()
	_build_menu()
	_build_upgrade()
	_build_gameover()
	_build_pause()
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 0.15, 0.1, 0.0)
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_rect)
	show_menu()

# ---------------------------------------------------------------- styling

func _panel_style() -> StyleBox:
	if _panel_tex != null:
		var st := StyleBoxTexture.new()
		st.texture = _panel_tex
		st.texture_margin_left = 24.0
		st.texture_margin_right = 24.0
		st.texture_margin_top = 24.0
		st.texture_margin_bottom = 24.0
		st.content_margin_left = 24.0
		st.content_margin_right = 24.0
		st.content_margin_top = 20.0
		st.content_margin_bottom = 20.0
		return st
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.06, 0.12, 0.92)
	s.border_color = Color(0.3, 0.8, 1.0, 0.6)
	s.set_border_width_all(2)
	s.set_corner_radius_all(14)
	s.content_margin_left = 24.0
	s.content_margin_right = 24.0
	s.content_margin_top = 20.0
	s.content_margin_bottom = 20.0
	return s

func _button_style() -> StyleBox:
	# The Kenney header texture is a bad fit for text buttons: its blue
	# header band ends mid-button, so white text straddles the blue/grey
	# seam and turns unreadable. Flat blue buttons stay readable.
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.1, 0.35, 0.55, 1.0)
	s.set_corner_radius_all(10)
	s.content_margin_left = 18.0
	s.content_margin_right = 18.0
	s.content_margin_top = 10.0
	s.content_margin_bottom = 10.0
	return s

func _label(text: String, size: int, col: Color = Color(0.92, 0.96, 1.0)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _bar(fill: Color, bg: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0.0
	b.max_value = 100.0
	b.value = 100.0
	b.show_percentage = false
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = bg
	bg_style.set_corner_radius_all(6)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill
	fill_style.set_corner_radius_all(6)
	b.add_theme_stylebox_override("background", bg_style)
	b.add_theme_stylebox_override("fill", fill_style)
	return b

# ---------------------------------------------------------------- HUD (in-game)

func _build_hud() -> void:
	_hud_root = Control.new()
	_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud_root)

	_wave_label = _label("WAVE 1", 30, Color(0.7, 0.95, 1.0))
	_wave_label.position = Vector2(20, 18)
	_hud_root.add_child(_wave_label)

	_orb_label = _label("◆ 0", 30, Color(1.0, 0.85, 0.3))
	_orb_label.position = Vector2(20, 58)
	_hud_root.add_child(_orb_label)

	_score_label = _label("0", 30)
	_score_label.position = Vector2(560, 18)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_score_label.size = Vector2(140, 40)
	_hud_root.add_child(_score_label)

	# Integrity bar, top center
	_integrity_bar = _bar(Color(0.3, 0.9, 1.0), Color(0.1, 0.12, 0.2, 0.9))
	_integrity_bar.position = Vector2(210, 22)
	_integrity_bar.size = Vector2(300, 20)
	_hud_root.add_child(_integrity_bar)
	_integrity_label = _label("CORE 100", 22, Color(0.7, 0.95, 1.0))
	_integrity_label.position = Vector2(210, 46)
	_integrity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_integrity_label.size = Vector2(300, 28)
	_hud_root.add_child(_integrity_label)

	# Pause button
	var pause_btn := Button.new()
	pause_btn.text = "II"
	pause_btn.position = Vector2(660, 100)
	pause_btn.size = Vector2(44, 44)
	pause_btn.add_theme_stylebox_override("normal", _button_style())
	pause_btn.pressed.connect(func() -> void: pause_game.emit())
	_hud_root.add_child(pause_btn)

	# Spin meter (bottom left)
	_spin_label = _label("SPIN 0%", 24, Color(0.6, 0.9, 1.0))
	_spin_label.position = Vector2(20, 1120)
	_hud_root.add_child(_spin_label)
	_spin_bar = _bar(Color(0.2, 0.85, 1.0), Color(0.1, 0.12, 0.2, 0.9))
	_spin_bar.position = Vector2(20, 1152)
	_spin_bar.size = Vector2(300, 16)
	_hud_root.add_child(_spin_bar)

	# RPM meter (bottom left, above spin)
	_rpm_label = _label("RPM 0%", 24, Color(1.0, 0.7, 0.3))
	_rpm_label.position = Vector2(20, 1064)
	_rpm_label.visible = false
	_hud_root.add_child(_rpm_label)
	_rpm_bar = _bar(Color(1.0, 0.6, 0.2), Color(0.1, 0.12, 0.2, 0.9))
	_rpm_bar.position = Vector2(20, 1096)
	_rpm_bar.size = Vector2(300, 16)
	_rpm_bar.visible = false
	_hud_root.add_child(_rpm_bar)

	# Weapon + switch (bottom right)
	_weapon_label = _label("CHAINED BLADE", 26, Color(0.9, 0.95, 1.0))
	_weapon_label.position = Vector2(400, 1120)
	_weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_weapon_label.size = Vector2(300, 32)
	_hud_root.add_child(_weapon_label)
	_switch_button = Button.new()
	_switch_button.text = "SWITCH WEAPON"
	_switch_button.position = Vector2(420, 1156)
	_switch_button.size = Vector2(280, 52)
	_switch_button.add_theme_stylebox_override("normal", _button_style())
	_switch_button.pressed.connect(func() -> void: switch_weapon.emit())
	_hud_root.add_child(_switch_button)

	# Attune progress (center)
	_attune_label = _label("ATTUNING... KEEP SPINNING", 26, Color(1.0, 0.9, 0.4))
	_attune_label.position = Vector2(110, 560)
	_attune_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_attune_label.size = Vector2(500, 34)
	_attune_label.visible = false
	_hud_root.add_child(_attune_label)
	_attune_bar = _bar(Color(1.0, 0.85, 0.3), Color(0.1, 0.12, 0.2, 0.9))
	_attune_bar.position = Vector2(210, 600)
	_attune_bar.size = Vector2(300, 16)
	_attune_bar.visible = false
	_hud_root.add_child(_attune_bar)

	# Popup label (center)
	_popup_label = _label("", 34, Color(1.0, 0.9, 0.4))
	_popup_label.position = Vector2(110, 480)
	_popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_label.size = Vector2(500, 44)
	_popup_label.modulate.a = 0.0
	_hud_root.add_child(_popup_label)

## Panels are wrapped in a full-rect CenterContainer: set_anchors_preset
## (PRESET_CENTER) at build time mis-centers because the panel has no
## size yet (its top-left lands on the center and it grows down-right).
func _center_wrap(panel: PanelContainer) -> CenterContainer:
	var wrap := CenterContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(panel)
	add_child(wrap)
	return wrap

func _build_menu() -> void:
	_menu_panel = PanelContainer.new()
	_menu_panel.custom_minimum_size = Vector2(600, 0)
	_menu_wrap = _center_wrap(_menu_panel)
	_menu_panel.add_theme_stylebox_override("panel", _panel_style())
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	_menu_panel.add_child(vb)
	var title := _label("KINETIC WHIP", 64, Color(0.5, 0.95, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := _label("Defend the neural core.\nWhip the robots apart.", 28)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	_best_label = _label("", 26, Color(1.0, 0.85, 0.3))
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_best_label)
	var start_btn := Button.new()
	start_btn.text = "TAP TO START"
	start_btn.custom_minimum_size = Vector2(0, 64)
	start_btn.add_theme_font_size_override("font_size", 30)
	start_btn.add_theme_stylebox_override("normal", _button_style())
	start_btn.pressed.connect(func() -> void: start_game.emit())
	vb.add_child(start_btn)
	var hint := _label("Drag in circles around the core to spin the whip.\nBlue shields break only above 65% spin.\nCollect the orbs. Spend them between waves.", 22, Color(0.65, 0.75, 0.9))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hint)
	var credits := _label("\"Energy Ball\" by yiannisd (CC-BY 3.0)  •  Icons by Lorc & Delapouite, game-icons.net (CC-BY 3.0)", 16, Color(0.5, 0.6, 0.75))
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(credits)

func _build_upgrade() -> void:
	_upgrade_panel = PanelContainer.new()
	_upgrade_panel.custom_minimum_size = Vector2(620, 0)
	_upgrade_wrap = _center_wrap(_upgrade_panel)
	_upgrade_panel.add_theme_stylebox_override("panel", _panel_style())
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_upgrade_panel.add_child(vb)
	var title := _label("WAVE CLEAR — SPEND ORBS", 32, Color(1.0, 0.9, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	_upgrade_list = VBoxContainer.new()
	_upgrade_list.add_theme_constant_override("separation", 8)
	vb.add_child(_upgrade_list)
	var next_btn := Button.new()
	next_btn.text = "NEXT WAVE"
	next_btn.custom_minimum_size = Vector2(0, 60)
	next_btn.add_theme_font_size_override("font_size", 28)
	next_btn.add_theme_stylebox_override("normal", _button_style())
	next_btn.pressed.connect(func() -> void: next_wave.emit())
	vb.add_child(next_btn)

func _build_gameover() -> void:
	_gameover_panel = PanelContainer.new()
	_gameover_panel.custom_minimum_size = Vector2(560, 0)
	_gameover_wrap = _center_wrap(_gameover_panel)
	_gameover_panel.add_theme_stylebox_override("panel", _panel_style())
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	_gameover_panel.add_child(vb)
	var title := _label("CORE BREACHED", 48, Color(1.0, 0.35, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	_go_score_label = _label("", 30)
	_go_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_go_score_label)
	_go_wave_label = _label("", 26, Color(0.7, 0.85, 1.0))
	_go_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_go_wave_label)
	var again_btn := Button.new()
	again_btn.text = "PLAY AGAIN"
	again_btn.custom_minimum_size = Vector2(0, 60)
	again_btn.add_theme_font_size_override("font_size", 28)
	again_btn.add_theme_stylebox_override("normal", _button_style())
	again_btn.pressed.connect(func() -> void: restart_game.emit())
	vb.add_child(again_btn)

func _build_pause() -> void:
	_pause_panel = PanelContainer.new()
	_pause_panel.custom_minimum_size = Vector2(420, 0)
	_pause_wrap = _center_wrap(_pause_panel)
	_pause_panel.add_theme_stylebox_override("panel", _panel_style())
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	_pause_panel.add_child(vb)
	var title := _label("PAUSED", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var resume_btn := Button.new()
	resume_btn.text = "RESUME"
	resume_btn.custom_minimum_size = Vector2(0, 56)
	resume_btn.add_theme_font_size_override("font_size", 26)
	resume_btn.add_theme_stylebox_override("normal", _button_style())
	resume_btn.pressed.connect(func() -> void: resume_game.emit())
	vb.add_child(resume_btn)
	var restart_btn := Button.new()
	restart_btn.text = "RESTART"
	restart_btn.custom_minimum_size = Vector2(0, 56)
	restart_btn.add_theme_font_size_override("font_size", 26)
	restart_btn.add_theme_stylebox_override("normal", _button_style())
	restart_btn.pressed.connect(func() -> void: restart_game.emit())
	vb.add_child(restart_btn)

# ---------------------------------------------------------------- public API

func _process(delta: float) -> void:
	if _popup_timer > 0.0:
		_popup_timer -= delta
		_popup_label.modulate.a = clampf(_popup_timer, 0.0, 1.0)
	if _flash_rect.color.a > 0.0:
		var c := _flash_rect.color
		c.a = maxf(0.0, c.a - delta * 1.8)
		_flash_rect.color = c

func show_popup(text: String) -> void:
	_popup_label.text = text
	_popup_timer = 1.4
	_popup_label.modulate.a = 1.0

func flash() -> void:
	_flash_rect.color = Color(1, 0.15, 0.1, 0.35)

func set_integrity(v: float, max_v: float) -> void:
	_integrity_bar.max_value = max_v
	_integrity_bar.value = v
	_integrity_label.text = "CORE %d" % int(v)

func set_wave(w: int) -> void:
	_wave_label.text = "WAVE %d" % w

func set_orbs(n: int) -> void:
	_orb_label.text = "ORB %d" % n

func set_score(n: int) -> void:
	_score_label.text = str(n)

func set_spin(pct: float) -> void:
	_spin_bar.value = pct
	_spin_label.text = "SPIN %d%%" % int(pct)

func set_rpm(pct: float, visible_rpm: bool) -> void:
	_rpm_bar.visible = visible_rpm
	_rpm_label.visible = visible_rpm
	_rpm_bar.value = pct
	_rpm_label.text = "RPM %d%%" % int(pct)

func set_weapon(name: String, can_switch: bool) -> void:
	_weapon_label.text = name
	_switch_button.disabled = not can_switch
	_switch_button.text = "SWITCH WEAPON" if can_switch else "LOCKED"

func set_attune(progress: float, active: bool) -> void:
	_attune_bar.visible = active
	_attune_label.visible = active
	_attune_bar.value = progress * 100.0

func set_best(n: int) -> void:
	_best_label.text = "BEST SCORE: %d" % n if n > 0 else ""

func show_menu() -> void:
	_hud_root.visible = false
	_menu_wrap.visible = true
	_upgrade_wrap.visible = false
	_gameover_wrap.visible = false
	_pause_wrap.visible = false

func show_hud() -> void:
	_hud_root.visible = true
	_menu_wrap.visible = false
	_upgrade_wrap.visible = false
	_gameover_wrap.visible = false
	_pause_wrap.visible = false

func show_upgrade(upgrades: Array, chakra_unlocked: bool, chakra_cost: int, orbs: int) -> void:
	_hud_root.visible = true
	_menu_wrap.visible = false
	_gameover_wrap.visible = false
	_pause_wrap.visible = false
	_upgrade_wrap.visible = true
	for child in _upgrade_list.get_children():
		child.queue_free()
	for u in upgrades:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var name_l := _label("%s  Lv%d" % [u["name"], u["level"]], 26)
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_l)
		var btn := Button.new()
		btn.text = "%d ORB" % u["cost"]
		btn.disabled = orbs < int(u["cost"])
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_stylebox_override("normal", _button_style())
		var uid: String = u["id"]
		btn.pressed.connect(func() -> void: upgrade_bought.emit(uid))
		row.add_child(btn)
		_upgrade_list.add_child(row)
	if not chakra_unlocked:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var name_l := _label("UNLOCK CHAKRA", 26, Color(1.0, 0.7, 0.3))
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_l)
		var btn := Button.new()
		btn.text = "%d ORB" % chakra_cost
		btn.disabled = orbs < chakra_cost
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_stylebox_override("normal", _button_style())
		btn.pressed.connect(func() -> void: unlock_chakra.emit())
		row.add_child(btn)
		_upgrade_list.add_child(row)

func show_gameover(score: int, best: int, wave: int) -> void:
	_hud_root.visible = false
	_menu_wrap.visible = false
	_upgrade_wrap.visible = false
	_pause_wrap.visible = false
	_gameover_wrap.visible = true
	_go_score_label.text = "SCORE %d   BEST %d" % [score, best]
	_go_wave_label.text = "Reached wave %d" % wave

func show_pause() -> void:
	_pause_wrap.visible = true

func hide_pause() -> void:
	_pause_wrap.visible = false

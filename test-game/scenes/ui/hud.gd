extends "res://_shared/scripts/ui/hud_base.gd"

## Test Game HUD
## 체력바, XP바, 레벨, 무기/패시브 슬롯 표시

const MAX_SLOTS = 3
const SLOT_SIZE = Vector2(36, 36)
const WEAPON_COLOR = Color(1.0, 0.6, 0.2)
const PASSIVE_COLOR = Color(0.3, 0.6, 1.0)
const EMPTY_COLOR = Color(0.2, 0.2, 0.2, 0.5)

var weapon_slots: Array[PanelContainer] = []
var passive_slots: Array[PanelContainer] = []
var weapon_slot_container: HBoxContainer
var passive_slot_container: HBoxContainer
var timer_label: Label
var game_manager: Node

func _setup_ui() -> void:
	health_bar = $MarginContainer/VBoxContainer/HealthBar
	xp_bar = $MarginContainer/VBoxContainer/XpContainer/XpBar
	level_label = $MarginContainer/VBoxContainer/XpContainer/LevelLabel
	weapon_slot_container = $MarginContainer/VBoxContainer/SlotsContainer/WeaponSlots
	passive_slot_container = $MarginContainer/VBoxContainer/SlotsContainer/PassiveSlots
	timer_label = $TimerContainer/TimerLabel

	# EventBus를 통해 타이머 이벤트 구독
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		event_bus.timer_updated.connect(_on_timer_updated)

	# GameManager 참조 (다른 용도)
	game_manager = get_node_or_null("/root/GameManager")

	# 슬롯 생성
	_create_slots()

## 슬롯 UI 생성
func _create_slots() -> void:
	# 무기 슬롯 3개
	for i in range(MAX_SLOTS):
		var slot = _create_slot(WEAPON_COLOR)
		weapon_slot_container.add_child(slot)
		weapon_slots.append(slot)

	# 패시브 슬롯 3개
	for i in range(MAX_SLOTS):
		var slot = _create_slot(PASSIVE_COLOR)
		passive_slot_container.add_child(slot)
		passive_slots.append(slot)

## 개별 슬롯 생성
func _create_slot(border_color: Color) -> PanelContainer:
	var slot = PanelContainer.new()
	slot.custom_minimum_size = SLOT_SIZE

	# 스타일 설정
	var style = StyleBoxFlat.new()
	style.bg_color = EMPTY_COLOR
	style.border_color = border_color
	style.border_color.a = 0.3
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	slot.add_theme_stylebox_override("panel", style)

	# 내부 컨테이너 (아이콘 + 레벨)
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_child(vbox)

	# 아이콘 placeholder (나중에 TextureRect로 교체)
	var icon = ColorRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(20, 20)
	icon.color = Color.TRANSPARENT
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon)

	# 레벨 라벨
	var level = Label.new()
	level.name = "Level"
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level.add_theme_font_size_override("font_size", 10)
	level.text = ""
	vbox.add_child(level)

	return slot

## 플레이어 시그널 연결 (오버라이드)
func _connect_player_signals() -> void:
	# 부모 시그널 연결
	super._connect_player_signals()

	# WeaponManager 시그널 연결
	if player.has_method("get") and player.get("weapon_manager"):
		var wm = player.weapon_manager
		if wm.has_signal("weapon_acquired"):
			wm.weapon_acquired.connect(_on_weapon_acquired)
		if wm.has_signal("weapon_upgraded"):
			wm.weapon_upgraded.connect(_on_weapon_upgraded)
		if wm.has_signal("weapons_changed"):
			wm.weapons_changed.connect(_update_weapon_slots)
		# 초기 상태 업데이트
		_update_weapon_slots()

	# SkillManager 시그널 연결
	if player.has_method("get") and player.get("skill_manager"):
		var sm = player.skill_manager
		if sm.has_signal("skill_acquired"):
			sm.skill_acquired.connect(_on_passive_changed)
		if sm.has_signal("skill_upgraded"):
			sm.skill_upgraded.connect(_on_passive_changed)
		# 초기 상태 업데이트
		_update_passive_slots()

## 무기 획득 시
func _on_weapon_acquired(_weapon_data, _level: int) -> void:
	_update_weapon_slots()

## 무기 업그레이드 시
func _on_weapon_upgraded(_weapon_data, _new_level: int) -> void:
	_update_weapon_slots()

## 패시브 변경 시
func _on_passive_changed(_skill, _level: int) -> void:
	_update_passive_slots()

## 무기 슬롯 업데이트
func _update_weapon_slots() -> void:
	if not player or not player.weapon_manager:
		return

	var wm = player.weapon_manager
	var active = wm.active_weapons
	var idx = 0

	for weapon_id in active:
		if idx >= MAX_SLOTS:
			break
		var info = active[weapon_id]
		var data = info.data
		var level = info.level

		_update_slot(weapon_slots[idx], data, level, WEAPON_COLOR)
		idx += 1

	# 빈 슬롯 초기화
	for i in range(idx, MAX_SLOTS):
		_clear_slot(weapon_slots[i], WEAPON_COLOR)

## 패시브 슬롯 업데이트
func _update_passive_slots() -> void:
	if not player or not player.skill_manager:
		return

	var sm = player.skill_manager
	var acquired = sm.acquired_skills
	var idx = 0

	for skill_id in acquired:
		if idx >= MAX_SLOTS:
			break
		var level = acquired[skill_id]
		var skill = sm._get_skill_by_id(skill_id)
		if skill and skill.skill_type == 0:  # PASSIVE
			_update_slot(passive_slots[idx], skill, level, PASSIVE_COLOR)
			idx += 1

	# 빈 슬롯 초기화
	for i in range(idx, MAX_SLOTS):
		_clear_slot(passive_slots[i], PASSIVE_COLOR)

## 슬롯 업데이트
func _update_slot(slot: PanelContainer, data, level: int, color: Color) -> void:
	# 스타일 업데이트 - 활성화
	var style = slot.get_theme_stylebox("panel").duplicate()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_color = color
	slot.add_theme_stylebox_override("panel", style)

	# 아이콘 업데이트
	var icon = slot.get_node("VBoxContainer/Icon")
	if data.icon:
		# TextureRect로 교체
		if icon is ColorRect:
			var tex_rect = TextureRect.new()
			tex_rect.name = "Icon"
			tex_rect.custom_minimum_size = Vector2(20, 20)
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			tex_rect.texture = data.icon
			var vbox = slot.get_node("VBoxContainer")
			vbox.remove_child(icon)
			icon.queue_free()
			vbox.add_child(tex_rect)
			vbox.move_child(tex_rect, 0)
		else:
			icon.texture = data.icon
	else:
		# 플레이스홀더 색상
		if icon is ColorRect:
			icon.color = color
			icon.color.a = 0.7

	# 레벨 라벨
	var level_label_node = slot.get_node("VBoxContainer/Level")
	level_label_node.text = "Lv.%d" % level
	level_label_node.add_theme_color_override("font_color", color)

## 슬롯 초기화 (빈 상태)
func _clear_slot(slot: PanelContainer, color: Color) -> void:
	var style = slot.get_theme_stylebox("panel").duplicate()
	style.bg_color = EMPTY_COLOR
	style.border_color = color
	style.border_color.a = 0.3
	slot.add_theme_stylebox_override("panel", style)

	var icon = slot.get_node("VBoxContainer/Icon")
	if icon is ColorRect:
		icon.color = Color.TRANSPARENT
	elif icon is TextureRect:
		icon.texture = null

	var level_label_node = slot.get_node("VBoxContainer/Level")
	level_label_node.text = ""

## 타이머 업데이트
func _on_timer_updated(remaining: float, _total: float) -> void:
	if timer_label:
		var total_seconds := int(remaining)
		@warning_ignore("integer_division")
		var minutes := total_seconds / 60
		var seconds := total_seconds % 60
		timer_label.text = "%d:%02d" % [minutes, seconds]

		# 1분 이하면 빨간색
		if remaining <= 60:
			timer_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		# 3분 이하면 노란색
		elif remaining <= 180:
			timer_label.add_theme_color_override("font_color", Color(1, 1, 0.3))
		else:
			timer_label.add_theme_color_override("font_color", Color.WHITE)

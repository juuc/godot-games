extends "res://_shared/scripts/ui/skill_selection_ui.gd"

## Test Game 스킬/무기 선택 UI
## 무기와 패시브를 구분하여 표시

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var cards_container: HBoxContainer = $Panel/VBoxContainer/CardsContainer

## 스킬 카드 프리팹 (동적 생성)
var card_scene: PackedScene

## WeaponManager 참조 (무기 레벨 조회용)
var weapon_manager = null

## 무기/패시브 색상
const WEAPON_COLOR = Color(1.0, 0.6, 0.2)  # 주황색
const PASSIVE_COLOR = Color(0.3, 0.6, 1.0)  # 파란색

## WeaponManager 설정
func set_weapon_manager(wm) -> void:
	weapon_manager = wm

func _setup_ui() -> void:
	# 패널 중앙 배치
	if panel:
		panel.anchor_left = 0.5
		panel.anchor_right = 0.5
		panel.anchor_top = 0.5
		panel.anchor_bottom = 0.5
		panel.offset_left = -300
		panel.offset_right = 300
		panel.offset_top = -200
		panel.offset_bottom = 200

func _update_skill_display() -> void:
	# 기존 카드 제거
	for child in cards_container.get_children():
		child.queue_free()

	skill_buttons.clear()

	# 새 카드 생성
	for i in range(current_options.size()):
		var option = current_options[i]
		var card = _create_option_card(option, i)
		cards_container.add_child(card)

## 통합 옵션 카드 생성 (무기 또는 패시브)
func _create_option_card(option, index: int) -> Control:
	# 옵션 타입 파악
	var is_weapon := false
	var data = option
	var current_level := 0

	if option is Dictionary and option.has("type"):
		is_weapon = (option.type == "weapon")
		data = option.data
		current_level = option.level
	elif skill_manager:
		current_level = skill_manager.get_skill_level(data.id)

	var next_level = current_level + 1
	var type_color = WEAPON_COLOR if is_weapon else PASSIVE_COLOR

	# 카드 컨테이너
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 300)

	# 스타일박스로 테두리 색상 적용
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.bg_color = Color(0.15, 0.15, 0.15)
	style.border_color = type_color
	style.set_border_width_all(3)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	# 타입 라벨 (WEAPON / PASSIVE)
	var type_label = Label.new()
	type_label.text = "WEAPON" if is_weapon else "PASSIVE"
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.add_theme_color_override("font_color", type_color)
	vbox.add_child(type_label)

	# 아이콘 (또는 플레이스홀더)
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(0, 64)
	vbox.add_child(icon_container)

	if data.icon:
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(64, 64)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = data.icon
		icon_container.add_child(icon_rect)
	else:
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(64, 64)
		color_rect.color = type_color
		color_rect.color.a = 0.5
		icon_container.add_child(color_rect)

	# 이름
	var name_label = Label.new()
	name_label.text = data.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)

	# 레벨 표시
	var level_label = Label.new()
	if current_level == 0:
		level_label.text = "NEW"
		level_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		level_label.text = "Lv.%d -> %d" % [current_level, next_level]
		level_label.add_theme_color_override("font_color", Color.GREEN)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_label)

	# 설명
	var desc_label = Label.new()
	if is_weapon and data.has_method("get_upgrade_description"):
		desc_label.text = data.get_upgrade_description(current_level, next_level)
	elif data.has_method("get_description_at_level"):
		desc_label.text = data.get_description_at_level(next_level)
	else:
		desc_label.text = data.description if "description" in data else ""
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size.y = 50
	desc_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(desc_label)

	# 선택 버튼
	var button = Button.new()
	button.text = "Select"
	button.pressed.connect(_on_skill_selected.bind(index))
	vbox.add_child(button)
	skill_buttons.append(button)

	return card

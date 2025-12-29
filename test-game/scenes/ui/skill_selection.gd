extends "res://_shared/scripts/ui/skill_selection_ui.gd"

## Test Game 스킬 선택 UI
## 3개의 스킬 카드를 표시

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var cards_container: HBoxContainer = $Panel/VBoxContainer/CardsContainer

## 스킬 카드 프리팹 (동적 생성)
var card_scene: PackedScene

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
		var skill = current_options[i]
		var card = _create_skill_card(skill, i)
		cards_container.add_child(card)

func _create_skill_card(skill, index: int) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 280)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	# 아이콘 (또는 플레이스홀더)
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(64, 64)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if skill.icon:
		icon_rect.texture = skill.icon
	else:
		# 플레이스홀더 색상 박스
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(64, 64)
		color_rect.color = Color(0.3, 0.5, 0.8)
		vbox.add_child(color_rect)
	if skill.icon:
		vbox.add_child(icon_rect)

	# 스킬 이름
	var name_label = Label.new()
	name_label.text = skill.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)

	# 현재 레벨 표시
	var current_level = 0
	if skill_manager:
		current_level = skill_manager.get_skill_level(skill.id)
	var next_level = current_level + 1

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
	desc_label.text = skill.get_description_at_level(next_level)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size.y = 60
	vbox.add_child(desc_label)

	# 선택 버튼
	var button = Button.new()
	button.text = "Select"
	button.pressed.connect(_on_skill_selected.bind(index))
	vbox.add_child(button)
	skill_buttons.append(button)

	return card

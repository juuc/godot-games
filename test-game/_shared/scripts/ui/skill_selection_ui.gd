class_name SkillSelectionUI
extends CanvasLayer

## 스킬 선택 UI 베이스 클래스
## 게임별로 스타일링을 위해 상속하여 사용

signal skill_selected(skill)
signal selection_cancelled()

## 스킬 매니저 참조
var skill_manager

## 현재 표시된 옵션들
var current_options: Array = []

## UI 요소 (자식에서 설정)
var container: Control
var skill_buttons: Array[Button] = []

func _ready() -> void:
	# 기본적으로 숨김
	visible = false

	# 게임 일시정지 시 UI는 동작해야 함
	process_mode = Node.PROCESS_MODE_ALWAYS

	_setup_ui()

## UI 초기화 (자식에서 오버라이드)
func _setup_ui() -> void:
	pass

## 스킬 매니저 연결
func set_skill_manager(manager) -> void:
	skill_manager = manager

## 선택지 표시
func show_selection(options: Array) -> void:
	current_options = options

	# 게임 일시정지
	get_tree().paused = true

	# UI 업데이트
	_update_skill_display()

	visible = true

## 스킬 버튼 표시 업데이트 (자식에서 오버라이드)
func _update_skill_display() -> void:
	pass

## 스킬 선택 처리
func _on_skill_selected(index: int) -> void:
	if index < 0 or index >= current_options.size():
		return

	var selected_skill = current_options[index]

	# 스킬 획득
	if skill_manager:
		skill_manager.acquire_skill(selected_skill)

	# 시그널 발생
	skill_selected.emit(selected_skill)

	# UI 숨김 및 게임 재개
	_close_selection()

## UI 닫기
func _close_selection() -> void:
	visible = false
	current_options.clear()
	get_tree().paused = false

## 취소 (ESC 등)
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		# 스킬 선택은 필수이므로 취소 불가 (옵션)
		# selection_cancelled.emit()
		# _close_selection()
		pass

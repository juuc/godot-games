class_name SkillSelectionUI
extends CanvasLayer

## 스킬 선택 UI 베이스 클래스
## 게임별로 스타일링을 위해 상속하여 사용

signal skill_selected(skill)
@warning_ignore("unused_signal")
signal selection_cancelled()  ## TODO: 취소 기능 구현 시 사용

## 스킬 매니저 참조
var skill_manager

## 현재 표시된 옵션들
var current_options: Array[Dictionary] = []

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
func show_selection(options: Array[Dictionary]) -> void:
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

	var selected_option = current_options[index]

	# 통합 옵션 형식 체크 {type: "weapon"|"passive", data, level}
	# 시그널 핸들러(player)가 타입별 처리를 담당
	if selected_option is Dictionary and selected_option.has("type"):
		# 시그널만 발생 - player._on_skill_selected에서 처리
		skill_selected.emit(selected_option)
	else:
		# 기존 스킬 형식 (하위 호환)
		if skill_manager:
			skill_manager.acquire_skill(selected_option)
		skill_selected.emit(selected_option)

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

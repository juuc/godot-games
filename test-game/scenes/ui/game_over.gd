extends CanvasLayer

## 게임오버 화면
## 사망 시 표시, 재시작/메인메뉴 버튼
## EventBus의 game_over 시그널에 자동 반응

signal restart_requested
signal main_menu_requested

@onready var panel: Control = $Panel
@onready var stats_label: Label = $Panel/VBoxContainer/StatsLabel
@onready var restart_button: Button = $Panel/VBoxContainer/ButtonContainer/RestartButton
@onready var quit_button: Button = $Panel/VBoxContainer/ButtonContainer/QuitButton

var final_stats: Dictionary = {}

func _ready() -> void:
	add_to_group("game_over_ui")

	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# EventBus 연결
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		event_bus.game_over.connect(_on_game_over)

	# 시작 시 숨김
	hide()

## EventBus game_over 시그널 핸들러
func _on_game_over(stats: Dictionary) -> void:
	show_game_over(stats)

## 게임오버 표시
func show_game_over(stats: Dictionary = {}) -> void:
	final_stats = stats
	_update_stats_display()

	# 게임 일시정지
	get_tree().paused = true

	show()

	# 페이드인 효과
	panel.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)

## 통계 표시 업데이트
func _update_stats_display() -> void:
	var text = ""

	if final_stats.has("level"):
		text += "레벨: %d\n" % final_stats.level
	if final_stats.has("kills"):
		text += "처치: %d\n" % final_stats.kills
	if final_stats.has("time"):
		var total_seconds := int(final_stats.time)
		@warning_ignore("integer_division")
		var minutes := total_seconds / 60
		var seconds := total_seconds % 60
		text += "생존: %d:%02d\n" % [minutes, seconds]
	if final_stats.has("xp"):
		text += "획득 XP: %d" % final_stats.xp

	if text.is_empty():
		text = "다시 도전하세요!"

	stats_label.text = text

func _on_restart_pressed() -> void:
	hide()
	restart_requested.emit()

	# GameManager로 재시작 (없으면 직접 처리)
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.restart_game()
	else:
		get_tree().paused = false
		get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	main_menu_requested.emit()
	# 메인 메뉴가 없으면 게임 종료
	get_tree().quit()

## 외부에서 게임오버 트리거 (하위 호환성)
func trigger_game_over(stats: Dictionary = {}) -> void:
	show_game_over(stats)

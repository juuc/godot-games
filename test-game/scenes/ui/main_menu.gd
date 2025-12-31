extends CanvasLayer

## 메인 메뉴 화면
## 게임 시작, 통계, 종료 버튼 제공

@onready var start_button: Button = $Panel/VBoxContainer/StartButton
@onready var stats_button: Button = $Panel/VBoxContainer/StatsButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

var stats_screen_scene: PackedScene

func _ready() -> void:
	# 게임 일시정지 해제 (이전 게임에서 넘어온 경우)
	get_tree().paused = false

	# GameManager 상태 초기화
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager._reset_stats()

	# 버튼 연결
	start_button.pressed.connect(_on_start_pressed)
	stats_button.pressed.connect(_on_stats_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 통계 화면 프리로드
	stats_screen_scene = preload("res://scenes/ui/stats_screen.tscn")

	# 버튼 스타일 적용
	_setup_button_styles()

func _setup_button_styles() -> void:
	var buttons = [start_button, stats_button, quit_button]

	for button in buttons:
		# 기본 스타일
		var normal_style = StyleBoxFlat.new()
		normal_style.set_corner_radius_all(8)
		normal_style.bg_color = Color(0.15, 0.15, 0.15)
		normal_style.border_color = Color(0.4, 0.4, 0.4)
		normal_style.set_border_width_all(2)
		button.add_theme_stylebox_override("normal", normal_style)

		# 호버 스타일
		var hover_style = StyleBoxFlat.new()
		hover_style.set_corner_radius_all(8)
		hover_style.bg_color = Color(0.2, 0.2, 0.2)
		hover_style.border_color = Color(1.0, 0.6, 0.2)  # 오렌지
		hover_style.set_border_width_all(3)
		button.add_theme_stylebox_override("hover", hover_style)

		# 프레스 스타일
		var pressed_style = StyleBoxFlat.new()
		pressed_style.set_corner_radius_all(8)
		pressed_style.bg_color = Color(0.25, 0.25, 0.25)
		pressed_style.border_color = Color(1.0, 0.7, 0.3)
		pressed_style.set_border_width_all(3)
		button.add_theme_stylebox_override("pressed", pressed_style)

		# 폰트 크기
		button.add_theme_font_size_override("font_size", 24)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_stats_pressed() -> void:
	var stats_screen = stats_screen_scene.instantiate()
	stats_screen.back_requested.connect(_on_stats_back)
	add_child(stats_screen)

func _on_stats_back() -> void:
	# StatsScreen이 자체적으로 queue_free 호출
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()

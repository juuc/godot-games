extends CanvasLayer

## 통계 화면
## StatsManager의 누적 통계를 표시

signal back_requested

@onready var stats_container: GridContainer = $Panel/VBoxContainer/StatsContainer
@onready var recent_list: VBoxContainer = $Panel/VBoxContainer/RecentSection/RecentList
@onready var back_button: Button = $Panel/VBoxContainer/BackButton

## 통계 라벨 (키: 표시명)
const STAT_LABELS = {
	"total_plays": "Total Plays",
	"total_time": "Total Time",
	"total_kills": "Total Kills",
	"total_xp": "Total XP",
	"best_level": "Best Level",
	"best_kills": "Best Kills",
	"best_time": "Best Time",
	"best_wave": "Best Wave",
	"avg_time": "Avg. Time",
	"avg_kills": "Avg. Kills"
}

## 하이라이트할 키 (베스트 기록)
const HIGHLIGHT_KEYS = ["best_level", "best_kills", "best_time", "best_wave"]

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_setup_button_style()
	_populate_stats()

func _setup_button_style() -> void:
	# 기본 스타일
	var normal_style = StyleBoxFlat.new()
	normal_style.set_corner_radius_all(8)
	normal_style.bg_color = Color(0.15, 0.15, 0.15)
	normal_style.border_color = Color(0.4, 0.4, 0.4)
	normal_style.set_border_width_all(2)
	back_button.add_theme_stylebox_override("normal", normal_style)

	# 호버 스타일
	var hover_style = StyleBoxFlat.new()
	hover_style.set_corner_radius_all(8)
	hover_style.bg_color = Color(0.2, 0.2, 0.2)
	hover_style.border_color = Color(0.3, 0.6, 1.0)  # 블루
	hover_style.set_border_width_all(3)
	back_button.add_theme_stylebox_override("hover", hover_style)

	back_button.add_theme_font_size_override("font_size", 20)

func _populate_stats() -> void:
	var stats_manager = get_node_or_null("/root/StatsManager")
	if not stats_manager:
		return

	var formatted = stats_manager.get_formatted_stats()

	# 기존 내용 삭제
	for child in stats_container.get_children():
		child.queue_free()

	# GridContainer에 통계 추가
	for key in STAT_LABELS:
		# 라벨명
		var name_label = Label.new()
		name_label.text = STAT_LABELS[key] + ":"
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		stats_container.add_child(name_label)

		# 값
		var value_label = Label.new()
		value_label.text = formatted.get(key, "0")
		value_label.add_theme_font_size_override("font_size", 18)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		# 베스트 기록은 오렌지로 하이라이트
		if key in HIGHLIGHT_KEYS:
			value_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
		else:
			value_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

		stats_container.add_child(value_label)

	# 최근 게임 기록
	_populate_recent_games(stats_manager.get_stats())

func _populate_recent_games(stats: Dictionary) -> void:
	# 기존 내용 삭제
	for child in recent_list.get_children():
		child.queue_free()

	var recent = stats.get("recent_results", [])

	if recent.is_empty():
		var no_games = Label.new()
		no_games.text = "No games played yet"
		no_games.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		no_games.add_theme_font_size_override("font_size", 14)
		recent_list.add_child(no_games)
		return

	# 최근 5개만 표시
	for i in range(min(5, recent.size())):
		var result = recent[i]
		var entry = Label.new()

		var time_val = result.get("time", 0.0)
		@warning_ignore("integer_division")
		var mins := int(time_val) / 60
		var secs := int(time_val) % 60

		entry.text = "Lv.%d | %d kills | %d:%02d" % [
			result.get("level", 0),
			result.get("kills", 0),
			mins,
			secs
		]
		entry.add_theme_font_size_override("font_size", 14)
		entry.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		recent_list.add_child(entry)

func _on_back_pressed() -> void:
	back_requested.emit()
	queue_free()

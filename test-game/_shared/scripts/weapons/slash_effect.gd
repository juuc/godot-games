class_name SlashEffect
extends Node2D

## 슬래시 이펙트
## 반원형 아크를 그리고 페이드아웃됩니다.

var arc_range: float = 80.0
var arc_angle: float = 120.0
var duration: float = 0.2
var arc_color: Color = Color(1, 1, 1, 0.8)

var elapsed: float = 0.0

## 이펙트 설정
func setup(p_range: float, p_angle: float, p_duration: float, p_color: Color = Color.WHITE) -> void:
	arc_range = p_range
	arc_angle = p_angle
	duration = p_duration
	arc_color = p_color
	arc_color.a = 0.8

func _ready() -> void:
	# 페이드아웃 후 제거
	var tween = create_tween()
	tween.tween_method(_set_alpha, arc_color.a, 0.0, duration)
	tween.tween_callback(queue_free)

func _set_alpha(alpha: float) -> void:
	arc_color.a = alpha
	queue_redraw()

func _draw() -> void:
	# 아크 그리기
	var half_angle = deg_to_rad(arc_angle / 2)
	var points: PackedVector2Array = [Vector2.ZERO]
	var segments = 16

	for i in range(segments + 1):
		var angle = -half_angle + (i * 2 * half_angle / segments)
		points.append(Vector2(cos(angle), sin(angle)) * arc_range)

	# 반투명 채우기
	var fill_color = arc_color
	fill_color.a *= 0.3
	draw_colored_polygon(points, fill_color)

	# 테두리
	var outline_points: PackedVector2Array = []
	for i in range(segments + 1):
		var angle = -half_angle + (i * 2 * half_angle / segments)
		outline_points.append(Vector2(cos(angle), sin(angle)) * arc_range)

	for i in range(outline_points.size() - 1):
		draw_line(outline_points[i], outline_points[i + 1], arc_color, 3.0)

	# 시작선과 끝선
	draw_line(Vector2.ZERO, outline_points[0], arc_color, 2.0)
	draw_line(Vector2.ZERO, outline_points[outline_points.size() - 1], arc_color, 2.0)

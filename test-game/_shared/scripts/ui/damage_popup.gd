class_name DamagePopup
extends Node2D

## 데미지 숫자 팝업
## 피격 시 위로 튀어오르며 페이드아웃되는 숫자 표시
## 타격감을 위해: 랜덤 퍼짐, 크기 펑!, 페이드아웃

@onready var label: Label = $Label

## 애니메이션 설정
@export var float_height: float = 40.0  ## 떠오르는 높이
@export var float_duration: float = 0.6  ## 떠오르는 시간
@export var pop_scale: float = 1.5  ## 시작 스케일 (펑!)
@export var pop_duration: float = 0.1  ## 펑 효과 시간
@export var spread_x: float = 20.0  ## 좌우 퍼짐 범위

## 팝업 타입별 색상
const COLORS = {
	"damage": Color(1.0, 1.0, 1.0),  # 흰색
	"critical": Color(1.0, 0.9, 0.2),  # 노랑
	"heal": Color(0.3, 1.0, 0.5),  # 초록
	"player_damage": Color(1.0, 0.3, 0.3)  # 빨강 (플레이어 피격)
}

func _ready() -> void:
	# 초기 상태 숨김 (setup 호출 전)
	modulate.a = 0.0

## 팝업 설정 및 애니메이션 시작
func setup(amount: float, popup_type: String = "damage") -> void:
	if not label:
		label = $Label

	# 숫자 표시 (정수로)
	var display_amount = int(amount)
	label.text = str(display_amount)

	# 크리티컬 판정 (데미지가 높으면)
	if popup_type == "damage" and amount >= 10:
		popup_type = "critical"

	# 색상 설정
	var color = COLORS.get(popup_type, COLORS["damage"])
	modulate = color

	# 랜덤 X 오프셋 (퍼지는 효과)
	var offset_x = randf_range(-spread_x, spread_x)
	position.x += offset_x

	# 시작 스케일 (펑!)
	scale = Vector2(pop_scale, pop_scale)

	# 애니메이션 시작
	_animate()

## Tween 기반 애니메이션
func _animate() -> void:
	var tween = create_tween()
	tween.set_parallel(false)

	# Phase 1: 펑! (스케일 축소) - 0.1초
	tween.tween_property(self, "scale", Vector2.ONE, pop_duration)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)

	# Phase 2: 떠오름 + 페이드아웃 - 0.6초 (동시 실행)
	tween.set_parallel(true)

	# 위로 이동 (살짝 느려지는 느낌)
	var target_pos = position + Vector2(0, -float_height)
	tween.tween_property(self, "position", target_pos, float_duration)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)

	# 페이드아웃 (후반부에 빠르게)
	tween.tween_property(self, "modulate:a", 0.0, float_duration)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUAD)

	# 완료 후 삭제
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

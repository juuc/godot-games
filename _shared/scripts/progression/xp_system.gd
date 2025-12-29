class_name XpSystem
extends RefCounted

## 경험치 및 레벨 시스템
## 플레이어에서 분리하여 독립적으로 사용 가능

signal xp_changed(current: int, required: int)
signal level_up(new_level: int)

var current_xp: int = 0
var current_level: int = 1
var xp_to_next_level: int = 10

## XP 공식 설정
var base_xp: int = 10
var xp_per_level: int = 5

func _init(base: int = 10, per_level: int = 5) -> void:
	base_xp = base
	xp_per_level = per_level
	xp_to_next_level = _calculate_xp_for_level(1)

## 경험치 획득
func add_xp(amount: int) -> void:
	current_xp += amount
	xp_changed.emit(current_xp, xp_to_next_level)

	while current_xp >= xp_to_next_level:
		_level_up()

## 레벨업 처리
func _level_up() -> void:
	current_xp -= xp_to_next_level
	current_level += 1
	xp_to_next_level = _calculate_xp_for_level(current_level)

	level_up.emit(current_level)
	xp_changed.emit(current_xp, xp_to_next_level)

## 레벨별 필요 경험치 계산
func _calculate_xp_for_level(level: int) -> int:
	return base_xp + (level - 1) * xp_per_level

## 리셋
func reset() -> void:
	current_xp = 0
	current_level = 1
	xp_to_next_level = _calculate_xp_for_level(1)
	xp_changed.emit(current_xp, xp_to_next_level)

## 현재 상태 딕셔너리로 반환 (저장용)
func get_state() -> Dictionary:
	return {
		"current_xp": current_xp,
		"current_level": current_level,
		"xp_to_next_level": xp_to_next_level
	}

## 상태 복원 (로드용)
func load_state(state: Dictionary) -> void:
	current_xp = state.get("current_xp", 0)
	current_level = state.get("current_level", 1)
	xp_to_next_level = state.get("xp_to_next_level", _calculate_xp_for_level(current_level))
	xp_changed.emit(current_xp, xp_to_next_level)

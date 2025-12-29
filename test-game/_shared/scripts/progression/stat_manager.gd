class_name StatManager
extends RefCounted

## 스탯 관리자
## 모든 수정자를 모아 최종 스탯 값을 계산합니다.

const StatModifierClass = preload("res://_shared/scripts/progression/stat_modifier.gd")

signal stats_changed

## 기본 스탯 값
var base_stats: Dictionary = {}

## 활성 수정자 목록
var modifiers: Array = []

## 캐시된 최종 값
var _cached_values: Dictionary = {}
var _cache_dirty: bool = true

func _init() -> void:
	_init_base_stats()

## 기본 스탯 초기화
func _init_base_stats() -> void:
	base_stats = {
		StatModifierClass.StatType.MAX_HEALTH: 100.0,
		StatModifierClass.StatType.MOVE_SPEED: 200.0,
		StatModifierClass.StatType.PICKUP_RANGE: 50.0,
		StatModifierClass.StatType.XP_MULTIPLIER: 1.0,
		StatModifierClass.StatType.DAMAGE: 1.0,
		StatModifierClass.StatType.FIRE_RATE: 0.25,
		StatModifierClass.StatType.PROJECTILE_SPEED: 2000.0,
		StatModifierClass.StatType.PROJECTILE_COUNT: 1.0,
		StatModifierClass.StatType.PIERCE_COUNT: 0.0,
		StatModifierClass.StatType.KNOCKBACK: 100.0,
		StatModifierClass.StatType.DAMAGE_REDUCTION: 0.0,
		StatModifierClass.StatType.INVINCIBILITY_DURATION: 1.0
	}

## 기본 스탯 설정
func set_base_stat(stat_type: int, value: float) -> void:
	base_stats[stat_type] = value
	_cache_dirty = true

## 수정자 추가
func add_modifier(modifier: StatModifierClass) -> void:
	modifiers.append(modifier)
	_cache_dirty = true
	stats_changed.emit()

## 특정 출처의 수정자 제거
func remove_modifiers_by_source(source_id: String) -> void:
	modifiers = modifiers.filter(func(m): return m.source_id != source_id)
	_cache_dirty = true
	stats_changed.emit()

## 모든 수정자 제거
func clear_modifiers() -> void:
	modifiers.clear()
	_cache_dirty = true
	stats_changed.emit()

## 최종 스탯 값 계산
func get_stat(stat_type: int) -> float:
	if _cache_dirty:
		_recalculate_all()

	if _cached_values.has(stat_type):
		return _cached_values[stat_type]

	return base_stats.get(stat_type, 0.0)

## 모든 스탯 재계산
func _recalculate_all() -> void:
	_cached_values.clear()

	for stat_type in base_stats:
		_cached_values[stat_type] = _calculate_stat(stat_type)

	_cache_dirty = false

## 단일 스탯 계산
func _calculate_stat(stat_type: int) -> float:
	var base = base_stats.get(stat_type, 0.0)

	var flat_bonus: float = 0.0
	var percent_bonus: float = 0.0
	var multiplier: float = 1.0

	for modifier in modifiers:
		if modifier.stat_type != stat_type:
			continue

		match modifier.modifier_type:
			StatModifierClass.ModifierType.FLAT:
				flat_bonus += modifier.value
			StatModifierClass.ModifierType.PERCENT:
				percent_bonus += modifier.value
			StatModifierClass.ModifierType.MULTIPLY:
				multiplier *= modifier.value

	# 계산 순서: (base + flat) * (1 + percent) * multiply
	var result = (base + flat_bonus) * (1.0 + percent_bonus) * multiplier

	# 특수 처리: 발사 속도는 낮을수록 좋음 (최소값 제한)
	if stat_type == StatModifierClass.StatType.FIRE_RATE:
		result = max(result, 0.05)

	return result

## 편의 메서드들

func get_max_health() -> float:
	return get_stat(StatModifierClass.StatType.MAX_HEALTH)

func get_move_speed() -> float:
	return get_stat(StatModifierClass.StatType.MOVE_SPEED)

func get_damage() -> float:
	return get_stat(StatModifierClass.StatType.DAMAGE)

func get_fire_rate() -> float:
	return get_stat(StatModifierClass.StatType.FIRE_RATE)

func get_projectile_count() -> int:
	return int(get_stat(StatModifierClass.StatType.PROJECTILE_COUNT))

func get_pickup_range() -> float:
	return get_stat(StatModifierClass.StatType.PICKUP_RANGE)

## 디버그: 모든 스탯 출력
func debug_print() -> void:
	print("=== Stats ===")
	for stat_type in base_stats:
		var base = base_stats[stat_type]
		var final_val = get_stat(stat_type)
		var stat_name = StatModifierClass.StatType.keys()[stat_type]
		print("  %s: %.2f -> %.2f" % [stat_name, base, final_val])

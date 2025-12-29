class_name SkillData
extends Resource

## 스킬 데이터 리소스
## 각 스킬의 기본 정보와 레벨별 효과 정의
## StatModifier와 연동하여 자동으로 스탯 수정

enum SkillType {
	PASSIVE,    ## 패시브 (자동 적용)
	WEAPON,     ## 무기 (발사체 등)
	ABILITY     ## 액티브 스킬
}

## StatModifier의 StatType을 참조 (preload 없이)
enum TargetStat {
	NONE = -1,
	MAX_HEALTH = 0,
	MOVE_SPEED = 1,
	PICKUP_RANGE = 2,
	XP_MULTIPLIER = 3,
	DAMAGE = 4,
	FIRE_RATE = 5,
	PROJECTILE_SPEED = 6,
	PROJECTILE_COUNT = 7,
	PIERCE_COUNT = 8,
	KNOCKBACK = 9,
	DAMAGE_REDUCTION = 10,
	INVINCIBILITY_DURATION = 11
}

## StatModifier의 ModifierType을 참조
enum ModifierMode {
	FLAT = 0,       ## 고정값 추가
	PERCENT = 1,    ## 퍼센트 증가
	MULTIPLY = 2,   ## 배수
	SET_VALUE = 3   ## 값 직접 설정 (레거시 호환)
}

@export_group("Basic Info")
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var skill_type: SkillType = SkillType.PASSIVE
@export var max_level: int = 5

@export_group("Stat Modification")
## 수정할 스탯 타입
@export var target_stat: TargetStat = TargetStat.NONE
## 수정 방식
@export var modifier_mode: ModifierMode = ModifierMode.FLAT

@export_group("Level Values")
## 레벨별 효과 값 (예: [10, 20, 30, 40, 50] = 레벨 1~5의 데미지)
@export var level_values: Array[float] = []

## 레벨별 설명 (옵션)
@export var level_descriptions: Array[String] = []

## 현재 레벨의 값 반환
func get_value_at_level(level: int) -> float:
	if level <= 0 or level_values.is_empty():
		return 0.0
	var index = min(level - 1, level_values.size() - 1)
	return level_values[index]

## 현재 레벨의 설명 반환
func get_description_at_level(level: int) -> String:
	if level_descriptions.is_empty():
		return description
	var index = min(level - 1, level_descriptions.size() - 1)
	return level_descriptions[index] if index >= 0 else description

## StatModifier 생성 (StatManager와 연동 시 사용)
func create_modifier(level: int) -> RefCounted:
	if target_stat == TargetStat.NONE:
		return null

	var StatModifierClass = load("res://_shared/scripts/progression/stat_modifier.gd")
	var value = get_value_at_level(level)

	# SET_VALUE 모드는 FLAT으로 변환 (기본값을 0으로 설정해야 함)
	var mod_type = modifier_mode if modifier_mode != ModifierMode.SET_VALUE else ModifierMode.FLAT

	return StatModifierClass.new(target_stat, mod_type, value, id)

## 스탯을 직접 수정하는 스킬인지 확인
func has_stat_modifier() -> bool:
	return target_stat != TargetStat.NONE

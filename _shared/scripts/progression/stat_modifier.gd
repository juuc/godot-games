class_name StatModifier
extends RefCounted

## 스탯 수정자
## 스킬, 아이템 등에서 플레이어/무기 스탯을 수정할 때 사용

enum ModifierType {
	FLAT,       ## 고정값 추가 (base + flat)
	PERCENT,    ## 퍼센트 증가 (base * (1 + percent))
	MULTIPLY    ## 배수 (base * multiply)
}

enum StatType {
	# Player Stats
	MAX_HEALTH,
	MOVE_SPEED,
	PICKUP_RANGE,
	XP_MULTIPLIER,

	# Weapon Stats
	DAMAGE,
	FIRE_RATE,
	PROJECTILE_SPEED,
	PROJECTILE_COUNT,
	PIERCE_COUNT,
	KNOCKBACK,

	# Defense
	DAMAGE_REDUCTION,
	INVINCIBILITY_DURATION
}

var stat_type: StatType
var modifier_type: ModifierType
var value: float
var source_id: String  ## 수정자 출처 (스킬 ID 등)

func _init(p_stat: StatType, p_type: ModifierType, p_value: float, p_source: String = "") -> void:
	stat_type = p_stat
	modifier_type = p_type
	value = p_value
	source_id = p_source

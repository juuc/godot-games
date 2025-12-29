class_name SkillData
extends Resource

## 스킬 데이터 리소스
## 각 스킬의 기본 정보와 레벨별 효과 정의

enum SkillType {
	PASSIVE,    ## 패시브 (자동 적용)
	WEAPON,     ## 무기 (발사체 등)
	ABILITY     ## 액티브 스킬
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var skill_type: SkillType = SkillType.PASSIVE
@export var max_level: int = 5

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

class_name SkillManager
extends RefCounted

## 스킬 관리자
## 획득한 스킬, 레벨, 선택 로직 담당

signal skill_acquired(skill, level: int)
signal skill_upgraded(skill, new_level: int)
signal selection_required(options: Array)

## 사용 가능한 모든 스킬 풀
var available_skills: Array = []

## 획득한 스킬 {skill_id: level}
var acquired_skills: Dictionary = {}

## 선택지 개수
var selection_count: int = 3

## 스킬 풀 설정
func set_skill_pool(skills: Array) -> void:
	available_skills = skills

## 스킬 획득/업그레이드
func acquire_skill(skill) -> void:
	var current_level = acquired_skills.get(skill.id, 0)

	if current_level >= skill.max_level:
		return

	var new_level = current_level + 1
	acquired_skills[skill.id] = new_level

	if current_level == 0:
		skill_acquired.emit(skill, new_level)
	else:
		skill_upgraded.emit(skill, new_level)

## 스킬 레벨 조회
func get_skill_level(skill_id: String) -> int:
	return acquired_skills.get(skill_id, 0)

## 스킬 보유 여부
func has_skill(skill_id: String) -> bool:
	return acquired_skills.has(skill_id)

## 레벨업 시 호출 - 선택지 생성
func request_skill_selection() -> Array:
	var options: Array = []
	var candidates: Array = []

	# 업그레이드 가능한 스킬 + 새로 획득 가능한 스킬
	for skill in available_skills:
		var current_level = acquired_skills.get(skill.id, 0)
		if current_level < skill.max_level:
			candidates.append(skill)

	# 랜덤 선택
	candidates.shuffle()
	for i in range(min(selection_count, candidates.size())):
		options.append(candidates[i])

	if not options.is_empty():
		selection_required.emit(options)

	return options

## 특정 스킬의 현재 값 조회
func get_skill_value(skill_id: String) -> float:
	var level = get_skill_level(skill_id)
	if level == 0:
		return 0.0

	for skill in available_skills:
		if skill.id == skill_id:
			return skill.get_value_at_level(level)

	return 0.0

## 상태 저장
func get_state() -> Dictionary:
	return {
		"acquired_skills": acquired_skills.duplicate()
	}

## 상태 복원
func load_state(state: Dictionary) -> void:
	acquired_skills = state.get("acquired_skills", {}).duplicate()

## 리셋
func reset() -> void:
	acquired_skills.clear()

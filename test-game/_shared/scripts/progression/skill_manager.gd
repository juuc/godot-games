class_name SkillManager
extends RefCounted

## 스킬 관리자
## 획득한 스킬, 레벨, 선택 로직 담당
## 패시브 스킬 슬롯 제한 지원

signal skill_acquired(skill, level: int)
signal skill_upgraded(skill, new_level: int)
signal selection_required(options: Array)

## 최대 패시브 스킬 슬롯 수
const MAX_PASSIVE_SLOTS: int = 3

## 사용 가능한 모든 스킬 풀
var available_skills: Array[SkillData] = []

## 획득한 스킬 {skill_id: level}
var acquired_skills: Dictionary = {}

## 선택지 개수
var selection_count: int = 3

## 스킬 풀 설정
func set_skill_pool(skills: Array[SkillData]) -> void:
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
func request_skill_selection() -> Array[SkillData]:
	var options: Array[SkillData] = []
	var candidates: Array[SkillData] = []

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

## 현재 패시브 스킬 수 반환
func get_passive_count() -> int:
	var count = 0
	for skill_id in acquired_skills:
		var skill = _get_skill_by_id(skill_id)
		if skill and skill.skill_type == 0:  # PASSIVE = 0
			count += 1
	return count

## 새 패시브 스킬 획득 가능 여부
func can_acquire_passive() -> bool:
	return get_passive_count() < MAX_PASSIVE_SLOTS

## ID로 스킬 찾기
func _get_skill_by_id(skill_id: String):
	for skill in available_skills:
		if skill.id == skill_id:
			return skill
	return null

## 패시브 스킬만 선택지로 반환 (통합 선택 UI용)
func get_passive_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []

	for skill in available_skills:
		# PASSIVE 타입만 (skill_type == 0)
		if skill.skill_type != 0:
			continue

		var current_level = acquired_skills.get(skill.id, 0)

		# 최대 레벨이면 스킵
		if current_level >= skill.max_level:
			continue

		# 새 스킬인데 슬롯이 없으면 스킵
		if current_level == 0 and not can_acquire_passive():
			continue

		options.append({
			"type": "passive",
			"data": skill,
			"level": current_level
		})

	return options

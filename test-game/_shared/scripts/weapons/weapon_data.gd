class_name WeaponData
extends Resource

## 무기 데이터 리소스
## 무기의 기본 속성을 정의합니다.

@export_group("Basic Info")
@export var id: String = "default_weapon"
@export var display_name: String = "Default Weapon"
@export var description: String = ""
@export var icon: Texture2D

@export_group("Combat Stats")
## 기본 데미지
@export var base_damage: float = 1.0
## 발사 간격 (초)
@export var fire_rate: float = 0.25
## 넉백 힘
@export var knockback_force: float = 100.0

@export_group("Projectile")
## 발사체 씬
@export var projectile_scene: PackedScene
## 발사체 속도
@export var projectile_speed: float = 2000.0
## 발사체 수명
@export var projectile_lifetime: float = 0.5
## 한 번에 발사하는 발사체 수
@export var projectiles_per_shot: int = 1
## 발사체 간 각도 (다중 발사 시)
@export var spread_angle: float = 15.0

@export_group("Behavior")
## 자동 발사 여부
@export var auto_fire: bool = true
## 가장 가까운 적 자동 조준
@export var auto_aim: bool = false
## 관통 횟수 (0 = 관통 안함)
@export var pierce_count: int = 0

@export_group("Melee")
## 근접 무기 여부
@export var is_melee: bool = false
## 근접 공격 범위
@export var base_range: float = 80.0
## 슬래시 각도 (도)
@export var arc_angle: float = 120.0
## 슬래시 지속 시간
@export var slash_duration: float = 0.2

@export_group("Level Upgrades")
## 최대 레벨
@export var max_level: int = 5
## 레벨별 데미지 배율
@export var level_damage: Array[float] = []
## 레벨별 발사 속도
@export var level_fire_rate: Array[float] = []
## 레벨별 발사체 수 (샷건 등)
@export var level_projectiles: Array[int] = []
## 레벨별 범위 (근접 무기)
@export var level_range: Array[float] = []

@export_group("Audio")
## 발사 사운드
@export var fire_sound: AudioStream

## 레벨에 따른 데미지 반환
func get_damage_at_level(level: int) -> float:
	if level <= 0:
		return base_damage
	var idx = level - 1
	if level_damage.size() > idx:
		return level_damage[idx]
	return base_damage

## 레벨에 따른 발사 속도 반환
func get_fire_rate_at_level(level: int) -> float:
	if level <= 0:
		return fire_rate
	var idx = level - 1
	if level_fire_rate.size() > idx:
		return level_fire_rate[idx]
	return fire_rate

## 레벨에 따른 발사체 수 반환
func get_projectiles_at_level(level: int) -> int:
	if level <= 0:
		return projectiles_per_shot
	var idx = level - 1
	if level_projectiles.size() > idx:
		return level_projectiles[idx]
	return projectiles_per_shot

## 레벨에 따른 범위 반환 (근접 무기)
func get_range_at_level(level: int) -> float:
	if level <= 0:
		return base_range
	var idx = level - 1
	if level_range.size() > idx:
		return level_range[idx]
	return base_range

## 레벨업 시 표시할 설명
func get_upgrade_description(from_level: int, to_level: int) -> String:
	var changes: Array[String] = []

	# 데미지 변화
	if level_damage.size() >= to_level:
		var old_dmg = get_damage_at_level(from_level)
		var new_dmg = get_damage_at_level(to_level)
		if new_dmg != old_dmg:
			changes.append("DMG %.1f → %.1f" % [old_dmg, new_dmg])

	# 발사 속도 변화
	if level_fire_rate.size() >= to_level:
		var old_rate = get_fire_rate_at_level(from_level)
		var new_rate = get_fire_rate_at_level(to_level)
		if new_rate != old_rate:
			changes.append("Rate %.2fs → %.2fs" % [old_rate, new_rate])

	# 발사체 수 변화
	if level_projectiles.size() >= to_level:
		var old_proj = get_projectiles_at_level(from_level)
		var new_proj = get_projectiles_at_level(to_level)
		if new_proj != old_proj:
			changes.append("Proj %d → %d" % [old_proj, new_proj])

	# 범위 변화
	if level_range.size() >= to_level:
		var old_range = get_range_at_level(from_level)
		var new_range = get_range_at_level(to_level)
		if new_range != old_range:
			changes.append("Range %.0f → %.0f" % [old_range, new_range])

	if changes.is_empty():
		return description
	return "\n".join(changes)

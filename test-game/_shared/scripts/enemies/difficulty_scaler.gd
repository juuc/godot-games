class_name DifficultyScaler
extends RefCounted

## 난이도 스케일링 관리
##
## 웨이브 시스템, 난이도 증가, 적 스탯 스케일링을 담당합니다.
## SpawnManager에서 사용합니다.

signal wave_changed(wave: int, health_mult: float, damage_mult: float)

## Wave 설정
var difficulty_interval: float = 30.0  ## 난이도 증가 간격 (초)
var health_scale_per_wave: float = 0.1  ## 웨이브당 체력 증가율 (10%)
var damage_scale_per_wave: float = 0.05  ## 웨이브당 데미지 증가율 (5%)

## 스폰 스케일링 설정
var min_spawn_interval: float = 0.5  ## 최소 스폰 간격
var max_enemies_per_spawn: int = 10  ## 최대 동시 스폰 수

## 상태
var current_wave: int = 1
var last_wave_time: float = 0.0
var game_time: float = 0.0

## 현재 스케일링 값
var current_health_multiplier: float = 1.0
var current_damage_multiplier: float = 1.0

## 기본값 (초기화 시 저장)
var _base_spawn_interval: float
var _base_enemies_per_spawn: int

## EventBus 참조
var event_bus: Node = null

func _init() -> void:
	event_bus = Services.event_bus

## 초기값 설정
func initialize(base_spawn_interval: float, base_enemies_per_spawn: int) -> void:
	_base_spawn_interval = base_spawn_interval
	_base_enemies_per_spawn = base_enemies_per_spawn

## 설정값 로드 (SpawnManager export 변수들)
func configure(config: Dictionary) -> void:
	if config.has("difficulty_interval"):
		difficulty_interval = config.difficulty_interval
	if config.has("health_scale_per_wave"):
		health_scale_per_wave = config.health_scale_per_wave
	if config.has("damage_scale_per_wave"):
		damage_scale_per_wave = config.damage_scale_per_wave
	if config.has("min_spawn_interval"):
		min_spawn_interval = config.min_spawn_interval
	if config.has("max_enemies_per_spawn"):
		max_enemies_per_spawn = config.max_enemies_per_spawn

## 게임 시간 업데이트 및 웨이브 체크
## Returns: { spawn_interval, enemies_per_spawn } 현재 스폰 설정
func update(delta: float) -> Dictionary:
	game_time += delta
	_check_wave_advance()
	
	return {
		"spawn_interval": get_current_spawn_interval(),
		"enemies_per_spawn": get_current_enemies_per_spawn()
	}

## 웨이브 진행 체크
func _check_wave_advance() -> void:
	var time_since_last_wave = game_time - last_wave_time
	if time_since_last_wave >= difficulty_interval:
		_advance_wave()

## 웨이브 진행 (난이도 증가)
func _advance_wave() -> void:
	current_wave += 1
	last_wave_time = game_time

	# 적 스탯 스케일링
	current_health_multiplier = 1.0 + (current_wave - 1) * health_scale_per_wave
	current_damage_multiplier = 1.0 + (current_wave - 1) * damage_scale_per_wave

	# 시그널 발행
	wave_changed.emit(current_wave, current_health_multiplier, current_damage_multiplier)

	# EventBus로도 발행
	if event_bus:
		event_bus.wave_started.emit(current_wave)

	print("[Wave %d] Interval: %.2f, Spawn: %d, HP: x%.2f, DMG: x%.2f" % [
		current_wave, get_current_spawn_interval(), get_current_enemies_per_spawn(),
		current_health_multiplier, current_damage_multiplier
	])

## 현재 스폰 간격 계산
func get_current_spawn_interval() -> float:
	return maxf(min_spawn_interval, _base_spawn_interval * pow(0.9, current_wave - 1))

## 현재 동시 스폰 수 계산
func get_current_enemies_per_spawn() -> int:
	return mini(max_enemies_per_spawn, _base_enemies_per_spawn + (current_wave - 1))

## 적에게 난이도 스케일링 적용
func apply_scaling_to_enemy(enemy: EnemyBase) -> void:
	if current_wave <= 1:
		return

	# 체력 스케일링
	enemy.current_health *= current_health_multiplier

	# 데미지 스케일링
	if enemy.has_method("set_damage_multiplier"):
		enemy.set_damage_multiplier(current_damage_multiplier)
	else:
		enemy.set_meta("damage_multiplier", current_damage_multiplier)

## 초기화 (게임 재시작 시)
func reset() -> void:
	current_wave = 1
	last_wave_time = 0.0
	game_time = 0.0
	current_health_multiplier = 1.0
	current_damage_multiplier = 1.0

## 현재 웨이브 반환
func get_current_wave() -> int:
	return current_wave

## 현재 게임 시간 반환
func get_game_time() -> float:
	return game_time

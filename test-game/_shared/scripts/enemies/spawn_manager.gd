class_name SpawnManager
extends Node

## 적 스폰 관리자
## 플레이어 주변에 적을 주기적으로 스폰합니다.
## EventBus를 통해 게임 시스템과 느슨하게 결합

signal enemy_spawned(enemy: EnemyBase)
signal enemy_died(enemy: EnemyBase, position: Vector2)

@export_group("Spawn Settings")
@export var enemy_data_list: Array[EnemyData]  ## 스폰할 적 종류
@export var spawn_interval: float = 2.0  ## 스폰 간격 (초)
@export var enemies_per_spawn: int = 3  ## 한번에 스폰할 적 수
@export var max_enemies: int = 50  ## 최대 동시 적 수

@export_group("Spawn Area")
@export var min_spawn_distance: float = 300.0  ## 최소 스폰 거리
@export var max_spawn_distance: float = 400.0  ## 최대 스폰 거리

@export_group("References")
@export var player: Node2D

var spawn_timer: float = 0.0
var current_enemy_count: int = 0
var game_time: float = 0.0  ## 게임 시간 (난이도 스케일링용)
var is_spawning_enabled: bool = true

## EventBus 참조
var event_bus: Node = null

func _ready() -> void:
	# EventBus 참조
	event_bus = get_node_or_null("/root/EventBus")

	# EventBus 이벤트 구독
	if event_bus:
		event_bus.player_spawned.connect(_on_player_spawned)
		event_bus.game_over.connect(_on_game_over)
		event_bus.game_restarted.connect(_on_game_restarted)

	# 플레이어 자동 찾기
	if not player:
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group("player")

## EventBus: 플레이어 스폰 시 타겟 업데이트
func _on_player_spawned(new_player: Node2D) -> void:
	player = new_player

## EventBus: 게임 오버 시 스폰 중지
func _on_game_over(_stats: Dictionary) -> void:
	is_spawning_enabled = false

## EventBus: 게임 재시작 시 스폰 재개
func _on_game_restarted() -> void:
	is_spawning_enabled = true
	current_enemy_count = 0
	spawn_timer = 0.0

func _process(delta: float) -> void:
	if not player or not is_spawning_enabled:
		return

	game_time += delta
	spawn_timer += delta

	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_wave()

func _spawn_wave() -> void:
	if enemy_data_list.is_empty():
		return

	var to_spawn = min(enemies_per_spawn, max_enemies - current_enemy_count)

	for i in range(to_spawn):
		var enemy_data = enemy_data_list[randi() % enemy_data_list.size()]
		# 각 적마다 완전히 랜덤한 각도로 스폰
		var spawn_angle = randf_range(0, TAU)
		_spawn_enemy_at_angle(enemy_data, spawn_angle)

func _spawn_enemy_at_angle(data: EnemyData, angle: float) -> void:
	if not data or not data.scene:
		return

	if current_enemy_count >= max_enemies:
		return

	var enemy = data.scene.instantiate() as EnemyBase
	if not enemy:
		return

	# 데이터 설정
	enemy.enemy_data = data

	# 시그널 연결
	enemy.died.connect(_on_enemy_died)

	# 먼저 씬에 추가 (global_position이 제대로 동작하려면 트리에 있어야 함)
	get_tree().current_scene.add_child(enemy)

	# 그 다음 위치 설정
	var distance = randf_range(min_spawn_distance, max_spawn_distance)
	enemy.global_position = player.global_position + Vector2.RIGHT.rotated(angle) * distance

	# 타겟 설정
	enemy.set_target(player)

	current_enemy_count += 1
	enemy_spawned.emit(enemy)

	# EventBus로도 발행
	if event_bus:
		event_bus.enemy_spawned.emit(enemy)

func _spawn_enemy(data: EnemyData) -> void:
	if not data or not data.scene:
		return

	var enemy = data.scene.instantiate() as EnemyBase
	if not enemy:
		return

	# 위치 설정 (플레이어 주변 원형)
	enemy.global_position = _get_spawn_position()

	# 데이터 및 타겟 설정
	enemy.enemy_data = data
	enemy.set_target(player)

	# 시그널 연결
	enemy.died.connect(_on_enemy_died)

	# 씬에 추가
	get_tree().current_scene.add_child(enemy)
	current_enemy_count += 1

	enemy_spawned.emit(enemy)

	# EventBus로도 발행
	if event_bus:
		event_bus.enemy_spawned.emit(enemy)

func _get_spawn_position() -> Vector2:
	if not player:
		return Vector2.ZERO

	var angle = randf() * TAU
	var distance = randf_range(min_spawn_distance, max_spawn_distance)
	return player.global_position + Vector2.RIGHT.rotated(angle) * distance

func _on_enemy_died(enemy: EnemyBase, pos: Vector2) -> void:
	current_enemy_count -= 1
	enemy_died.emit(enemy, pos)

	# EventBus로도 발행 (EnemyBase에서 이미 발행하지만, 로컬 시그널 구독자용)
	# 참고: xp_value는 enemy.enemy_data에서 가져옴
	var xp_value = enemy.enemy_data.xp_value if enemy.enemy_data else 0
	if event_bus:
		event_bus.enemy_killed.emit(enemy, pos, xp_value)

## 모든 적 제거
func clear_all_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.queue_free()
	current_enemy_count = 0

## 난이도에 따른 스폰 간격 조정
func set_difficulty(difficulty_mult: float) -> void:
	spawn_interval = max(0.5, 2.0 / difficulty_mult)
	enemies_per_spawn = int(3 * difficulty_mult)

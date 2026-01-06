class_name SpawnManager
extends Node

## 적 스폰 관리자
## 플레이어 주변에 적을 주기적으로 스폰합니다.
## EventBus를 통해 게임 시스템과 느슨하게 결합
## 난이도 스케일링은 DifficultyScaler에 위임

const DifficultyScalerClass = preload("res://_shared/scripts/enemies/difficulty_scaler.gd")

signal enemy_spawned(enemy: EnemyBase)
signal enemy_died(enemy: EnemyBase, position: Vector2)
signal wave_changed(wave: int, health_mult: float, damage_mult: float)
signal boss_spawned(boss: EnemyBase)
signal boss_defeated(boss: EnemyBase, position: Vector2)

@export_group("Spawn Settings")
@export var enemy_data_list: Array[EnemyData]  ## 스폰할 적 종류
@export var spawn_interval: float = 1.5  ## 스폰 간격 (초)
@export var enemies_per_spawn: int = 5  ## 한번에 스폰할 적 수
@export var max_enemies: int = 80  ## 최대 동시 적 수

@export_group("Difficulty Scaling")
@export var enable_difficulty_scaling: bool = true  ## 시간 기반 난이도 증가
@export var difficulty_interval: float = 30.0  ## 난이도 증가 간격 (초)
@export var min_spawn_interval: float = 0.5  ## 최소 스폰 간격
@export var max_enemies_per_spawn: int = 10  ## 최대 동시 스폰 수
@export var health_scale_per_wave: float = 0.1  ## 웨이브당 체력 증가율 (10%)
@export var damage_scale_per_wave: float = 0.05  ## 웨이브당 데미지 증가율 (5%)

@export_group("Elite Settings")
@export var elite_spawn_interval: float = 60.0  ## Elite 스폰 간격 (초)
@export var elite_stat_multiplier: float = 3.0  ## Elite 스탯 배수

@export_group("Boss Settings")
@export var boss_data: EnemyData  ## 보스 데이터 (is_boss=true인 EnemyData)
@export var boss_spawn_interval: float = 300.0  ## 보스 스폰 간격 (초, 기본 5분)

@export_group("Spawn Area")
@export var min_spawn_distance: float = 400.0  ## 최소 스폰 거리
@export var max_spawn_distance: float = 550.0  ## 최대 스폰 거리
@export var cull_distance: float = 700.0  ## 이 거리 이상 적은 컬링 대상
@export var max_spawn_attempts: int = 8  ## 스폰 위치 찾기 최대 시도

@export_group("References")
@export var player: Node2D
@export var spawn_container: Node  ## 적이 추가될 컨테이너 (미설정 시 부모 노드)

var spawn_timer: float = 0.0
var elite_spawn_timer: float = 0.0  ## Elite 스폰 타이머
var boss_spawn_timer: float = 0.0  ## Boss 스폰 타이머
var current_enemy_count: int = 0  ## 일반 적 수
var current_elite_count: int = 0  ## 엘리트 적 수 (별도 관리)
var current_boss_count: int = 0  ## 보스 적 수 (별도 관리)
var is_spawning_enabled: bool = true

## 난이도 스케일러 (웨이브/스케일링 로직 위임)
var difficulty_scaler: DifficultyScalerClass

## EventBus 참조
var event_bus: Node = null

func _ready() -> void:
	# 난이도 스케일러 초기화
	difficulty_scaler = DifficultyScalerClass.new()
	difficulty_scaler.initialize(spawn_interval, enemies_per_spawn)
	difficulty_scaler.configure({
		"difficulty_interval": difficulty_interval,
		"health_scale_per_wave": health_scale_per_wave,
		"damage_scale_per_wave": damage_scale_per_wave,
		"min_spawn_interval": min_spawn_interval,
		"max_enemies_per_spawn": max_enemies_per_spawn
	})
	difficulty_scaler.wave_changed.connect(_on_wave_changed)

	# EventBus 참조
	event_bus = Services.event_bus

	# EventBus 이벤트 구독
	if event_bus:
		event_bus.player_spawned.connect(_on_player_spawned)
		event_bus.game_over.connect(_on_game_over)
		event_bus.game_restarted.connect(_on_game_restarted)

	# 플레이어 자동 찾기
	if not player:
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group("player")

## DifficultyScaler 웨이브 변경 시그널 전달
func _on_wave_changed(wave: int, health_mult: float, damage_mult: float) -> void:
	wave_changed.emit(wave, health_mult, damage_mult)

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
	current_elite_count = 0
	current_boss_count = 0
	spawn_timer = 0.0
	elite_spawn_timer = 0.0
	boss_spawn_timer = 0.0

	# 난이도 스케일러 초기화
	difficulty_scaler.reset()

## 스폰 컨테이너 반환 (명시적 설정 > 부모 노드 폴백)
func _get_spawn_container() -> Node:
	if spawn_container:
		return spawn_container
	return get_parent()

## 먼 적 컬링 (max_enemies 도달 시 호출)
## 가장 먼 non-elite 적부터 삭제
func _cull_distant_enemies(count_to_cull: int) -> int:
	if not player:
		return 0

	# non-elite 적들을 거리순으로 정렬
	var enemies_with_distance: Array[Dictionary] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if enemy.is_elite:
			continue  # elite는 컬링 대상에서 제외

		var dist = enemy.global_position.distance_to(player.global_position)
		if dist >= cull_distance:
			enemies_with_distance.append({"enemy": enemy, "distance": dist})

	# 거리 내림차순 정렬 (가장 먼 적부터)
	enemies_with_distance.sort_custom(func(a, b): return a.distance > b.distance)

	# 컬링 실행
	var culled = 0
	for i in range(min(count_to_cull, enemies_with_distance.size())):
		var enemy = enemies_with_distance[i].enemy
		if is_instance_valid(enemy):
			enemy.queue_free()
			culled += 1

	current_enemy_count -= culled
	return culled

func _process(delta: float) -> void:
	if not player or not is_spawning_enabled:
		return

	spawn_timer += delta
	elite_spawn_timer += delta
	boss_spawn_timer += delta

	# 난이도 스케일링 업데이트 (웨이브 체크 포함)
	var spawn_settings: Dictionary = {}
	if enable_difficulty_scaling:
		spawn_settings = difficulty_scaler.update(delta)

	# 현재 스폰 간격 결정
	var current_spawn_interval = spawn_settings.get("spawn_interval", spawn_interval) if enable_difficulty_scaling else spawn_interval
	var current_enemies_per_spawn = spawn_settings.get("enemies_per_spawn", enemies_per_spawn) if enable_difficulty_scaling else enemies_per_spawn

	# 일반 적 스폰
	if spawn_timer >= current_spawn_interval:
		spawn_timer = 0.0
		_spawn_enemies(current_enemies_per_spawn)

	# Elite 스폰 (시간 기반)
	if elite_spawn_timer >= elite_spawn_interval:
		elite_spawn_timer = 0.0
		_spawn_elite_enemy()

	# Boss 스폰 (시간 기반)
	if boss_spawn_timer >= boss_spawn_interval and boss_data:
		boss_spawn_timer = 0.0
		_spawn_boss()

func _spawn_enemies(count: int) -> void:
	if enemy_data_list.is_empty():
		return

	var available_slots = max_enemies - current_enemy_count
	var to_spawn = min(count, available_slots)

	# 슬롯 부족 시 먼 적 컬링 시도
	if to_spawn < count:
		var need_to_cull = count - to_spawn
		var culled = _cull_distant_enemies(need_to_cull)
		to_spawn += culled

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

	# walkable 위치 찾기 (여러 번 시도)
	var spawn_pos := Vector2.ZERO
	var found_valid_pos := false

	for _attempt in range(max_spawn_attempts):
		var test_angle = angle + randf_range(-0.5, 0.5)  # 약간의 각도 변화
		var distance = randf_range(min_spawn_distance, max_spawn_distance)
		var pos = player.global_position + Vector2.RIGHT.rotated(test_angle) * distance

		if _is_position_walkable(pos):
			spawn_pos = pos
			found_valid_pos = true
			break

	# walkable 위치를 못 찾으면 스폰 포기
	if not found_valid_pos:
		return

	var enemy = data.scene.instantiate() as EnemyBase
	if not enemy:
		return

	# 데이터 설정
	enemy.enemy_data = data

	# 시그널 연결
	enemy.died.connect(_on_enemy_died)

	# 스폰 컨테이너에 추가
	_get_spawn_container().add_child(enemy)

	# 위치 설정
	enemy.global_position = spawn_pos

	# 타겟 설정
	enemy.set_target(player)

	# 난이도 스케일링 적용 (DifficultyScaler에 위임)
	if enable_difficulty_scaling:
		difficulty_scaler.apply_scaling_to_enemy(enemy)

	current_enemy_count += 1
	enemy_spawned.emit(enemy)

	# EventBus로도 발행
	if event_bus:
		event_bus.enemy_spawned.emit(enemy)

func _get_spawn_position() -> Vector2:
	if not player:
		return Vector2.ZERO

	# 여러 번 시도해서 walkable 위치 찾기
	for _attempt in range(max_spawn_attempts):
		var angle = randf() * TAU
		var distance = randf_range(min_spawn_distance, max_spawn_distance)
		var pos = player.global_position + Vector2.RIGHT.rotated(angle) * distance

		if _is_position_walkable(pos):
			return pos

	# 실패 시 기본 위치 반환 (스폰 포기보다는 낫다)
	var fallback_angle = randf() * TAU
	var fallback_distance = randf_range(min_spawn_distance, max_spawn_distance)
	return player.global_position + Vector2.RIGHT.rotated(fallback_angle) * fallback_distance

## 위치가 walkable한지 체크 (레벨 노드에 위임)
func _is_position_walkable(pos: Vector2) -> bool:
	var level_node = get_tree().get_first_node_in_group("level")
	if level_node and level_node.has_method("is_tile_walkable"):
		return level_node.is_tile_walkable(pos)
	# 레벨 노드가 없으면 기본적으로 허용
	return true

func _on_enemy_died(enemy: EnemyBase, pos: Vector2) -> void:
	if enemy.is_elite:
		current_elite_count -= 1
	else:
		current_enemy_count -= 1
	enemy_died.emit(enemy, pos)
	# NOTE: EventBus.enemy_killed는 EnemyBase._die()에서 이미 발행됨
	# 여기서 중복 발행하면 GameManager.kill_count가 2배로 증가하는 버그 발생

## 모든 적 제거
func clear_all_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.queue_free()
	current_enemy_count = 0
	current_elite_count = 0
	current_boss_count = 0

## 자동 Elite 스폰 (타이머 기반)
func _spawn_elite_enemy() -> void:
	if enemy_data_list.is_empty():
		return

	# 랜덤 적 데이터 선택
	var enemy_data = enemy_data_list[randi() % enemy_data_list.size()]
	var elite = spawn_elite(enemy_data)

	if elite:
		print("[Elite Spawn] %s spawned at wave %d" % [enemy_data.enemy_name, difficulty_scaler.get_current_wave()])

## 엘리트 적 스폰 (max_enemies 제한 무시)
func spawn_elite(data: EnemyData, spawn_pos: Vector2 = Vector2.ZERO) -> EnemyBase:
	if not data or not data.scene:
		return null

	# 위치 결정 (walkable 체크 포함)
	var final_pos := spawn_pos
	if spawn_pos == Vector2.ZERO and player:
		var found_valid_pos := false
		for _attempt in range(max_spawn_attempts):
			var angle = randf() * TAU
			var distance = randf_range(min_spawn_distance, max_spawn_distance)
			var pos = player.global_position + Vector2.RIGHT.rotated(angle) * distance

			if _is_position_walkable(pos):
				final_pos = pos
				found_valid_pos = true
				break

		# 위치를 못 찾으면 스폰 포기
		if not found_valid_pos:
			return null

	var enemy = data.scene.instantiate() as EnemyBase
	if not enemy:
		return null

	enemy.enemy_data = data

	enemy.died.connect(_on_enemy_died)

	_get_spawn_container().add_child(enemy)

	# 위치 설정
	enemy.global_position = final_pos

	if player:
		enemy.set_target(player)

	# Elite 시각 효과 및 스탯 적용
	enemy.apply_elite_visuals(elite_stat_multiplier)

	# 엘리트에도 난이도 스케일링 적용
	if enable_difficulty_scaling:
		difficulty_scaler.apply_scaling_to_enemy(enemy)

	current_elite_count += 1
	enemy_spawned.emit(enemy)

	if event_bus:
		event_bus.enemy_spawned.emit(enemy)

	return enemy

## 보스 스폰
func _spawn_boss() -> void:
	if not boss_data or not boss_data.scene:
		return
	
	var boss = spawn_boss(boss_data)
	if boss:
		print("[Boss Spawn] %s spawned at wave %d (game time: %.0fs)" % [
			boss_data.enemy_name,
			difficulty_scaler.get_current_wave(),
			difficulty_scaler.get_game_time()
		])

## 보스 스폰 (공개 메서드 - 외부에서 호출 가능)
func spawn_boss(data: EnemyData, spawn_pos: Vector2 = Vector2.ZERO) -> EnemyBase:
	if not data or not data.scene:
		return null
	
	# 위치 결정 (walkable 체크 포함)
	var final_pos := spawn_pos
	if spawn_pos == Vector2.ZERO and player:
		var found_valid_pos := false
		for _attempt in range(max_spawn_attempts):
			var angle = randf() * TAU
			var distance = randf_range(min_spawn_distance, max_spawn_distance)
			var pos = player.global_position + Vector2.RIGHT.rotated(angle) * distance
			
			if _is_position_walkable(pos):
				final_pos = pos
				found_valid_pos = true
				break
		
		# 위치를 못 찾으면 스폰 포기
		if not found_valid_pos:
			return null
	
	var boss = data.scene.instantiate() as EnemyBase
	if not boss:
		return null
	
	boss.enemy_data = data
	boss.died.connect(_on_boss_died)
	
	_get_spawn_container().add_child(boss)
	boss.global_position = final_pos
	
	if player:
		boss.set_target(player)
	
	# 난이도 스케일링 적용
	if enable_difficulty_scaling:
		difficulty_scaler.apply_scaling_to_enemy(boss)
	
	current_boss_count += 1
	boss_spawned.emit(boss)
	
	if event_bus and event_bus.has_signal("boss_spawned"):
		event_bus.boss_spawned.emit(boss)
	
	return boss

func _on_boss_died(boss: EnemyBase, pos: Vector2) -> void:
	current_boss_count -= 1
	boss_defeated.emit(boss, pos)
	
	if event_bus and event_bus.has_signal("boss_defeated"):
		event_bus.boss_defeated.emit(boss, pos)

## 난이도에 따른 스폰 간격 조정
func set_difficulty(difficulty_mult: float) -> void:
	spawn_interval = max(0.5, 2.0 / difficulty_mult)
	enemies_per_spawn = int(3 * difficulty_mult)

## 씬 정리 시 시그널 연결 해제 (메모리 누수 방지)
func _exit_tree() -> void:
	if event_bus and is_instance_valid(event_bus):
		if event_bus.player_spawned.is_connected(_on_player_spawned):
			event_bus.player_spawned.disconnect(_on_player_spawned)
		if event_bus.game_over.is_connected(_on_game_over):
			event_bus.game_over.disconnect(_on_game_over)
		if event_bus.game_restarted.is_connected(_on_game_restarted):
			event_bus.game_restarted.disconnect(_on_game_restarted)

## 현재 웨이브 반환
func get_current_wave() -> int:
	return difficulty_scaler.get_current_wave()

## 현재 게임 시간 반환
func get_game_time() -> float:
	return difficulty_scaler.get_game_time()

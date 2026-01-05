extends Node2D

## 레벨 - 게임 흐름 관리 및 시스템 조합
##
## ChunkManager를 사용하여 월드를 생성하고,
## 게임 플로우(플레이어, 이벤트)를 관리합니다.
## 530줄 → ~140줄로 리팩토링됨

const ResourcePathsClass = preload("res://_shared/scripts/core/resource_paths.gd")
const ChunkManagerClass = preload("res://_shared/scripts/world_generator/chunk_manager.gd")

# --- Configuration ---
@export var world_config: WorldConfig
@export var debug_noise_layer: bool = false

# --- Child References ---
@onready var tile_map: TileMap = $TileMap

# --- Runtime State ---
var player: Node2D = null
var chunk_manager: ChunkManagerClass

# --- Debug Visualization ---
var debug_container: Node2D

# --- Core System References ---
var game_manager: Node = null
var event_bus: Node = null

# --- Loading Screen ---
var loading_screen: CanvasLayer = null

func _ready() -> void:
	# 미니맵 등에서 참조할 수 있도록 그룹 추가
	add_to_group("level")

	# 로딩 화면 생성
	_setup_loading_screen()

	# Core system references
	game_manager = Services.game_manager
	event_bus = Services.event_bus

	# EventBus 이벤트 구독 (느슨한 결합)
	if event_bus:
		event_bus.player_died.connect(_on_player_died_event)

	# Load default config if not set
	if not world_config:
		world_config = preload("res://resources/world_config.tres")

	# ChunkManager 초기화
	_setup_chunk_manager()

	# 디버그 컨테이너 설정
	_setup_debug_container()

	# 플레이어 찾기 및 스폰 위치 설정
	_setup_player()

	# 초기 청크 로딩 시작
	if player:
		chunk_manager.start_loading_around(player.position)
	else:
		_finish_initial_loading()

## ChunkManager 설정
func _setup_chunk_manager() -> void:
	chunk_manager = ChunkManagerClass.new(world_config, tile_map)
	chunk_manager.initialize()

	# 시그널 연결
	chunk_manager.initial_load_complete.connect(_on_initial_load_complete)
	chunk_manager.loading_progress.connect(_on_loading_progress)

## 디버그 컨테이너 설정
func _setup_debug_container() -> void:
	debug_container = Node2D.new()
	debug_container.name = "DebugNoise"
	debug_container.z_index = 4
	add_child(debug_container)
	chunk_manager.set_debug_container(debug_container)

## 로딩 화면 설정
func _setup_loading_screen() -> void:
	var loading_scene = ResourcePathsClass.load_scene(ResourcePathsClass.UI_LOADING_SCREEN)
	if loading_scene:
		loading_screen = loading_scene.instantiate()
		add_child(loading_screen)

## 플레이어 설정 (동적 탐색 및 스폰)
func _setup_player() -> void:
	# 씬 내 플레이어 또는 그룹에서 찾기 (EntityLayer 안에 있을 수 있음)
	player = get_node_or_null("EntityLayer/Player")
	if not player:
		player = get_node_or_null("Player")
	if not player:
		player = get_tree().get_first_node_in_group("player")

	if not player:
		return

	# 안전한 스폰 위치 설정
	var spawn_tile = chunk_manager.find_safe_spawn()
	player.position = tile_map.map_to_local(spawn_tile)

	# EventBus로 플레이어 스폰 알림
	if event_bus:
		event_bus.player_spawned.emit(player)

## 로딩 진행률 업데이트
func _on_loading_progress(progress: float) -> void:
	if loading_screen:
		loading_screen.update_progress(progress)

## 초기 로딩 완료
func _on_initial_load_complete() -> void:
	_finish_initial_loading()

## 초기 로딩 완료 처리
func _finish_initial_loading() -> void:
	# GameManager에 레벨 등록 및 게임 시작
	if game_manager:
		game_manager.register_level(self)
		game_manager.start_game()

	# 로딩 화면 숨기기
	if loading_screen:
		loading_screen.finish_loading()

## 플레이어 사망 이벤트 처리 (EventBus에서 수신)
func _on_player_died_event(_player: Node2D, _position: Vector2) -> void:
	# EventBus 통해 GameManager가 이미 처리하므로 여기서는 추가 로직만
	pass

## 적 처치 시 호출 (하위 호환성) - 새 코드는 EventBus.enemy_killed 사용 권장
func on_enemy_killed(xp_value: int = 0) -> void:
	# EventBus가 없을 때를 위한 폴백
	if game_manager and not event_bus:
		game_manager.kill_count += 1
		game_manager.total_xp += xp_value

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if debug_container:
			debug_container.visible = not debug_container.visible

func _process(_delta: float) -> void:
	# 초기 로딩 중에는 game_over 체크 무시 (청크 로딩 필요)
	if not chunk_manager.is_initial_load:
		var is_game_over = game_manager.is_game_over if game_manager else false
		if is_game_over:
			return

	if not player:
		return

	chunk_manager.update(player.position)

## 타일이 걸을 수 있는지 확인 (외부 API)
func is_tile_walkable(global_pos: Vector2) -> bool:
	var map_pos = tile_map.local_to_map(global_pos)
	return chunk_manager.is_tile_walkable(map_pos)

## 씬 정리 시 시그널 연결 해제 (메모리 누수 방지)
func _exit_tree() -> void:
	if event_bus and is_instance_valid(event_bus):
		if event_bus.player_died.is_connected(_on_player_died_event):
			event_bus.player_died.disconnect(_on_player_died_event)

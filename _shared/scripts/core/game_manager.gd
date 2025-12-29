extends Node

## 게임 상태 관리자 (싱글톤)
## 게임 흐름, 통계, 상태를 중앙에서 관리
##
## 사용법:
## 1. autoload로 등록: GameManager
## 2. 상태 조회: GameManager.is_game_over, GameManager.game_time
## 3. 이벤트: EventBus 시그널 사용

# --- Game State ---
enum GameState {
	NONE,
	INITIALIZING,
	PLAYING,
	PAUSED,
	GAME_OVER
}

var current_state: GameState = GameState.NONE
var previous_state: GameState = GameState.NONE

# --- Game Statistics ---
var game_time: float = 0.0
var kill_count: int = 0
var total_xp: int = 0
var current_wave: int = 0

# --- References ---
var player: Node2D = null
var current_level: Node2D = null

# --- Convenience Properties ---
var is_playing: bool:
	get: return current_state == GameState.PLAYING

var is_paused: bool:
	get: return current_state == GameState.PAUSED

var is_game_over: bool:
	get: return current_state == GameState.GAME_OVER

# --- EventBus Reference ---
var event_bus: Node = null

func _ready() -> void:
	# EventBus 찾기 (autoload로 등록된 경우)
	event_bus = get_node_or_null("/root/EventBus")

	if event_bus:
		_connect_events()

func _connect_events() -> void:
	# 플레이어 이벤트
	event_bus.player_spawned.connect(_on_player_spawned)
	event_bus.player_died.connect(_on_player_died)
	event_bus.player_level_up.connect(_on_player_level_up)

	# 적 이벤트
	event_bus.enemy_killed.connect(_on_enemy_killed)

	# 픽업 이벤트
	event_bus.xp_gained.connect(_on_xp_gained)

	# 웨이브 이벤트
	event_bus.wave_started.connect(_on_wave_started)
	event_bus.wave_completed.connect(_on_wave_completed)

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		game_time += delta

# --- Game Flow ---

## 게임 시작
func start_game() -> void:
	_reset_stats()
	_change_state(GameState.PLAYING)

	if event_bus:
		event_bus.game_started.emit()

## 게임 일시정지
func pause_game() -> void:
	if current_state != GameState.PLAYING:
		return

	_change_state(GameState.PAUSED)
	get_tree().paused = true

	if event_bus:
		event_bus.game_paused.emit()

## 게임 재개
func resume_game() -> void:
	if current_state != GameState.PAUSED:
		return

	_change_state(GameState.PLAYING)
	get_tree().paused = false

	if event_bus:
		event_bus.game_resumed.emit()

## 게임 오버
func trigger_game_over() -> void:
	if current_state == GameState.GAME_OVER:
		return

	_change_state(GameState.GAME_OVER)

	var stats = get_final_stats()

	if event_bus:
		event_bus.game_over.emit(stats)

## 게임 재시작
func restart_game() -> void:
	get_tree().paused = false
	_reset_stats()

	if event_bus:
		event_bus.game_restarted.emit()

	get_tree().reload_current_scene()

# --- Stats Management ---

func _reset_stats() -> void:
	game_time = 0.0
	kill_count = 0
	total_xp = 0
	current_wave = 0
	player = null

## 최종 통계 반환
func get_final_stats() -> Dictionary:
	var player_level = 1
	if player and player.has_method("get") and "current_level" in player:
		player_level = player.current_level
	elif player and "current_level" in player:
		player_level = player.current_level

	return {
		"level": player_level,
		"kills": kill_count,
		"time": game_time,
		"xp": total_xp,
		"wave": current_wave
	}

## 포맷된 시간 문자열 반환
func get_formatted_time() -> String:
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	return "%d:%02d" % [minutes, seconds]

# --- State Management ---

func _change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	previous_state = current_state
	current_state = new_state

	_on_state_changed(previous_state, new_state)

## 상태 변경 시 호출 (오버라이드 가능)
func _on_state_changed(_old_state: GameState, _new_state: GameState) -> void:
	pass

# --- Event Handlers ---

func _on_player_spawned(p: Node2D) -> void:
	player = p

func _on_player_died(_p: Node2D, _position: Vector2) -> void:
	trigger_game_over()

func _on_player_level_up(_p: Node2D, _new_level: int) -> void:
	pass

func _on_enemy_killed(_enemy: Node2D, _position: Vector2, xp_value: int) -> void:
	kill_count += 1
	total_xp += xp_value

func _on_xp_gained(amount: int, _total: int) -> void:
	total_xp += amount

func _on_wave_started(wave_number: int) -> void:
	current_wave = wave_number

func _on_wave_completed(_wave_number: int) -> void:
	pass

# --- Level Registration ---

## 레벨이 자신을 등록
func register_level(level: Node2D) -> void:
	current_level = level

## 레벨 등록 해제
func unregister_level() -> void:
	current_level = null

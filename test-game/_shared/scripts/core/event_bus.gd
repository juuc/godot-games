extends Node

## 전역 이벤트 버스 (싱글톤)
## 시스템 간 느슨한 결합을 위한 중앙 이벤트 허브
##
## 사용법:
## 1. autoload로 등록: EventBus
## 2. 이벤트 발생: EventBus.enemy_killed.emit(enemy, position)
## 3. 이벤트 수신: EventBus.enemy_killed.connect(_on_enemy_killed)

# --- Game Flow Events ---
signal game_started
signal game_paused
signal game_resumed
signal game_over(stats: Dictionary)
signal game_restarted

# --- Player Events ---
signal player_spawned(player: Node2D)
signal player_died(player: Node2D, position: Vector2)
signal player_damaged(player: Node2D, amount: float, current_health: float)
signal player_healed(player: Node2D, amount: float, current_health: float)
signal player_level_up(player: Node2D, new_level: int)

# --- Enemy Events ---
signal enemy_spawned(enemy: Node2D)
signal enemy_killed(enemy: Node2D, position: Vector2, xp_value: int)
signal enemy_damaged(enemy: Node2D, amount: float)

# --- Combat Events ---
signal damage_dealt(source: Node2D, target: Node2D, amount: float)
signal projectile_fired(projectile: Node2D, source: Node2D)
signal projectile_hit(projectile: Node2D, target: Node2D)

# --- Pickup Events ---
signal pickup_spawned(pickup: Node2D, position: Vector2)
signal pickup_collected(pickup: Node2D, collector: Node2D)
signal xp_gained(amount: int, total: int)

# --- Skill Events ---
signal skill_acquired(skill, level: int)
signal skill_upgraded(skill, level: int)
signal skill_selection_requested(options: Array)
signal skill_selected(skill)

# --- Wave/Spawn Events ---
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal spawn_requested(enemy_type: String, position: Vector2)

# --- UI Events ---
signal ui_show_requested(ui_name: String, data: Dictionary)
signal ui_hide_requested(ui_name: String)
signal notification_requested(message: String, duration: float)

# --- Debug ---
var _debug_mode: bool = false

func _ready() -> void:
	# 디버그 모드에서 모든 이벤트 로깅
	if OS.is_debug_build():
		_debug_mode = false  # 필요시 true로 변경

func enable_debug() -> void:
	_debug_mode = true
	print("[EventBus] Debug mode enabled")

func disable_debug() -> void:
	_debug_mode = false

## 디버그용 이벤트 로깅 헬퍼
func _log_event(event_name: String, args: Array = []) -> void:
	if _debug_mode:
		print("[EventBus] %s: %s" % [event_name, str(args)])

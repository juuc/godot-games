extends Node

## 전역 이벤트 버스 (싱글톤)
## 시스템 간 느슨한 결합을 위한 중앙 이벤트 허브
##
## 사용법:
## 1. autoload로 등록: EventBus
## 2. 이벤트 발생: EventBus.enemy_killed.emit(enemy, position)
## 3. 이벤트 수신: EventBus.enemy_killed.connect(_on_enemy_killed)

# EventBus 시그널은 외부 클래스에서 emit/connect 되므로 unused_signal 경고 무시
# --- Game Flow Events ---
@warning_ignore("unused_signal")
signal game_started
@warning_ignore("unused_signal")
signal game_paused
@warning_ignore("unused_signal")
signal game_resumed
@warning_ignore("unused_signal")
signal game_over(stats: Dictionary)
@warning_ignore("unused_signal")
signal game_restarted

# --- Timer Events ---
@warning_ignore("unused_signal")
signal timer_updated(remaining: float, total: float)
@warning_ignore("unused_signal")
signal cycle_completed(cycle_number: int)

# --- Player Events ---
@warning_ignore("unused_signal")
signal player_spawned(player: Node2D)
@warning_ignore("unused_signal")
signal player_died(player: Node2D, position: Vector2)
@warning_ignore("unused_signal")
signal player_damaged(player: Node2D, amount: float, current_health: float)
@warning_ignore("unused_signal")
signal player_healed(player: Node2D, amount: float, current_health: float)
@warning_ignore("unused_signal")
signal player_level_up(player: Node2D, new_level: int)

# --- Enemy Events ---
@warning_ignore("unused_signal")
signal enemy_spawned(enemy: Node2D)
@warning_ignore("unused_signal")
signal enemy_killed(enemy: Node2D, position: Vector2, xp_value: int)
@warning_ignore("unused_signal")
signal enemy_damaged(enemy: Node2D, amount: float)

# --- Combat Events ---
@warning_ignore("unused_signal")
signal damage_dealt(source: Node2D, target: Node2D, amount: float)  ## TODO: 데미지 팝업 구현 시
@warning_ignore("unused_signal")
signal projectile_fired(projectile: Node2D, source: Node2D)
@warning_ignore("unused_signal")
signal projectile_hit(projectile: Node2D, target: Node2D)  ## TODO: 원거리 적 구현 시

# --- Pickup Events ---
@warning_ignore("unused_signal")
signal pickup_spawned(pickup: Node2D, position: Vector2)
@warning_ignore("unused_signal")
signal pickup_collected(pickup: Node2D, collector: Node2D)
@warning_ignore("unused_signal")
signal xp_gained(amount: int, total: int)
@warning_ignore("unused_signal")
signal treasure_collected(chest: Node, player: Node)  ## 보물상자 획득

# --- Skill Events ---
@warning_ignore("unused_signal")
signal skill_acquired(skill, level: int)  ## TODO: 스킬 시스템 확장 시
@warning_ignore("unused_signal")
signal skill_upgraded(skill, level: int)
@warning_ignore("unused_signal")
signal skill_selection_requested(options: Array)
@warning_ignore("unused_signal")
signal skill_selected(skill)

# --- Wave/Spawn Events ---
@warning_ignore("unused_signal")
signal wave_started(wave_number: int)
@warning_ignore("unused_signal")
signal wave_completed(wave_number: int)  ## TODO: 웨이브 완료 emit 추가 필요
@warning_ignore("unused_signal")
signal spawn_requested(enemy_type: String, position: Vector2)

# --- UI Events ---
@warning_ignore("unused_signal")
signal ui_show_requested(ui_name: String, data: Dictionary)  ## TODO: UI 관리 시스템 구현 시
@warning_ignore("unused_signal")
signal ui_hide_requested(ui_name: String)
@warning_ignore("unused_signal")
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

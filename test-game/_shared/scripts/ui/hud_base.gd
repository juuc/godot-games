class_name HudBase
extends CanvasLayer

## HUD 베이스 클래스
## 체력바, XP바, 레벨 표시

## 플레이어 참조
var player: Node

## UI 요소 참조 (자식에서 설정)
var health_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label

func _ready() -> void:
	# UI가 항상 보이도록
	layer = 5

	_setup_ui()

	# 플레이어 찾기
	await get_tree().process_frame
	_find_and_connect_player()

## UI 초기화 (자식에서 오버라이드)
func _setup_ui() -> void:
	pass

## 플레이어 찾기 및 시그널 연결
func _find_and_connect_player() -> void:
	player = get_tree().get_first_node_in_group("player")

	if player:
		_connect_player_signals()
		_update_health(player.current_health, player.max_health)
		_update_xp(player.current_xp, player.xp_to_next_level)
		_update_level(player.current_level)

## 플레이어 시그널 연결
func _connect_player_signals() -> void:
	if player.has_signal("health_changed"):
		player.health_changed.connect(_update_health)
	if player.has_signal("xp_changed"):
		player.xp_changed.connect(_update_xp)
	if player.has_signal("level_up"):
		player.level_up.connect(_update_level)

## 체력바 업데이트
func _update_health(current: float, max_health: float) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current

## XP바 업데이트
func _update_xp(current: int, required: int) -> void:
	if xp_bar:
		xp_bar.max_value = required
		xp_bar.value = current

## 레벨 업데이트
func _update_level(new_level: int) -> void:
	if level_label:
		level_label.text = "Lv.%d" % new_level

## 씬 정리 시 시그널 연결 해제
func _exit_tree() -> void:
	_disconnect_player_signals()

## 플레이어 시그널 연결 해제 (메모리 누수 방지)
func _disconnect_player_signals() -> void:
	if not player or not is_instance_valid(player):
		return

	if player.has_signal("health_changed") and player.health_changed.is_connected(_update_health):
		player.health_changed.disconnect(_update_health)
	if player.has_signal("xp_changed") and player.xp_changed.is_connected(_update_xp):
		player.xp_changed.disconnect(_update_xp)
	if player.has_signal("level_up") and player.level_up.is_connected(_update_level):
		player.level_up.disconnect(_update_level)

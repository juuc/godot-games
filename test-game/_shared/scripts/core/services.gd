extends Node

## 서비스 로케이터 (싱글톤)
## Autoload 참조를 중앙에서 관리하여 반복 코드 제거
##
## 사용법:
## - Services.event_bus.some_signal.emit(...)
## - Services.game_manager.start_game()
## - if Services.is_playing(): ...

# --- Cached Service References (lazy initialization) ---
var _event_bus: Node = null
var _game_manager: Node = null
var _stats_manager: Node = null
var _audio_manager: Node = null

# --- Game Config ---
var _game_config: Resource = null

# --- Typed Getters (null-safe, cached) ---

## EventBus 참조
var event_bus: Node:
	get:
		if not _event_bus:
			_event_bus = get_node_or_null("/root/EventBus")
		return _event_bus

## GameManager 참조
var game_manager: Node:
	get:
		if not _game_manager:
			_game_manager = get_node_or_null("/root/GameManager")
		return _game_manager

## StatsManager 참조
var stats_manager: Node:
	get:
		if not _stats_manager:
			_stats_manager = get_node_or_null("/root/StatsManager")
		return _stats_manager

## AudioManager 참조
var audio_manager: Node:
	get:
		if not _audio_manager:
			_audio_manager = get_node_or_null("/root/AudioManager")
		return _audio_manager

## GameConfig 참조
var config: Resource:
	get:
		if not _game_config:
			_game_config = preload("res://resources/game_config.tres")
		return _game_config

# --- Convenience Properties ---

## 게임 플레이 중 여부
var is_playing: bool:
	get: return game_manager and game_manager.is_playing

## 게임 오버 여부
var is_game_over: bool:
	get: return game_manager and game_manager.is_game_over

## 게임 일시정지 여부
var is_paused: bool:
	get: return game_manager and game_manager.is_paused

# --- Helper Methods ---

## 이벤트 발행 헬퍼 (null-safe)
func emit_event(signal_name: StringName, args: Array = []) -> void:
	if event_bus and event_bus.has_signal(signal_name):
		match args.size():
			0: event_bus.emit_signal(signal_name)
			1: event_bus.emit_signal(signal_name, args[0])
			2: event_bus.emit_signal(signal_name, args[0], args[1])
			3: event_bus.emit_signal(signal_name, args[0], args[1], args[2])
			_: push_warning("Services.emit_event: Too many arguments")

## 캐시 초기화 (씬 전환 시 호출 가능)
func clear_cache() -> void:
	_event_bus = null
	_game_manager = null
	_stats_manager = null
	_audio_manager = null

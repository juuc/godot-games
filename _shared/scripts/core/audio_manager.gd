extends Node

## 오디오 매니저 (싱글톤)
## 사운드 효과와 음악을 중앙에서 관리합니다.
## EventBus 이벤트에 반응하여 자동으로 사운드를 재생할 수 있습니다.

# --- Volume Settings ---
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 0.7
var ui_volume: float = 1.0

# --- Audio Player Pools ---
var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_pool_size: int = 16

# --- Music Player ---
var music_player: AudioStreamPlayer = null
var current_music: AudioStream = null

# --- Sound Library ---
## 사운드 ID → AudioStream 매핑
var sound_library: Dictionary = {}

# --- EventBus 참조 ---
var event_bus: Node = null

func _ready() -> void:
	# SFX 풀 생성
	for i in range(sfx_pool_size):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_pool.append(player)

	# 음악 플레이어 생성
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	# EventBus 연동
	event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		_connect_event_bus()

## EventBus 이벤트 구독
func _connect_event_bus() -> void:
	# 게임 이벤트에 사운드 연결 (사운드가 등록된 경우에만 재생)
	event_bus.player_damaged.connect(_on_player_damaged)
	event_bus.player_died.connect(_on_player_died)
	event_bus.player_level_up.connect(_on_player_level_up)
	event_bus.enemy_killed.connect(_on_enemy_killed)
	event_bus.pickup_collected.connect(_on_pickup_collected)

# --- EventBus 핸들러 ---

func _on_player_damaged(_player: Node2D, _amount: float, _health: float) -> void:
	play_sfx("player_hit")

func _on_player_died(_player: Node2D, _pos: Vector2) -> void:
	play_sfx("player_death")

func _on_player_level_up(_player: Node2D, _level: int) -> void:
	play_sfx("level_up")

func _on_enemy_killed(_enemy: Node2D, _pos: Vector2, _xp: int) -> void:
	play_sfx("enemy_death")

func _on_pickup_collected(_pickup: Node2D, _collector: Node2D) -> void:
	play_sfx("pickup")

# --- Public API ---

## 사운드 라이브러리에 사운드 등록
func register_sound(id: String, stream: AudioStream) -> void:
	sound_library[id] = stream

## 사운드 라이브러리에서 사운드 제거
func unregister_sound(id: String) -> void:
	sound_library.erase(id)

## ID로 SFX 재생
func play_sfx(sound_id: String, volume_db: float = 0.0) -> void:
	if not sound_library.has(sound_id):
		return  # 등록되지 않은 사운드는 무시

	play_sound(sound_library[sound_id], volume_db)

## AudioStream으로 SFX 재생
func play_sound(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return

	var player = _get_available_player()
	if player:
		player.stream = stream
		player.volume_db = volume_db + linear_to_db(sfx_volume * master_volume)
		player.play()

## 특정 위치에서 2D SFX 재생
func play_sound_at(stream: AudioStream, position: Vector2, volume_db: float = 0.0) -> void:
	if not stream:
		return

	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = volume_db + linear_to_db(sfx_volume * master_volume)
	player.bus = "SFX"
	player.global_position = position

	get_tree().current_scene.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

## 음악 재생
func play_music(stream: AudioStream, fade_in: float = 0.5) -> void:
	if stream == current_music:
		return

	current_music = stream
	music_player.stream = stream
	music_player.volume_db = linear_to_db(music_volume * master_volume)

	if fade_in > 0:
		music_player.volume_db = -80
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db",
			linear_to_db(music_volume * master_volume), fade_in)

	music_player.play()

## 음악 정지
func stop_music(fade_out: float = 0.5) -> void:
	if fade_out > 0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_out)
		tween.tween_callback(music_player.stop)
	else:
		music_player.stop()

	current_music = null

## 음악 일시정지
func pause_music() -> void:
	music_player.stream_paused = true

## 음악 재개
func resume_music() -> void:
	music_player.stream_paused = false

# --- Volume Control ---

## 마스터 볼륨 설정 (0.0 ~ 1.0)
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	_update_music_volume()

## SFX 볼륨 설정 (0.0 ~ 1.0)
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)

## 음악 볼륨 설정 (0.0 ~ 1.0)
func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	_update_music_volume()

func _update_music_volume() -> void:
	if music_player and music_player.playing:
		music_player.volume_db = linear_to_db(music_volume * master_volume)

# --- Internal ---

## 사용 가능한 오디오 플레이어 반환
func _get_available_player() -> AudioStreamPlayer:
	for player in sfx_pool:
		if not player.playing:
			return player

	# 모든 플레이어가 사용 중이면 가장 오래된 것 재사용
	return sfx_pool[0]

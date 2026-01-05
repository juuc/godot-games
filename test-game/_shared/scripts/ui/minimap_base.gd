extends Control

## 미니맵 베이스 클래스

const MinimapPOIConfig = preload("res://_shared/scripts/ui/minimap_poi_config.gd")
## 지형 렌더링 + POI 시스템
##
## 사용법:
## 1. 이 클래스를 상속
## 2. _get_terrain_color() 오버라이드하여 지형 색상 정의
## 3. POI 설정 추가 (add_poi_config)
## 4. 엔티티가 그룹에 속하면 자동 표시, 또는 register_poi() 수동 호출

signal poi_clicked(poi_type: String, world_position: Vector2)

## 설정
@export_group("Size")
@export var minimap_size: Vector2 = Vector2(150, 150)
@export var world_radius: float = 300.0  ## 미니맵에 표시할 월드 반경

@export_group("Update")
@export var terrain_update_interval: float = 0.5  ## 지형 업데이트 주기
@export var poi_update_interval: float = 0.1  ## POI 업데이트 주기
@export var terrain_resolution: int = 2  ## 지형 샘플링 해상도 (높을수록 성능↓ 품질↑)

@export_group("Appearance")
@export var background_color: Color = Color(0.1, 0.1, 0.1, 0.8)
@export var border_color: Color = Color.WHITE
@export var border_width: float = 2.0
@export var player_indicator_size: float = 4.0

## 지형 색상 (자식에서 오버라이드 또는 설정)
var terrain_colors: Dictionary = {
	"water": Color("#3498db"),
	"sand": Color("#f1c40f"),
	"grass": Color("#2ecc71"),
	"cliff": Color("#8b4513"),
	"unknown": Color("#333333")
}

## POI 설정 {poi_type: MinimapPOIConfig}
var poi_configs: Dictionary = {}

## 내부 상태
var player: Node2D
var world_generator  ## WorldGenerator 참조 (옵션)
var tile_size: int = 16  ## 타일 크기 (픽셀)

var terrain_image: Image
var terrain_texture: ImageTexture
var terrain_update_timer: float = 0.0
var poi_update_timer: float = 0.0
var last_terrain_center: Vector2 = Vector2.INF

## 활성 POI 목록 [{type, position, node, config}]
var active_pois: Array[Dictionary] = []

## 수동 등록된 POI {node: poi_data}
var registered_pois: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = minimap_size

	_setup_default_poi_configs()
	_setup_terrain_texture()

	await get_tree().process_frame
	_find_player()
	_on_ready()

## 자식 클래스에서 추가 초기화
func _on_ready() -> void:
	pass

## 기본 POI 설정 (자식에서 오버라이드하여 추가 가능)
func _setup_default_poi_configs() -> void:
	# 플레이어
	var player_config = MinimapPOIConfig.new()
	player_config.poi_type = "player"
	player_config.display_name = "Player"
	player_config.color = Color.WHITE
	player_config.size = player_indicator_size
	player_config.priority = 100
	player_config.blink = true
	player_config.blink_speed = 8.0
	poi_configs["player"] = player_config

	# 적
	var enemy_config = MinimapPOIConfig.new()
	enemy_config.poi_type = "enemy"
	enemy_config.display_name = "Enemy"
	enemy_config.color = Color("#e74c3c")
	enemy_config.size = 2.0
	enemy_config.priority = 10
	enemy_config.group_name = "enemies"
	poi_configs["enemy"] = enemy_config

## POI 설정 추가 (게임에서 호출)
func add_poi_config(config: MinimapPOIConfig) -> void:
	poi_configs[config.poi_type] = config

## POI 설정 일괄 추가
func add_poi_configs(configs: Array) -> void:
	for config in configs:
		add_poi_config(config)

func _setup_terrain_texture() -> void:
	var tex_size = int(minimap_size.x / terrain_resolution)
	terrain_image = Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	terrain_image.fill(background_color)
	terrain_texture = ImageTexture.create_from_image(terrain_image)

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")

## WorldGenerator 연결 (지형 색상 자동 결정)
func set_world_generator(generator) -> void:
	world_generator = generator

func _process(delta: float) -> void:
	if not player:
		_find_player()
		return

	# 지형 업데이트
	terrain_update_timer += delta
	if terrain_update_timer >= terrain_update_interval:
		terrain_update_timer = 0.0
		_update_terrain()

	# POI 업데이트
	poi_update_timer += delta
	if poi_update_timer >= poi_update_interval:
		poi_update_timer = 0.0
		_update_pois()

	queue_redraw()

## 지형 업데이트
func _update_terrain() -> void:
	if not player:
		return

	var center = player.global_position

	# 이동 거리가 작으면 스킵 (최적화)
	if last_terrain_center.distance_to(center) < world_radius * 0.1:
		return
	last_terrain_center = center

	var tex_size = terrain_image.get_width()
	var world_scale = world_radius * 2.0 / tex_size

	for x in range(tex_size):
		for y in range(tex_size):
			var world_x = center.x + (x - tex_size / 2.0) * world_scale
			var world_y = center.y + (y - tex_size / 2.0) * world_scale

			var color = _get_terrain_color(int(world_x), int(world_y))
			terrain_image.set_pixel(x, y, color)

	terrain_texture.update(terrain_image)

## 지형 색상 결정 (자식에서 오버라이드)
func _get_terrain_color(world_x: int, world_y: int) -> Color:
	if world_generator and world_generator.has_method("get_biome_at"):
		# 월드 좌표(픽셀)를 타일 좌표로 변환
		@warning_ignore("integer_division")
		var tile_x := world_x / tile_size
		@warning_ignore("integer_division")
		var tile_y := world_y / tile_size
		var biome = world_generator.get_biome_at(tile_x, tile_y)

		# 레이어 우선순위에 따라 색상 결정
		if biome.has(3):  # cliff
			return terrain_colors.get("cliff", terrain_colors["unknown"])
		elif biome.has(2):  # grass
			return terrain_colors.get("grass", terrain_colors["unknown"])
		elif biome.has(1):  # sand
			return terrain_colors.get("sand", terrain_colors["unknown"])
		elif biome.has(0):  # water
			return terrain_colors.get("water", terrain_colors["unknown"])

	return terrain_colors.get("unknown", Color.BLACK)

## POI 업데이트
func _update_pois() -> void:
	active_pois.clear()

	# 플레이어 추가
	if player:
		active_pois.append({
			"type": "player",
			"position": player.global_position,
			"node": player,
			"config": poi_configs.get("player")
		})

	# 그룹 기반 자동 수집
	for poi_type in poi_configs:
		var config = poi_configs[poi_type]
		if config.group_name.is_empty() or not config.show_on_minimap:
			continue

		var nodes = get_tree().get_nodes_in_group(config.group_name)
		var count = 0

		for node in nodes:
			if config.max_display_count >= 0 and count >= config.max_display_count:
				break

			if node is Node2D:
				active_pois.append({
					"type": poi_type,
					"position": node.global_position,
					"node": node,
					"config": config
				})
				count += 1

	# 수동 등록된 POI 추가
	for node in registered_pois:
		if is_instance_valid(node):
			var poi_data = registered_pois[node]
			var config = poi_configs.get(poi_data.type)
			if config and config.show_on_minimap:
				active_pois.append({
					"type": poi_data.type,
					"position": node.global_position,
					"node": node,
					"config": config
				})

	# 우선순위 정렬 (낮은 것 먼저 그려서 높은 것이 위에)
	active_pois.sort_custom(func(a, b):
		var pa = a.config.priority if a.config else 0
		var pb = b.config.priority if b.config else 0
		return pa < pb
	)

	# 커스텀 POI 추가 (자식에서 오버라이드)
	_update_custom_pois()

## 커스텀 POI 추가 (자식에서 오버라이드)
func _update_custom_pois() -> void:
	pass

## POI 수동 등록
func register_poi(node: Node2D, poi_type: String, custom_data: Dictionary = {}) -> void:
	registered_pois[node] = {
		"type": poi_type,
		"custom": custom_data
	}

	# 노드 삭제 시 자동 해제
	if not node.tree_exiting.is_connected(_on_poi_node_exiting):
		node.tree_exiting.connect(_on_poi_node_exiting.bind(node))

## POI 수동 해제
func unregister_poi(node: Node2D) -> void:
	registered_pois.erase(node)

func _on_poi_node_exiting(node: Node2D) -> void:
	unregister_poi(node)

## 그리기
func _draw() -> void:
	# 배경
	draw_rect(Rect2(Vector2.ZERO, minimap_size), background_color)

	# 지형
	draw_texture_rect(terrain_texture, Rect2(Vector2.ZERO, minimap_size), false)

	# POI 그리기
	for poi in active_pois:
		_draw_poi(poi)

	# 테두리
	draw_rect(Rect2(Vector2.ZERO, minimap_size), border_color, false, border_width)

## POI 그리기
func _draw_poi(poi: Dictionary) -> void:
	var config = poi.config
	if not config:
		return

	var screen_pos = _world_to_minimap(poi.position)

	# 범위 밖 체크
	if not _is_in_bounds(screen_pos):
		if config.show_direction_indicator:
			_draw_direction_indicator(poi, screen_pos)
		return

	var color = config.color
	var poi_size = config.size

	# 깜빡임 효과
	if config.blink:
		var blink_value = sin(Time.get_ticks_msec() * 0.001 * config.blink_speed)
		color.a = 0.5 + 0.5 * blink_value

	# 원형으로 그리기
	draw_circle(screen_pos, poi_size, color)

## 방향 표시기 (화면 밖 POI)
func _draw_direction_indicator(poi: Dictionary, screen_pos: Vector2) -> void:
	var config = poi.config
	var center = minimap_size / 2
	var direction = (screen_pos - center).normalized()

	# 미니맵 가장자리 위치 계산
	var edge_pos = center + direction * (minimap_size.x / 2 - 5)

	# 삼각형 방향 표시
	var arrow_size = 4.0
	var perpendicular = Vector2(-direction.y, direction.x)

	var points = PackedVector2Array([
		edge_pos + direction * arrow_size,
		edge_pos - direction * arrow_size + perpendicular * arrow_size,
		edge_pos - direction * arrow_size - perpendicular * arrow_size
	])

	draw_colored_polygon(points, config.color)

## 월드 좌표 → 미니맵 좌표
func _world_to_minimap(world_pos: Vector2) -> Vector2:
	if not player:
		return minimap_size / 2

	var offset = world_pos - player.global_position
	var map_scale = minimap_size.x / (world_radius * 2)
	return minimap_size / 2 + offset * map_scale

## 범위 체크
func _is_in_bounds(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < minimap_size.x and pos.y >= 0 and pos.y < minimap_size.y

## 클릭 처리
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var click_pos = event.position
			var _world_pos = _minimap_to_world(click_pos)

			# 가장 가까운 POI 찾기
			var closest_poi = null
			var closest_dist = INF

			for poi in active_pois:
				var poi_screen = _world_to_minimap(poi.position)
				var dist = poi_screen.distance_to(click_pos)
				if dist < 10 and dist < closest_dist:
					closest_dist = dist
					closest_poi = poi

			if closest_poi:
				poi_clicked.emit(closest_poi.type, closest_poi.position)

## 미니맵 좌표 → 월드 좌표
func _minimap_to_world(minimap_pos: Vector2) -> Vector2:
	if not player:
		return Vector2.ZERO

	var offset = minimap_pos - minimap_size / 2
	var inv_scale = (world_radius * 2) / minimap_size.x
	return player.global_position + offset * inv_scale

## 특정 POI 타입 표시/숨김
func set_poi_visible(poi_type: String, visible_state: bool) -> void:
	if poi_configs.has(poi_type):
		poi_configs[poi_type].show_on_minimap = visible_state

## 특정 POI 타입 색상 변경
func set_poi_color(poi_type: String, color: Color) -> void:
	if poi_configs.has(poi_type):
		poi_configs[poi_type].color = color

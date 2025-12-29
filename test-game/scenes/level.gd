extends Node2D

## World Generator를 사용하는 레벨 스크립트
## WorldConfig 리소스로 설정을 외부화하여 재사용 가능
## GameManager와 EventBus로 게임 상태 관리 위임

# --- Configuration ---
@export var world_config: WorldConfig
@export var debug_noise_layer: bool = false

# References to child nodes
@onready var tile_map: TileMap = $TileMap

# Player reference (동적으로 관리 - 직접 참조 대신 EventBus 사용)
var player: Node2D = null

# World Generator instance (uses shared module)
var generator: WorldGenerator

# --- Chunk Management ---
var drawn_chunks: Dictionary = {}
var chunks_being_generated: Dictionary = {}
var chunks_to_draw: Array[Vector2i] = []
var generation_mutex: Mutex = Mutex.new()

# Debug Visualization
var debug_container: Node2D
var debug_sprites: Dictionary = {}

# --- Autotiling Rules ---
var tile_rules: Dictionary = {}

# --- Core System References ---
var game_manager: Node = null
var event_bus: Node = null

const NEIGHBORS = [
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER
]

func _ready() -> void:
	# 미니맵 등에서 참조할 수 있도록 그룹 추가
	add_to_group("level")

	# Core system references
	game_manager = get_node_or_null("/root/GameManager")
	event_bus = get_node_or_null("/root/EventBus")

	# EventBus 이벤트 구독 (느슨한 결합)
	if event_bus:
		event_bus.player_died.connect(_on_player_died_event)

	# GameManager에 레벨 등록
	if game_manager:
		game_manager.register_level(self)
		game_manager.start_game()

	# Load default config if not set
	if not world_config:
		world_config = preload("res://resources/world_config.tres")

	# Initialize WorldGenerator with config
	generator = WorldGenerator.new(world_config)
	generator.initialize()

	# Create debug container
	debug_container = Node2D.new()
	debug_container.name = "DebugNoise"
	debug_container.z_index = 4
	add_child(debug_container)

	# 플레이어 찾기 및 스폰 위치 설정
	_setup_player()

	# Build autotiling rules from TileSet
	_build_tile_rules()
	_setup_tree_alternatives()

## 플레이어 설정 (동적 탐색 및 스폰)
func _setup_player() -> void:
	# 씬 내 플레이어 또는 그룹에서 찾기
	player = get_node_or_null("Player")
	if not player:
		player = get_tree().get_first_node_in_group("player")

	if not player:
		return

	# 안전한 스폰 위치 설정
	var spawn_tile = generator.find_safe_spawn()
	player.position = tile_map.map_to_local(spawn_tile)

	# EventBus로 플레이어 스폰 알림
	if event_bus:
		event_bus.player_spawned.emit(player)

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

func _setup_tree_alternatives() -> void:
	var source: TileSetAtlasSource = tile_map.tile_set.get_source(0)
	var tree_coords = [
		world_config.tree_palm_1,
		world_config.tree_palm_2,
		world_config.tree_forest
	]
	for coords in tree_coords:
		if source.get_alternative_tiles_count(coords) < 2:
			var alt_id = 1
			source.create_alternative_tile(coords, alt_id)
			var tile_data = source.get_tile_data(coords, alt_id)
			tile_data.flip_h = true

func _build_tile_rules() -> void:
	var source: TileSetAtlasSource = tile_map.tile_set.get_source(0)
	var tiles_count = source.get_tiles_count()

	for i in range(tiles_count):
		var coords = source.get_tile_id(i)
		var tile_data = source.get_tile_data(coords, 0)

		var terrain = tile_data.get_terrain()
		if terrain == -1:
			continue

		if not tile_rules.has(terrain):
			tile_rules[terrain] = []

		var rule = {
			"coords": coords,
			"peering": {},
			"prob": tile_data.probability
		}

		var score = 0
		for bit in NEIGHBORS:
			var peering_terrain = tile_data.get_terrain_peering_bit(bit)
			if peering_terrain != -1:
				rule["peering"][bit] = peering_terrain
				score += 1

		rule["score"] = score
		tile_rules[terrain].append(rule)

	for terrain in tile_rules:
		tile_rules[terrain].sort_custom(func(a, b): return a["score"] > b["score"])

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if debug_container:
			debug_container.visible = not debug_container.visible

func _process(delta: float) -> void:
	# GameManager 상태 체크
	var is_game_over = game_manager.is_game_over if game_manager else false

	if not player or is_game_over:
		return

	var player_pos = tile_map.local_to_map(player.position)
	var current_chunk = Vector2i(
		floor(player_pos.x / float(world_config.chunk_size)),
		floor(player_pos.y / float(world_config.chunk_size))
	)

	# 1. Schedule Generation
	for x in range(current_chunk.x - world_config.generation_distance, current_chunk.x + world_config.generation_distance + 1):
		for y in range(current_chunk.y - world_config.generation_distance, current_chunk.y + world_config.generation_distance + 1):
			var chunk = Vector2i(x, y)

			generation_mutex.lock()
			var already_generating = chunks_being_generated.has(chunk)
			generation_mutex.unlock()

			if not already_generating:
				generator.data_mutex.lock()
				var done = generator.terrain_atlas_coords.has(chunk * world_config.chunk_size)
				generator.data_mutex.unlock()

				if not done:
					generation_mutex.lock()
					chunks_being_generated[chunk] = true
					generation_mutex.unlock()
					WorkerThreadPool.add_task(_generate_chunk.bind(chunk))

	# 2. Schedule Drawing
	var draw_radius_chunks = []
	for x in range(current_chunk.x - world_config.render_distance, current_chunk.x + world_config.render_distance + 1):
		for y in range(current_chunk.y - world_config.render_distance, current_chunk.y + world_config.render_distance + 1):
			draw_radius_chunks.append(Vector2i(x, y))

	for chunk in draw_radius_chunks:
		if not drawn_chunks.has(chunk) and not chunks_to_draw.has(chunk):
			generator.data_mutex.lock()
			var coords_exist = generator.terrain_atlas_coords.has(chunk * world_config.chunk_size)
			generator.data_mutex.unlock()
			if coords_exist:
				chunks_to_draw.append(chunk)

	# 3. Unload Chunks
	var chunks_to_undraw = []
	for chunk in drawn_chunks:
		if chunk not in draw_radius_chunks:
			chunks_to_undraw.append(chunk)
	for chunk in chunks_to_undraw:
		_undraw_chunk(chunk)

	# 4. Execute Draw (Budgeted)
	var budget = world_config.render_budget
	while not chunks_to_draw.is_empty() and budget > 0:
		_draw_chunk(chunks_to_draw.pop_front())
		budget -= 1

func _draw_chunk(chunk: Vector2i) -> void:
	var start_pos = chunk * world_config.chunk_size
	generator.data_mutex.lock()
	for x in range(world_config.chunk_size):
		for y in range(world_config.chunk_size):
			var pos = start_pos + Vector2i(x, y)
			if generator.terrain_atlas_coords.has(pos):
				var layers = generator.terrain_atlas_coords[pos]
				for layer in layers:
					var data = layers[layer]
					tile_map.set_cell(layer, pos, 0, Vector2i(data.x, data.y), data.z)
	generator.data_mutex.unlock()
	drawn_chunks[chunk] = true

	var texture = _create_debug_texture(chunk)
	if texture:
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2(16, 16)
		sprite.centered = false
		sprite.position = Vector2(chunk * world_config.chunk_size * 16)
		debug_container.add_child(sprite)
		debug_sprites[chunk] = sprite

func _undraw_chunk(chunk: Vector2i) -> void:
	drawn_chunks.erase(chunk)
	var start_pos = chunk * world_config.chunk_size
	for x in range(world_config.chunk_size):
		for y in range(world_config.chunk_size):
			var pos = start_pos + Vector2i(x, y)
			for i in range(tile_map.get_layers_count()):
				tile_map.erase_cell(i, pos)

	if debug_sprites.has(chunk):
		debug_sprites[chunk].queue_free()
		debug_sprites.erase(chunk)

func _create_debug_texture(chunk: Vector2i) -> ImageTexture:
	var img = Image.create(world_config.chunk_size, world_config.chunk_size, false, Image.FORMAT_RGBA8)
	var start_pos = chunk * world_config.chunk_size

	for x in range(world_config.chunk_size):
		for y in range(world_config.chunk_size):
			var pos = start_pos + Vector2i(x, y)
			var n = generator.get_noise_at(pos.x, pos.y)
			var color = Color.BLACK

			if n < world_config.water_threshold:
				color = Color(0, 0, 0.8, 0.25)
			elif n < world_config.sand_end:
				color = Color(0.8, 0.8, 0.2, 0.25)
			elif n < world_config.cliff_start:
				color = Color(0.2, 0.8, 0.2, 0.25)
			else:
				color = Color(0.5, 0.5, 0.5, 0.25)

			img.set_pixel(x, y, color)

	return ImageTexture.create_from_image(img)

func _generate_chunk(chunk: Vector2i) -> void:
	var start_pos = chunk * world_config.chunk_size

	# Step 1: Generate terrain data using WorldGenerator
	var chunk_ids = generator.generate_chunk_data(chunk)

	# Step 2: Solve autotiling
	var chunk_coords = {}
	var chunk_neighbors = {}

	generator.data_mutex.lock()
	for x in range(world_config.chunk_size):
		for y in range(world_config.chunk_size):
			var pos = start_pos + Vector2i(x, y)
			var neighbor_terrains = {}
			for bit in NEIGHBORS:
				var n_pos = tile_map.get_neighbor_cell(pos, bit)
				if generator.terrain_data.has(n_pos):
					neighbor_terrains[bit] = generator.terrain_data[n_pos].values()
				else:
					neighbor_terrains[bit] = []
			chunk_neighbors[pos] = neighbor_terrains
	generator.data_mutex.unlock()

	for x in range(world_config.chunk_size):
		for y in range(world_config.chunk_size):
			var pos = start_pos + Vector2i(x, y)
			var layers = chunk_ids[pos]
			var resolved_layers = {}

			for layer_id in layers:
				var type = layers[layer_id]

				# Deep water override
				if layer_id == world_config.layer_water and type == world_config.terrain_water:
					var n = generator.get_noise_at(pos.x, pos.y)
					if n < world_config.deep_water_threshold:
						resolved_layers[layer_id] = Vector3i(
							world_config.deep_water_coords.x,
							world_config.deep_water_coords.y,
							0
						)
						continue

				if not tile_rules.has(type):
					continue

				var candidates = []
				var best_score = -1
				var rules = tile_rules[type]
				var neighbor_terrains = chunk_neighbors[pos]

				for rule in rules:
					if not candidates.is_empty() and rule["score"] < best_score:
						break

					var fail = false
					var peering = rule["peering"]
					for bit in peering:
						var req = peering[bit]
						var has_neighbor = neighbor_terrains[bit].has(req)

						# Sand connects to Grass
						if not has_neighbor:
							if type == world_config.terrain_sand and req == world_config.terrain_sand:
								if neighbor_terrains[bit].has(world_config.terrain_grass):
									has_neighbor = true

						if not has_neighbor:
							fail = true
							break

					if not fail:
						if candidates.is_empty():
							best_score = rule["score"]
						candidates.append(rule)

				if not candidates.is_empty():
					var res = _pick_weighted(candidates)
					resolved_layers[layer_id] = Vector3i(res.x, res.y, 0)
				elif not rules.is_empty():
					var res = rules[0]["coords"]
					resolved_layers[layer_id] = Vector3i(res.x, res.y, 0)

			chunk_coords[pos] = resolved_layers

	# Step 3: Trees using WorldGenerator
	for x in range(world_config.chunk_size):
		for y in range(world_config.chunk_size):
			var pos = start_pos + Vector2i(x, y)

			if randf() > world_config.tree_frequency:
				continue

			if not generator.can_place_tree(pos, chunk_ids):
				continue

			# Spacing check
			var safe = true
			for sx in range(-world_config.tree_spacing, world_config.tree_spacing + 1):
				for sy in range(-world_config.tree_spacing, world_config.tree_spacing + 1):
					if sx == 0 and sy == 0:
						continue
					var s_pos = pos + Vector2i(sx, sy)

					if chunk_coords.has(s_pos) and chunk_coords[s_pos].has(world_config.layer_env):
						safe = false
						break

					generator.data_mutex.lock()
					if generator.terrain_atlas_coords.has(s_pos) and generator.terrain_atlas_coords[s_pos].has(world_config.layer_env):
						safe = false
					generator.data_mutex.unlock()
					if not safe:
						break
				if not safe:
					break

			if safe:
				if not chunk_coords.has(pos):
					chunk_coords[pos] = {}

				var tree_coords = generator.get_tree_coords(pos, chunk_ids)
				var alt_id = 1 if randf() > 0.5 else 0
				chunk_coords[pos][world_config.layer_env] = Vector3i(tree_coords.x, tree_coords.y, alt_id)

	# Commit to cache
	generator.data_mutex.lock()
	for pos in chunk_coords:
		generator.terrain_atlas_coords[pos] = chunk_coords[pos]
	generator.data_mutex.unlock()

	generation_mutex.lock()
	chunks_being_generated.erase(chunk)
	generation_mutex.unlock()

func _pick_weighted(candidates: Array) -> Vector2i:
	if candidates.size() == 1:
		return candidates[0]["coords"]

	var total_weight = 0.0
	for c in candidates:
		total_weight += c["prob"]

	var roll = randf() * total_weight
	var current = 0.0
	for c in candidates:
		current += c["prob"]
		if roll <= current:
			return c["coords"]

	return candidates[0]["coords"]

func is_tile_walkable(global_pos: Vector2) -> bool:
	var map_pos = tile_map.local_to_map(global_pos)
	return generator.is_walkable(map_pos.x, map_pos.y)

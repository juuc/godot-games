class_name ChunkManager
extends RefCounted

## 청크 라이프사이클 관리
##
## 청크 스케줄링, 로딩/언로딩, 진행률 추적을 담당합니다.
## level.gd에서 인스턴스화하여 사용합니다.

const AutotileSolverClass = preload("res://_shared/scripts/world_generator/autotile_solver.gd")

signal chunk_ready(chunk: Vector2i)
signal loading_progress(progress: float)
signal initial_load_complete

var generator: WorldGenerator
var autotile_solver: AutotileSolverClass
var tile_map: TileMap
var world_config: WorldConfig

# --- Chunk State ---
var drawn_chunks: Dictionary = {}
var chunks_being_generated: Dictionary = {}
var chunks_to_draw: Array[Vector2i] = []
var generation_mutex: Mutex = Mutex.new()

# --- Loading State ---
var is_initial_load: bool = true
var initial_chunks_needed: int = 0
var initial_chunks_loaded: int = 0

# --- Debug Visualization ---
var debug_container: Node2D
var debug_sprites: Dictionary = {}

func _init(config: WorldConfig, tilemap: TileMap) -> void:
	world_config = config
	tile_map = tilemap
	generator = WorldGenerator.new(config)
	autotile_solver = AutotileSolverClass.new(config, tilemap)

## 초기화 (노이즈, 오토타일 규칙 빌드)
func initialize() -> void:
	generator.initialize()
	autotile_solver.build_rules()
	autotile_solver.setup_tree_alternatives()

## 디버그 컨테이너 설정 (level에서 호출)
func set_debug_container(container: Node2D) -> void:
	debug_container = container

## 안전한 스폰 위치 찾기 (Generator 위임)
func find_safe_spawn() -> Vector2i:
	return generator.find_safe_spawn()

## 초기 청크 로딩 시작
func start_loading_around(position: Vector2) -> void:
	var player_pos = tile_map.local_to_map(position)
	var current_chunk = Vector2i(
		floor(player_pos.x / float(world_config.chunk_size)),
		floor(player_pos.y / float(world_config.chunk_size))
	)

	# 초기 로딩에 필요한 청크 수 계산
	var rd = world_config.render_distance
	initial_chunks_needed = (rd * 2 + 1) * (rd * 2 + 1)
	initial_chunks_loaded = 0

	# 초기 청크 생성 예약
	for x in range(current_chunk.x - rd, current_chunk.x + rd + 1):
		for y in range(current_chunk.y - rd, current_chunk.y + rd + 1):
			var chunk = Vector2i(x, y)
			generation_mutex.lock()
			chunks_being_generated[chunk] = true
			generation_mutex.unlock()
			WorkerThreadPool.add_task(_generate_chunk.bind(chunk))

## 매 프레임 업데이트 (플레이어 위치 기반)
func update(player_position: Vector2) -> void:
	var player_pos = tile_map.local_to_map(player_position)
	var current_chunk = Vector2i(
		floor(player_pos.x / float(world_config.chunk_size)),
		floor(player_pos.y / float(world_config.chunk_size))
	)

	# 1. Schedule Generation
	_schedule_generation(current_chunk)

	# 2. Schedule Drawing
	var draw_radius_chunks = _get_chunks_in_radius(current_chunk, world_config.render_distance)
	_schedule_drawing(draw_radius_chunks)

	# 3. Unload Chunks
	_unload_distant_chunks(draw_radius_chunks)

	# 4. Execute Draw (Budgeted)
	_execute_draw_budget()

## 청크 생성 스케줄링
func _schedule_generation(current_chunk: Vector2i) -> void:
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

## 청크 그리기 스케줄링
func _schedule_drawing(draw_radius_chunks: Array[Vector2i]) -> void:
	for chunk in draw_radius_chunks:
		if not drawn_chunks.has(chunk) and not chunks_to_draw.has(chunk):
			generator.data_mutex.lock()
			var coords_exist = generator.terrain_atlas_coords.has(chunk * world_config.chunk_size)
			generator.data_mutex.unlock()
			if coords_exist:
				chunks_to_draw.append(chunk)

## 먼 청크 언로드
func _unload_distant_chunks(draw_radius_chunks: Array[Vector2i]) -> void:
	var chunks_to_undraw: Array[Vector2i] = []
	for chunk in drawn_chunks:
		if chunk not in draw_radius_chunks:
			chunks_to_undraw.append(chunk)
	for chunk in chunks_to_undraw:
		_undraw_chunk(chunk)

## 프레임 예산 내 그리기 실행
func _execute_draw_budget() -> void:
	var budget = world_config.render_budget
	while not chunks_to_draw.is_empty() and budget > 0:
		_draw_chunk(chunks_to_draw.pop_front())
		budget -= 1

## 반경 내 청크 목록 반환
func _get_chunks_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var chunks: Array[Vector2i] = []
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			chunks.append(Vector2i(x, y))
	return chunks

## 청크 그리기
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

	# 초기 로딩 진행률 업데이트
	if is_initial_load:
		var progress = float(drawn_chunks.size()) / float(initial_chunks_needed)
		loading_progress.emit(clamp(progress, 0.0, 1.0))
		_check_initial_loading_complete()

	# 디버그 시각화
	if debug_container:
		_create_debug_sprite(chunk)

	chunk_ready.emit(chunk)

## 청크 언로드
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

## 초기 로딩 완료 체크
func _check_initial_loading_complete() -> void:
	if not is_initial_load:
		return

	if drawn_chunks.size() >= initial_chunks_needed:
		is_initial_load = false
		initial_load_complete.emit()

## 청크 생성 (백그라운드 스레드)
func _generate_chunk(chunk: Vector2i) -> void:
	# Step 1: Generate terrain data
	var chunk_ids = generator.generate_chunk_data(chunk)

	# Step 2: Solve autotiling
	var chunk_coords = autotile_solver.resolve(chunk, chunk_ids, generator)

	# Step 3: Trees
	_place_trees(chunk, chunk_ids, chunk_coords)

	# Commit to cache
	generator.data_mutex.lock()
	for pos in chunk_coords:
		generator.terrain_atlas_coords[pos] = chunk_coords[pos]
	generator.data_mutex.unlock()

	generation_mutex.lock()
	chunks_being_generated.erase(chunk)
	generation_mutex.unlock()

## 나무 배치
func _place_trees(chunk: Vector2i, chunk_ids: Dictionary, chunk_coords: Dictionary) -> void:
	var start_pos = chunk * world_config.chunk_size

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

## 디버그 스프라이트 생성
func _create_debug_sprite(chunk: Vector2i) -> void:
	var texture = _create_debug_texture(chunk)
	if texture:
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2(16, 16)
		sprite.centered = false
		sprite.position = Vector2(chunk * world_config.chunk_size * 16)
		debug_container.add_child(sprite)
		debug_sprites[chunk] = sprite

## 디버그 텍스처 생성
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

## 타일이 걸을 수 있는지 확인 (Generator 위임)
func is_tile_walkable(map_pos: Vector2i) -> bool:
	return generator.is_walkable(map_pos.x, map_pos.y)

## 특정 위치의 노이즈 값 반환 (Generator 위임)
func get_noise_at(x: int, y: int) -> float:
	return generator.get_noise_at(x, y)

class_name WorldGenerator
extends RefCounted

## Reusable 2D Infinite World Generator
##
## 이 클래스는 WorldConfig를 기반으로 무한 2D 절차적 세계를 생성합니다.
## 다른 게임에서 재사용하려면:
## 1. WorldConfig 리소스 생성 및 설정
## 2. WorldGenerator.new(config) 호출
## 3. generate_chunk(), get_terrain_at() 등 메서드 사용
##
## 예시:
## ```gdscript
## var config = preload("res://my_world_config.tres")
## var generator = WorldGenerator.new(config)
## generator.initialize()
## var chunk_data = generator.generate_chunk(Vector2i(0, 0))
## ```

var config: WorldConfig
var noise: FastNoiseLite

# --- Data Caches ---
var terrain_data: Dictionary = {}  # pos -> { layer_id -> terrain_id }
var terrain_atlas_coords: Dictionary = {}  # pos -> { layer_id -> Vector3i }

var data_mutex: Mutex = Mutex.new()

func _init(world_config: WorldConfig) -> void:
	config = world_config
	noise = FastNoiseLite.new()

func initialize(custom_seed: int = 0) -> void:
	var seed_value = custom_seed if custom_seed != 0 else config.noise_seed
	if seed_value == 0:
		seed_value = randi()

	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = config.noise_frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = config.fractal_octaves

## 특정 위치의 노이즈 값 반환
func get_noise_at(x: int, y: int) -> float:
	return noise.get_noise_2d(x, y)

## 특정 위치의 생물군계 판단
func get_biome_at(x: int, y: int) -> Dictionary:
	var n = get_noise_at(x, y)
	var layers = {}

	# Water
	if n < config.water_threshold:
		layers[config.layer_water] = config.terrain_water

	# Sand
	if n > config.sand_start and n < config.sand_end:
		layers[config.layer_sand] = config.terrain_sand

	# Grass
	if n > config.grass_start and n < config.grass_end:
		layers[config.layer_grass] = config.terrain_grass

	# Cliff
	if n > config.cliff_start:
		layers[config.layer_cliff] = config.terrain_cliff

	return layers

## 안전한 스폰 위치 찾기 (나선형 검색)
func find_safe_spawn() -> Vector2i:
	var x = 0
	var y = 0
	var dx = 0
	var dy = -1

	for i in range(int(pow(config.spawn_search_radius * 2, 2))):
		if is_safe_spawn(x, y):
			return Vector2i(x, y)

		if x == y or (x < 0 and x == -y) or (x > 0 and x == 1 - y):
			var temp = dx
			dx = -dy
			dy = temp

		x += dx
		y += dy

	return Vector2i(0, 0)

## 스폰 가능 위치인지 확인
func is_safe_spawn(x: int, y: int) -> bool:
	var n = get_noise_at(x, y)
	return n >= config.safe_spawn_min and n <= config.safe_spawn_max

## 타일이 걸을 수 있는지 확인
func is_walkable(x: int, y: int) -> bool:
	data_mutex.lock()
	var has_data = terrain_data.has(Vector2i(x, y))
	var layers = {}
	if has_data:
		layers = terrain_data[Vector2i(x, y)]
	data_mutex.unlock()

	if not has_data:
		return false

	return layers.has(config.layer_grass) or layers.has(config.layer_sand) or layers.has(config.layer_cliff)

## 청크 데이터 생성 (백그라운드 스레드에서 호출 가능)
func generate_chunk_data(chunk: Vector2i) -> Dictionary:
	var start_pos = chunk * config.chunk_size
	var chunk_ids = {}
	var gen_buffer = 3

	# Step 1: Terrain IDs 생성
	for x in range(-gen_buffer, config.chunk_size + gen_buffer):
		for y in range(-gen_buffer, config.chunk_size + gen_buffer):
			var pos = start_pos + Vector2i(x, y)
			chunk_ids[pos] = get_biome_at(pos.x, pos.y)

	# 캐시에 저장
	data_mutex.lock()
	for pos in chunk_ids:
		terrain_data[pos] = chunk_ids[pos]
	data_mutex.unlock()

	return chunk_ids

## 나무 배치 가능 여부 확인
func can_place_tree(pos: Vector2i, chunk_ids: Dictionary) -> bool:
	var is_sand = chunk_ids[pos].has(config.layer_sand) and not chunk_ids[pos].has(config.layer_grass)
	var is_grass = chunk_ids[pos].has(config.layer_grass)

	if chunk_ids[pos].has(config.layer_cliff):
		return false

	if not (is_sand or is_grass):
		return false

	# 주변 체크
	for bx in range(-config.decoration_buffer, config.decoration_buffer + 1):
		for by in range(-config.decoration_buffer, config.decoration_buffer + 1):
			var b_pos = pos + Vector2i(bx, by)

			data_mutex.lock()
			var has_data = terrain_data.has(b_pos)
			var b_ids = {}
			if has_data:
				b_ids = terrain_data[b_pos]
			data_mutex.unlock()

			if not has_data:
				return false
			if b_ids.has(config.layer_cliff):
				return false
			if is_sand and not b_ids.has(config.layer_sand):
				return false
			if is_grass and not b_ids.has(config.layer_grass):
				return false

	return true

## 나무 타일 좌표 반환
func get_tree_coords(pos: Vector2i, chunk_ids: Dictionary) -> Vector2i:
	var is_sand = chunk_ids[pos].has(config.layer_sand) and not chunk_ids[pos].has(config.layer_grass)

	if is_sand:
		return config.tree_palm_1 if randf() > 0.5 else config.tree_palm_2
	else:
		return config.tree_forest

## 데이터 캐시 클리어
func clear_cache() -> void:
	data_mutex.lock()
	terrain_data.clear()
	terrain_atlas_coords.clear()
	data_mutex.unlock()

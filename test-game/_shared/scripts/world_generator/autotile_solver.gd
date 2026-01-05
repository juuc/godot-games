class_name AutotileSolver
extends RefCounted

## TileSet 기반 오토타일 해결
##
## TileSet의 terrain 정보를 분석하여 올바른 타일을 선택합니다.
## ChunkManager에서 청크 생성 시 호출됩니다.

var world_config: WorldConfig
var tile_map: TileMap
var tile_rules: Dictionary = {}

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

func _init(config: WorldConfig, tilemap: TileMap) -> void:
	world_config = config
	tile_map = tilemap

## TileSet에서 오토타일 규칙 빌드
func build_rules() -> void:
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

	# 점수 높은 순으로 정렬 (더 구체적인 규칙 우선)
	for terrain in tile_rules:
		tile_rules[terrain].sort_custom(func(a, b): return a["score"] > b["score"])

## 나무 타일 대체 버전 설정 (뒤집기)
func setup_tree_alternatives() -> void:
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

## 청크의 오토타일 해결
## chunk_ids: pos -> { layer_id -> terrain_id }
## generator: WorldGenerator (terrain_data 접근용)
## Returns: pos -> { layer_id -> Vector3i(atlas_x, atlas_y, alt_id) }
func resolve(chunk: Vector2i, chunk_ids: Dictionary, generator: WorldGenerator) -> Dictionary:
	var start_pos = chunk * world_config.chunk_size
	var chunk_coords: Dictionary = {}

	# 이웃 타일 정보 수집
	var chunk_neighbors: Dictionary = {}
	generator.data_mutex.lock()
	for x in range(world_config.chunk_size):
		for y in range(world_config.chunk_size):
			var pos = start_pos + Vector2i(x, y)
			var neighbor_terrains: Dictionary = {}
			for bit in NEIGHBORS:
				var n_pos = tile_map.get_neighbor_cell(pos, bit)
				if generator.terrain_data.has(n_pos):
					neighbor_terrains[bit] = generator.terrain_data[n_pos].values()
				else:
					neighbor_terrains[bit] = []
			chunk_neighbors[pos] = neighbor_terrains
	generator.data_mutex.unlock()

	# 각 타일 해결
	for x in range(world_config.chunk_size):
		for y in range(world_config.chunk_size):
			var pos = start_pos + Vector2i(x, y)
			var layers = chunk_ids[pos]
			var resolved_layers: Dictionary = {}

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

				var candidates: Array = []
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

	return chunk_coords

## 가중치 기반 랜덤 선택
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

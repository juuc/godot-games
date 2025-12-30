class_name WorldConfig
extends Resource

## World Generator Configuration
## 다른 게임에서 재사용할 수 있도록 모든 설정을 외부화한 리소스
##
## 사용법:
## 1. 에디터에서 New Resource -> WorldConfig 생성
## 2. 값 설정 후 .tres 파일로 저장
## 3. WorldGenerator에 할당

# --- Noise Settings ---
@export_group("Noise")
@export var noise_seed: int = 0  ## 0이면 랜덤 시드
@export var noise_frequency: float = 0.001  ## 낮을수록 큰 대륙, 높을수록 작은 섬
@export var fractal_octaves: int = 7  ## 노이즈 디테일 (낮을수록 부드러움)

# --- Chunk Settings ---
@export_group("Chunks")
@export var chunk_size: int = 16  ## 청크 크기 (타일 단위)
@export var render_distance: int = 10  ## 렌더링 거리 (청크 단위)
@export var generation_distance: int = 15  ## 생성 거리 (청크 단위)
@export var render_budget: int = 2  ## 프레임당 렌더링할 청크 수

# --- Biome Thresholds ---
## 노이즈 값에 따른 생물군계 결정
## 예: noise < water_threshold -> 물
@export_group("Biome Thresholds")
@export var water_threshold: float = 0.0
@export var sand_start: float = -0.025
@export var sand_end: float = 0.15
@export var grass_start: float = 0.135
@export var grass_end: float = 0.55
@export var cliff_start: float = 0.535

# --- Layer IDs ---
## TileMap 레이어 인덱스 (TileMap 설정과 일치해야 함)
@export_group("Layer IDs")
@export var layer_water: int = 0
@export var layer_sand: int = 1
@export var layer_grass: int = 2
@export var layer_cliff: int = 3
@export var layer_env: int = 4

# --- Terrain IDs ---
## TileSet의 terrain ID (TileSet 설정과 일치해야 함)
@export_group("Terrain IDs")
@export var terrain_water: int = 0
@export var terrain_sand: int = 1
@export var terrain_grass: int = 2
@export var terrain_cliff: int = 3

# --- Decoration Settings ---
@export_group("Decorations")
@export var tree_frequency: float = 0.003  ## 나무 생성 확률 (0~1)
@export var tree_spacing: int = 3  ## 나무 간 최소 간격
@export var decoration_buffer: int = 2  ## 데코레이션 체크 버퍼

# --- Tree Atlas Coordinates ---
## TileSet에서 나무 타일의 좌표
@export_group("Tree Tiles")
@export var tree_palm_1: Vector2i = Vector2i(12, 2)
@export var tree_palm_2: Vector2i = Vector2i(15, 2)
@export var tree_forest: Vector2i = Vector2i(15, 6)

# --- Deep Water ---
@export_group("Special Tiles")
@export var deep_water_threshold: float = -0.2
@export var deep_water_coords: Vector2i = Vector2i(0, 1)

# --- Spawn Settings ---
@export_group("Spawn")
@export var safe_spawn_min: float = 0.0  ## 안전 스폰 최소 노이즈 값
@export var safe_spawn_max: float = 0.45  ## 안전 스폰 최대 노이즈 값
@export var spawn_search_radius: int = 100  ## 스폰 위치 검색 반경

# --- Walkable Settings ---
@export_group("Walkable")
## 걸을 수 있는 레이어 (grass, sand 등)
@export var walkable_layers: Array[int] = [1, 2]  ## layer_sand, layer_grass
## 차단하는 레이어 (cliff, water 등) - walkable 레이어가 있어도 차단
@export var blocking_layers: Array[int] = [3]  ## layer_cliff
## water 레이어 (단독으로 있으면 차단, 다른 walkable과 겹치면 허용)
@export var water_layer: int = 0

## 특정 타일이 walkable인지 판단
func is_tile_walkable(layers: Dictionary) -> bool:
	# 차단 레이어가 있으면 걸을 수 없음
	for blocking in blocking_layers:
		if layers.has(blocking):
			return false

	# water만 있으면 걸을 수 없음 (다른 walkable 없이)
	if layers.has(water_layer):
		var has_walkable = false
		for walkable in walkable_layers:
			if layers.has(walkable):
				has_walkable = true
				break
		if not has_walkable:
			return false

	# walkable 레이어가 있으면 걸을 수 있음
	for walkable in walkable_layers:
		if layers.has(walkable):
			return true

	return false

class_name WorldConfig
extends Resource

## World Generator Configuration
## 다른 게임에서 재사용할 수 있도록 모든 설정을 외부화한 리소스
##
## 사용법:
## 1. 에디터에서 New Resource -> WorldConfig 생성
## 2. 값 설정 후 .tres 파일로 저장
## 3. WorldGenerator에 할당

## BiomeData 클래스 preload (로딩 순서 보장)
const BiomeDataClass = preload("res://_shared/scripts/world_generator/biome_data.gd")

## Elevation 레벨 (바이옴 매트릭스 행)
enum ElevationLevel { DEEP_WATER, LOW, MID, HIGH }

## Moisture 레벨 (바이옴 매트릭스 열)
enum MoistureLevel { DRY, NORMAL, WET }

# --- Elevation Noise Settings ---
@export_group("Elevation Noise")
@export var noise_seed: int = 0  ## 0이면 랜덤 시드
@export var noise_frequency: float = 0.001  ## 낮을수록 큰 대륙, 높을수록 작은 섬
@export var fractal_octaves: int = 7  ## 노이즈 디테일 (낮을수록 부드러움)

# --- Moisture Noise Settings ---
@export_group("Moisture Noise")
@export var moisture_noise_seed: int = 0  ## 0이면 elevation seed + 1000
@export var moisture_frequency: float = 0.0008  ## 수분 노이즈 주파수 (elevation보다 약간 큰 스케일)
@export var moisture_octaves: int = 5  ## 수분 노이즈 옥타브

# --- Chunk Settings ---
@export_group("Chunks")
@export var chunk_size: int = 16  ## 청크 크기 (타일 단위)
@export var render_distance: int = 10  ## 렌더링 거리 (청크 단위)
@export var generation_distance: int = 15  ## 생성 거리 (청크 단위)
@export var render_budget: int = 2  ## 프레임당 렌더링할 청크 수

# --- Legacy Biome Thresholds (for terrain layer generation) ---
## 노이즈 값에 따른 터레인 레이어 결정
## 예: noise < water_threshold -> water layer
@export_group("Terrain Thresholds")
@export var water_threshold: float = 0.0
@export var sand_start: float = -0.025
@export var sand_end: float = 0.15
@export var grass_start: float = 0.135
@export var grass_end: float = 0.55
@export var cliff_start: float = 0.535

# --- Elevation Level Thresholds ---
## elevation 노이즈 값을 ElevationLevel로 변환하는 임계값
@export_group("Elevation Levels")
@export var elevation_deep_water: float = -0.15  ## 이하 -> DEEP_WATER
@export var elevation_low: float = 0.1  ## 이하 -> LOW (beach/shallow)
@export var elevation_mid: float = 0.45  ## 이하 -> MID (grass/desert/forest)
## elevation_mid 초과 -> HIGH (mountain/snow)

# --- Moisture Level Thresholds ---
## moisture 노이즈 값을 MoistureLevel로 변환하는 임계값
@export_group("Moisture Levels")
@export var moisture_dry: float = -0.1  ## 이하 -> DRY
@export var moisture_normal: float = 0.15  ## 이하 -> NORMAL
## moisture_normal 초과 -> WET

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

# --- Biome Definitions ---
## 바이옴 ID 상수
const BIOME_OCEAN = 0
const BIOME_DEEP_SEA = 1
const BIOME_BEACH = 2
const BIOME_SHALLOW = 3
const BIOME_SWAMP = 4
const BIOME_DESERT = 5
const BIOME_GRASS = 6
const BIOME_FOREST = 7
const BIOME_ROCKY = 8
const BIOME_MOUNTAIN = 9
const BIOME_SNOW = 10

## 바이옴 데이터 캐시 (lazy initialization)
var _biome_cache: Dictionary = {}

## 바이옴 데이터 가져오기 (캐시됨)
func get_biome_data(biome_id: int) -> BiomeDataClass:
	if _biome_cache.is_empty():
		_initialize_biomes()
	return _biome_cache.get(biome_id, _biome_cache[BIOME_GRASS])

## 바이옴 초기화 (최초 호출 시 1회)
func _initialize_biomes() -> void:
	# terrain: 0=water, 1=sand, 2=grass, 3=cliff
	
	# Deep water biomes
	_biome_cache[BIOME_OCEAN] = BiomeDataClass.create(
		"Ocean", BIOME_OCEAN, 0,
		Color(1.0, 1.0, 1.0),  # 기본 물 색상
		Color(0.2, 0.4, 0.7)   # 바다 색상
	)
	_biome_cache[BIOME_DEEP_SEA] = BiomeDataClass.create(
		"Deep Sea", BIOME_DEEP_SEA, 0,
		Color(0.8, 0.85, 0.95),  # 약간 어둡게
		Color(0.1, 0.25, 0.5)    # 깊은 바다 색상
	)
	
	# Low elevation biomes
	_biome_cache[BIOME_BEACH] = BiomeDataClass.create(
		"Beach", BIOME_BEACH, 1,
		Color(1.0, 0.95, 0.85),  # 따뜻한 모래색
		Color(0.3, 0.6, 0.8)
	)
	_biome_cache[BIOME_SHALLOW] = BiomeDataClass.create(
		"Shallow Water", BIOME_SHALLOW, 0,
		Color(0.9, 0.95, 1.0),
		Color(0.3, 0.55, 0.75)   # 얕은 물
	)
	_biome_cache[BIOME_SWAMP] = BiomeDataClass.create(
		"Swamp", BIOME_SWAMP, 2,
		Color(0.6, 0.75, 0.5),   # 어두운 녹색
		Color(0.3, 0.45, 0.35)   # 늪 물색
	)
	
	# Mid elevation biomes
	_biome_cache[BIOME_DESERT] = BiomeDataClass.create(
		"Desert", BIOME_DESERT, 1,
		Color(1.0, 0.9, 0.7),    # 노란 모래
		Color(0.4, 0.5, 0.6)
	)
	_biome_cache[BIOME_GRASS] = BiomeDataClass.create(
		"Grassland", BIOME_GRASS, 2,
		Color(1.0, 1.0, 1.0),    # 기본 풀 색상
		Color(0.3, 0.5, 0.7)
	)
	_biome_cache[BIOME_FOREST] = BiomeDataClass.create(
		"Forest", BIOME_FOREST, 2,
		Color(0.7, 0.9, 0.6),    # 진한 녹색
		Color(0.25, 0.4, 0.5)
	)
	
	# High elevation biomes
	_biome_cache[BIOME_ROCKY] = BiomeDataClass.create(
		"Rocky", BIOME_ROCKY, 3,
		Color(0.85, 0.8, 0.75),  # 갈색빛 바위
		Color(0.3, 0.4, 0.5)
	)
	_biome_cache[BIOME_MOUNTAIN] = BiomeDataClass.create(
		"Mountain", BIOME_MOUNTAIN, 3,
		Color(0.9, 0.9, 0.9),    # 회색 바위
		Color(0.35, 0.45, 0.55)
	)
	_biome_cache[BIOME_SNOW] = BiomeDataClass.create(
		"Snow", BIOME_SNOW, 3,
		Color(0.95, 0.97, 1.0),  # 푸른빛 흰색
		Color(0.5, 0.6, 0.7)
	)

## elevation 노이즈 값을 레벨로 변환
func get_elevation_level(elevation: float) -> ElevationLevel:
	if elevation <= elevation_deep_water:
		return ElevationLevel.DEEP_WATER
	elif elevation <= elevation_low:
		return ElevationLevel.LOW
	elif elevation <= elevation_mid:
		return ElevationLevel.MID
	else:
		return ElevationLevel.HIGH

## moisture 노이즈 값을 레벨로 변환
func get_moisture_level(moisture: float) -> MoistureLevel:
	if moisture <= moisture_dry:
		return MoistureLevel.DRY
	elif moisture <= moisture_normal:
		return MoistureLevel.NORMAL
	else:
		return MoistureLevel.WET

## elevation + moisture로 바이옴 결정 (바이옴 매트릭스)
## 
## 매트릭스:
##                DRY          NORMAL        WET
## DEEP_WATER    Ocean        Ocean         Deep Sea
## LOW           Beach        Shallow       Swamp
## MID           Desert       Grass         Forest
## HIGH          Rocky        Mountain      Snow
func get_biome_from_levels(elev_level: ElevationLevel, moist_level: MoistureLevel) -> BiomeDataClass:
	if _biome_cache.is_empty():
		_initialize_biomes()
	
	var biome_id: int
	
	match elev_level:
		ElevationLevel.DEEP_WATER:
			match moist_level:
				MoistureLevel.DRY: biome_id = BIOME_OCEAN
				MoistureLevel.NORMAL: biome_id = BIOME_OCEAN
				MoistureLevel.WET: biome_id = BIOME_DEEP_SEA
		ElevationLevel.LOW:
			match moist_level:
				MoistureLevel.DRY: biome_id = BIOME_BEACH
				MoistureLevel.NORMAL: biome_id = BIOME_SHALLOW
				MoistureLevel.WET: biome_id = BIOME_SWAMP
		ElevationLevel.MID:
			match moist_level:
				MoistureLevel.DRY: biome_id = BIOME_DESERT
				MoistureLevel.NORMAL: biome_id = BIOME_GRASS
				MoistureLevel.WET: biome_id = BIOME_FOREST
		ElevationLevel.HIGH:
			match moist_level:
				MoistureLevel.DRY: biome_id = BIOME_ROCKY
				MoistureLevel.NORMAL: biome_id = BIOME_MOUNTAIN
				MoistureLevel.WET: biome_id = BIOME_SNOW
	
	return _biome_cache.get(biome_id, _biome_cache[BIOME_GRASS])

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

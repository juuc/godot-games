class_name BiomeData
extends Resource

## 바이옴 데이터 리소스
##
## 각 바이옴의 시각적 특성과 게임플레이 속성을 정의합니다.
## WorldConfig의 바이옴 매트릭스에서 사용됩니다.

@export_group("Basic Info")
@export var biome_name: String = "Unknown"
@export var biome_id: int = 0  ## 고유 ID (매트릭스 인덱싱용)

@export_group("Terrain Mapping")
## 이 바이옴에서 사용할 기본 터레인 타입
## 0=water, 1=sand, 2=grass, 3=cliff
@export var base_terrain: int = 2  ## 기본 grass

@export_group("Visual")
## 타일에 적용할 색상 변조
@export var color_modulate: Color = Color.WHITE
## 물 타일 색상 (해당 바이옴의 물)
@export var water_color: Color = Color(0.3, 0.5, 0.8, 1.0)

@export_group("Gameplay")
## 이동 속도 배율 (1.0 = 기본)
@export var move_speed_multiplier: float = 1.0
## 적 스폰 배율
@export var enemy_spawn_multiplier: float = 1.0

## 편의 생성자
static func create(
	p_name: String,
	p_id: int,
	p_terrain: int,
	p_color: Color,
	p_water_color: Color = Color(0.3, 0.5, 0.8, 1.0)
) -> Resource:
	var script = load("res://_shared/scripts/world_generator/biome_data.gd")
	var data = script.new()
	data.biome_name = p_name
	data.biome_id = p_id
	data.base_terrain = p_terrain
	data.color_modulate = p_color
	data.water_color = p_water_color
	return data

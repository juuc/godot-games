extends "res://_shared/scripts/ui/minimap_base.gd"

## Test Game Minimap
## 지형 색상과 POI 설정을 커스터마이징

func _on_ready() -> void:
	# 지형 색상 설정 (Paradise 타일셋에 맞춤)
	terrain_colors = {
		"water": Color("#2980b9"),   # 깊은 바다 느낌
		"sand": Color("#f39c12"),    # 모래사장
		"grass": Color("#27ae60"),   # 풀밭
		"cliff": Color("#6d4c41"),   # 절벽/언덕
		"unknown": Color("#1a1a2e")  # 탐험 안된 영역
	}

	# WorldGenerator 연결
	_connect_world_generator()

func _connect_world_generator() -> void:
	# Level에서 WorldGenerator 찾기
	var level = get_tree().get_first_node_in_group("level")
	if level and level.has_method("get_generator"):
		set_world_generator(level.get_generator())
	elif level and "generator" in level:
		set_world_generator(level.generator)

## 기본 POI 설정 확장
func _setup_default_poi_configs() -> void:
	super._setup_default_poi_configs()

	# 크랩 (적) - 이미 enemies 그룹에서 자동 수집됨
	var crab_config = MinimapPOIConfig.new()
	crab_config.poi_type = "crab"
	crab_config.display_name = "Crab"
	crab_config.color = Color("#c0392b")  # 붉은색
	crab_config.size = 2.0
	crab_config.priority = 10
	crab_config.group_name = "enemies"
	poi_configs["crab"] = crab_config

	# XP 젬
	var xp_config = MinimapPOIConfig.new()
	xp_config.poi_type = "xp_gem"
	xp_config.display_name = "XP Gem"
	xp_config.color = Color("#9b59b6")  # 보라색
	xp_config.size = 1.5
	xp_config.priority = 5
	xp_config.group_name = "xp_gems"
	xp_config.max_display_count = 20  # 성능을 위해 제한
	poi_configs["xp_gem"] = xp_config

	# 보물상자 (미래 확장용)
	var treasure_config = MinimapPOIConfig.new()
	treasure_config.poi_type = "treasure"
	treasure_config.display_name = "Treasure Chest"
	treasure_config.color = Color("#f1c40f")  # 금색
	treasure_config.size = 3.0
	treasure_config.priority = 50
	treasure_config.blink = true
	treasure_config.blink_speed = 3.0
	treasure_config.group_name = "treasures"
	treasure_config.show_direction_indicator = true
	poi_configs["treasure"] = treasure_config

	# 구급상자 (미래 확장용)
	var health_config = MinimapPOIConfig.new()
	health_config.poi_type = "health_pack"
	health_config.display_name = "Health Pack"
	health_config.color = Color("#e74c3c")  # 빨간색
	health_config.size = 2.5
	health_config.priority = 40
	health_config.group_name = "health_packs"
	health_config.show_direction_indicator = true
	poi_configs["health_pack"] = health_config

	# Elite 적
	var elite_config = MinimapPOIConfig.new()
	elite_config.poi_type = "elite"
	elite_config.display_name = "Elite"
	elite_config.color = Color("#e74c3c")  # 밝은 빨강
	elite_config.size = 4.0
	elite_config.priority = 60
	elite_config.blink = true
	elite_config.blink_speed = 3.0
	elite_config.group_name = "elites"
	elite_config.show_direction_indicator = true
	poi_configs["elite"] = elite_config

	# 보스 (미래 확장용)
	var boss_config = MinimapPOIConfig.new()
	boss_config.poi_type = "boss"
	boss_config.display_name = "Boss"
	boss_config.color = Color("#8e44ad")  # 진한 보라
	boss_config.size = 5.0
	boss_config.priority = 80
	boss_config.blink = true
	boss_config.blink_speed = 2.0
	boss_config.group_name = "bosses"
	boss_config.show_direction_indicator = true
	poi_configs["boss"] = boss_config

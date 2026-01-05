class_name ResourcePaths
extends RefCounted

## 리소스 경로 중앙 관리
## 모든 하드코딩된 경로를 여기서 관리
##
## 사용법:
## - var scene = ResourcePaths.load_scene(ResourcePaths.UI_SKILL_SELECTION)
## - const MyClass = preload(ResourcePaths.SCRIPT_WEAPON_BASE)

# --- UI Scenes ---
const UI_SKILL_SELECTION := "res://scenes/ui/skill_selection.tscn"
const UI_LOADING_SCREEN := "res://scenes/ui/loading_screen.tscn"
const UI_DAMAGE_POPUP := "res://scenes/ui/damage_popup.tscn"
const UI_STATS_SCREEN := "res://scenes/ui/stats_screen.tscn"
const UI_GAME_OVER := "res://scenes/ui/game_over.tscn"

# --- Pickup Scenes ---
const PICKUP_XP_GEM := "res://scenes/pickups/xp_gem.tscn"
const PICKUP_HEALTH := "res://scenes/pickups/health_pickup.tscn"
const PICKUP_TREASURE := "res://scenes/pickups/treasure_chest.tscn"

# --- Config Resources ---
const CONFIG_WORLD := "res://resources/world_config.tres"
const CONFIG_GAME := "res://resources/game_config.tres"

# --- Shared Scripts ---
const SCRIPT_STAT_MANAGER := "res://_shared/scripts/progression/stat_manager.gd"
const SCRIPT_STAT_MODIFIER := "res://_shared/scripts/progression/stat_modifier.gd"
const SCRIPT_SKILL_MANAGER := "res://_shared/scripts/progression/skill_manager.gd"
const SCRIPT_WEAPON_MANAGER := "res://_shared/scripts/weapons/weapon_manager.gd"
const SCRIPT_WEAPON_BASE := "res://_shared/scripts/weapons/weapon_base.gd"
const SCRIPT_MELEE_WEAPON := "res://_shared/scripts/weapons/melee_weapon_base.gd"
const SCRIPT_SLASH_EFFECT := "res://_shared/scripts/weapons/slash_effect.gd"
const SCRIPT_MINIMAP_POI := "res://_shared/scripts/ui/minimap_poi_config.gd"

# --- Scene Cache for Runtime Loading ---
static var _scene_cache: Dictionary = {}

## 씬 로드 (캐시 사용)
static func load_scene(path: String) -> PackedScene:
	if not _scene_cache.has(path):
		_scene_cache[path] = load(path)
	return _scene_cache[path]

## 리소스 로드 (캐시 사용)
static func load_resource(path: String) -> Resource:
	if not _scene_cache.has(path):
		_scene_cache[path] = load(path)
	return _scene_cache[path]

## 캐시 초기화
static func clear_cache() -> void:
	_scene_cache.clear()

## 특정 경로 캐시 제거
static func invalidate(path: String) -> void:
	_scene_cache.erase(path)

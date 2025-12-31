# Shared Modules 사용 가이드

뱀서라이크 게임 프레임워크의 공유 모듈 API 레퍼런스입니다.

> **Last Updated**: 2024-12-31
>
> **관련 문서**: [아키텍처 가이드](architecture.md)

## 디렉토리 구조

```
_shared/scripts/
├── core/
│   ├── event_bus.gd           # 전역 이벤트 버스 (Autoload)
│   ├── game_manager.gd        # 게임 상태 관리 (Autoload)
│   ├── stats_manager.gd       # 통계 저장/로드 (Autoload)
│   └── audio_manager.gd       # 오디오 관리 (Autoload)
├── player/
│   └── player_base.gd         # 플레이어 기본 클래스
├── enemies/
│   ├── enemy_base.gd          # 적 기본 클래스 + Separation
│   ├── enemy_data.gd          # 적 데이터 리소스
│   └── spawn_manager.gd       # 스폰 + 컬링 + Elite
├── weapons/
│   ├── weapon_base.gd         # 원거리 무기 베이스
│   ├── weapon_data.gd         # 무기 데이터 리소스
│   ├── weapon_manager.gd      # 다중 무기 관리
│   ├── melee_weapon_base.gd   # 근접 무기 베이스
│   ├── slash_effect.gd        # 슬래시 이펙트
│   └── projectile.gd          # 발사체
├── pickups/
│   ├── xp_gem.gd              # XP 젬 픽업
│   └── health_pickup.gd       # 체력 회복 픽업
├── progression/
│   ├── xp_system.gd           # XP/레벨 시스템
│   ├── skill_data.gd          # 스킬 데이터 리소스
│   ├── skill_manager.gd       # 스킬 관리 (무기/패시브 분리)
│   ├── stat_modifier.gd       # 스탯 수정자 (FLAT/PERCENT/MULTIPLY)
│   └── stat_manager.gd        # 중앙 스탯 계산기
├── ui/
│   ├── main_menu.gd           # 메인 메뉴 (게임 시작 화면)
│   ├── stats_screen.gd        # 통계 화면
│   ├── skill_selection_ui.gd  # 스킬 선택 UI 베이스
│   ├── hud_base.gd            # HUD 베이스
│   └── minimap_base.gd        # 미니맵 베이스
└── world_generator/
    ├── world_config.gd        # 월드 설정 리소스
    └── world_generator.gd     # 청크 기반 월드 생성
```

---

## 아키텍처 개요

```
┌─────────────────────────────────────────────────────────────────┐
│                      Core (Autoload)                            │
│  ┌──────────────┐                      ┌───────────────────┐   │
│  │   EventBus   │◄────────────────────►│   GameManager     │   │
│  │  (시그널 허브) │                      │   (상태 관리)      │   │
│  └──────────────┘                      └───────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
         ▲                    ▲                    ▲
         │ emit/connect       │                    │
    ┌────┴────┐          ┌────┴────┐          ┌────┴────┐
    │ Player  │          │ Enemies │          │   UI    │
    │ ┌─────┐ │          │ ┌─────┐ │          │ ┌─────┐ │
    │ │Stats│ │          │ │Spawn│ │          │ │ HUD │ │
    │ │Weap │ │          │ │Cull │ │          │ │Mini │ │
    │ │Skill│ │          │ │Elite│ │          │ │Skill│ │
    │ └─────┘ │          │ └─────┘ │          │ └─────┘ │
    └─────────┘          └─────────┘          └─────────┘
```

---

## 새 게임에 적용하기

### 1. 공유 스크립트 복사

```bash
cp -r _shared/scripts/ your-game/_shared/scripts/
```

### 2. project.godot 설정

```ini
[autoload]
EventBus="*res://_shared/scripts/core/event_bus.gd"
GameManager="*res://_shared/scripts/core/game_manager.gd"
StatsManager="*res://_shared/scripts/core/stats_manager.gd"

[layer_names]
2d_physics/layer_1="landscape"
2d_physics/layer_2="players"
2d_physics/layer_3="bullets"
2d_physics/layer_4="enemies"
2d_physics/layer_5="pickups"
```

### 3. 씬 구조 (EntityLayer 패턴)

TileMap과 캐릭터/적의 렌더링 분리를 위해 CanvasLayer 사용:

```
World (Node2D)
├── TileMap
├── EntityLayer (CanvasLayer, layer=1, follow_viewport=true)
│   ├── Player
│   └── SpawnManager
├── UI (CanvasLayer)
└── HUD (CanvasLayer)
```

---

## Core Systems

### EventBus

전역 이벤트 버스로 시스템 간 느슨한 결합을 제공합니다.

#### 주요 시그널

| 카테고리 | 시그널 | 파라미터 |
|---------|--------|----------|
| Game | `game_started` | - |
| | `game_over` | `stats: Dictionary` |
| | `game_restarted` | - |
| Timer | `timer_updated` | `remaining: float, total: float` |
| | `cycle_completed` | `cycle_number: int` |
| Player | `player_spawned` | `player` |
| | `player_died` | `player, position` |
| | `player_damaged` | `player, amount, current_health` |
| | `player_healed` | `player, amount, current_health` |
| | `player_level_up` | `player, new_level` |
| Enemy | `enemy_spawned` | `enemy` |
| | `enemy_killed` | `enemy, position, xp_value` |
| | `enemy_damaged` | `enemy, amount` |
| Pickup | `pickup_collected` | `pickup, collector` |
| | `xp_gained` | `amount, total` |
| Wave | `wave_started` | `wave_number` |

#### 사용법

```gdscript
# 발행
var event_bus = get_node_or_null("/root/EventBus")
if event_bus:
    event_bus.enemy_killed.emit(self, global_position, xp_value)

# 구독
func _ready() -> void:
    var event_bus = get_node_or_null("/root/EventBus")
    if event_bus:
        event_bus.enemy_killed.connect(_on_enemy_killed)
```

### GameManager

게임 상태와 통계를 중앙에서 관리합니다.

```gdscript
# 상태
GameManager.is_playing
GameManager.is_game_over
GameManager.game_time        # 경과 시간
GameManager.remaining_time   # 카운트다운 남은 시간
GameManager.kill_count
GameManager.cycle_count      # 완료된 사이클 수

# 메서드
GameManager.start_game()
GameManager.trigger_game_over()
GameManager.restart_game()
GameManager.get_final_stats() -> Dictionary
GameManager.get_formatted_time() -> String         # "M:SS" 형식
GameManager.get_formatted_remaining_time() -> String
```

타이머 이벤트는 EventBus를 통해 발행됩니다:
- `timer_updated(remaining, total)` - 매 프레임
- `cycle_completed(cycle_number)` - 사이클 완료 시

### StatsManager

게임 결과를 저장하고 누적 통계를 제공합니다.

```gdscript
# 저장 경로
const SAVE_PATH = "user://stats.json"

# 게임 결과 저장 (게임오버 시 자동 호출)
StatsManager.save_result(result: Dictionary)

# 통계 조회
StatsManager.get_stats() -> Dictionary
StatsManager.get_formatted_stats() -> Dictionary  # UI 표시용
StatsManager.has_played() -> bool

# 통계 초기화
StatsManager.reset_stats()
```

저장되는 통계:
- `total_plays` - 총 플레이 횟수
- `total_time` - 총 플레이 시간
- `total_kills` - 총 처치 수
- `total_xp` - 총 획득 XP
- `best_level`, `best_kills`, `best_time`, `best_wave` - 최고 기록
- `recent_results` - 최근 10게임 기록

---

## Stat System

### StatModifier

스탯 수정자 모드:

```gdscript
enum ModifierMode {
    FLAT,      # 기본값에 더함: base + value
    PERCENT,   # 퍼센트 증가: base * (1 + value)
    MULTIPLY   # 곱연산: base * value
}
```

### StatManager

중앙 집중식 스탯 계산:

```gdscript
# 수정자 추가
stat_manager.add_modifier(StatModifier.new("move_speed", 20, FLAT))
stat_manager.add_modifier(StatModifier.new("damage", 0.1, PERCENT))

# 계산된 스탯 조회
var speed = stat_manager.get_move_speed()
var damage = stat_manager.get_damage()
```

---

## Weapon System

### WeaponManager

다중 무기 슬롯 관리 (최대 3개):

```gdscript
const MAX_WEAPONS = 3

# 무기 추가
weapon_manager.add_weapon(weapon_data) -> bool

# 무기 업그레이드
weapon_manager.upgrade_weapon(weapon_id)

# 옵션 조회 (레벨업 시)
weapon_manager.get_available_options() -> Array
```

### WeaponBase vs MeleeWeaponBase

| 타입 | 클래스 | 동작 |
|------|--------|------|
| 원거리 | `WeaponBase` | 발사체 스폰, 쿨다운 |
| 근접 | `MeleeWeaponBase` | Arc 슬래시, 범위 데미지 |

### WeaponData

```gdscript
@export var damage: float = 10.0
@export var fire_rate: float = 0.5
@export var is_melee: bool = false
@export var max_level: int = 5
@export var level_damage: Array[float] = []
@export var level_fire_rate: Array[float] = []
```

---

## Enemy System

### EnemyBase

적 기본 클래스 (추적, 공격, 드롭, 분리):

```gdscript
# 주요 변수
@export var enemy_data: EnemyData  # 스탯, 드롭 설정

var is_elite: bool = false  # Elite 플래그 (컬링 제외)
var separation_radius: float = 20.0
var separation_force: float = 80.0
var damage_multiplier: float = 1.0  # 난이도 스케일링

# 오버라이드 가능
func _get_movement_velocity() -> Vector2
func _spawn_drops() -> void
```

### EnemyData

적 데이터 리소스:

```gdscript
@export_group("Stats")
@export var max_health: float = 10.0
@export var move_speed: float = 50.0
@export var damage: float = 10.0
@export var knockback_resistance: float = 0.0

@export_group("Rewards")
@export var xp_value: int = 1

@export_group("Health Drop")
@export var health_drop_base_chance: float = 0.05      # 기본 5%
@export var health_drop_low_hp_chance: float = 0.20    # 저체력 시 20%
@export var health_drop_low_hp_threshold: float = 0.3  # 30% 이하 시
```

### SpawnManager

스폰 + 컬링 + Elite 지원:

```gdscript
@export var max_enemies: int = 50
@export var cull_distance: float = 600.0  # 이 거리 이상 적은 컬링 대상
@export var spawn_container: Node  # 명시적 스폰 위치 (미설정 시 부모)

var current_enemy_count: int = 0   # 일반 적
var current_elite_count: int = 0   # Elite (별도 관리)

# Elite 스폰 (max_enemies 무시)
func spawn_elite(data: EnemyData, pos: Vector2) -> EnemyBase
```

### Separation Steering

적끼리 겹침 방지 (물리 충돌 없이):

```gdscript
func _get_separation_velocity() -> Vector2:
    var separation = Vector2.ZERO
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if enemy == self: continue
        var dist = global_position.distance_to(enemy.global_position)
        if dist < separation_radius:
            separation += (global_position - enemy.global_position).normalized()
    return separation.normalized() * separation_force
```

**장점**: O(n) 복잡도, 물리 엔진 우회, 부드러운 동작

### Distance Culling

먼 적 자동 삭제:

```gdscript
func _cull_distant_enemies(count: int) -> int:
    # 1. cull_distance 이상 떨어진 non-elite 적 수집
    # 2. 거리 내림차순 정렬
    # 3. 가장 먼 적부터 삭제
```

---

## Skill System

### SkillManager

무기/패시브 분리 관리:

```gdscript
const MAX_PASSIVE_SLOTS = 3

# 무기 옵션 조회
func get_weapon_options() -> Array

# 패시브 옵션 조회
func get_passive_options() -> Array

# 슬롯 체크
func can_acquire_passive() -> bool
```

### SkillData

```gdscript
enum SkillType { PASSIVE, WEAPON }

@export var skill_type: SkillType
@export var target_stat: String  # "move_speed", "damage" 등
@export var modifier_mode: StatModifier.ModifierMode
@export var level_values: Array[float]
```

---

## UI Systems

### MainMenu

게임 시작 화면:

```gdscript
# 버튼
- Start Game → level.tscn으로 전환
- Statistics → StatsScreen 표시
- Quit → 게임 종료
```

### StatsScreen

누적 통계 표시:

```gdscript
signal back_requested

# StatsManager에서 통계 조회
# - 누적 통계 (플레이 수, 총 시간, 총 킬 등)
# - 최고 기록 (오렌지 하이라이트)
# - 최근 게임 5개 표시
```

### EntityLayer 패턴

TileMap 색깔이 캐릭터에 영향주는 문제 해결:

```gdscript
# level.tscn 구조
[node name="EntityLayer" type="CanvasLayer" parent="."]
layer = 1
follow_viewport_enabled = true

[node name="Player" parent="EntityLayer"]
[node name="SpawnManager" parent="EntityLayer"]
```

### SkillSelectionUI

레벨업 시 스킬 선택:

```gdscript
func show_selection(options: Array) -> void
func _on_skill_selected(skill, index: int) -> void

signal skill_selected(skill, level: int)
```

---

## World Generator

### WorldConfig

월드 생성 설정 리소스:

```gdscript
@export_group("Noise")
@export var noise_seed: int = 0        # 0이면 랜덤
@export var noise_frequency: float = 0.001
@export var fractal_octaves: int = 7

@export_group("Chunks")
@export var chunk_size: int = 16
@export var render_distance: int = 10
@export var generation_distance: int = 15

@export_group("Biome Thresholds")
@export var water_threshold: float = 0.0
@export var sand_start: float = -0.025
@export var grass_start: float = 0.135
@export var cliff_start: float = 0.535

@export_group("Walkable")
@export var walkable_layers: Array[int] = [1, 2]  # sand, grass
@export var blocking_layers: Array[int] = [3]     # cliff
@export var water_layer: int = 0

func is_tile_walkable(layers: Dictionary) -> bool
```

**Walkable 판단 로직:**
1. `blocking_layers`에 포함된 레이어가 있으면 → 걸을 수 없음
2. `water_layer`만 있으면 → 걸을 수 없음
3. `walkable_layers`에 포함된 레이어가 있으면 → 걸을 수 있음

### WorldGenerator

청크 기반 무한 월드 생성:

```gdscript
var generator = WorldGenerator.new(config)
generator.initialize(custom_seed)

# 청크 생성 (백그라운드 스레드 가능)
var chunk_data = generator.generate_chunk_data(Vector2i(0, 0))

# 타일 정보 조회
var is_walkable = generator.is_walkable(x, y)
var biome = generator.get_biome_at(x, y)

# 안전한 스폰 위치 찾기
var spawn_pos = generator.find_safe_spawn()
```

---

## Collision Layers

| Layer | Value | 용도 |
|-------|-------|------|
| 1 | 1 | 환경 (벽, 장애물) |
| 2 | 2 | Player |
| 3 | 4 | Bullets |
| 4 | 8 | Enemies |
| 5 | 16 | Pickups |

### 권장 설정

- **Player**: Layer 2, Mask 1+8+16
- **Enemy**: Layer 8, Mask 1+2+4
- **Bullet**: Layer 4, Mask 8
- **XP Gem**: Layer 16, Mask 2

---

## 체크리스트

### 새 게임 설정

- [ ] `_shared/scripts/` 복사
- [ ] `project.godot`에 Autoload 추가
- [ ] Collision layers 설정
- [ ] EntityLayer CanvasLayer 추가

### Player 설정

- [ ] PlayerBase 상속
- [ ] StatManager 초기화
- [ ] WeaponManager 초기화
- [ ] SkillManager 초기화

### Enemy 설정

- [ ] EnemyBase 상속
- [ ] EnemyData 리소스 생성
- [ ] SpawnManager에 spawn_container 설정

### UI 설정

- [ ] HUD 연결 (체력바, XP바)
- [ ] SkillSelectionUI 연결
- [ ] GameOver UI 연결

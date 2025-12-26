# Vampire Survivors Framework 계획서

## 1. 현재 상태 분석

### 구현 완료
| 시스템 | 상태 | 위치 |
|--------|------|------|
| 무한 월드 생성 | ✅ | `_shared/scripts/world_generator/` |
| 8방향 이동 | ✅ | `test-game/scenes/player.gd` |
| 방향 기반 발사 | ✅ | `test-game/scenes/player.gd` |
| 모바일 조이스틱 | ✅ | `test-game/scenes/virtual_joystick.gd` |
| 줌 UI | ✅ | `test-game/scenes/zoom_ui.gd` |
| 지형 충돌 | ✅ | `test-game/scenes/level.gd` |

### 뱀서라이크에 필요하지만 미구현
| 시스템 | 우선순위 | 복잡도 |
|--------|----------|--------|
| 자동 공격 무기 시스템 | 🔴 Critical | High |
| 적 스폰 및 AI | 🔴 Critical | High |
| 경험치/레벨업 | 🔴 Critical | Medium |
| 업그레이드 선택 UI | 🔴 Critical | Medium |
| 스탯 시스템 | 🟡 High | Medium |
| 픽업 시스템 (젬, 체력) | 🟡 High | Low |
| 웨이브/난이도 관리 | 🟡 High | Medium |
| 데미지 시스템 | 🟡 High | Low |
| 플레이어 체력/사망 | 🟡 High | Low |
| 게임 타이머 | 🟢 Medium | Low |
| 보스 시스템 | 🟢 Medium | High |
| 업적/언락 | 🔵 Low | Medium |
| 메타 진행 (골드) | 🔵 Low | Medium |

---

## 2. 공유 모듈 아키텍처

```
_shared/
├── scripts/
│   ├── world_generator/          # ✅ 기존
│   │   ├── world_config.gd
│   │   └── world_generator.gd
│   │
│   ├── combat/                   # 🆕 전투 시스템
│   │   ├── damage_system.gd      # 데미지 계산, 히트박스
│   │   ├── health_component.gd   # 체력 관리 컴포넌트
│   │   └── hitbox.gd             # Area2D 기반 히트박스
│   │
│   ├── weapons/                  # 🆕 무기 시스템
│   │   ├── weapon_base.gd        # 추상 무기 클래스
│   │   ├── weapon_data.gd        # 무기 데이터 리소스
│   │   ├── patterns/
│   │   │   ├── projectile_pattern.gd   # 투사체 (화살, 탄환)
│   │   │   ├── area_pattern.gd         # 범위 공격 (마늘, 성경)
│   │   │   ├── orbital_pattern.gd      # 공전 (성경, 십자가)
│   │   │   ├── beam_pattern.gd         # 빔/레이저
│   │   │   └── melee_pattern.gd        # 근접 (채찍)
│   │   └── weapon_manager.gd     # 무기 슬롯 관리
│   │
│   ├── enemies/                  # 🆕 적 시스템
│   │   ├── enemy_base.gd         # 추상 적 클래스
│   │   ├── enemy_data.gd         # 적 데이터 리소스
│   │   ├── behaviors/
│   │   │   ├── chase_behavior.gd       # 추적 AI
│   │   │   ├── swarm_behavior.gd       # 군집 AI
│   │   │   ├── ranged_behavior.gd      # 원거리 AI
│   │   │   └── boss_behavior.gd        # 보스 AI
│   │   └── spawn_manager.gd      # 스폰 로직
│   │
│   ├── progression/              # 🆕 진행 시스템
│   │   ├── experience_system.gd  # XP, 레벨업
│   │   ├── upgrade_system.gd     # 업그레이드 관리
│   │   ├── upgrade_data.gd       # 업그레이드 리소스
│   │   └── stats_system.gd       # 스탯 계산 (곱연산/합연산)
│   │
│   ├── pickups/                  # 🆕 픽업 시스템
│   │   ├── pickup_base.gd        # 추상 픽업
│   │   ├── xp_gem.gd             # 경험치 젬
│   │   ├── health_pickup.gd      # 체력 회복
│   │   └── chest.gd              # 보물상자
│   │
│   ├── waves/                    # 🆕 웨이브 시스템
│   │   ├── wave_manager.gd       # 웨이브 진행
│   │   ├── wave_data.gd          # 웨이브 정의 리소스
│   │   └── difficulty_scaler.gd  # 시간별 난이도
│   │
│   └── ui/                       # 🆕 UI 컴포넌트
│       ├── health_bar.gd
│       ├── xp_bar.gd
│       ├── game_timer.gd
│       ├── kill_counter.gd
│       ├── level_up_menu.gd      # 업그레이드 선택 UI
│       ├── pause_menu.gd
│       └── damage_numbers.gd     # 플로팅 데미지
│
├── resources/                    # 🆕 기본 리소스 템플릿
│   ├── weapons/
│   │   └── example_weapon.tres
│   ├── enemies/
│   │   └── example_enemy.tres
│   └── upgrades/
│       └── example_upgrade.tres
│
└── docs/
    └── vampire-survivors-framework-plan.md  # 이 문서
```

---

## 3. 핵심 시스템 상세 설계

### 3.1 무기 시스템 (Weapons)

**WeaponBase** - 모든 무기의 부모 클래스:
```gdscript
class_name WeaponBase
extends Node2D

signal weapon_fired(weapon: WeaponBase)
signal weapon_leveled_up(weapon: WeaponBase, new_level: int)

@export var weapon_data: WeaponData

var current_level: int = 1
var cooldown_timer: float = 0.0

# 오버라이드 필수
func _fire() -> void:
    pass

# 스탯 계산 (기본값 * 레벨 보너스 * 플레이어 스탯)
func get_damage() -> float:
    return weapon_data.base_damage * _get_level_multiplier() * owner.stats.damage_mult

func get_cooldown() -> float:
    return weapon_data.base_cooldown * owner.stats.cooldown_mult

func get_area() -> float:
    return weapon_data.base_area * owner.stats.area_mult

func get_projectile_count() -> int:
    return weapon_data.base_projectiles + weapon_data.projectiles_per_level * (current_level - 1)
```

**WeaponData** - 무기 정의 리소스:
```gdscript
class_name WeaponData
extends Resource

@export var weapon_name: String
@export var icon: Texture2D
@export var description: String

@export_group("Base Stats")
@export var base_damage: float = 10.0
@export var base_cooldown: float = 1.0
@export var base_area: float = 1.0
@export var base_projectiles: int = 1
@export var base_speed: float = 300.0
@export var base_duration: float = 2.0
@export var base_pierce: int = 1

@export_group("Scaling")
@export var damage_per_level: float = 5.0
@export var projectiles_per_level: int = 0
@export var max_level: int = 8

@export_group("Pattern")
@export var pattern_scene: PackedScene  # 발사 패턴 씬
@export var projectile_scene: PackedScene  # 투사체 씬
```

**패턴 예시 - ProjectilePattern**:
```gdscript
class_name ProjectilePattern
extends WeaponBase

func _fire() -> void:
    var count = get_projectile_count()
    var spread = weapon_data.spread_angle
    var base_angle = owner.aim_direction.angle()

    for i in range(count):
        var angle_offset = lerp(-spread/2, spread/2, float(i) / max(count-1, 1))
        var direction = Vector2.RIGHT.rotated(base_angle + angle_offset)
        _spawn_projectile(direction)

func _spawn_projectile(direction: Vector2) -> void:
    var proj = weapon_data.projectile_scene.instantiate()
    proj.global_position = owner.global_position
    proj.direction = direction
    proj.damage = get_damage()
    proj.speed = weapon_data.base_speed
    proj.pierce = weapon_data.base_pierce
    get_tree().current_scene.add_child(proj)
```

---

### 3.2 적 시스템 (Enemies)

**EnemyBase**:
```gdscript
class_name EnemyBase
extends CharacterBody2D

signal died(enemy: EnemyBase, position: Vector2)

@export var enemy_data: EnemyData

var health: float
var target: Node2D  # 플레이어

func _ready() -> void:
    health = enemy_data.max_health
    add_to_group("enemies")

func take_damage(amount: float, source: Node = null) -> void:
    health -= amount
    _on_hit(amount, source)
    if health <= 0:
        _die()

func _die() -> void:
    died.emit(self, global_position)
    _spawn_drops()
    queue_free()

func _spawn_drops() -> void:
    # XP 젬 스폰
    var xp_value = enemy_data.xp_value
    # ... 젬 생성 로직
```

**SpawnManager**:
```gdscript
class_name SpawnManager
extends Node

@export var spawn_config: SpawnConfig
@export var player: Node2D

var spawn_timer: float = 0.0
var difficulty_mult: float = 1.0

func _process(delta: float) -> void:
    spawn_timer += delta
    _check_spawn_waves()

func _spawn_enemy(enemy_data: EnemyData, count: int = 1) -> void:
    for i in range(count):
        var pos = _get_spawn_position()
        var enemy = enemy_data.scene.instantiate()
        enemy.global_position = pos
        enemy.target = player
        get_tree().current_scene.add_child(enemy)

func _get_spawn_position() -> Vector2:
    # 화면 밖 랜덤 위치 계산
    var viewport = get_viewport().get_visible_rect().size
    var angle = randf() * TAU
    var distance = viewport.length() / 2 + 100
    return player.global_position + Vector2.RIGHT.rotated(angle) * distance
```

---

### 3.3 진행 시스템 (Progression)

**StatsSystem**:
```gdscript
class_name StatsSystem
extends Node

# 기본 스탯
var base_stats := {
    "max_health": 100.0,
    "speed": 200.0,
    "damage_mult": 1.0,
    "cooldown_mult": 1.0,
    "area_mult": 1.0,
    "projectile_speed_mult": 1.0,
    "duration_mult": 1.0,
    "pickup_range": 50.0,
    "luck": 1.0,
    "growth": 1.0,  # XP 획득량
    "armor": 0.0,
    "regen": 0.0,
}

# 업그레이드로 인한 추가 스탯
var flat_bonuses: Dictionary = {}  # 합연산
var mult_bonuses: Dictionary = {}  # 곱연산

func get_stat(stat_name: String) -> float:
    var base = base_stats.get(stat_name, 0.0)
    var flat = flat_bonuses.get(stat_name, 0.0)
    var mult = mult_bonuses.get(stat_name, 1.0)
    return (base + flat) * mult

func add_flat_bonus(stat_name: String, value: float) -> void:
    flat_bonuses[stat_name] = flat_bonuses.get(stat_name, 0.0) + value

func add_mult_bonus(stat_name: String, value: float) -> void:
    mult_bonuses[stat_name] = mult_bonuses.get(stat_name, 1.0) * value
```

**ExperienceSystem**:
```gdscript
class_name ExperienceSystem
extends Node

signal xp_gained(amount: int)
signal level_up(new_level: int)

var current_xp: int = 0
var current_level: int = 1

# 레벨별 필요 XP (뱀서 공식)
func get_xp_for_level(level: int) -> int:
    if level <= 20:
        return 5 + (level - 1) * 10
    elif level <= 40:
        return 205 + (level - 20) * 13
    else:
        return 465 + (level - 40) * 16

func add_xp(amount: int) -> void:
    var growth = owner.stats.get_stat("growth")
    current_xp += int(amount * growth)
    xp_gained.emit(amount)

    while current_xp >= get_xp_for_level(current_level):
        current_xp -= get_xp_for_level(current_level)
        current_level += 1
        level_up.emit(current_level)
```

**UpgradeSystem**:
```gdscript
class_name UpgradeSystem
extends Node

signal upgrade_selected(upgrade: UpgradeData)

@export var available_upgrades: Array[UpgradeData]
@export var upgrade_choices: int = 3

var acquired_upgrades: Dictionary = {}  # upgrade_id -> level

func get_random_choices() -> Array[UpgradeData]:
    var choices: Array[UpgradeData] = []
    var pool = _get_valid_upgrades()
    pool.shuffle()

    for i in range(min(upgrade_choices, pool.size())):
        choices.append(pool[i])

    return choices

func _get_valid_upgrades() -> Array[UpgradeData]:
    var valid: Array[UpgradeData] = []
    for upgrade in available_upgrades:
        var current_level = acquired_upgrades.get(upgrade.id, 0)
        if current_level < upgrade.max_level:
            valid.append(upgrade)
    return valid

func apply_upgrade(upgrade: UpgradeData) -> void:
    var current_level = acquired_upgrades.get(upgrade.id, 0)
    acquired_upgrades[upgrade.id] = current_level + 1

    # 무기 업그레이드
    if upgrade.weapon_scene:
        _handle_weapon_upgrade(upgrade)

    # 패시브 스탯 업그레이드
    for stat_bonus in upgrade.stat_bonuses:
        owner.stats.add_flat_bonus(stat_bonus.stat_name, stat_bonus.value)

    upgrade_selected.emit(upgrade)
```

---

### 3.4 레벨업 UI

**LevelUpMenu**:
```gdscript
class_name LevelUpMenu
extends CanvasLayer

signal upgrade_chosen(upgrade: UpgradeData)

@export var choice_button_scene: PackedScene
@onready var container: VBoxContainer = $Panel/VBoxContainer

func show_choices(choices: Array[UpgradeData]) -> void:
    get_tree().paused = true

    for child in container.get_children():
        child.queue_free()

    for upgrade in choices:
        var btn = choice_button_scene.instantiate()
        btn.setup(upgrade)
        btn.pressed.connect(_on_choice_selected.bind(upgrade))
        container.add_child(btn)

    show()

func _on_choice_selected(upgrade: UpgradeData) -> void:
    hide()
    get_tree().paused = false
    upgrade_chosen.emit(upgrade)
```

---

## 4. 게임별 커스터마이징 포인트

각 게임에서 정의해야 할 요소:

### 4.1 테마/애셋
| 요소 | 예시 |
|------|------|
| 타일셋 | 중세, SF, 동양, 좀비 등 |
| 캐릭터 스프라이트 | 기사, 마법사, 사무라이 등 |
| 적 스프라이트 | 슬라임, 좀비, 로봇 등 |
| 무기 이펙트 | 화염, 얼음, 전기 등 |
| UI 테마 | 판타지, 사이버펑크 등 |

### 4.2 게임별 리소스 파일
```
my-survivors-game/
├── resources/
│   ├── weapons/
│   │   ├── sword.tres      # 근접
│   │   ├── fireball.tres   # 투사체
│   │   ├── garlic.tres     # 범위
│   │   └── bible.tres      # 공전
│   ├── enemies/
│   │   ├── slime.tres
│   │   ├── skeleton.tres
│   │   └── boss_dragon.tres
│   ├── upgrades/
│   │   ├── passive_might.tres
│   │   ├── passive_speed.tres
│   │   └── weapon_sword.tres
│   └── waves/
│       ├── wave_1.tres
│       └── wave_2.tres
└── balance/
    └── game_config.tres    # 게임 밸런스 설정
```

### 4.3 GameConfig 리소스
```gdscript
class_name GameConfig
extends Resource

@export_group("Game Rules")
@export var game_duration: float = 1800.0  # 30분
@export var starting_weapons: Array[WeaponData]
@export var max_weapons: int = 6

@export_group("Difficulty")
@export var base_spawn_rate: float = 1.0
@export var spawn_rate_growth: float = 0.1  # 분당 증가
@export var enemy_health_growth: float = 0.05
@export var enemy_damage_growth: float = 0.03

@export_group("Progression")
@export var xp_gem_values: Array[int] = [1, 5, 25, 100]
@export var level_up_choices: int = 3
@export var reroll_cost: int = 50

@export_group("Meta")
@export var gold_per_kill: float = 0.1
@export var gold_per_minute: float = 10.0
```

---

## 5. 구현 로드맵

### Phase 1: Core Combat (1주)
1. ✅ 플레이어 이동/방향
2. 🔲 WeaponBase + ProjectilePattern
3. 🔲 EnemyBase + ChaseBehavior
4. 🔲 HealthComponent + DamageSystem
5. 🔲 기본 스폰 매니저

### Phase 2: Progression (1주)
1. 🔲 ExperienceSystem + XP 젬
2. 🔲 LevelUpMenu UI
3. 🔲 UpgradeSystem
4. 🔲 StatsSystem
5. 🔲 2-3개 기본 무기 패턴

### Phase 3: Polish (1주)
1. 🔲 웨이브 시스템
2. 🔲 난이도 스케일링
3. 🔲 게임 타이머 + 승리 조건
4. 🔲 데미지 숫자 + 이펙트
5. 🔲 사운드 시스템

### Phase 4: Content (지속)
1. 🔲 다양한 무기 패턴
2. 🔲 보스 시스템
3. 🔲 무기 진화 시스템
4. 🔲 메타 진행 (골드, 언락)
5. 🔲 캐릭터 선택

---

## 6. 첫 번째 뱀서 게임 제안

### "Medieval Survivors"
- **테마**: 중세 판타지
- **타일셋**: 기존 Paradise Asset 활용
- **시작 무기**: 검 (근접), 화살 (투사체)
- **적**: 슬라임, 스켈레톤, 고블린
- **보스**: 드래곤

### 필요 에셋
| 종류 | 필요량 | 소스 |
|------|--------|------|
| 적 스프라이트 | 5-10종 | itch.io 무료 에셋 |
| 무기 이펙트 | 5-8종 | 생성 or 무료 에셋 |
| UI 요소 | 기본 세트 | Godot 기본 + 커스텀 |

---

## 7. 파일 의존성 다이어그램

```
┌─────────────────────────────────────────────────────────────┐
│                        Game Scene                            │
│  ┌─────────┐  ┌───────────┐  ┌────────────┐  ┌───────────┐ │
│  │ Player  │  │  Enemies  │  │  Pickups   │  │    UI     │ │
│  └────┬────┘  └─────┬─────┘  └─────┬──────┘  └─────┬─────┘ │
└───────┼─────────────┼──────────────┼───────────────┼───────┘
        │             │              │               │
        ▼             ▼              ▼               ▼
┌───────────────────────────────────────────────────────────┐
│                    _shared Modules                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────┐ │
│  │ Weapons  │  │ Enemies  │  │ Pickups  │  │    UI     │ │
│  │ System   │  │ System   │  │ System   │  │Components │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └─────┬─────┘ │
│       │             │              │               │       │
│       └─────────────┴──────────────┴───────────────┘       │
│                           │                                 │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐  │
│  │              Core Systems                            │  │
│  │  ┌────────────┐  ┌────────────┐  ┌───────────────┐  │  │
│  │  │   Stats    │  │  Combat    │  │  Progression  │  │  │
│  │  │  System    │  │  System    │  │    System     │  │  │
│  │  └────────────┘  └────────────┘  └───────────────┘  │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

---

## 8. 다음 단계

1. **즉시**: 이 계획 검토 및 우선순위 확정
2. **Phase 1 시작**: WeaponBase, EnemyBase, DamageSystem 구현
3. **테스트 게임**: test-game을 첫 뱀서 게임으로 전환

질문:
- 어떤 테마의 첫 게임을 만들까요?
- 무기 패턴 중 우선 구현할 것은?
- 모바일 우선 vs PC 우선?

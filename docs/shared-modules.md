# Shared Modules 사용 가이드

뱀서라이크 게임 프레임워크의 공유 모듈 사용법입니다.

## 디렉토리 구조

```
_shared/scripts/
├── core/
│   ├── event_bus.gd         # 전역 이벤트 버스 (Autoload)
│   └── game_manager.gd      # 게임 상태 관리 (Autoload)
├── player/
│   └── player_base.gd       # 플레이어 기본 클래스
├── enemies/
│   ├── enemy_base.gd        # 적 기본 클래스
│   └── spawn_manager.gd     # 적 스폰 관리
├── weapons/
│   └── projectile.gd        # 발사체 기본 클래스
├── pickups/
│   └── xp_gem.gd            # XP 젬 픽업
├── progression/
│   ├── xp_system.gd         # XP/레벨 시스템 (독립)
│   ├── skill_data.gd        # 스킬 데이터 리소스
│   └── skill_manager.gd     # 스킬 관리
└── ui/
    └── skill_selection_ui.gd # 스킬 선택 UI 베이스
```

## 새 게임에 적용하기

### 1. 공유 스크립트 복사

Godot은 심볼릭 링크를 지원하지 않으므로 파일을 복사해야 합니다.

```bash
cp -r _shared/scripts/ your-game/_shared/scripts/
```

### 2. 경로 기반 상속 사용

class_name은 에디터에서 프로젝트를 열어야 등록됩니다. CLI 실행 호환성을 위해 경로 기반 상속을 권장합니다.

```gdscript
# 권장 (경로 기반)
extends "res://_shared/scripts/player/player_base.gd"

# 에디터에서만 작동 (class_name 기반)
extends PlayerBase
```

---

## Core System (EventBus + GameManager)

시스템 간 느슨한 결합과 중앙화된 게임 상태 관리를 위한 핵심 아키텍처입니다.

### 아키텍처 개요

```
┌─────────────────────────────────────────────────────────────┐
│                        EventBus                             │
│  (전역 시그널 허브 - 시스템 간 직접 참조 없이 통신)           │
└─────────────────────────────────────────────────────────────┘
         ▲              ▲              ▲              ▲
         │              │              │              │
    emit │         emit │         emit │        connect│
         │              │              │              │
    ┌────┴────┐   ┌────┴────┐   ┌────┴────┐   ┌─────┴─────┐
    │ Player  │   │ Enemy   │   │  Level  │   │GameManager│
    └─────────┘   └─────────┘   └─────────┘   └───────────┘
                                                    │
                                              ┌─────┴─────┐
                                              │ Game Over │
                                              │    UI     │
                                              └───────────┘
```

### 설정 방법

`project.godot`에 autoload 추가:

```ini
[autoload]

EventBus="*res://_shared/scripts/core/event_bus.gd"
GameManager="*res://_shared/scripts/core/game_manager.gd"
```

### EventBus

전역 이벤트 버스로 시스템 간 느슨한 결합을 제공합니다.

#### 사용 가능한 시그널

| 카테고리 | 시그널 | 파라미터 | 설명 |
|---------|--------|----------|------|
| **Game Flow** | `game_started` | - | 게임 시작 |
| | `game_paused` | - | 일시정지 |
| | `game_resumed` | - | 재개 |
| | `game_over` | `stats: Dictionary` | 게임오버 |
| | `game_restarted` | - | 재시작 |
| **Player** | `player_spawned` | `player: Node2D` | 스폰 |
| | `player_died` | `player: Node2D, position: Vector2` | 사망 |
| | `player_damaged` | `player: Node2D, amount: float, current_health: float` | 피격 |
| | `player_healed` | `player: Node2D, amount: float, current_health: float` | 회복 |
| | `player_level_up` | `player: Node2D, new_level: int` | 레벨업 |
| **Enemy** | `enemy_spawned` | `enemy: Node2D` | 적 스폰 |
| | `enemy_killed` | `enemy: Node2D, position: Vector2, xp_value: int` | 적 처치 |
| | `enemy_damaged` | `enemy: Node2D, amount: float` | 적 피격 |
| **Combat** | `damage_dealt` | `source, target, amount` | 데미지 발생 |
| | `projectile_fired` | `projectile, source` | 발사체 발사 |
| | `projectile_hit` | `projectile, target` | 발사체 명중 |
| **Pickup** | `pickup_spawned` | `pickup, position` | 픽업 스폰 |
| | `pickup_collected` | `pickup, collector` | 픽업 획득 |
| | `xp_gained` | `amount: int, total: int` | XP 획득 |
| **Skill** | `skill_acquired` | `skill, level: int` | 스킬 획득 |
| | `skill_upgraded` | `skill, level: int` | 스킬 업그레이드 |
| | `skill_selection_requested` | `options: Array` | 스킬 선택 요청 |
| **Wave** | `wave_started` | `wave_number: int` | 웨이브 시작 |
| | `wave_completed` | `wave_number: int` | 웨이브 완료 |

#### 이벤트 발행 (emit)

```gdscript
# 어디서든 이벤트 발행 가능
var event_bus = get_node_or_null("/root/EventBus")
if event_bus:
    event_bus.enemy_killed.emit(self, global_position, xp_value)
```

#### 이벤트 구독 (connect)

```gdscript
func _ready() -> void:
    var event_bus = get_node_or_null("/root/EventBus")
    if event_bus:
        event_bus.enemy_killed.connect(_on_enemy_killed)
        event_bus.player_level_up.connect(_on_player_level_up)

func _on_enemy_killed(enemy: Node2D, position: Vector2, xp: int) -> void:
    # 킬 카운트 UI 업데이트 등
    kill_label.text = str(kill_count)
```

### GameManager

게임 상태와 통계를 중앙에서 관리합니다.

#### 게임 상태

```gdscript
enum GameState {
    NONE,         # 초기 상태
    INITIALIZING, # 초기화 중
    PLAYING,      # 플레이 중
    PAUSED,       # 일시정지
    GAME_OVER     # 게임오버
}
```

#### 제공 속성

| 속성 | 타입 | 설명 |
|------|------|------|
| `current_state` | `GameState` | 현재 게임 상태 |
| `is_playing` | `bool` | 플레이 중 여부 |
| `is_paused` | `bool` | 일시정지 여부 |
| `is_game_over` | `bool` | 게임오버 여부 |
| `game_time` | `float` | 게임 경과 시간 (초) |
| `kill_count` | `int` | 처치 수 |
| `total_xp` | `int` | 획득 XP 총합 |
| `current_wave` | `int` | 현재 웨이브 |
| `player` | `Node2D` | 플레이어 참조 |

#### 제공 메서드

```gdscript
# 게임 흐름 제어
GameManager.start_game()        # 게임 시작
GameManager.pause_game()        # 일시정지
GameManager.resume_game()       # 재개
GameManager.trigger_game_over() # 게임오버 트리거
GameManager.restart_game()      # 재시작

# 유틸리티
GameManager.get_final_stats()   # 최종 통계 Dictionary 반환
GameManager.get_formatted_time() # "3:45" 형식 시간 문자열

# 레벨 등록 (Level에서 호출)
GameManager.register_level(self)
```

### 통합 사용 예시

#### Level.gd에서 GameManager 사용

```gdscript
extends Node2D

var game_manager: Node = null
var event_bus: Node = null

func _ready() -> void:
    add_to_group("level")

    # Core system 참조
    game_manager = get_node_or_null("/root/GameManager")
    event_bus = get_node_or_null("/root/EventBus")

    # GameManager에 등록 및 게임 시작
    if game_manager:
        game_manager.register_level(self)
        game_manager.start_game()

    # 플레이어 스폰 알림
    if event_bus and player:
        event_bus.player_spawned.emit(player)

func _process(delta: float) -> void:
    # GameManager 상태 체크
    if game_manager and game_manager.is_game_over:
        return
    # ... 게임 로직
```

#### Game Over UI에서 EventBus 구독

```gdscript
extends CanvasLayer

func _ready() -> void:
    var event_bus = get_node_or_null("/root/EventBus")
    if event_bus:
        event_bus.game_over.connect(_on_game_over)
    hide()

func _on_game_over(stats: Dictionary) -> void:
    # stats = { "level": 5, "kills": 42, "time": 185.5, "xp": 1250 }
    _update_stats_display(stats)
    get_tree().paused = true
    show()

func _on_restart_pressed() -> void:
    var game_manager = get_node_or_null("/root/GameManager")
    if game_manager:
        game_manager.restart_game()
```

#### 커스텀 시스템에서 이벤트 구독

```gdscript
# 데미지 숫자 팝업 시스템
extends Node

func _ready() -> void:
    var event_bus = get_node_or_null("/root/EventBus")
    if event_bus:
        event_bus.enemy_damaged.connect(_spawn_damage_number)

func _spawn_damage_number(enemy: Node2D, amount: float) -> void:
    var popup = damage_popup_scene.instantiate()
    popup.global_position = enemy.global_position
    popup.set_value(amount)
    get_tree().root.add_child(popup)
```

### 하위 호환성

EventBus가 없는 환경에서도 동작하도록 폴백 처리:

```gdscript
func _die() -> void:
    # EventBus로 이벤트 발행 (권장)
    if event_bus:
        event_bus.enemy_killed.emit(self, global_position, xp)
    else:
        # 폴백: 직접 레벨에 통보
        var level = get_tree().get_first_node_in_group("level")
        if level and level.has_method("on_enemy_killed"):
            level.on_enemy_killed(xp)
```

### 장점

1. **느슨한 결합**: 시스템 간 직접 참조 없이 통신
2. **중앙화된 상태**: 게임 상태를 한 곳에서 관리
3. **확장성**: 새 시스템 추가 시 기존 코드 수정 불필요
4. **테스트 용이**: 개별 시스템을 독립적으로 테스트 가능
5. **하위 호환**: EventBus 없이도 동작

---

## PlayerBase

플레이어의 체력, 무적, XP, 레벨업 시스템을 제공합니다.

### 시그널

로컬 시그널과 EventBus 시그널을 동시에 발행합니다.

| Signal | Parameters | EventBus | 설명 |
|--------|------------|----------|------|
| `health_changed` | `current: float, max_health: float` | `player_damaged`, `player_healed` | 체력 변경 시 |
| `died` | - | `player_died` | 사망 시 |
| `level_up` | `new_level: int` | `player_level_up` | 레벨업 시 |
| `xp_changed` | `current: int, required: int` | - | XP 변경 시 |

### 오버라이드 가능한 메서드

```gdscript
func _on_ready() -> void:
    # _ready() 후 호출됨
    player_sprite = $PlayerSprite  # 스프라이트 참조 설정 필수

func _get_input_direction() -> Vector2:
    # 이동 입력 (기본: WASD)
    return Input.get_vector("left", "right", "up", "down")

func _calculate_velocity(direction: Vector2, delta: float) -> Vector2:
    # 속도 계산 (지형 충돌 등 커스텀 로직)
    return direction * speed

func _on_physics_process(delta: float) -> void:
    # 추가 physics 로직 (발사 등)
    pass

func _on_die() -> void:
    # 사망 처리 (게임오버 화면 등)
    pass

func _on_level_up() -> void:
    # 레벨업 처리 (스킬 선택 UI 등)
    pass
```

### 사용 예시

```gdscript
extends "res://_shared/scripts/player/player_base.gd"

func _on_ready() -> void:
    player_sprite = $PlayerSprite
    player_sprite.play("idle_down")

func _on_level_up() -> void:
    # 스킬 선택 UI 표시
    skill_selection_ui.show_selection(skill_manager.request_skill_selection())

func _on_die() -> void:
    # 게임오버 대신 체력 리셋
    current_health = max_health
```

---

## Projectile

직선 이동하는 발사체의 기본 클래스입니다.

### Export 변수

| Variable | Type | Default | 설명 |
|----------|------|---------|------|
| `speed` | float | 2000.0 | 이동 속도 |
| `damage` | float | 1.0 | 데미지 |
| `knockback_force` | float | 100.0 | 넉백 힘 |
| `lifetime` | float | 0.5 | 수명 (초) |

### 오버라이드 가능한 메서드

```gdscript
func _on_hit(body: Node) -> void:
    # 충돌 시 추가 처리 (파티클 등)
    pass
```

### 사용 예시

```gdscript
extends "res://_shared/scripts/weapons/projectile.gd"

func _on_hit(body: Node) -> void:
    # 폭발 파티클 생성
    var explosion = explosion_scene.instantiate()
    explosion.global_position = global_position
    get_tree().root.add_child(explosion)
```

---

## EnemyBase

적의 체력, 이동, 공격, 드롭 시스템을 제공합니다.

### 시그널

로컬 시그널과 EventBus 시그널을 동시에 발행합니다.

| Signal | Parameters | EventBus | 설명 |
|--------|------------|----------|------|
| `died` | `enemy: EnemyBase, position: Vector2` | `enemy_killed` | 사망 시 |
| `damaged` | `enemy: EnemyBase, amount: float` | `enemy_damaged` | 피격 시 |

스폰 시 `enemy_spawned` EventBus 시그널이 자동 발행됩니다.

### 주요 변수

```gdscript
@export var enemy_data: EnemyData  # 적 데이터 리소스

var target: Node2D      # 추적 대상
var is_dead: bool       # 사망 여부
var is_attacking: bool  # 공격 중 여부

# 애니메이션 프레임 설정
var walk_frames_start: int = 0
var walk_frames_end: int = 5
var attack_frames_start: int = 6
var attack_frames_end: int = 9
```

### 오버라이드 가능한 메서드

```gdscript
func _get_movement_velocity() -> Vector2:
    # 이동 방향 계산 (기본: 타겟 추적)
    pass

func _spawn_drops() -> void:
    # 드롭 아이템 스폰 (기본: XP 젬)
    pass
```

---

## Skill System

레벨업 시 스킬 선택 UI를 제공하는 시스템입니다.

### 구성 요소

1. **SkillData** - 스킬 정의 리소스
2. **SkillManager** - 스킬 획득/관리
3. **SkillSelectionUI** - 선택 UI 베이스

### SkillData 리소스 생성

```
[gd_resource type="Resource" script_class="SkillData" load_steps=2 format=3]

[ext_resource type="Script" path="res://_shared/scripts/progression/skill_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = "attack_speed"
display_name = "Attack Speed"
description = "Increases fire rate"
skill_type = 1
max_level = 5
level_values = [0.2, 0.18, 0.15, 0.12, 0.1]
level_descriptions = ["Fire rate: 0.20s", "Fire rate: 0.18s", ...]
```

### SkillManager 사용

```gdscript
const SkillManagerClass = preload("res://_shared/scripts/progression/skill_manager.gd")

var skill_manager: SkillManagerClass

func _setup_skill_system() -> void:
    skill_manager = SkillManagerClass.new()

    # 스킬 풀 설정
    var skills: Array = []
    for path in skill_paths:
        skills.append(load(path))
    skill_manager.set_skill_pool(skills)

    # 시그널 연결
    skill_manager.skill_acquired.connect(_on_skill_changed)
    skill_manager.skill_upgraded.connect(_on_skill_changed)

func _on_level_up() -> void:
    var options = skill_manager.request_skill_selection()
    skill_selection_ui.show_selection(options)

func _apply_skill_effects() -> void:
    # 스킬 값 조회
    var attack_speed = skill_manager.get_skill_value("attack_speed")
    if attack_speed > 0:
        fire_rate = attack_speed
```

### SkillSelectionUI 커스터마이즈

```gdscript
extends "res://_shared/scripts/ui/skill_selection_ui.gd"

func _setup_ui() -> void:
    # UI 초기화
    pass

func _update_skill_display() -> void:
    # 카드 생성 로직
    for i in range(current_options.size()):
        var card = _create_skill_card(current_options[i], i)
        cards_container.add_child(card)

func _create_skill_card(skill, index: int) -> Control:
    # 게임별 카드 스타일링
    pass
```

---

## Collision Layers

권장 충돌 레이어 설정:

| Layer | Value | 용도 |
|-------|-------|------|
| 1 | 1 | 환경 (벽, 장애물) |
| 2 | 2 | Player |
| 3 | 4 | Enemies |
| 4 | 8 | Bullets |
| 5 | 16 | Pickups (XP 젬 등) |

### 충돌 마스크 설정

- **Player**: Layer 2, Mask 4+16 (적, 픽업 감지)
- **Enemy**: Layer 4, Mask 2+8 (플레이어, 총알 감지)
- **Bullet**: Layer 8, Mask 4 (적만 감지)
- **XP Gem**: Layer 16, Mask 2 (플레이어만 감지)

---

## 체크리스트

새 게임 시작 시:

### 필수 설정
- [ ] `_shared/scripts/` 복사
- [ ] `project.godot`에 Autoload 추가 (EventBus, GameManager)
- [ ] Collision layers 설정

### Player 시스템
- [ ] player.gd에서 PlayerBase 상속
- [ ] `player_sprite` 참조 설정
- [ ] bullet.gd에서 Projectile 상속

### Skill 시스템
- [ ] `resources/skills/` 폴더에 스킬 리소스 생성
- [ ] skill_selection UI 씬 생성
- [ ] player에서 `_apply_skill_effects()` 구현

### Level 통합
- [ ] Level에서 GameManager 등록 (`register_level`)
- [ ] Level에서 `start_game()` 호출
- [ ] Game Over UI에서 EventBus 구독

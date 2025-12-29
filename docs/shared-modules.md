# Shared Modules 사용 가이드

뱀서라이크 게임 프레임워크의 공유 모듈 사용법입니다.

## 디렉토리 구조

```
_shared/scripts/
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

## PlayerBase

플레이어의 체력, 무적, XP, 레벨업 시스템을 제공합니다.

### 시그널

| Signal | Parameters | 설명 |
|--------|------------|------|
| `health_changed` | `current: float, max_health: float` | 체력 변경 시 |
| `died` | - | 사망 시 |
| `level_up` | `new_level: int` | 레벨업 시 |
| `xp_changed` | `current: int, required: int` | XP 변경 시 |

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

| Signal | Parameters | 설명 |
|--------|------------|------|
| `died` | `enemy: EnemyBase, position: Vector2` | 사망 시 |
| `damaged` | `enemy: EnemyBase, amount: float` | 피격 시 |

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

- [ ] `_shared/scripts/` 복사
- [ ] player.gd에서 PlayerBase 상속
- [ ] `player_sprite` 참조 설정
- [ ] bullet.gd에서 Projectile 상속
- [ ] `resources/skills/` 폴더에 스킬 리소스 생성
- [ ] skill_selection UI 씬 생성
- [ ] player에서 `_apply_skill_effects()` 구현
- [ ] Collision layers 설정

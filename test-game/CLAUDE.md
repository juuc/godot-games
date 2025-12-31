# test-game - Claude Code Context

Vampire Survivors 스타일 2D 탑다운 슈터 프로젝트입니다.

## 문서

| 문서 | 설명 |
|------|------|
| [TODO.md](TODO.md) | 작업 목록, 진행 상황 |
| [../docs/architecture.md](../docs/architecture.md) | 시스템 아키텍처, 설계 패턴 |
| [../docs/shared-modules.md](../docs/shared-modules.md) | 공유 모듈 API 레퍼런스 |

---

## Tech Stack

- **Engine**: Godot 4.5+
- **Language**: GDScript
- **Renderer**: GL Compatibility

---

## Quick Reference

### 씬 구조 (EntityLayer 패턴)

```
World (Node2D)
├── TileMap
├── EntityLayer (CanvasLayer)  ← Player, SpawnManager 여기에
│   ├── Player
│   └── SpawnManager
├── HUD
├── MinimapUI
└── GameOver
```

### Core Autoloads

```ini
# project.godot
[autoload]
EventBus="*res://_shared/scripts/core/event_bus.gd"
GameManager="*res://_shared/scripts/core/game_manager.gd"
StatsManager="*res://_shared/scripts/core/stats_manager.gd"
```

### Collision Layers

| Layer | Value | Name |
|-------|-------|------|
| 1 | 1 | landscape |
| 2 | 2 | players |
| 3 | 4 | bullets |
| 4 | 8 | enemies |
| 5 | 16 | pickups |

---

## Key Files

### 게임 로직

| 파일 | 역할 |
|------|------|
| `scenes/level.gd` | 월드 관리, 청크, TileMap |
| `scenes/player.gd` | 이동, 발사, 레벨업 |
| `scenes/ui/main_menu.gd` | 메인 메뉴 (시작, 통계, 종료) |
| `scenes/ui/stats_screen.gd` | 누적 통계 화면 |
| `scenes/ui/hud.gd` | 체력바, XP바, 타이머 |
| `scenes/ui/game_over.gd` | 게임오버 화면 |

### 리소스

| 경로 | 내용 |
|------|------|
| `resources/weapons/` | 무기 데이터 (.tres) |
| `resources/enemies/` | 적 데이터 (.tres) |
| `resources/skills/` | 스킬 데이터 (.tres) |
| `resources/world_config.tres` | 월드 생성 설정 |

### 공유 스크립트 (주요)

| 경로 | Class | 역할 |
|------|-------|------|
| `_shared/scripts/core/event_bus.gd` | - | 이벤트 허브 |
| `_shared/scripts/core/game_manager.gd` | - | 상태/통계 |
| `_shared/scripts/core/stats_manager.gd` | - | 통계 저장/로드 |
| `_shared/scripts/enemies/spawn_manager.gd` | SpawnManager | 스폰, 컬링 |
| `_shared/scripts/weapons/weapon_manager.gd` | WeaponManager | 다중 무기 |
| `_shared/scripts/progression/stat_manager.gd` | StatManager | 스탯 계산 |

---

## 프로젝트 구조

```
test-game/
├── _shared/scripts/        # 공유 모듈
├── Assets/                 # 에셋 (타일셋, 스프라이트, 사운드)
├── resources/              # 게임 데이터 (.tres)
├── scenes/                 # 씬 파일 (.tscn, .gd)
└── project.godot
```

---

## 실행

```bash
# Godot MCP로 실행
mcp__godot-mcp__run_project projectPath="/Users/juucheol/games/godot-games/test-game"

# Godot CLI
godot --path /path/to/test-game
```

---

## 주의사항

### EntityLayer 필수

Player와 SpawnManager는 반드시 EntityLayer 안에 배치:

```
[node name="EntityLayer" type="CanvasLayer"]
layer = 1
follow_viewport_enabled = true
```

이유: TileMap 색상이 캐릭터/적 스프라이트에 영향주는 문제 방지

### 스탯 수정자 모드

| 모드 | 계산 | 예시 |
|------|------|------|
| FLAT | base + value | 10 + 5 = 15 |
| PERCENT | base * (1 + value) | 10 * 1.2 = 12 |
| MULTIPLY | base * value | 10 * 0.9 = 9 |

### 이벤트 사용

```gdscript
# 발행
var event_bus = get_node_or_null("/root/EventBus")
if event_bus:
    event_bus.enemy_killed.emit(self, pos, xp)

# 구독
func _ready():
    var event_bus = get_node_or_null("/root/EventBus")
    if event_bus:
        event_bus.enemy_killed.connect(_on_enemy_killed)
```

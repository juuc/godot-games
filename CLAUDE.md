# godot-games - Monorepo

뱀서라이크 스타일 게임 프레임워크 모노레포입니다.

## 프로젝트 구조

```
godot-games/
├── _shared/scripts/     # 공유 모듈 (원본)
├── docs/                # 문서
│   └── shared-modules.md  # 공유 모듈 사용 가이드
├── test-game/           # 테스트 게임 프로젝트
└── [future-game]/       # 추가 게임 프로젝트
```

## 문서

| 문서 | 설명 |
|------|------|
| [docs/shared-modules.md](docs/shared-modules.md) | 공유 모듈 사용 가이드 (PlayerBase, Projectile, EnemyBase, Skill System) |

## 공유 모듈 요약

### `_shared/scripts/`

| 경로 | 설명 |
|------|------|
| `core/event_bus.gd` | 전역 이벤트 버스 (시스템 간 느슨한 결합) |
| `core/game_manager.gd` | 게임 상태 관리 (시간, 킬, XP 등) |
| `core/audio_manager.gd` | 중앙 오디오 관리 (SFX 풀, 음악, EventBus 연동) |
| `player/player_base.gd` | 체력, 무적, XP, 레벨업, StatManager 통합 |
| `enemies/enemy_base.gd` | 추적, 공격, 드롭 |
| `enemies/spawn_manager.gd` | 웨이브 스폰, EventBus 연동 |
| `weapons/weapon_data.gd` | 무기 데이터 리소스 (데미지, 발사속도 등) |
| `weapons/weapon_base.gd` | 무기 로직 (발사, 쿨다운, modifier) |
| `weapons/projectile.gd` | 발사체 |
| `pickups/xp_gem.gd` | XP 젬, EventBus 연동 |
| `progression/skill_data.gd` | 스킬 데이터 (target_stat, modifier_mode) |
| `progression/skill_manager.gd` | 스킬 관리 |
| `progression/stat_modifier.gd` | 스탯 수정자 (FLAT, PERCENT, MULTIPLY) |
| `progression/stat_manager.gd` | 중앙 스탯 계산기 |
| `ui/skill_selection_ui.gd` | 스킬 선택 UI |

### Core 시스템 (Autoload)

새 게임에서 EventBus와 GameManager를 사용하려면 `project.godot`에 추가:

```ini
[autoload]
EventBus="*res://_shared/scripts/core/event_bus.gd"
GameManager="*res://_shared/scripts/core/game_manager.gd"
```

## 새 게임 생성

1. 새 Godot 프로젝트 폴더 생성
2. `_shared/scripts/` 복사
3. [shared-modules.md](docs/shared-modules.md) 참고하여 상속 구현

## 주의사항

- Godot은 심볼릭 링크 미지원 → 공유 스크립트는 각 프로젝트에 복사
- CLI 실행 호환성을 위해 경로 기반 상속 사용 (`extends "res://..."`)
- 각 프로젝트별 세부사항은 해당 프로젝트의 `CLAUDE.md` 참고

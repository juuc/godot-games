# godot-games - Monorepo

뱀서라이크 스타일 게임 프레임워크 모노레포입니다.

## 프로젝트 구조

```
godot-games/
├── docs/                    # 프레임워크 문서
│   ├── architecture.md      # 시스템 아키텍처
│   └── shared-modules.md    # API 레퍼런스
├── test-game/               # 테스트 게임 프로젝트
│   ├── _shared/scripts/     # 공유 모듈 (복사본)
│   ├── CLAUDE.md            # 프로젝트 컨텍스트
│   └── TODO.md              # 작업 목록
└── [future-game]/           # 추가 게임 프로젝트
```

## 문서

| 문서 | 설명 |
|------|------|
| [docs/architecture.md](docs/architecture.md) | 시스템 아키텍처, 설계 패턴, 확장 가이드 |
| [docs/shared-modules.md](docs/shared-modules.md) | 공유 모듈 API 레퍼런스 |
| [test-game/TODO.md](test-game/TODO.md) | 현재 작업 목록, 진행 상황 |

---

## 공유 모듈 요약

### Core (Autoload)

| 모듈 | 역할 |
|------|------|
| `event_bus.gd` | 전역 이벤트 버스 (시스템 간 느슨한 결합) |
| `game_manager.gd` | 게임 상태/통계 관리, 타이머 |
| `stats_manager.gd` | 통계 저장/로드 (user://stats.json) |
| `audio_manager.gd` | 중앙 오디오 관리 (SFX 풀, 음악) |

### Player

| 모듈 | 역할 |
|------|------|
| `player_base.gd` | 체력, 무적, XP, 레벨업 |
| `stat_manager.gd` | 중앙 스탯 계산 (FLAT/PERCENT/MULTIPLY) |
| `skill_manager.gd` | 무기/패시브 슬롯 관리 |

### Enemy

| 모듈 | 역할 |
|------|------|
| `enemy_base.gd` | 추적, 공격, 드롭, Separation Steering |
| `enemy_data.gd` | 적 데이터 리소스 (스탯, 드롭 설정) |
| `spawn_manager.gd` | 스폰, Distance Culling, Elite 지원 |

### Weapon

| 모듈 | 역할 |
|------|------|
| `weapon_manager.gd` | 다중 무기 슬롯 (최대 3) |
| `weapon_base.gd` | 원거리 무기 |
| `melee_weapon_base.gd` | 근접 무기 (Arc 슬래시) |
| `projectile.gd` | 발사체 |

### World

| 모듈 | 역할 |
|------|------|
| `world_config.gd` | 월드 설정 (노이즈, 청크, Walkable) |
| `world_generator.gd` | 청크 기반 무한 월드 생성 |

---

## 새 게임 생성

1. 새 Godot 프로젝트 폴더 생성
2. `_shared/scripts/` 복사
3. `project.godot`에 Autoload 추가:
   ```ini
   [autoload]
   EventBus="*res://_shared/scripts/core/event_bus.gd"
   GameManager="*res://_shared/scripts/core/game_manager.gd"
   StatsManager="*res://_shared/scripts/core/stats_manager.gd"
   ```
4. [architecture.md](docs/architecture.md)의 확장 가이드 참고

---

## 주의사항

- **심볼릭 링크 미지원**: Godot은 symlink를 지원하지 않음 → 공유 스크립트는 각 프로젝트에 복사
- **경로 기반 상속**: CLI 호환성을 위해 `extends "res://..."` 사용
- **EntityLayer 필수**: TileMap과 엔티티 렌더링 분리 필요
- **프로젝트별 문서**: 각 프로젝트의 `CLAUDE.md` 참고

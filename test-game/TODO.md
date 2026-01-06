# Test Game - TODO

> **Last Updated**: 2025-01-06

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Core (Autoload)                         │
│  EventBus ─────────────── GameManager                          │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│    Player     │    │   Enemies     │    │      UI       │
│ ┌───────────┐ │    │ ┌───────────┐ │    │ ┌───────────┐ │
│ │StatManager│ │    │ │SpawnMgr   │ │    │ │    HUD    │ │
│ │WeaponMgr  │ │    │ │AttackCtrl │ │    │ │ Minimap   │ │
│ │SkillMgr   │ │    │ │BossCtrl   │ │    │ │SkillSelect│ │
│ └───────────┘ │    │ │Projectile │ │    │ │ GameOver  │ │
└───────────────┘    └───────────────┘    └───────────────┘
```

---

## Current Sprint: 폴리시 & 컨텐츠

### P1: High (핵심 컨텐츠) ✅ 완료

- [x] 적 다양화
  - [x] 원거리 공격 적 (발사체 공격, 파란 크랩)
  - [x] Elite 적 (60초마다 스폰, 스탯 3배)
  - [x] 보스 적 (60초마다 등장, 2페이즈, 원거리)
- [x] 무기 다양화
  - [x] 샷건 (부채꼴 발사)
  - [x] 대검/슬래시 무기
  - [x] 머신건, 스나이퍼
  - [x] 관통탄 (pierce_count)
- [x] 회복 아이템 드롭 (기본 5%, 저체력 20%)
- [x] 보물상자 드롭 (1% 확률)
- [x] 레벨업 무적 시간 (2초)

### P2: Medium (폴리시)

- [ ] **지형 개선 (다중 노이즈)** ⭐ 우선순위 높음
  - [ ] 고도(elevation) 노이즈 추가
  - [ ] 습도(moisture) 노이즈 추가
  - [ ] 다양한 생물군계 조합
  - [ ] 강/호수 생성
- [ ] 킬/시간 통계 UI (게임 중 표시)
- [ ] 무기/패시브 슬롯 HUD 표시
- [ ] 사운드
  - [ ] 레벨업 효과음
  - [ ] 무기 발사 효과음
  - [ ] 피격 효과음
  - [ ] BGM

### P3: Low (나중에)

- [ ] 캐릭터 선택
- [ ] 메타 진행 (영구 업그레이드)
- [ ] 업적 시스템

---

## 완료된 시스템

### Core Systems
| 시스템 | 파일 | 설명 |
|--------|------|------|
| EventBus | `core/event_bus.gd` | 전역 이벤트 버스 (보스 시그널 포함) |
| GameManager | `core/game_manager.gd` | 게임 상태 관리 |
| StatsManager | `core/stats_manager.gd` | 통계 저장/로드 |
| GameConfig | `core/game_config.gd` | 전역 설정 |
| ResourcePaths | `core/resource_paths.gd` | 리소스 경로 상수 |

### Player Systems
| 시스템 | 파일 | 설명 |
|--------|------|------|
| PlayerBase | `player/player_base.gd` | 체력, 무적, XP, 레벨업 |
| StatManager | `progression/stat_manager.gd` | 중앙 스탯 계산 |
| StatModifier | `progression/stat_modifier.gd` | FLAT/PERCENT/MULTIPLY 모드 |
| WeaponManager | `weapons/weapon_manager.gd` | 다중 무기 슬롯 (최대 3) |
| SkillManager | `progression/skill_manager.gd` | 패시브 슬롯 (최대 3) |

### Weapon Systems
| 시스템 | 파일 | 설명 |
|--------|------|------|
| WeaponBase | `weapons/weapon_base.gd` | 무기 로직, 쿨다운, pierce_count |
| WeaponData | `weapons/weapon_data.gd` | 무기 데이터 리소스 |
| MeleeWeaponBase | `weapons/melee_weapon_base.gd` | 근접 무기 베이스 |
| SlashEffect | `weapons/slash_effect.gd` | 슬래시 이펙트 |
| Projectile | `weapons/projectile.gd` | 발사체 (관통 지원) |

### Enemy Systems
| 시스템 | 파일 | 설명 |
|--------|------|------|
| EnemyBase | `enemies/enemy_base.gd` | 추적, 공격, 드롭, 보스 지원 |
| EnemyData | `enemies/enemy_data.gd` | AttackType enum, 보스 설정 |
| EnemyAttackController | `enemies/enemy_attack_controller.gd` | 근접/원거리 공격 위임 |
| EnemyProjectile | `enemies/enemy_projectile.gd` | 적 발사체 |
| BossController | `enemies/boss_controller.gd` | 페이즈 관리, 분노 상태 |
| SpawnManager | `enemies/spawn_manager.gd` | 스폰, 컬링, Elite, 보스 |
| EnemyDropController | `enemies/enemy_drop_controller.gd` | 드롭 로직 |
| DifficultyScaler | `enemies/difficulty_scaler.gd` | 난이도 스케일링 |

### UI Systems
| 시스템 | 파일 | 설명 |
|--------|------|------|
| MainMenu | `ui/main_menu.gd` | 메인 메뉴 |
| StatsScreen | `ui/stats_screen.gd` | 누적 통계 표시 |
| HUD | `ui/hud_base.gd` | 체력바, XP바 |
| Minimap | `ui/minimap_base.gd` | 미니맵 + POI |
| SkillSelection | `ui/skill_selection_ui.gd` | 레벨업 선택 UI |
| GameOver | `ui/game_over.gd` | 게임오버 화면 |

### World Systems
| 시스템 | 파일 | 설명 |
|--------|------|------|
| WorldGenerator | `world_generator/world_generator.gd` | 무한 청크 생성 (단일 노이즈) |
| WorldConfig | `world_generator/world_config.gd` | 월드 설정 리소스 |
| ChunkManager | `scenes/level/chunk_manager.gd` | 청크 로딩/언로딩 |
| AutotileSolver | `scenes/level/autotile_solver.gd` | 오토타일 계산 |

---

## 최근 변경 이력

### 2025-01-06
- [x] 원거리 적 구현 (EnemyAttackController, EnemyProjectile)
- [x] 보스 적 구현 (BossController, 페이즈 시스템)
- [x] EnemyData 확장 (AttackType enum, 보스 설정)
- [x] SpawnManager 보스 스폰 지원
- [x] EventBus 보스 시그널 추가

### 2024-12-31
- [x] 메인 메뉴 시스템 구현
- [x] StatsManager 구현
- [x] 데미지 숫자 팝업 구현

### 2024-12-30
- [x] Elite 적 구현
- [x] 보물상자 드롭 구현
- [x] 웨이브/난이도 시스템 구현
- [x] 체력 픽업 드롭 구현
- [x] 레벨업 무적 시간 구현

---

## 지형 개선 설계 (다중 노이즈)

### 현재 시스템
```
단일 노이즈 → 생물군계 결정
noise < 0.0  → water
noise 0.0~0.15 → sand
noise 0.15~0.55 → grass
noise > 0.55 → cliff
```

### 목표 시스템
```
┌─────────────┐   ┌─────────────┐
│ Elevation   │   │  Moisture   │
│   Noise     │   │   Noise     │
└──────┬──────┘   └──────┬──────┘
       │                 │
       └────────┬────────┘
                ▼
        ┌───────────────┐
        │ Biome Matrix  │
        │               │
        │  Low Moist    │  High Moist
        │  ─────────    │  ──────────
        │  High: Mountain│  High: Snow
        │  Mid: Desert  │  Mid: Forest
        │  Low: Beach   │  Low: Swamp
        └───────────────┘
```

### 구현 계획
1. `WorldConfig`에 다중 노이즈 설정 추가
2. `WorldGenerator`에 elevation/moisture 노이즈 추가
3. 생물군계 매트릭스 로직 구현
4. 새로운 타일셋/터레인 추가

---

## 다음 액션

```
1. 지형 개선 (다중 노이즈)
   - WorldConfig에 elevation/moisture 노이즈 설정 추가
   - WorldGenerator 다중 노이즈 지원
   - 생물군계 매트릭스 구현

2. 폴리시
   - 킬/시간 통계 HUD
   - 무기/패시브 슬롯 HUD
   - 사운드 추가
```

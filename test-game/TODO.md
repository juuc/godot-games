# Test Game - TODO

> **Last Updated**: 2024-12-30

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
│ │WeaponMgr  │ │    │ │Separation │ │    │ │ Minimap   │ │
│ │SkillMgr   │ │    │ │Culling    │ │    │ │SkillSelect│ │
│ └───────────┘ │    │ │Elite      │ │    │ │ GameOver  │ │
└───────────────┘    └───────────────┘    └───────────────┘
```

---

## Current Sprint: 핵심 게임루프 완성

### P0: Critical (게임 플레이 가능)

- [x] ~~색깔 렌더링 버그~~ - EntityLayer로 해결
- [x] ~~적 겹침 문제~~ - Separation Steering 구현
- [x] ~~먼 적 무한 누적~~ - Distance Culling 구현
- [x] ~~Elite 시스템 기반~~ - is_elite 플래그, 별도 카운트
- [x] ~~게임오버 → 재시작 플로우~~ - GameManager + GameOver UI 연동 완료
- [x] ~~웨이브/시간 기반 난이도~~ - SpawnManager 30초 간격, 체력/데미지 스케일링

### P1: High (재미 요소)

- [x] ~~회복 아이템 드롭~~ - 기본 5%, 체력 30% 이하 시 20% 확률
- [x] ~~보물상자 드롭~~ - 1% 확률, 접촉 시 무기/패시브 선택 UI 표시
- [ ] 적 다양화
  - [ ] 원거리 공격 적
  - [ ] Elite 적 구현 (더 크고 강함, 미니맵 표시)
  - [ ] 보스 적 (5분마다 등장)
- [ ] 무기 다양화
  - [ ] 샷건 무기 데이터 추가
  - [ ] 대검(슬래시) 무기 구현
  - [ ] 관통탄 (pierce count)

### P2: Medium (폴리시)

- [ ] 데미지 숫자 팝업
- [ ] 킬/시간 통계 UI
- [ ] 레벨업 시 무적 시간 (2초)
- [ ] 무기/패시브 슬롯 HUD 표시
- [ ] 사운드
  - [ ] 레벨업 효과음
  - [ ] 무기 발사 효과음
  - [ ] 피격 효과음
  - [ ] BGM

### P3: Low (나중에)

- [ ] 메인 메뉴
- [ ] 캐릭터 선택
- [ ] 메타 진행 (영구 업그레이드)
- [ ] 지형 개선 (다중 노이즈)
- [ ] 업적 시스템

---

## 완료된 시스템

### Core Systems
| 시스템 | 파일 | 설명 |
|--------|------|------|
| EventBus | `core/event_bus.gd` | 전역 이벤트 버스 |
| GameManager | `core/game_manager.gd` | 게임 상태 관리 |

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
| WeaponBase | `weapons/weapon_base.gd` | 무기 로직, 쿨다운 |
| WeaponData | `weapons/weapon_data.gd` | 무기 데이터 리소스 |
| MeleeWeaponBase | `weapons/melee_weapon_base.gd` | 근접 무기 베이스 |
| SlashEffect | `weapons/slash_effect.gd` | 슬래시 이펙트 |
| Projectile | `weapons/projectile.gd` | 발사체 |

### Enemy Systems
| 시스템 | 파일 | 설명 |
|--------|------|------|
| EnemyBase | `enemies/enemy_base.gd` | 추적, 공격, 드롭 |
| EnemyData | `enemies/enemy_data.gd` | 적 데이터 리소스 |
| SpawnManager | `enemies/spawn_manager.gd` | 스폰, 컬링, Elite 지원 |
| Separation | `enemy_base.gd` | 적끼리 겹침 방지 |

### UI Systems
| 시스템 | 파일 | 설명 |
|--------|------|------|
| HUD | `ui/hud_base.gd` | 체력바, XP바 |
| Minimap | `ui/minimap_base.gd` | 미니맵 + POI |
| SkillSelection | `ui/skill_selection_ui.gd` | 레벨업 선택 UI |
| GameOver | `ui/game_over.gd` | 게임오버 화면 |

### World Systems
| 시스템 | 파일 | 설명 |
|--------|------|------|
| WorldGenerator | `world_generator/world_generator.gd` | 무한 청크 생성 |
| WorldConfig | `world_generator/world_config.gd` | 월드 설정 리소스 |

---

## 최근 변경 이력

### 2024-12-30
- [x] 보물상자 드롭 구현 (1% 확률, 무기/패시브 선택 UI)
- [x] 게임오버 → 재시작 플로우 검증 (이미 구현됨)
- [x] 웨이브/난이도 시스템 구현 (30초 간격, 체력/데미지 스케일링)
- [x] 체력 픽업 드롭 구현 (기본 5%, 저체력 시 20%)
- [x] EntityLayer로 인한 타일 충돌 버그 수정
- [x] 10분 카운트다운 타이머 구현
- [x] 로딩 화면 구현
- [x] 데미지업 스킬 발사속도 버그 수정 (fire_rate 분리)
- [x] 아키텍처 리팩토링:
  - Timer 시그널 → EventBus 이동
  - 드롭 설정 → EnemyData 이동
  - Walkable 설정 → WorldConfig 이동
- [x] attack_speed 스킬 수정 (PASSIVE 타입, PERCENT 모드)
- [x] 경고 메시지 정리 (모든 컴파일 경고 해결):
  - EventBus 시그널 warning_ignore 추가
  - Integer division 경고 수정
  - 파라미터 섀도잉 수정 (is_visible → visible_state)
  - skill_selection_ui 미사용 시그널 정리
- [x] 문서 체계 정립:
  - `docs/architecture.md` 신규 생성 (설계 철학, 패턴, 확장 가이드)
  - `docs/shared-modules.md` 업데이트 (Timer, Health Drop, Walkable 추가)
  - `test-game/CLAUDE.md` 간소화 (docs 참조로 변경)
  - `CLAUDE.md` 업데이트 (문서 링크 추가)

### 2024-12-29
- [x] EntityLayer 도입으로 타일/스프라이트 색깔 렌더링 문제 해결
- [x] Separation Steering 구현 (적끼리 겹침 방지)
- [x] Distance Culling 구현 (먼 적 자동 삭제)
- [x] Elite 시스템 기반 (`is_elite`, 별도 카운트, 컬링 제외)
- [x] SpawnManager에 `spawn_container` 추가 (의존성 명시화)
- [x] 레벨업 무적 시간 논의

### 이전
- [x] WeaponManager 구현 (다중 무기 슬롯)
- [x] MeleeWeaponBase + SlashEffect 구현
- [x] StatManager + StatModifier 구현
- [x] SkillManager 무기/패시브 분리
- [x] 미니맵 구현 (지형 + POI)
- [x] HUD 구현 (체력바, XP바)
- [x] 스킬 시스템 구현
- [x] 적 밀림 방지 수정
- [x] 총알 겹침 버그 수정

---

## 기술 부채

- [x] ~~아키텍처 정리: Timer 시그널 EventBus로 이동~~
- [x] ~~아키텍처 정리: 드롭 설정 EnemyData로 이동~~
- [x] ~~아키텍처 정리: Walkable 설정 WorldConfig로 이동~~
- [x] ~~EventBus 시그널 경고 정리~~ (warning_ignore 추가)
- [x] ~~Integer division 경고 수정~~ (game_manager, hud, minimap, game_over)
- [x] ~~파라미터 섀도잉 경고 수정~~ (minimap_base is_visible → visible_state)
- [x] ~~skill_selection_ui 미사용 시그널 정리~~
- [x] ~~공유 모듈 문서 최신화~~ (architecture.md 신규 생성, shared-modules.md 업데이트)

---

## 다음 액션

```
1. 적 다양화
   - 원거리 공격 적 (발사체 공격)
   - Elite 적 구현 (더 크고 강함, 미니맵 표시)
   - 보스 적 (5분마다 등장)

2. 무기 다양화
   - 샷건 무기 데이터 추가
   - 관통탄 (pierce count)

3. 폴리시
   - 데미지 숫자 팝업
   - 킬/시간 통계 UI
```

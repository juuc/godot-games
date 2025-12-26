# test-game - Claude Code Context

## Project Overview

2D 탑다운 슈터 with 무한 절차적 월드 생성. RapidWorldGen을 기반으로 하며, 모바일/PC 크로스 플랫폼 지원.

## Tech Stack

- **Engine**: Godot 4.5+
- **Language**: GDScript
- **Target**: PC, iOS, Android

## Architecture

### Shared Module (`_shared/scripts/world_generator/`)

모노레포에서 재사용 가능한 월드 생성 모듈:

```
_shared/scripts/world_generator/
├── world_config.gd    # WorldConfig Resource - 모든 설정 외부화
└── world_generator.gd # WorldGenerator 클래스 - 노이즈, 바이옴, 스폰 로직
```

**WorldConfig 주요 설정**:
- `noise_frequency`: 0.001 (낮을수록 큰 대륙)
- `chunk_size`: 16 (타일 단위)
- `render_distance`: 10, `generation_distance`: 15 (청크 단위)
- Biome thresholds: water < 0.0, sand 0.0~0.15, grass 0.15~0.55, cliff > 0.535

### Core Files

| File | Purpose |
|------|---------|
| `scenes/level.gd` | 월드 관리, 청크 스케줄링, TileMap 렌더링, 오토타일링 솔버 |
| `scenes/player.gd` | 캐릭터 이동, 방향 기반 발사, 애니메이션 |
| `scenes/camera_2d.gd` | 줌 인/아웃 (마우스휠, 버튼) |
| `scenes/virtual_joystick.gd` | 모바일 터치 조이스틱 |
| `scenes/mobile_controls.gd` | 조이스틱 + 발사 버튼 통합 |
| `scenes/zoom_ui.gd` | +/- 줌 버튼 UI |
| `scenes/bullet.gd` | RigidBody2D 탄환 |
| `resources/world_config.tres` | WorldConfig 리소스 인스턴스 |

## Controls

| Platform | Move | Fire | Zoom |
|----------|------|------|------|
| PC | WASD | 자동 (바라보는 방향) | Mouse Wheel |
| Mobile | Virtual Joystick | Fire Button | +/- Buttons |

## Key Features

### 1. 무한 월드 생성
- FastNoiseLite (Simplex + FBM)
- WorkerThreadPool 멀티스레드 청크 생성
- 커스텀 오토타일링 솔버 (fuzzy matching)
- 4개 레이어: Water → Sand → Grass → Cliff

### 2. 플레이어 시스템
- 8방향 스무스 이동 (키보드 + 조이스틱)
- 바라보는 방향으로 자동 조준/발사
- `direction_smoothing`: 부드러운 방향 전환 (0.15)
- 지형 충돌 체크 (물 위 이동 불가)

### 3. 모바일 지원
- CanvasLayer 기반 UI (카메라 독립)
- 가상 조이스틱 (데드존 0.2)
- 발사 버튼 (Input.action_press 시뮬레이션)

### 4. 카메라
- Pixel snap 활성화 (크리스프한 2D)
- position_smoothing 비활성화 (뱀서라이크 스타일)
- Zoom 범위: 1.5 ~ 5.0

## Running the Project

```bash
# Godot 에디터에서 열기
godot --path /path/to/test-game

# 또는 MCP로 실행
# mcp__godot-mcp__run_project with projectPath
```

**단축키**:
- `F5` (또는 `Fn+F5` on Mac): 게임 실행
- `Tab`: 디버그 노이즈 레이어 토글

## Project Structure

```
test-game/
├── _shared/scripts/world_generator/  # 공유 모듈 (복사본)
├── Assets/
│   ├── Paradise/                     # 타일셋, 캐릭터 스프라이트
│   ├── Audio/                        # 사운드
│   └── sprites/                      # 탄환 등
├── resources/
│   └── world_config.tres             # 월드 설정 리소스
├── scenes/
│   ├── level.tscn/gd                 # 메인 씬
│   ├── player.tscn/gd                # 플레이어
│   ├── bullet.tscn/gd                # 탄환
│   ├── camera_2d.gd                  # 카메라 스크립트
│   ├── zoom_ui.tscn/gd               # 줌 UI
│   ├── virtual_joystick.tscn/gd      # 조이스틱
│   └── mobile_controls.tscn/gd       # 모바일 컨트롤
└── project.godot
```

## TileMap Configuration

5개 레이어 (level.tscn의 TileMap):
- Layer 0: water
- Layer 1: sand
- Layer 2: grass
- Layer 3: cliff
- Layer 4: environment (나무 등)

TileSet 소스: `Assets/Paradise/FOR_TUTORIAL/tilemap1.png`
- Terrain autotiling with 8-direction peering bits
- 4 terrains: water(0), sand(1), grass(2), cliff(3)

## Important Notes

### Godot 특이사항
- `res://` 경로는 프로젝트 폴더 내부만 접근 가능
- 심볼릭 링크 미지원 → 공유 스크립트는 복사 필요
- `class_name`은 에디터에서 프로젝트 열어야 등록됨

### 성능 최적화
- `render_budget`: 프레임당 렌더링할 청크 수 (기본 2)
- 청크 언로드: render_distance 밖 청크 자동 제거
- Mutex 사용: 멀티스레드 데이터 접근 보호

### 커스터마이징
새 타일셋 사용 시 `resources/world_config.tres`에서:
1. `layer_*`, `terrain_*` ID 수정
2. `tree_palm_1`, `tree_palm_2`, `tree_forest` 좌표 수정
3. Biome threshold 조정

## Git Info

- Remote: `git@github.com-personal:juuc/godot-games.git`
- Branch: `main`

## Credits

- [RapidWorldGen](https://github.com/TNTGuerrilla/RapidWorldGen) - 원본 월드 생성 레퍼런스
- [Paradise Asset Pack](https://jackie-codes.itch.io/paradise-asset-pack) - 타일셋
- [Godot4Tilemaps](https://github.com/...) - TileSet 설정 레퍼런스

# Godot Games Monorepo

Godot Engine 4.5+로 제작하는 게임 프로젝트 모음입니다.

## Repository Structure

```
godot-games/
├── _shared/                    # 공유 스크립트 및 에셋
│   └── scripts/
│       └── world_generator/    # 2D 무한 월드 생성기
│           ├── world_config.gd
│           └── world_generator.gd
│
├── test-game/                  # 첫 번째 게임: 2D 탑다운 슈터
│   ├── project.godot
│   ├── scenes/
│   └── Assets/
│
└── (future games...)
```

## Games

### 1. test-game
**2D Top-down Shooter with Infinite World**

RapidWorldGen을 기반으로 한 무한 절차적 2D 월드 게임

**Features:**
- 무한 2D 절차적 세계 생성 (Water → Sand → Grass → Cliff)
- 멀티스레드 청크 기반 로딩
- 모바일 지원 (가상 조이스틱 + 발사 버튼)
- 줌 인/아웃 UI

**Controls:**
| Platform | Move | Fire | Zoom |
|----------|------|------|------|
| PC | WASD | Mouse Click | Mouse Wheel |
| Mobile | Virtual Joystick | Fire Button | +/- Buttons |

## Shared Modules

### World Generator (`_shared/scripts/world_generator/`)

재사용 가능한 2D 무한 월드 생성 시스템

**Usage:**
```gdscript
# 1. WorldConfig 리소스 생성 (에디터에서 또는 코드로)
var config = WorldConfig.new()
config.noise_frequency = 0.001
config.chunk_size = 16

# 2. WorldGenerator 초기화
var generator = WorldGenerator.new(config)
generator.initialize()

# 3. 청크 데이터 생성
var chunk_data = generator.generate_chunk_data(Vector2i(0, 0))

# 4. 안전한 스폰 위치 찾기
var spawn = generator.find_safe_spawn()
```

**Customization:**
- `WorldConfig`에서 모든 설정 조정 가능
- 생물군계 임계값, 나무 좌표, 레이어 ID 등
- 다른 타일셋 사용 시 해당 값만 수정

## Tech Stack

- **Engine:** Godot 4.5+
- **Language:** GDScript
- **Target:** PC, Mobile (iOS/Android)

## Getting Started

```bash
# Clone
git clone git@github.com-personal:juuc/godot-games.git

# Open specific game in Godot
# 1. Open Godot
# 2. Import -> Select test-game/project.godot
# 3. Run (F5)
```

## License

MIT License - See individual game folders for specific licenses.

## Credits

- [RapidWorldGen](https://github.com/TNTGuerrilla/RapidWorldGen) - World generation reference
- [Paradise Asset Pack](https://jackiecodes.itch.io/) - Tileset assets

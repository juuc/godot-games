class_name GameConfig
extends Resource

## 게임 전역 설정 리소스
## 게임 밸런스 및 상수 값을 중앙에서 관리
##
## 사용법:
## - Services.config.cycle_duration
## - var config: GameConfig = preload("res://resources/game_config.tres")

# --- Timer Settings ---
@export_group("Timer")
## 한 사이클 지속 시간 (초) - 기본 10분
@export var cycle_duration: float = 600.0
## 노란색 경고 임계값 (초)
@export var warning_threshold_yellow: float = 180.0
## 빨간색 경고 임계값 (초)
@export var warning_threshold_red: float = 60.0

# --- Combat Base Values ---
@export_group("Combat")
## 기본 데미지 (스킬 배수 계산용)
@export var base_damage: float = 1.0
## 기본 발사 속도 (스킬 배수 계산용)
@export var base_fire_rate: float = 0.25
## 레벨업 후 무적 시간 (초)
@export var levelup_invincibility_duration: float = 1.0

# --- Slot Limits ---
@export_group("Slots")
## 최대 무기 슬롯 수
@export var max_weapon_slots: int = 3
## 최대 패시브 스킬 슬롯 수
@export var max_passive_slots: int = 3

# --- Drop Settings ---
@export_group("Drops")
## 체력 픽업 기본 드롭 확률
@export var health_drop_base_chance: float = 0.05
## 저체력 시 체력 픽업 드롭 확률
@export var health_drop_low_hp_chance: float = 0.20
## 저체력 판정 임계값 (최대 체력 대비 비율)
@export var health_drop_low_hp_threshold: float = 0.3
## 보물상자 기본 드롭 확률
@export var treasure_drop_chance: float = 0.01

# --- Enemy Combat Settings ---
@export_group("Enemy Combat")
## 적 분리 감지 반경
@export var enemy_separation_radius: float = 20.0
## 적 분리 힘
@export var enemy_separation_force: float = 80.0
## 적 공격 쿨다운 (초)
@export var enemy_attack_cooldown: float = 1.0
## 적 공격 범위
@export var enemy_attack_range: float = 25.0
## 넉백 감쇠율
@export var knockback_decay: float = 10.0

# --- Animation Settings ---
@export_group("Animation")
## 적 애니메이션 속도 (초당 프레임)
@export var enemy_animation_speed: float = 10.0
## 방향 전환 스무딩
@export var direction_smoothing: float = 0.15

# --- UI Settings ---
@export_group("UI")
## 슬롯 크기
@export var slot_size: Vector2 = Vector2(36, 36)
## 무기 슬롯 색상
@export var weapon_slot_color: Color = Color(1.0, 0.6, 0.2)
## 패시브 슬롯 색상
@export var passive_slot_color: Color = Color(0.3, 0.6, 1.0)
## 빈 슬롯 색상
@export var empty_slot_color: Color = Color(0.2, 0.2, 0.2, 0.5)

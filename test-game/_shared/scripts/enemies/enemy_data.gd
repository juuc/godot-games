class_name EnemyData
extends Resource

## 적 데이터 리소스
## 각 적 타입의 스탯과 설정을 정의합니다.

enum AttackType { MELEE, RANGED }

@export_group("Basic Info")
@export var enemy_name: String = "Enemy"
@export var scene: PackedScene  ## 적 씬 (스프라이트 포함)
@export var is_boss: bool = false  ## 보스 여부

@export_group("Stats")
@export var max_health: float = 10.0
@export var move_speed: float = 50.0
@export var damage: float = 10.0  ## 플레이어에게 주는 데미지
@export var knockback_resistance: float = 0.0  ## 0 = 풀 넉백, 1 = 넉백 없음

@export_group("Attack")
@export var attack_type: AttackType = AttackType.MELEE
@export var attack_range: float = 25.0  ## 근접: 25, 원거리: 200+
@export var attack_cooldown: float = 1.0  ## 공격 간격 (초)
@export var projectile_scene: PackedScene  ## 원거리 공격용 발사체 씬
@export var projectile_speed: float = 200.0  ## 발사체 속도
@export var stop_to_attack: bool = true  ## 공격 시 멈춤 여부 (원거리는 false 권장)

@export_group("Rewards")
@export var xp_value: int = 1  ## 처치 시 XP
@export var drop_chance: float = 1.0  ## 드롭 확률 (0~1)

@export_group("Health Drop")
@export var health_drop_base_chance: float = 0.05  ## 기본 드롭 확률 (5%)
@export var health_drop_low_hp_chance: float = 0.20  ## 플레이어 저체력 시 (20%)
@export var health_drop_low_hp_threshold: float = 0.3  ## 저체력 기준 (30% 이하)

@export_group("Treasure Drop")
@export var treasure_drop_chance: float = 0.01  ## 보물상자 드롭 확률 (1%)

@export_group("Scaling")
@export var health_scale: float = 1.0  ## 시간에 따른 체력 증가율
@export var damage_scale: float = 1.0  ## 시간에 따른 데미지 증가율

@export_group("Boss Settings")
@export var boss_scale: float = 2.0  ## 보스 크기 배율
@export var boss_phases: int = 1  ## 페이즈 수
@export var phase_health_thresholds: Array[float] = []  ## 페이즈 전환 체력 비율 (예: [0.5] = 50%에서 2페이즈)

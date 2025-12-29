class_name EnemyData
extends Resource

## 적 데이터 리소스
## 각 적 타입의 스탯과 설정을 정의합니다.

@export_group("Basic Info")
@export var enemy_name: String = "Enemy"
@export var scene: PackedScene  ## 적 씬 (스프라이트 포함)

@export_group("Stats")
@export var max_health: float = 10.0
@export var move_speed: float = 50.0
@export var damage: float = 10.0  ## 플레이어에게 주는 데미지
@export var knockback_resistance: float = 0.0  ## 0 = 풀 넉백, 1 = 넉백 없음

@export_group("Rewards")
@export var xp_value: int = 1  ## 처치 시 XP
@export var drop_chance: float = 1.0  ## 드롭 확률 (0~1)

@export_group("Scaling")
@export var health_scale: float = 1.0  ## 시간에 따른 체력 증가율
@export var damage_scale: float = 1.0  ## 시간에 따른 데미지 증가율

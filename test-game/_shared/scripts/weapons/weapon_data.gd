class_name WeaponData
extends Resource

## 무기 데이터 리소스
## 무기의 기본 속성을 정의합니다.

@export_group("Basic Info")
@export var id: String = "default_weapon"
@export var display_name: String = "Default Weapon"
@export var description: String = ""
@export var icon: Texture2D

@export_group("Combat Stats")
## 기본 데미지
@export var base_damage: float = 1.0
## 발사 간격 (초)
@export var fire_rate: float = 0.25
## 넉백 힘
@export var knockback_force: float = 100.0

@export_group("Projectile")
## 발사체 씬
@export var projectile_scene: PackedScene
## 발사체 속도
@export var projectile_speed: float = 2000.0
## 발사체 수명
@export var projectile_lifetime: float = 0.5
## 한 번에 발사하는 발사체 수
@export var projectiles_per_shot: int = 1
## 발사체 간 각도 (다중 발사 시)
@export var spread_angle: float = 15.0

@export_group("Behavior")
## 자동 발사 여부
@export var auto_fire: bool = true
## 가장 가까운 적 자동 조준
@export var auto_aim: bool = false
## 관통 횟수 (0 = 관통 안함)
@export var pierce_count: int = 0

@export_group("Audio")
## 발사 사운드
@export var fire_sound: AudioStream

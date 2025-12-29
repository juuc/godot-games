extends Resource

## 미니맵 POI (Point of Interest) 설정
## 새로운 엔티티 타입 추가 시 이 리소스를 확장

@export var poi_type: String = ""
@export var display_name: String = ""
@export var color: Color = Color.WHITE
@export var size: float = 3.0
@export var priority: int = 0  ## 높을수록 위에 그려짐
@export var blink: bool = false  ## 깜빡임 효과
@export var blink_speed: float = 5.0
@export var show_on_minimap: bool = true
@export var show_direction_indicator: bool = false  ## 화면 밖일 때 방향 표시
@export var max_display_count: int = -1  ## -1 = 무제한
@export var group_name: String = ""  ## 자동 등록할 그룹명 (비어있으면 수동 등록)

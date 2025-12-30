extends CanvasLayer

## 로딩 화면
## 초기 청크 생성 완료될 때까지 표시

signal loading_complete

@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var hint_label: Label = $VBoxContainer/HintLabel

var hints: Array[String] = [
	"Generating terrain...",
	"Planting trees...",
	"Preparing enemies...",
	"Almost ready..."
]

var is_loading: bool = true

func _ready() -> void:
	# 시작 시 표시
	show()
	_update_hint(0)

## 진행률 업데이트 (0.0 ~ 1.0)
func update_progress(progress: float) -> void:
	if progress_bar:
		progress_bar.value = progress

	# 힌트 텍스트 변경
	var hint_index = int(progress * (hints.size() - 1))
	_update_hint(hint_index)

func _update_hint(index: int) -> void:
	if hint_label and index < hints.size():
		hint_label.text = hints[index]

## 로딩 완료 - 페이드 아웃
func finish_loading() -> void:
	if not is_loading:
		return

	is_loading = false

	# 진행률 100%
	if progress_bar:
		progress_bar.value = 1.0
	_update_hint(hints.size() - 1)

	# 짧은 딜레이 후 페이드 아웃
	await get_tree().create_timer(0.3).timeout

	var tween = create_tween()
	tween.tween_property($Background, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property($VBoxContainer, "modulate:a", 0.0, 0.5)
	await tween.finished

	loading_complete.emit()
	hide()

## 즉시 숨기기 (페이드 없이)
func hide_immediately() -> void:
	is_loading = false
	hide()

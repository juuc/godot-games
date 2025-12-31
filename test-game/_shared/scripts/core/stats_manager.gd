extends Node

## 통계 관리자 (Autoload)
## 게임 결과를 저장하고 누적 통계를 제공합니다.
## 저장 경로: user://stats.json

const SAVE_PATH = "user://stats.json"
const MAX_RECENT_RESULTS = 10
const SAVE_VERSION = 1

## 현재 통계 (로드된 데이터)
var stats: Dictionary = {}

func _ready() -> void:
	_load_stats()

## ─────────────────────────────────────────────────────────────
## Public API
## ─────────────────────────────────────────────────────────────

## 게임 결과 저장
func save_result(result: Dictionary) -> void:
	# 타임스탬프 추가
	if not result.has("timestamp"):
		result["timestamp"] = int(Time.get_unix_time_from_system())

	# 누적 통계 업데이트
	stats.total_plays += 1
	stats.total_time += result.get("time", 0.0)
	stats.total_kills += result.get("kills", 0)
	stats.total_xp += result.get("xp", 0)

	# 최고 기록 업데이트
	_update_best_records(result)

	# 최근 결과에 추가 (FIFO)
	stats.recent_results.push_front(result)
	if stats.recent_results.size() > MAX_RECENT_RESULTS:
		stats.recent_results.pop_back()

	_save_stats()

## 전체 통계 반환
func get_stats() -> Dictionary:
	return stats.duplicate(true)

## 포맷팅된 통계 반환 (UI 표시용)
func get_formatted_stats() -> Dictionary:
	var plays = stats.get("total_plays", 0)
	return {
		"total_plays": str(plays),
		"total_time": _format_time(stats.get("total_time", 0.0)),
		"total_kills": str(stats.get("total_kills", 0)),
		"total_xp": str(stats.get("total_xp", 0)),
		"best_level": str(stats.get("best_level", 0)),
		"best_kills": str(stats.get("best_kills", 0)),
		"best_time": _format_time(stats.get("best_time", 0.0)),
		"best_wave": str(stats.get("best_wave", 0)),
		"avg_time": _format_time(stats.get("total_time", 0.0) / max(plays, 1)),
		"avg_kills": str(int(stats.get("total_kills", 0) / max(plays, 1)))
	}

## 플레이 기록이 있는지 확인
func has_played() -> bool:
	return stats.get("total_plays", 0) > 0

## 통계 초기화
func reset_stats() -> void:
	stats = _create_default_stats()
	_save_stats()

## ─────────────────────────────────────────────────────────────
## Internal
## ─────────────────────────────────────────────────────────────

func _load_stats() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			var error = json.parse(file.get_as_text())
			file.close()
			if error == OK and json.data is Dictionary:
				stats = json.data
				return

	# 파일이 없거나 파싱 실패 시 기본값
	stats = _create_default_stats()

func _save_stats() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(stats, "\t"))
		file.close()

func _create_default_stats() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"total_plays": 0,
		"total_time": 0.0,
		"total_kills": 0,
		"total_xp": 0,
		"best_level": 0,
		"best_kills": 0,
		"best_time": 0.0,
		"best_wave": 0,
		"recent_results": []
	}

func _update_best_records(result: Dictionary) -> void:
	stats.best_level = max(stats.get("best_level", 0), result.get("level", 0))
	stats.best_kills = max(stats.get("best_kills", 0), result.get("kills", 0))
	stats.best_time = max(stats.get("best_time", 0.0), result.get("time", 0.0))
	stats.best_wave = max(stats.get("best_wave", 0), result.get("wave", 0))

func _format_time(seconds: float) -> String:
	var total_seconds := int(seconds)
	@warning_ignore("integer_division")
	var mins := total_seconds / 60
	var secs := total_seconds % 60
	return "%d:%02d" % [mins, secs]

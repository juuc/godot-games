extends "res://_shared/scripts/ui/hud_base.gd"

## Test Game HUD
## 체력바, XP바, 레벨 표시

func _setup_ui() -> void:
	health_bar = $MarginContainer/VBoxContainer/HealthBar
	xp_bar = $MarginContainer/VBoxContainer/XpContainer/XpBar
	level_label = $MarginContainer/VBoxContainer/XpContainer/LevelLabel

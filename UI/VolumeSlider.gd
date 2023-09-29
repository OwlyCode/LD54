extends HSlider

var _bus := AudioServer.get_bus_index("Master")


func _ready() -> void:
	value = db_to_linear(Global.sound)
	apply()

func _on_value_changed(v: float) -> void:
	Global.sound = linear_to_db(v)
	apply()

func apply() -> void:
	AudioServer.set_bus_volume_db(_bus, Global.sound)

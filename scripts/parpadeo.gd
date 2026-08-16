## Fuego. Dos senos de frecuencias que no encajan entre sí, para que el
## parpadeo no tenga patrón audible. Un solo seno se nota enseguida y arruina
## la ilusión.
extends OmniLight3D

var _base := 0.0
var _fase := 0.0


func _ready() -> void:
	_base = light_energy
	_fase = randf() * TAU


func _process(dt: float) -> void:
	_fase += dt
	var p := 0.84 + sin(_fase * 6.7) * 0.10 + sin(_fase * 13.1) * 0.06
	light_energy = _base * p

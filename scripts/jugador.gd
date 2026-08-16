## El jugador y la cámara. Están juntos a propósito: en una vista isométrica
## el control y la cámara son la misma decisión de diseño — si se separan,
## girar la cámara invierte los controles y se siente roto.
##
## La cámara sale del documento de diseño:
##  - Órbita RESTRINGIDA: gira en horizontal, la inclinación está acotada.
##    Nunca termina al ras del piso, que es donde se cae el decorado y donde
##    habría que modelar lo que hoy no modelamos.
##  - Lejos por defecto. Es la distancia donde se lee la situación social de
##    un vistazo.
##  - Zoom con piso y techo. El piso es, literalmente, el presupuesto de arte.
class_name Jugador
extends CharacterBody3D

signal quiere_interactuar
signal quiere_golpear

const VELOCIDAD := 7.5
const ACELERACION := 14.0
const FUERZA_SALTO := 6.2
const GRAVEDAD := 18.0

# Límites de la órbita. La inclinación va de casi cenital a tres cuartos.
const PITCH_MIN := deg_to_rad(28.0)
const PITCH_MAX := deg_to_rad(64.0)
const DIST_MIN := 9.0
const DIST_MAX := 42.0

var _yaw := deg_to_rad(38.0)
var _pitch := deg_to_rad(56.0)
var _dist := 27.0
var _dist_objetivo := 27.0
var _arrastrando := false

@onready var _pivote: Node3D = $Pivote
@onready var _camara: Camera3D = $Pivote/Camara
@onready var _malla: Node3D = $Malla


func _ready() -> void:
	_camara.current = true
	_recolocar_camara(true)


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton:
		var e := evento as InputEventMouseButton
		if e.button_index == MOUSE_BUTTON_RIGHT:
			_arrastrando = e.pressed
		elif e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			_dist_objetivo = clampf(_dist_objetivo - 1.6, DIST_MIN, DIST_MAX)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			_dist_objetivo = clampf(_dist_objetivo + 1.6, DIST_MIN, DIST_MAX)
	elif evento is InputEventMouseMotion and _arrastrando:
		var m := evento as InputEventMouseMotion
		_yaw -= m.relative.x * 0.006
		_pitch = clampf(_pitch + m.relative.y * 0.004, PITCH_MIN, PITCH_MAX)
	elif evento.is_action_pressed("interactuar"):
		quiere_interactuar.emit()
	elif evento.is_action_pressed("golpear"):
		quiere_golpear.emit()


func _physics_process(dt: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVEDAD * dt
	elif Input.is_action_just_pressed("saltar"):
		velocity.y = FUERZA_SALTO

	# La dirección es relativa a la cámara, aplanada al piso. Sin esto, girar
	# la cámara invierte los controles.
	var eje := Input.get_vector("izquierda", "derecha", "adelante", "atras")
	var base := Basis(Vector3.UP, _yaw)
	var dir := (base * Vector3(eje.x, 0.0, eje.y)).normalized()

	var deseada := dir * VELOCIDAD
	velocity.x = move_toward(velocity.x, deseada.x, ACELERACION * dt)
	velocity.z = move_toward(velocity.z, deseada.z, ACELERACION * dt)

	if dir.length_squared() > 0.01:
		# Girar el cuerpo hacia donde camina, suave.
		var objetivo := atan2(dir.x, dir.z)
		_malla.rotation.y = lerp_angle(_malla.rotation.y, objetivo, 12.0 * dt)

	move_and_slide()
	_dist = lerp(_dist, _dist_objetivo, 8.0 * dt)
	_recolocar_camara(false)


func _recolocar_camara(inmediato: bool) -> void:
	var desplazamiento := Vector3(
		sin(_yaw) * cos(_pitch),
		sin(_pitch),
		cos(_yaw) * cos(_pitch),
	) * _dist
	var destino := desplazamiento
	if inmediato:
		_pivote.position = Vector3.ZERO
		_camara.position = destino
	else:
		_camara.position = _camara.position.lerp(destino, 0.25)
	_camara.look_at(global_position + Vector3.UP * 1.1, Vector3.UP)


## Empujón visual al pegar. Sin animaciones todavía: esto al menos da feedback.
func amagar_golpe() -> void:
	var t := create_tween()
	t.tween_property(_malla, "scale", Vector3(1.15, 0.88, 1.15), 0.06)
	t.tween_property(_malla, "scale", Vector3.ONE, 0.14)

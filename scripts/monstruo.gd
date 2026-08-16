## Los que viven en el Sotobosque.
##
## La IA es una máquina de tres estados y nada más. Un monstruo con
## comportamiento complejo en un blockout no se lee: lo que sí se lee es que
## te NOTE, que dude un momento, y que después venga. Ese momento de duda es
## lo que lo hace sentir vivo, y es una sola variable.
class_name Monstruo
extends CharacterBody3D

signal murio(quien: Monstruo)
signal pego(danio: int)

enum Estado { RONDA, ALERTA, PERSIGUE, MUERTO }

const VELOCIDAD := 4.2
const VELOCIDAD_RONDA := 1.3
const GRAVEDAD := 18.0
const VISTA := 15.0
const ALCANCE := 2.3
const DANIO := 9
const ESPERA_GOLPE := 1.25
const DUDA := 0.55   ## lo que tarda en decidirse a atacar. Sin esto no asusta.

var vida := 40
var objetivo: Node3D
var casa: Vector3         ## a dónde vuelve si te perdés de vista

var _estado := Estado.RONDA
var _figura: Figura
var _reloj_golpe := 0.0
var _reloj_duda := 0.0
var _destino_ronda: Vector3
var _reloj_ronda := 0.0
var _altura_terreno: Callable


func preparar(pos: Vector3, alturas: Callable) -> void:
	position = pos
	casa = pos
	_altura_terreno = alturas
	_destino_ronda = pos

	var forma := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.5
	cap.height = 1.5
	forma.shape = cap
	forma.position.y = 0.75
	add_child(forma)

	_figura = Figura.new()
	_figura.set_script(preload("res://scripts/figura.gd"))
	_figura.altura = 1.45
	# Verde enfermo, apagado: en un valle de tonos cálidos, lo frío lee como
	# ajeno antes de que el jugador entienda qué es.
	_figura.color = Color(0.20, 0.30, 0.22)
	_figura.color_piel = Color(0.42, 0.46, 0.34)
	add_child(_figura)
	_figura.construir()

	# Dos ojos que brillan. Es lo único que emite luz en ellos y es lo que
	# los hace visibles entre los árboles antes de que los veas del todo.
	for lado: float in [-0.09, 0.09]:
		var ojo := MeshInstance3D.new()
		var e := SphereMesh.new()
		e.radius = 0.045
		e.height = 0.09
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1.0, 0.55, 0.15)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.45, 0.10)
		m.emission_energy_multiplier = 9.0
		e.material = m
		ojo.mesh = e
		ojo.position = Vector3(lado, 1.36, 0.20)
		_figura.add_child(ojo)


func _physics_process(dt: float) -> void:
	if _estado == Estado.MUERTO:
		return
	if not is_on_floor():
		velocity.y -= GRAVEDAD * dt

	_reloj_golpe = maxf(0.0, _reloj_golpe - dt)

	var dist := INF
	if objetivo != null:
		dist = global_position.distance_to(objetivo.global_position)

	match _estado:
		Estado.RONDA:
			_rondar(dt)
			if dist < VISTA:
				_estado = Estado.ALERTA
				_reloj_duda = DUDA
		Estado.ALERTA:
			# El momento de duda: se frena, te mira, y recién ahí decide.
			velocity.x = move_toward(velocity.x, 0.0, 12.0 * dt)
			velocity.z = move_toward(velocity.z, 0.0, 12.0 * dt)
			_mirar_a(objetivo.global_position, dt, 9.0)
			_reloj_duda -= dt
			if dist > VISTA * 1.3:
				_estado = Estado.RONDA
			elif _reloj_duda <= 0.0:
				_estado = Estado.PERSIGUE
		Estado.PERSIGUE:
			if dist > VISTA * 1.6:
				_estado = Estado.RONDA
				_destino_ronda = casa
			elif dist <= ALCANCE:
				velocity.x = move_toward(velocity.x, 0.0, 16.0 * dt)
				velocity.z = move_toward(velocity.z, 0.0, 16.0 * dt)
				_mirar_a(objetivo.global_position, dt, 12.0)
				if _reloj_golpe <= 0.0:
					_reloj_golpe = ESPERA_GOLPE
					_figura.atacar()
					pego.emit(DANIO)
			else:
				var dir := (objetivo.global_position - global_position)
				dir.y = 0.0
				dir = dir.normalized()
				velocity.x = dir.x * VELOCIDAD
				velocity.z = dir.z * VELOCIDAD
				_mirar_a(objetivo.global_position, dt, 10.0)

	move_and_slide()
	_figura.animar(dt, Vector2(velocity.x, velocity.z).length(), is_on_floor())


func _rondar(dt: float) -> void:
	_reloj_ronda -= dt
	if _reloj_ronda <= 0.0 or global_position.distance_to(_destino_ronda) < 1.5:
		_reloj_ronda = randf_range(2.5, 6.0)
		var a := randf() * TAU
		var r := randf_range(2.0, 9.0)
		_destino_ronda = casa + Vector3(cos(a) * r, 0, sin(a) * r)
		if _altura_terreno.is_valid():
			_destino_ronda.y = _altura_terreno.call(_destino_ronda.x, _destino_ronda.z)

	var dir := (_destino_ronda - global_position)
	dir.y = 0.0
	if dir.length() > 0.6:
		dir = dir.normalized()
		velocity.x = dir.x * VELOCIDAD_RONDA
		velocity.z = dir.z * VELOCIDAD_RONDA
		_mirar_a(_destino_ronda, dt, 5.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * dt)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * dt)


func _mirar_a(punto: Vector3, dt: float, rapidez: float) -> void:
	var d := punto - global_position
	d.y = 0.0
	if d.length_squared() < 0.01:
		return
	_figura.rotation.y = lerp_angle(_figura.rotation.y, atan2(d.x, d.z), rapidez * dt)


func recibir(danio: int) -> void:
	if _estado == Estado.MUERTO:
		return
	vida -= danio
	_figura.doler()
	# Te pegaron: dejate de rondar y andá al que te pegó.
	if _estado == Estado.RONDA:
		_estado = Estado.PERSIGUE
	if vida <= 0:
		_morir()


func _morir() -> void:
	_estado = Estado.MUERTO
	velocity = Vector3.ZERO
	_figura.caer()
	murio.emit(self)
	var t := create_tween()
	t.tween_interval(2.5)
	t.tween_property(_figura, "scale", Vector3(0.01, 0.01, 0.01), 0.7)
	t.tween_callback(queue_free)

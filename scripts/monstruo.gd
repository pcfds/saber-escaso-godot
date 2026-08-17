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
## El id de la fila en `threats`. Sin esto el bicho es decorado: no se le puede
## avisar al servidor que le pegaste, y matarlo no le pasa a nadie más.
var id_servidor := ""
## Cómo se llama. Los que no son humanos tienen nombre: no son mobs, son
## pueblos, y matar a alguien con nombre pesa distinto.
var nombre_servidor := ""

var _estado := Estado.RONDA
var _figura: Figura
var _reloj_golpe := 0.0
var _reloj_duda := 0.0
var _destino_ronda: Vector3
var _reloj_ronda := 0.0
var _altura_terreno: Callable

# ── Los dos relojes del impacto ─────────────────────────────────────────────
#
# **Este archivo es el que sabe la geometría del choque**, y por eso es el que
# pinta el impacto en las dos direcciones. Nadie más sabe quién le pegó a
# quién: `valle.gd` decide a QUIÉN le pegaste (por distancia) pero no de qué
# lado, y `jugador.gd` no sabe qué bicho lo mordió.
#
# Los dos relojes existen por la misma razón: **el golpe llega en el cuadro 5,
# no en el 0.** El swing tiene 5 cuadros de anticipo, y si la reacción se
# pintara al apretar el botón, el bicho se dolería mientras el brazo todavía
# va para atrás. Que la respuesta empiece en el cuadro del botón —la regla— la
# cumple el ANTICIPO, que arranca en el cuadro 0; lo que espera es el contacto.
var _contacto_recibe := -1.0   ## < 0 = no hay golpe tuyo en vuelo
var _contacto_pega := -1.0     ## < 0 = no hay zarpazo suyo en vuelo
## Retroceso. Se suma a `velocity` y se apaga por rozamiento en 3-8 cuadros.
var _empuje := Vector3.ZERO


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
	_correr_contactos(dt)

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
					# El brazo arranca YA —el anticipo es la respuesta— y el
					# zarpazo cae 5 cuadros después, cuando el brazo llega.
					_figura.atacar()
					_contacto_pega = Impacto.CONTACTO
			else:
				var dir := (objetivo.global_position - global_position)
				dir.y = 0.0
				dir = dir.normalized()
				velocity.x = dir.x * VELOCIDAD
				velocity.z = dir.z * VELOCIDAD
				_mirar_a(objetivo.global_position, dt, 10.0)

	# El retroceso se SUMA a lo que la IA quiso hacer y se apaga por rozamiento,
	# en vez de reemplazar la velocidad: así el bicho sale despedido medio metro
	# pero no se le corta la embestida, que es lo que lo haría ver como que se
	# reinició. `EMPUJE_FRENO` = 62 m/s² lo apaga en 8 cuadros.
	#
	# **Y se SACA justo después de `move_and_slide()`.** Sin eso el empujón se
	# acumula: `velocity` es un miembro que sobrevive al cuadro, la IA lo baja
	# con un `move_toward` de 16 m/s² —0,27 m/s por cuadro— y el empujón suma 8
	# de una. Medido con el bug puesto: el bicho llegaba a **41 m/s** en seis
	# cuadros y salía disparado del valle. Sumar y restar en el mismo cuadro
	# deja el empujón como lo que es, un desvío, y no como estado.
	var empujon := _empuje
	if empujon.length_squared() > 0.0004:
		velocity.x += empujon.x
		velocity.z += empujon.z
		_empuje = _empuje.move_toward(Vector3.ZERO, Impacto.EMPUJE_FRENO * dt)
	else:
		empujon = Vector3.ZERO
		_empuje = Vector3.ZERO

	move_and_slide()
	velocity.x -= empujon.x
	velocity.z -= empujon.z
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


## Reacción inmediata al golpe, sin tocar la vida: la vida la decide el
## servidor. Esto es para que el clic se sienta en el mismo cuadro.
##
## "En el mismo cuadro" pasó a significar dos cosas distintas y las dos se
## cumplen: **la IA reacciona ya** (deja de rondar y viene por vos, en este
## mismo cuadro) y **la presentación del choque espera al cuadro 5**, que es
## cuando el arma llega. Si el bicho se doliera en el cuadro 0 se estaría
## doliendo mientras el brazo todavía va para atrás.
func doler_ahora() -> void:
	if _estado == Estado.MUERTO:
		return
	if _estado == Estado.RONDA:
		_estado = Estado.PERSIGUE
	_contacto_recibe = Impacto.CONTACTO


## Los dos relojes de contacto, uno por dirección. Se cuentan en
## `_physics_process`, o sea que la pausa al impactar (`time_scale = 0`) los
## detiene igual que a todo lo demás — que es lo correcto: un golpe encadenado
## no se adelanta porque el mundo esté congelado.
func _correr_contactos(dt: float) -> void:
	if _contacto_recibe >= 0.0:
		_contacto_recibe -= dt
		if _contacto_recibe <= 0.0:
			_contacto_recibe = -1.0
			_te_pegaron()
	if _contacto_pega >= 0.0:
		_contacto_pega -= dt
		if _contacto_pega <= 0.0:
			_contacto_pega = -1.0
			_zarpazo()


## Cuadro 5 del golpe TUYO: el arma llega. Acá se juntan las cinco cosas, y las
## cinco son presentación —no se toca `vida`, eso lo dice el servidor.
##
##   · pausa      3 cuadros congelados
##   · retroceso  8,0 m/s en el bicho (≈52 cm, 8 cuadros) y 3,2 en vos (≈8 cm)
##   · sacudida   0,55 de amplitud, 7 cuadros
##   · respingo   10 cuadros de deformación de cuerpo entero + destello
##   · chispa     12 cuadros en el punto del choque
func _te_pegaron() -> void:
	if _estado == Estado.MUERTO:
		return
	_figura.doler()

	# De dónde vino. El único que te puede pegar es tu objetivo: `valle.gd`
	# elige por distancia al jugador y no hay otra fuente de `doler_ahora()`.
	var dir := Vector3.FORWARD
	if objetivo != null and is_instance_valid(objetivo):
		var d := global_position - objetivo.global_position
		d.y = 0.0
		if d.length_squared() > 0.0001:
			dir = d.normalized()

	_empuje = dir * Impacto.EMPUJE_RECIBE
	Impacto.congelar(Impacto.PAUSA_DAR)
	# La chispa va a la altura del pecho y 35 cm del lado del que pegó: en el
	# punto del choque, no en el centro del bicho. A 40 m son 10 px de
	# diferencia y aun así se nota cuál de los dos recibió.
	Impacto.estallar(self, global_position + Vector3.UP * 1.05 - dir * 0.35,
		Paleta.BRASA_EMISION, 1.0)

	var jug := objetivo as Jugador
	if jug != null:
		jug.sacudir(Impacto.SACUDIDA_DAR)
		# El que pega también retrocede, menos. Sin esto los dos cuerpos se
		# interpenetran y el cerebro lee "no chocaron".
		jug.empujar(-dir * Impacto.EMPUJE_PEGA)


## Cuadro 5 del zarpazo SUYO: el brazo llega.
##
## **Acá sale el aviso al servidor y no antes**, y eso es un cambio de cuándo,
## no de qué: el POST es el mismo, sale 83 ms más tarde, y el número lo sigue
## decidiendo el servidor. Se emite SIEMPRE, sin volver a mirar la distancia:
## la decisión de atacar ya se tomó con la comprobación de alcance que hace
## `PERSIGUE`, y re-chequear acá cambiaría cuánto daño recibe el jugador, que
## es justo lo que este archivo no puede decidir.
##
## Lo que sí se mira antes de PINTAR es que el jugador siga cerca: si rodó y se
## fue, sacudir la cámara y plantar una chispa donde ya no hay nadie es dibujar
## un choque que no se ve. El daño salió igual.
func _zarpazo() -> void:
	if _estado == Estado.MUERTO:
		return
	pego.emit(DANIO)

	if objetivo == null or not is_instance_valid(objetivo):
		return
	var d := objetivo.global_position - global_position
	d.y = 0.0
	if d.length_squared() < 0.0001 or d.length() > ALCANCE * 2.0:
		return
	var dir := d.normalized()

	Impacto.congelar(Impacto.PAUSA_RECIBIR)
	# Herrumbre y no brasa: el color dice de quién es el golpe sin un cartel.
	Impacto.estallar(self, objetivo.global_position + Vector3.UP * 1.10 - dir * 0.30,
		Paleta.HERRUMBRE, 1.15)
	# El bicho también rebota al pegar, poco: 8 cm.
	_empuje = -dir * Impacto.EMPUJE_PEGA
	var jug := objetivo as Jugador
	if jug != null:
		jug.sacudir(Impacto.SACUDIDA_RECIBIR)
		jug.empujar(dir * Impacto.EMPUJE_JUGADOR)


## La vida que manda el servidor. **No lleva pausa, ni sacudida, ni chispa**, y
## es a propósito: por acá entra `recibir(9999)` cuando `/mundo` avisa que el
## bicho ya no está, y eso puede ser un bicho que mató otro jugador en la otra
## punta del valle. Congelar el mundo por un golpe que no diste sería el
## clásico tirón sin causa. El respingo sí queda: si estás mirando, se ve caer.
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

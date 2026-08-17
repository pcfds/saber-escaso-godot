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

enum Estado { RONDA, ALERTA, PERSIGUE, AMAGO, MUERTO }

const VELOCIDAD := 4.2
const VELOCIDAD_RONDA := 1.3
const GRAVEDAD := 18.0
const VISTA := 15.0
const ALCANCE := 2.3
const DANIO := 9
const ESPERA_GOLPE := 1.25
const DUDA := 0.55   ## lo que tarda en decidirse a atacar. Sin esto no asusta.

# ── El brillo de los ojos: la escalera de intención ─────────────────────────
#
# Los ojos son lo único que emite luz en el bicho y ya eran lo que lo hace
# visible entre los árboles. Acá pasan además a decir **qué está por hacer**, y
# lo dicen con la única variable que se lee igual a 12 m que a 68: el VALOR.
# Un punto que se pone más brillante no depende de cuántos píxeles mida.
#
# Es la misma decisión que el destello del impacto en `figura.gd`, y es lo único
# de la cara que se toca: no es una expresión, es una lámpara. El piso de zoom
# dice "nunca la expresión" y esto no la contradice — a 40 m no se ve un gesto,
# se ve que hay dos brasas y que están más fuertes que hace un segundo.
const OJOS_RONDA := 9.0      ## no te vio: el brillo de siempre
const OJOS_ALERTA := 16.0    ## te vio. Y se queda así mientras te siga
const OJOS_AMAGO := 34.0     ## se está por tirar encima. Sube DURANTE el amago
## Rapidez del fundido entre escalones. 9,0 sube en unos 7 cuadros: rápido para
## que la noticia llegue, no instantáneo para que no parpadee.
const OJOS_FUNDIDO := 9.0

var vida := 40
## La vida más alta que se le vio. **No se elige acá**: se aprende mirando lo
## que manda el servidor, porque el máximo real es suyo y `40` es sólo el valor
## con el que nace un bicho al que todavía nadie le tocó nada. De acá sale la
## fracción `_maltrecho`, que es toda la consecuencia visible del golpe.
var vida_maxima := 40
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
## Lo que le queda al amago en curso. Ver el bloque de AMAGO en el `match`.
var _reloj_amago := 0.0
## `1 - vida/vida_maxima`. Se recalcula solo; ver `_al_dia_con_la_vida()`.
var _maltrecho := 0.0
## Los dos ojos, para poder subirles la emisión. Se guardan al construirlos:
## buscarlos por nombre sesenta veces por segundo es pagar dos veces.
var _ojos: Array[StandardMaterial3D] = []
var _brillo_ojos := OJOS_RONDA

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
	# ajeno antes de que el jugador entienda qué es. Los cuatro colores del bicho
	# salen de `paleta.gd`, que es la que tiene autoridad — eran los mismos
	# valores escritos a mano acá.
	_figura.color = Paleta.CUERPO_BICHO
	_figura.color_piel = Paleta.PIEL_BICHO
	add_child(_figura)
	_figura.construir()

	# Dos ojos que brillan. Es lo único que emite luz en ellos y es lo que
	# los hace visibles entre los árboles antes de que los veas del todo. La
	# energía no es fija: ver la escalera `OJOS_*` arriba.
	_ojos.clear()
	for lado: float in [-0.09, 0.09]:
		var ojo := MeshInstance3D.new()
		var e := SphereMesh.new()
		e.radius = 0.045
		e.height = 0.09
		var m := StandardMaterial3D.new()
		m.albedo_color = Paleta.OJO_BICHO
		m.emission_enabled = true
		m.emission = Paleta.OJO_BICHO_EMISION
		m.emission_energy_multiplier = OJOS_RONDA
		e.material = m
		ojo.mesh = e
		ojo.position = Vector3(lado, 1.36, 0.20)
		_figura.add_child(ojo)
		_ojos.append(m)


func _physics_process(dt: float) -> void:
	if _estado == Estado.MUERTO:
		return
	if not is_on_floor():
		velocity.y -= GRAVEDAD * dt

	_reloj_golpe = maxf(0.0, _reloj_golpe - dt)
	_correr_contactos(dt)
	_al_dia_con_la_vida()

	var dist := INF
	if objetivo != null:
		dist = global_position.distance_to(objetivo.global_position)

	match _estado:
		Estado.RONDA:
			_rondar(dt)
			_ojos_a(OJOS_RONDA, dt)
			if dist < VISTA:
				_estado = Estado.ALERTA
				_reloj_duda = DUDA
		Estado.ALERTA:
			# El momento de duda: se frena, te mira, y recién ahí decide.
			velocity.x = move_toward(velocity.x, 0.0, 12.0 * dt)
			velocity.z = move_toward(velocity.z, 0.0, 12.0 * dt)
			_mirar_a(objetivo.global_position, dt, 9.0)
			# Y los ojos suben un escalón. Ese cambio de brillo es el "te vi", y
			# es lo que hace que el momento de duda —que hasta ahora era un bicho
			# que se quedaba quieto— se lea como una decisión y no como un cuelgue.
			_ojos_a(OJOS_ALERTA, dt)
			_reloj_duda -= dt
			if dist > VISTA * 1.3:
				_estado = Estado.RONDA
			elif _reloj_duda <= 0.0:
				_estado = Estado.PERSIGUE
		Estado.PERSIGUE:
			_ojos_a(OJOS_ALERTA, dt)
			if dist > VISTA * 1.6:
				_estado = Estado.RONDA
				_destino_ronda = casa
			elif dist <= ALCANCE:
				velocity.x = move_toward(velocity.x, 0.0, 16.0 * dt)
				velocity.z = move_toward(velocity.z, 0.0, 16.0 * dt)
				_mirar_a(objetivo.global_position, dt, 12.0)
				if _reloj_golpe <= 0.0:
					_encabritarse()
			else:
				var dir := (objetivo.global_position - global_position)
				dir.y = 0.0
				dir = dir.normalized()
				var rapidez := VELOCIDAD * _factor_herido(Impacto.HERIDO_VELOCIDAD)
				velocity.x = dir.x * rapidez
				velocity.z = dir.z * rapidez
				_mirar_a(objetivo.global_position, dt, 10.0)
		Estado.AMAGO:
			_amagar(dt, dist)

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
		var rapidez := VELOCIDAD_RONDA * _factor_herido(Impacto.HERIDO_VELOCIDAD)
		velocity.x = dir.x * rapidez
		velocity.z = dir.z * rapidez
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


# ---------------------------------------------------------------------------
# El amago: 24 cuadros de aviso antes del zarpazo
# ---------------------------------------------------------------------------
#
# **El reclamo era literal: *"me ataca el monstruo sin decirme nada"*.** Y no
# se arregla con un cartel ni con una barra: se arregla con 400 ms en los que el
# bicho se encabrita, gruñe y no se mueve de donde está. La pose la dibuja
# `Figura._pose_de_amago()`; acá está cuándo empieza, cuándo se abandona y
# cuándo se convierte en zarpazo.
#
# ## Lo que NO cambia, y es la parte delicada
#
# **Quién decide el daño sigue siendo el servidor, y CUÁNDO se compromete el
# ataque sigue siendo exactamente la misma comprobación de antes.** El amago es
# una fase PREVIA al compromiso: mientras dura, el bicho todavía no atacó. El
# instante en que atacaba antes —`dist <= ALCANCE` y el enfriamiento vencido— es
# ahora el instante en que EMPIEZA el amago, y el ataque se compromete 24
# cuadros más tarde con la misma condición de distancia todavía en pie. El POST
# a `/danio` sale del mismo lugar que siempre (`_zarpazo`) y con el mismo
# incondicional: una vez comprometido, el golpe salió.
#
# ## Por qué se abandona a `ALCANCE * 2` y no a `ALCANCE`
#
# Porque `_zarpazo()` ya usa ese mismo número para decidir si vale la pena
# PINTAR el choque, y las dos preguntas son la misma: **no se compromete un
# ataque que no se va a dibujar.** Si el jugador se corrió más allá de 4,6 m
# durante el amago, el bicho baja los brazos y espera `AMAGO_CORTE`.
#
# Y esto es lo que convierte el aviso en algo más que información: si te
# apartás durante los 400 ms, el golpe no sale. Un aviso que no se puede
# aprovechar es un cartel; uno que se puede, es una regla del juego.

func _encabritarse() -> void:
	_estado = Estado.AMAGO
	_reloj_amago = Impacto.AMAGO_DURA * _factor_herido(Impacto.HERIDO_AMAGO)
	_figura.amagar(true)
	# El gruñido dura lo mismo que la pose y termina en el cuadro en que el
	# brazo sale. Es la mitad del aviso que funciona con el bicho fuera de
	# encuadre, que a esta cámara es la mitad de las veces.
	Impacto.grunir(self)


func _amagar(dt: float, dist: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 20.0 * dt)
	velocity.z = move_toward(velocity.z, 0.0, 20.0 * dt)
	if objetivo != null and is_instance_valid(objetivo):
		# Sigue girando hacia vos, pero despacio: un bicho encabritado que te
		# apunta como una torreta no se lee como que está cargando un golpe.
		_mirar_a(objetivo.global_position, dt, 5.0)

	# Los ojos suben DURANTE el amago en vez de saltar al valor final. Que la
	# rampa termine junto con la pose es lo que hace que se lea "esto va a pasar
	# ya" y no "esto está pasando".
	var u: float = 1.0 - clampf(_reloj_amago / maxf(Impacto.AMAGO_DURA, 0.001), 0.0, 1.0)
	_ojos_a(lerpf(OJOS_ALERTA, OJOS_AMAGO, u), dt * 2.5)

	_reloj_amago -= dt

	# Se fue: se abandona. Sin el enfriamiento, el que se queda justo en el borde
	# ve al bicho encabritándose y bajando en bucle, que es peor que no avisar.
	if objetivo == null or not is_instance_valid(objetivo) or dist > ALCANCE * 2.0:
		_figura.amagar(false)
		_estado = Estado.PERSIGUE
		_reloj_golpe = Impacto.AMAGO_CORTE
		return

	if _reloj_amago > 0.0:
		return

	# Comprometido. De acá en adelante es igual que siempre: el brazo sale, el
	# contacto cae 5 cuadros después y ahí `_zarpazo()` avisa al servidor.
	_figura.amagar(false)
	_figura.atacar()
	_contacto_pega = Impacto.CONTACTO
	_reloj_golpe = ESPERA_GOLPE * _factor_herido(Impacto.HERIDO_ESPERA)
	_estado = Estado.PERSIGUE


## El fundido del brillo de los ojos. Va por material y no por luz: son dos
## esferas emisivas y lo que se toca es cuánto emiten.
func _ojos_a(energia: float, dt: float) -> void:
	_brillo_ojos = lerpf(_brillo_ojos, energia, clampf(OJOS_FUNDIDO * dt, 0.0, 1.0))
	for m in _ojos:
		m.emission_energy_multiplier = _brillo_ojos


# ---------------------------------------------------------------------------
# La consecuencia: el cuerpo se entera de que la vida bajó
# ---------------------------------------------------------------------------
#
# *"Hoy la vida baja en un número y el cuerpo no se entera."* Se entera acá, y
# de la única manera que se lee a 40 m: **tiempo y postura.** Camina más lento,
# pega más espaciado, telegrafía más largo y se tambalea. Nada de barras y nada
# de color: el HUD es de otro y el color es de `paleta.gd`.
#
# El máximo NO se elige acá. `valle.gd` escribe `vida` directo con lo que manda
# el servidor —al crear el bicho y cada vez que llega `/mundo`, porque puede
# habérsela bajado otro jugador en la otra punta del valle— así que el máximo se
# APRENDE mirando el número más alto que pasó. Un bicho que entra a la escena ya
# herido se ve entero hasta que le pegan; es el precio de no inventar un dato
# que el servidor no manda, y es el precio correcto.

func _al_dia_con_la_vida() -> void:
	vida_maxima = maxi(vida_maxima, vida)
	var f: float = 1.0 - clampf(float(vida) / float(maxi(vida_maxima, 1)), 0.0, 1.0)
	if absf(f - _maltrecho) < 0.001:
		return
	_maltrecho = f
	_figura.maltratar(f)


## Interpola entre "entero" (1,0) y `si_herido` según lo maltrecho que esté.
func _factor_herido(si_herido: float) -> float:
	return lerpf(1.0, si_herido, _maltrecho)


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
	# Se le apagan los ojos. Es el escalón de abajo de la misma escalera que
	# `OJOS_ALERTA` y `OJOS_AMAGO`, y a 40 m es la lectura más clara que hay de
	# que se murió: las dos brasas que venías siguiendo entre los árboles se
	# apagan. Un cadáver con las luces prendidas se lee como que sigue vivo.
	for m in _ojos:
		m.emission_energy_multiplier = 0.0
	_figura.caer()
	murio.emit(self)
	var t := create_tween()
	t.tween_interval(2.5)
	t.tween_property(_figura, "scale", Vector3(0.01, 0.01, 0.01), 0.7)
	t.tween_callback(queue_free)

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
## Rodaste. Lleva cuánto falta para poder hacerlo de nuevo, para que la
## interfaz pueda dibujar la espera en vez de dejarte apretando una tecla muda.
signal esquivo(espera: float)

const VELOCIDAD := 7.5
## Correr con shift. El valle se agrandó a propósito —que haya distancia es
## parte del diseño— pero cruzarlo entero a paso de caminata es tedio, no
## distancia. Correr no es más rápido gratis: no podés pegar mientras corrés.
const VELOCIDAD_CORRIENDO := 13.5
const ACELERACION := 14.0
const FUERZA_SALTO := 6.2
const GRAVEDAD := 18.0

# ── Esquivar (Q). La defensa, y por qué ES una rodada y no un escudo ────────
#
# El reclamo fue "no puede defenderse". La respuesta obvia —bloquear, y que el
# golpe haga la mitad— **está prohibida por el invariante**: el daño lo decide
# el servidor en `/danio`, y no hay ningún campo donde decirle "estaba
# bloqueando". Un bloqueo que descuenta del lado del cliente es exactamente la
# vida local que ya se sacó una vez de este juego.
#
# La rodada no tiene ese problema, y no porque la disimule: **no inventa nada.**
# El bicho pega por proximidad (`Monstruo.ALCANCE` = 2,3 m) y sólo entonces el
# cliente manda `/danio`. Si te corriste, la comprobación falla sola, el POST
# no sale, y el golpe no existe para nadie — ni para vos ni para el mundo. La
# defensa es geometría real, no un descuento.
#
# 0,26 s a 21 m/s son ~5,4 m: más del doble del alcance del bicho, que es lo
# que hace que se sienta que zafaste y no que el juego te perdonó.
const ESQUIVE_DURA := 0.26
const ESQUIVE_VELOCIDAD := 21.0
## El costo. Sin espera, esquivar es caminar rápido y gratis; con espera, es
## una decisión que se toma una vez por embestida y se paga si la errás.
const ESQUIVE_ESPERA := 1.15

# Límites de la órbita. La inclinación va de casi cenital a tres cuartos.
## Hasta dónde se puede bajar la cámara para mirar el horizonte y el cielo.
##
## Estaba en 28°, o sea SIEMPRE mirando hacia abajo. Consecuencia que nadie
## había notado: el cielo entero —las dos lunas, el gigante gaseoso, las
## estrellas, los amaneceres, la cordillera— **no se veía nunca**. Todo eso
## estaba construido y era invisible.
##
## A 2° la cámara queda casi a la altura de los ojos y el horizonte entra en
## cuadro. No se permite negativo: mirar desde abajo del piso muestra el mundo
## por debajo y no hay nada ahí.
const PITCH_MIN := deg_to_rad(2.0)
const PITCH_MAX := deg_to_rad(64.0)
## La cámara vive LEJOS. Es la vista del juego —Stardew, Baldur's Gate— y es
## lo que hace que el valle se lea como un lugar y no como el pasto que tenés
## delante de la nariz. Acercarse es un gesto puntual para mirar algo, no la
## posición de trabajo.
const DIST_MIN := 12.0
const DIST_MAX := 68.0

var _yaw := deg_to_rad(38.0)
## 56° era casi mirar desde arriba: se veían techos y copas de árbol, que es
## la vista con menos información que hay. A 38° se ven las fachadas, los
## troncos y la silueta de la gente contra el suelo — que es lo que hace
## legible un mundo visto de lejos.
var _pitch := deg_to_rad(38.0)
var _dist := 40.0
var _dist_objetivo := 40.0
var _arrastrando := false

var _esquive := 0.0            # cuánto queda de la rodada en curso
var _espera_esquive := 0.0     # cuánto falta para poder volver a rodar
var _dir_esquive := Vector3.ZERO
var _esquive_gira := false     # ¿la rodada gira el cuerpo, o es hacia atrás?

# ── Lo que hace que el choque se sienta desde acá ───────────────────────────
#
# Los números están todos en `impacto.gd`, que es la tabla de cuadros. Acá sólo
# viven las dos cosas que son del jugador: la cámara y el cuerpo.
## Amplitud de la sacudida, 1 a 0 en 7 cuadros.
var _sacudida := 0.0
## Reloj propio de la sacudida: hace falta uno aparte porque el temblor es una
## suma de dos senos y necesita una fase continua, no un valor que decae.
var _sacudida_reloj := 0.0
## La posición suavizada de la cámara, SIN la sacudida. Tiene que ser una
## variable y no `_camara.position`: el suavizado es un lerp hacia el destino,
## y si la sacudida se escribiera en la misma variable el lerp la iría
## arrastrando de vuelta y el temblor saldría untado en medio segundo.
var _cam_suave := Vector3.ZERO
## Retroceso al recibir un golpe. Se suma a `velocity` y se apaga por
## rozamiento; ver `empujar()`.
var _empuje := Vector3.ZERO

@onready var _pivote: Node3D = $Pivote
@onready var _camara: Camera3D = $Pivote/Camara
@onready var _malla: Node3D = $Malla
var figura: Figura
## Lo setea el valle: mientras devuelva true, el teclado es del chat y no
## del personaje. Sin esto escribirle "andá" a un NPC te hace caminar.
var tecleando := Callable()


func _ready() -> void:
	_camara.current = true
	_recolocar_camara(true)


## Lo único que hace `_process` es descongelar el mundo después de la pausa al
## impactar, **y tiene que ser `_process` y no `_physics_process`**: con
## `Engine.time_scale` en cero el motor deja de dar pasos de física y
## `_physics_process` no se llama nunca más, así que el que apaga la pausa
## quedaría del otro lado de la pausa. `_process` se sigue llamando todos los
## cuadros dibujados, con delta 0, y el reloj de `Impacto` es de pared.
func _process(_dt: float) -> void:
	Impacto.vigilar()


## Si la escena se va con el mundo congelado, no se descongela solo.
func _exit_tree() -> void:
	Impacto.soltar()


func _tecleando() -> bool:
	return tecleando.is_valid() and bool(tecleando.call())


func _unhandled_input(evento: InputEvent) -> void:
	if _tecleando() and not (evento is InputEventMouseMotion or evento is InputEventMouseButton):
		return
	# OJO CON ESTE `if`. Estuvo como `if evento is InputEventMouseButton` seguido
	# de `elif`, y eso hacía que **el ataque no se disparara nunca**: golpear
	# está en el clic izquierdo, el clic entraba en esta rama, no coincidía con
	# derecho ni con rueda, y la cadena terminaba ahí. El botón parecía muerto y
	# lo era. Por eso ahora la rama sólo agarra lo que de verdad maneja.
	if evento is InputEventMouseButton and (evento as InputEventMouseButton).button_index \
			in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var e := evento as InputEventMouseButton
		if e.button_index == MOUSE_BUTTON_RIGHT:
			_arrastrando = e.pressed
		elif e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			_dist_objetivo = clampf(_dist_objetivo - _dist_objetivo * 0.12, DIST_MIN, DIST_MAX)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			_dist_objetivo = clampf(_dist_objetivo + _dist_objetivo * 0.12, DIST_MIN, DIST_MAX)
	elif evento is InputEventMouseMotion and _arrastrando:
		var m := evento as InputEventMouseMotion
		_yaw -= m.relative.x * 0.006
		_pitch = clampf(_pitch + m.relative.y * 0.004, PITCH_MIN, PITCH_MAX)
	elif evento.is_action_pressed("interactuar"):
		quiere_interactuar.emit()
	elif evento.is_action_pressed("golpear"):
		# No se pega en el medio de una rodada. Es el costo que hace que
		# esquivar sea una elección: mientras te sacás, no estás pegando.
		if _esquive <= 0.0:
			quiere_golpear.emit()
	elif evento is InputEventKey and (evento as InputEventKey).pressed \
			and not (evento as InputEventKey).echo \
			and (evento as InputEventKey).keycode == KEY_Q:
		# Tecla cruda y no una acción del mapa de entrada porque `project.godot`
		# no se toca en esta rama. Cuando se agregue, esto pasa a "esquivar".
		_esquivar()


## Rodar. Se compromete a una dirección y no se puede corregir a mitad de
## camino: eso es lo que la vuelve una decisión en vez de un botón de "no me
## pegues".
func _esquivar() -> void:
	if _esquive > 0.0 or _espera_esquive > 0.0 or not is_on_floor():
		return
	var eje := Input.get_vector("izquierda", "derecha", "adelante", "atras")
	var dir := (Basis(Vector3.UP, _yaw) * Vector3(eje.x, 0.0, eje.y))
	# Con dirección, rodás hacia donde apuntás y el cuerpo se da vuelta.
	#
	# Parado, **te apartás de costado, no para atrás.** Ir para atrás se probó y
	# se siente raro: en vista de arriba el retroceso se lee como que el juego
	# te empujó, no como que te sacaste. Un paso al costado deja al que te pega
	# donde estaba, te mantiene mirándolo para el contragolpe, y es lo que hace
	# cualquier juego con esta cámara.
	_esquive_gira = dir.length_squared() >= 0.01
	if not _esquive_gira:
		var frente := Vector3(sin(_malla.rotation.y), 0.0, cos(_malla.rotation.y))
		dir = frente.cross(Vector3.UP) * (1.0 if randf() < 0.5 else -1.0)
	_dir_esquive = dir.normalized()
	_esquive = ESQUIVE_DURA
	_espera_esquive = ESQUIVE_ESPERA
	esquivo.emit(ESQUIVE_ESPERA)


func _physics_process(dt: float) -> void:
	var mudo := _tecleando()
	_espera_esquive = maxf(0.0, _espera_esquive - dt)
	if not is_on_floor():
		velocity.y -= GRAVEDAD * dt
	elif Input.is_action_just_pressed("saltar") and not mudo:
		velocity.y = FUERZA_SALTO

	# La dirección es relativa a la cámara, aplanada al piso. Sin esto, girar
	# la cámara invierte los controles.
	var eje := Vector2.ZERO if mudo else Input.get_vector("izquierda", "derecha", "adelante", "atras")
	var base := Basis(Vector3.UP, _yaw)
	var dir := (base * Vector3(eje.x, 0.0, eje.y)).normalized()

	if _esquive > 0.0:
		_esquive = maxf(0.0, _esquive - dt)
		# `dir` de acá para abajo sólo decide hacia dónde mira el cuerpo. En la
		# rodada para atrás se deja en cero para que no gire (ver `_esquivar`).
		dir = _dir_esquive if _esquive_gira else Vector3.ZERO
		# Sin `move_toward`: la rodada es un empujón, no una aceleración. Con
		# rampa se siente como caminar rápido y no como sacar el cuerpo.
		velocity.x = _dir_esquive.x * ESQUIVE_VELOCIDAD
		velocity.z = _dir_esquive.z * ESQUIVE_VELOCIDAD
		# La vuelta de campana. Va en el contenedor `Malla` y no en `figura.gd`
		# a propósito: el esqueleto 3D tiene fecha de vencimiento —el juego pasa
		# a sprites 2D— y esto sobrevive igual porque es una sola rotación.
		# `sin(t*PI)` vuelve a cero solo al terminar, así que no hay que
		# acordarse de resetearlo (y no pisa la inclinación de estar caído,
		# que la escribe `valle.gd` cuando ya no se puede rodar).
		# El signo sigue al sentido: rodando hacia adelante da la vuelta de
		# campana para adelante, y tirándote para atrás, para atrás.
		if _esquive_gira:
			_malla.rotation.x = -sin((1.0 - _esquive / ESQUIVE_DURA) * PI) * 0.68
		else:
			# De costado el cuerpo se LADEA, no da la vuelta de campana. Rodar
			# hacia adelante mientras te movés al costado se ve a error.
			_malla.rotation.z = sin((1.0 - _esquive / ESQUIVE_DURA) * PI) * 0.55
	else:
		var corriendo := Input.is_key_pressed(KEY_SHIFT) and not mudo
		var deseada := dir * (VELOCIDAD_CORRIENDO if corriendo else VELOCIDAD)
		velocity.x = move_toward(velocity.x, deseada.x, ACELERACION * dt)
		velocity.z = move_toward(velocity.z, deseada.z, ACELERACION * dt)

	if dir.length_squared() > 0.01:
		# Girar el cuerpo hacia donde camina, suave.
		var objetivo := atan2(dir.x, dir.z)
		_malla.rotation.y = lerp_angle(_malla.rotation.y, objetivo, 12.0 * dt)

	_animar_golpe(dt)

	# El retroceso se SUMA a lo que pediste con el teclado y se apaga por
	# rozamiento en 3 a 5 cuadros. Se suma y no reemplaza porque un empujón que
	# te saca el control aunque sea una décima se siente peor que el golpe:
	# *"que te tira para atrás es raro"* ya fue el reclamo de esta cámara.
	#
	# Y se saca justo después de `move_and_slide()`, por el mismo motivo que en
	# `monstruo.gd`: `velocity` sobrevive al cuadro y el `move_toward` de la
	# caminata sólo la baja 0,23 m/s por cuadro, así que un empujón que se suma
	# todos los cuadros no se apaga, se acumula. Medido con el bug puesto en el
	# bicho: 41 m/s en seis cuadros.
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
	if figura != null:
		figura.animar(dt, Vector2(velocity.x, velocity.z).length(), is_on_floor())

	# 7 cuadros de sacudida con la amplitud bajando lineal. La fase sigue
	# corriendo aparte para que el temblor no se congele con la amplitud.
	if _sacudida > 0.0:
		_sacudida_reloj += dt
		_sacudida = maxf(0.0, _sacudida - dt / Impacto.SACUDIDA_DURA)
	else:
		_sacudida_reloj = 0.0

	_dist = lerp(_dist, _dist_objetivo, 8.0 * dt)
	_recolocar_camara(false)


## Sacudir la cámara. `fuerza` es 0..1 y se queda con la más grande de las que
## haya pendientes: dos golpes juntos no suman una sacudida del doble.
##
## Lo llama `monstruo.gd`, que es el que sabe la geometría del choque. Está
## acá porque la cámara vive acá.
func sacudir(fuerza: float) -> void:
	_sacudida = maxf(_sacudida, clampf(fuerza, 0.0, 1.0))


## Empujón de retroceso, en m/s. Se apaga solo.
func empujar(v: Vector3) -> void:
	_empuje = Vector3(v.x, 0.0, v.z)


func _recolocar_camara(inmediato: bool) -> void:
	var desplazamiento := Vector3(
		sin(_yaw) * cos(_pitch),
		sin(_pitch),
		cos(_yaw) * cos(_pitch),
	) * _dist
	if inmediato:
		_pivote.position = Vector3.ZERO
		_cam_suave = desplazamiento
	else:
		_cam_suave = _cam_suave.lerp(desplazamiento, 0.25)

	var pos := _cam_suave
	if _sacudida > 0.0:
		# El temblor va en el plano de la PANTALLA —derecha y arriba de la
		# cámara— y no en los ejes del mundo: sacudir en X del mundo con la
		# cámara mirando desde el noreste se lee como que el mundo se desliza
		# en diagonal, no como un impacto.
		var der := desplazamiento.cross(Vector3.UP)
		if der.length_squared() < 0.0001:
			der = Vector3.RIGHT
		der = der.normalized()
		var arr := der.cross(desplazamiento).normalized()
		# La amplitud es una FRACCIÓN de la distancia de cámara: 1,1% de 40 m
		# son 44 cm, que mueven la imagen ~1,4% del alto de pantalla (13 px a
		# 900p). Con la cámara a 12 m el mismo porcentaje da 13 cm y se ve
		# igual de fuerte, que es el punto.
		var amp := _dist * Impacto.SACUDIDA_FRACCION * _sacudida
		# Dos frecuencias que no encajan (34 Hz y 27 Hz): un seno solo se lee
		# como un péndulo. En 7 cuadros esto da tres cambios de sentido.
		pos += der * sin(_sacudida_reloj * 214.0) * amp
		pos += arr * sin(_sacudida_reloj * 173.0 + 1.7) * amp * 0.7
	_camara.position = pos
	_camara.look_at(global_position + Vector3.UP * 1.1, Vector3.UP)


## Pegar.
##
## MEDIDO, porque el reclamo fue "no mueve los brazos" y la conclusión obvia
## era que la animación estaba desconectada. **No lo está.** Con la figura
## armada en headless, `atacar()` seguido de `animar()` lleva el brazo derecho
## a **1,99 rad — 114 grados — durante 16 cuadros (~0,27 s)**. El swing existe
## y es amplio.
##
## Lo que no existe es a qué distancia se ve: la cámara está a 40 m por
## defecto, ahí un cuerpo de 1,8 m mide unos pocos píxeles de alto, y un brazo
## es una fracción de eso durante un cuarto de segundo. El jugador no se
## equivocó en lo que vio — se equivocó en la causa.
##
## Por eso además del swing va una estocada del cuerpo entero: 35 cm hacia
## adelante y vuelta. La silueta es lo único que se lee a esta distancia (es la
## regla de arte del proyecto), así que mover la silueta es lo que hace legible
## el golpe. Va en `position` del contenedor `Malla` y no en `figura.gd`: no
## pisa la rotación de la rodada ni el `position:y` con el que `valle.gd` te
## tumba, y cuando los cuerpos pasen a sprites 2D esto sigue valiendo igual.
## Cuánto avanza el cuerpo en el embate. Subió de 35 a 45 cm: a 40 m son 13 px
## de silueta desplazándose, que es el mínimo para que se lea como una estocada
## y no como que el personaje tembló.
const GOLPE_ALCANCE := 0.45
## Y cuánto retrocede ANTES. 22 cm en 5 cuadros. Es la mitad del recorrido de
## ida, la proporción de siempre: el anticipo tiene que verse y no tiene que
## competir con el golpe.
const GOLPE_RETROCESO := 0.22

var _golpe := 0.0

func amagar_golpe() -> void:
	if figura != null:
		figura.atacar()
	_golpe = Impacto.SWING_TOTAL


## La estocada, cuadro a cuadro. Mismas tres fases que el brazo en `figura.gd`
## y con los mismos números, que salen los dos de `impacto.gd`: si el cuerpo y
## el brazo no coinciden en el cuadro del contacto se ve como dos animaciones
## encimadas.
##
##   cuadros 0-4    el cuerpo se va 22 cm PARA ATRÁS
##   cuadro  5      contacto: acá pega, se congela y salta la chispa
##   cuadros 5-12   sale 45 cm para adelante, medio recorrido en 2 cuadros
##   cuadros 13-22  vuelve, con salida suave
##
## Se apaga sola en cero, así que no hay que acordarse de resetear la posición.
func _animar_golpe(dt: float) -> void:
	if _golpe <= 0.0:
		return
	_golpe = maxf(0.0, _golpe - dt)
	var e := Impacto.SWING_TOTAL - _golpe

	var avance := 0.0
	if e < Impacto.SWING_ANTICIPO:
		avance = -GOLPE_RETROCESO * sin(e / Impacto.SWING_ANTICIPO * PI * 0.5)
	elif e < Impacto.SWING_ANTICIPO + Impacto.SWING_EMBATE:
		var p := pow((e - Impacto.SWING_ANTICIPO) / Impacto.SWING_EMBATE, 0.45)
		avance = lerpf(-GOLPE_RETROCESO, GOLPE_ALCANCE, p)
	else:
		var u := clampf((e - Impacto.SWING_ANTICIPO - Impacto.SWING_EMBATE)
			/ Impacto.SWING_RECUPERA, 0.0, 1.0)
		avance = GOLPE_ALCANCE * (1.0 - u * u * (3.0 - 2.0 * u))

	# El desplazamiento es del contenedor `Malla`, no del cuerpo físico: es
	# presentación. El colisionador —y por lo tanto el alcance real que mide
	# `valle.gd`— no se mueve ni un centímetro.
	_malla.position.x = sin(_malla.rotation.y) * avance
	_malla.position.z = cos(_malla.rotation.y) * avance


func doler() -> void:
	if figura != null:
		figura.doler()


## F2 saca una captura al Escritorio.
##
## No es una comodidad: nadie del equipo puede ver el juego —Godot corre por
## software y sin GPU en la máquina donde se desarrolla— así que la única
## manera de saber cómo se ve de verdad es que la saque quien lo está jugando.
func _input(evento: InputEvent) -> void:
	if not (evento is InputEventKey and evento.pressed and not evento.echo):
		return
	if (evento as InputEventKey).keycode != KEY_F2:
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var dir := OS.get_executable_path().get_base_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(dir)
	var t := Time.get_datetime_dict_from_system()
	var nombre := "%02d%02d%02d-%02d%02d%02d.png" % [
		t.year % 100, t.month, t.day, t.hour, t.minute, t.second]
	img.save_png(dir.path_join(nombre))
	print("captura: ", dir.path_join(nombre))

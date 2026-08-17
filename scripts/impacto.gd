## La sensación del golpe. **Acá está la tabla de cuadros, y en ningún otro lado.**
##
## El diagnóstico, dicho por quien juega: *"sólo pegás con una mano, no podés
## equipar, es todo muy sonso"*. Y el golpe funciona: el clic llega, el servidor
## resuelve, la vida baja, el arma forjada se ve en la mano. Lo que faltaba no
## era una mecánica: era que el choque **pasara en pantalla**.
##
## Un golpe se siente por un puñado de cosas que ocurren en el mismo décimo de
## segundo, y todas están medidas en CUADROS a 60 fps, no en adjetivos:
##
## | # | qué                | cuadros | por qué ese número                        |
## |---|--------------------|---------|-------------------------------------------|
## | 1 | anticipo           |    5    | 83 ms. Menos no se ve a 40 m; más se lee   |
## |   |                    |         | como demora del botón.                     |
## | 2 | embate (al frente) |    8    | 133 ms. El tramo donde la silueta viaja.   |
## | 3 | recuperación       |   10    | 167 ms. Vuelve sola; no bloquea nada.      |
## | 4 | pausa al dar       |    3    | 50 ms congelados. Dos es poco a 40 m,      |
## |   |                    |         | cuatro ya se lee como tirón de red.        |
## | 5 | pausa al recibir   |    4    | 67 ms. El que te pegan pesa más.           |
## | 6 | sacudida de cámara |    7    | 117 ms con amplitud decreciendo lineal.    |
## | 7 | retroceso          |   4-8   | ver EMPUJE_*: se apagan por rozamiento.    |
## | 8 | chispa             |   12    | 200 ms: 5 abriendo, 7 apagándose.          |
## | 9 | sonido             |    0    | en el cuadro del contacto, no en un timer. |
##
## El swing entero son **23 cuadros (0,383 s)**. No hay bloqueo de control en
## ningún momento: podés caminar y girar mientras dura, así que los 23 cuadros
## no son 23 cuadros de "perdí el control" — son 23 cuadros de animación encima
## de un personaje que te sigue obedeciendo.
##
## ## Las dos reglas que ordenan todo esto
##
## **1. La respuesta empieza en el cuadro del botón.** El anticipo ES la
## respuesta: en el cuadro 0 el cuerpo ya se está echando hacia atrás. Lo que
## está en el cuadro 5 es el CONTACTO, no la reacción. Nada de esto espera al
## servidor — `valle.gd` ya pinta el golpe al instante y corrige después.
##
## **2. Todo se mueve a escala de cuerpo entero.** La cámara está a 40 m y a
## veces a 68. Ahí un brazo son dos píxeles: ya pasó que se reportara "no mueve
## los brazos" cuando el brazo llegaba a 114 grados. Por eso el anticipo mueve
## el torso 31°, el embate lo cruza 83°, el que recibe se aplasta un 17% y se
## va medio metro para atrás. Nada de esto es un detalle de miembro.
##
## ## Lo que este archivo NO hace
##
## **No inventa daño ni decide que un golpe acertó.** Todo lo de acá es
## presentación: cuadros congelados, píxeles temblando y una chispa. Quién
## acertó lo decide `valle.gd` por geometría y cuánto duele lo decide el
## servidor. Eso ya se rompió una vez en este proyecto y costó rehacerlo.
class_name Impacto
extends Node3D

const CUADRO := 1.0 / 60.0

# ── La tabla, en segundos ───────────────────────────────────────────────────

## Anticipo: 5 cuadros. El cuerpo se va para atrás antes de salir.
const SWING_ANTICIPO := 5.0 * CUADRO
## Embate: 8 cuadros. El tramo en el que la silueta viaja hacia adelante.
const SWING_EMBATE := 8.0 * CUADRO
## Recuperación: 10 cuadros. Vuelve a la pose neutra con salida suave.
const SWING_RECUPERA := 10.0 * CUADRO
## 23 cuadros, 0,383 s.
const SWING_TOTAL := SWING_ANTICIPO + SWING_EMBATE + SWING_RECUPERA

## El cuadro en que el arma llega. Coincide con el final del anticipo: si el
## impacto se pintara antes, el brazo todavía está yendo para atrás y se lee
## como que el enemigo se dolió solo.
const CONTACTO := SWING_ANTICIPO

## Pausa al impactar, en cuadros. Es lo más barato de esta lista y lo que más
## rinde: sin ella el golpe atraviesa al enemigo como si no estuviera.
const PAUSA_DAR := 3
const PAUSA_RECIBIR := 4
## Techo duro. Si algo se va de mano, el mundo no se queda congelado.
const PAUSA_MAX_MS := 120

## Sacudida de cámara: 7 cuadros. Más largo marea; a esta distancia con menos
## no se distingue de un tirón de red.
const SACUDIDA_DURA := 7.0 * CUADRO
## Amplitud como FRACCIÓN DE LA DISTANCIA de cámara, no en metros. A 40 m un
## desplazamiento de 40 cm mueve la imagen ~1,4% de la altura de pantalla; a
## 12 m el mismo desplazamiento sería un terremoto. Atarlo a `_dist` es lo que
## hace que la sacudida se vea igual con la cámara cerca y lejos.
const SACUDIDA_FRACCION := 0.011
## Cuánta de esa amplitud usa cada caso. Recibir sacude fuerte; dar, la mitad.
const SACUDIDA_DAR := 0.55
const SACUDIDA_RECIBIR := 1.0

## Retroceso, en m/s de empujón inicial. Se apagan con `EMPUJE_FRENO`, así que
## el número que importa es la DISTANCIA que recorren. **Medidas, integrando
## cuadro a cuadro y verificadas contra el juego corriendo:**
##   · el bicho al que le pegás:  8,0 m/s -> 8 cuadros, 58 cm
##   · vos cuando te pegan:       4,8 m/s -> 5 cuadros, 23 cm
##   · el que PEGA, siempre menos: 3,2 m/s -> 4 cuadros, 11 cm
##
## Los 23 cm de cuando te pegan son a propósito cortos: *"que te tira para
## atrás es raro"* ya fue un reclamo de esta cámara. Un sacudón de 5 cuadros se
## lee como un golpe; medio metro de deslizamiento se lee como que el juego te
## empujó. Los 58 cm del bicho sí son medio cuerpo, y ahí sí queremos que se
## vea que salió despedido.
const EMPUJE_RECIBE := 8.0
const EMPUJE_JUGADOR := 4.8
const EMPUJE_PEGA := 3.2
const EMPUJE_FRENO := 62.0

## La chispa: 12 cuadros.
const CHISPA_ABRE := 5.0 * CUADRO
const CHISPA_TOTAL := 12.0 * CUADRO
## Diámetro final en METROS, porque lo que importa es cuánto ocupa en pantalla:
## a 40 m con FOV 42° la pantalla mide 30,7 m de alto, así que 1,2 m son casi el
## 4% del alto — unos 35 px a 900p. Una chispa de 10 cm no existiría.
const CHISPA_DIAMETRO := 1.2
const CHISPA_PUAS := 6
## Energía del fogonazo. Bajó de 6 a 3 después de mirarlo: a 6 y de noche, con
## la cámara cerca, el impacto era la única fuente de luz de la escena y la
## lavaba entera. Tres alcanza para que se vea que el choque PINTA el pasto y
## los dos cuerpos, que es para lo que está.
const LUZ_ENERGIA := 3.0


# ---------------------------------------------------------------------------
# 1. La pausa al impactar
# ---------------------------------------------------------------------------
#
# `Engine.time_scale = 0` para de verdad: no es una animación de "casi quieto",
# es el mundo detenido, que es lo que hace que el cerebro registre el choque.
#
# El reloj de salida es de PARED (`Time.get_ticks_msec()`) y no del motor, y
# tiene que serlo: con el tiempo escalado a cero un temporizador del árbol
# tampoco avanza y la pausa duraría para siempre. `vigilar()` lo llama
# `Jugador._process()`, que sí se sigue ejecutando —con delta 0— mientras el
# mundo está congelado.

static var _congelado := false
static var _fin_ms := 0


## Congela el mundo `cuadros` cuadros. Reentrante: dos golpes juntos no suman
## sus pausas, se quedan con la más larga.
static func congelar(cuadros: int) -> void:
	var ms: int = mini(int(cuadros * 1000.0 / 60.0), PAUSA_MAX_MS)
	var fin: int = Time.get_ticks_msec() + ms
	if _congelado:
		_fin_ms = maxi(_fin_ms, fin)
		return
	_congelado = true
	_fin_ms = fin
	Engine.time_scale = 0.0


## El que descongela. Va en `_process` del jugador porque `_process` se llama
## todos los cuadros dibujados aunque `time_scale` sea cero, y `_physics_process`
## no.
static func vigilar() -> void:
	if not _congelado:
		return
	if Time.get_ticks_msec() >= _fin_ms:
		_congelado = false
		Engine.time_scale = 1.0


## Red de seguridad para cuando la escena se va (cambio de escena, cierre): un
## mundo que se queda en `time_scale = 0` no se recupera solo.
static func soltar() -> void:
	if _congelado:
		_congelado = false
		Engine.time_scale = 1.0


# ---------------------------------------------------------------------------
# 5. Algo que salta donde chocó
# ---------------------------------------------------------------------------
#
# No hace falta que sea lindo: hace falta que la pantalla CAMBIE ahí. Son seis
# púas radiales, un núcleo y una luz, en un disco que mira a la cámara. Se
# arma, se abre y se borra solo en 12 cuadros.
#
# Por qué púas y no un puñado de partículas: a 40 m una partícula de 5 cm no
# llega a un píxel. Lo que llega es una forma de un metro que aparece y se va.

var _reloj := 0.0
var _mat: StandardMaterial3D
var _luz: OmniLight3D
var _tono := Color.WHITE
var _escala := 1.0


## Planta una chispa en `donde`. `cerca` sólo se usa para llegar al árbol.
static func estallar(cerca: Node, donde: Vector3, tono: Color, escala: float = 1.0) -> void:
	if cerca == null or not cerca.is_inside_tree():
		return
	var raiz: Node = cerca.get_tree().current_scene
	if raiz == null:
		raiz = cerca.get_parent()
	if raiz == null:
		return
	var n := Impacto.new()
	n._tono = tono
	n._escala = escala
	raiz.add_child(n)
	n.global_position = donde
	n._armar()


func _armar() -> void:
	# Mirando a la cámara. Se orienta UNA vez y no por cuadro: dura 200 ms, en
	# ese rato la cámara no gira lo suficiente como para que se note, y así no
	# hay que buscar la cámara sesenta veces por segundo.
	# `get_viewport()` da null si el nodo todavía no está en el árbol, y un error
	# acá aborta la función ENTERA: quedaría una chispa sin mallas, sin luz y
	# sin sonido. Es la misma trampa que ya costó un `_ready()` sin HUD.
	var vp := get_viewport()
	var cam := vp.get_camera_3d() if vp != null else null
	if cam != null:
		var d := cam.global_position - global_position
		if d.length_squared() > 0.01:
			look_at(cam.global_position, Vector3.UP)

	_mat = StandardMaterial3D.new()
	# Sin sombreado y aditivo: una chispa tiene que verse igual de noche, en la
	# sombra del bosque y contra el cielo. Si la ilumina el sol, a veces no está.
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat.albedo_color = _tono

	# La malla se arma a tamaño 1 y el tamaño real lo pone `scale` en `_process`,
	# que es también quien la abre. Si el radio ya viniera multiplicado por
	# `_escala`, el factor se aplicaría dos veces.
	var radio := CHISPA_DIAMETRO * 0.5

	var nucleo := SphereMesh.new()
	nucleo.radius = radio * 0.30
	nucleo.height = radio * 0.60
	nucleo.material = _mat
	var mn := MeshInstance3D.new()
	mn.mesh = nucleo
	mn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mn)

	# Las púas no están repartidas parejo: un asterisco perfecto se lee como un
	# símbolo. El desvío las vuelve un estallido.
	for i: int in CHISPA_PUAS:
		var a := float(i) / float(CHISPA_PUAS) * TAU + sin(float(i) * 2.7) * 0.22
		var largo: float = radio * (0.72 + absf(sin(float(i) * 1.9)) * 0.5)
		var b := BoxMesh.new()
		b.size = Vector3(radio * 0.13, largo, radio * 0.13)
		b.material = _mat
		var mi := MeshInstance3D.new()
		mi.mesh = b
		mi.position = Vector3(cos(a), sin(a), 0.0) * (radio * 0.30 + largo * 0.5)
		mi.rotation.z = a - PI * 0.5
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)

	# La luz es la mitad del efecto y cuesta un nodo: pinta el pasto, el bicho y
	# tu propio cuerpo durante tres cuadros. Sin ella la chispa flota encima de
	# la escena en vez de pasar dentro de ella.
	_luz = OmniLight3D.new()
	_luz.light_color = _tono
	# El alcance va en metros de mundo y NO lo escala el nodo padre, así que acá
	# sí se multiplica por `_escala` a mano.
	_luz.omni_range = 4.0 * _escala
	_luz.light_energy = LUZ_ENERGIA
	_luz.shadow_enabled = false
	# **Fuera de la niebla volumétrica.** Sin esto la chispa no ilumina un
	# radio de cuatro metros: ilumina la niebla de `ambiente.gd`, que ocupa el
	# encuadre entero. Medido de noche a 14 m de cámara: la pantalla COMPLETA se
	# teñía de rojo herrumbre durante doce cuadros. Un fogonazo tiene que decir
	# "chocó ACÁ", y un tinte de pantalla entera dice exactamente lo contrario.
	_luz.light_volumetric_fog_energy = 0.0
	add_child(_luz)

	scale = Vector3.ONE * 0.35 * _escala
	_sonar()


func _process(dt: float) -> void:
	# `dt` está escalado por `time_scale`, o sea que durante la pausa vale 0 y
	# la chispa se queda quieta y encendida. Es exactamente lo que se quiere:
	# aparece, el mundo se para, y recién ahí se abre.
	_reloj += dt
	if _reloj >= CHISPA_TOTAL:
		queue_free()
		return

	# Cuadros 0-4: se abre de 0,35 a 1,0 con salida rápida (pow 0.45).
	# Cuadros 5-11: sigue creciendo apenas —hasta 1,15— mientras se apaga. Que
	# siga creciendo mientras se va es lo que lo hace leer como algo que se
	# disipa y no como algo que se apagó.
	var s := 1.0
	var brillo := 1.0
	if _reloj < CHISPA_ABRE:
		var u := _reloj / CHISPA_ABRE
		s = lerpf(0.35, 1.0, pow(u, 0.45))
	else:
		var u := (_reloj - CHISPA_ABRE) / (CHISPA_TOTAL - CHISPA_ABRE)
		s = lerpf(1.0, 1.15, u)
		brillo = 1.0 - u * u   # se apaga rápido al principio y se demora al final

	scale = Vector3.ONE * s * _escala
	if _mat != null:
		_mat.albedo_color = Color(_tono.r, _tono.g, _tono.b, brillo)
	if _luz != null:
		_luz.light_energy = LUZ_ENERGIA * brillo * brillo


# ---------------------------------------------------------------------------
# El sonido, en el cuadro exacto
# ---------------------------------------------------------------------------
#
# Un impacto que suena tarde se siente desconectado aunque sea el mismo sonido.
# Por eso el `play()` sale de la misma función que la chispa y la pausa, y no
# de un temporizador.
#
# Se sintetiza acá y no en `sonido.gd` a propósito: ese archivo es el LECHO de
# ambiente —bucles largos con buses por voz y mezcla por posición— y un golpe
# es lo contrario, una muestra de 100 ms que se dispara y se olvida. Meterlo
# ahí sería colgarle un caso especial a una máquina que no es para eso.

const SON_HZ := 22050
static var _wav: AudioStreamWAV


## Un golpe seco: un cuerpo grave que cae de 165 a 55 Hz en 40 ms y un
## chasquido de ruido encima. Es la misma receta que un tambor sintetizado, que
## es lo que un impacto ES.
static func _muestra() -> AudioStreamWAV:
	if _wav != null:
		return _wav
	var n := int(SON_HZ * 0.10)
	var datos := PackedByteArray()
	datos.resize(n * 2)
	var fase := 0.0
	var r := RandomNumberGenerator.new()
	r.seed = 20260817   # determinista: el mismo golpe en todas las máquinas
	var previo := 0.0
	for i: int in n:
		var t := float(i) / float(SON_HZ)
		# El cuerpo. La caída de tono es lo que lo vuelve un impacto y no un pitido.
		var hz: float = lerpf(165.0, 55.0, minf(1.0, t / 0.040))
		fase += TAU * hz / float(SON_HZ)
		var cuerpo: float = sin(fase) * exp(-t * 34.0)
		# El chasquido. Diferenciar el ruido lo sube de tono sin filtro: es un
		# pasa-altos de una línea, y para 100 ms alcanza.
		var blanco := r.randf_range(-1.0, 1.0)
		var chas: float = (blanco - previo) * 0.5 * exp(-t * 95.0)
		previo = blanco
		var v: float = clampf(cuerpo * 0.82 + chas * 0.55, -1.0, 1.0)
		var q := int(v * 32000.0)
		datos.encode_s16(i * 2, q)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SON_HZ
	w.stereo = false
	w.data = datos
	_wav = w
	return w


func _sonar() -> void:
	if not is_inside_tree():
		return   # sin árbol no hay reproducción, y el motor lo grita en rojo
	var p := AudioStreamPlayer3D.new()
	p.stream = _muestra()
	# Un golpe no compite con el lecho: entra 6 dB por debajo del pico y se va.
	p.volume_db = -6.0
	# El valle es grande y la cámara está a 40 m. Con la unidad por defecto (1 m)
	# un golpe a 40 m no se oiría; con 14 m se oye desde donde se juega y se
	# apaga si el choque fue en la otra punta.
	p.unit_size = 14.0
	p.max_distance = 90.0
	# Un poco de variación de tono para que diez golpes seguidos no suenen a
	# metralleta. Es el mismo truco del yunque en `sonido.gd`.
	p.pitch_scale = randf_range(0.92, 1.10)
	add_child(p)
	p.play()

## Lo que crece en el valle. Todo el valle, no una manchita.
##
## ===========================================================================
## EL DIAGNÓSTICO QUE TRAJO ESTE ARCHIVO
## ===========================================================================
##
## Había árboles: `_armar_bosque()` en valle.gd plantaba 46 conos con tronco.
## El problema era otro y era peor: **estaban sólo adentro del grupo `bosque`,
## en un radio de 13 metros, y el valle mide 360 metros de lado.** El 99 % del
## mapa no tenía un solo árbol. La vegetación nunca escaló cuando el mapa
## creció de 132 a 360 m, y de ahí sale el veredicto de quien lo juega: *"el
## mundo parece juegos de Playmobil"*.
##
## Un valle sin masas de vegetación no tiene horizonte: la cordillera arranca
## de la nada y el suelo llega hasta ella pelado. Lo que hace que un lugar se
## lea como un lugar desde 27 metros no son las hojas, es **dónde hay bulto
## oscuro y dónde no**.
##
## ===========================================================================
## LAS TRES REGLAS, Y CÓMO ESTÁN IMPLEMENTADAS
## ===========================================================================
##
## **1. VARIACIÓN, NO REPETICIÓN — y determinista.**
##
## Es multijugador: el bosque tiene que ser el MISMO en la pantalla de todos.
## Así que no hay un solo `randf()` acá adentro. Todo sale de `azar()`, un
## hash entero de la celda de la grilla, y de dos `FastNoiseLite` con semilla
## fija. Nada de `String.hash()`, que no promete el mismo número entre
## versiones del motor.
##
## Lo que varía por árbol: altura, grosor, ancho de copa, inclinación, giro y
## tono. Y una regla que hace más por la variación que todas las demás juntas:
##
##   **CUANTO MÁS SOLO, MÁS GRANDE.** El tamaño se escala por el inverso de la
##   densidad local. El motivo es de composición antes que de botánica: un
##   árbol suelto en el prado sólo existe si es lo bastante grande para ser un
##   punto de referencia, y adentro de una masa un árbol no es una pieza, es
##   textura de la masa — ahí conviene flaco y alto. Que además sea cierto en
##   el mundo real (uno tuvo lugar y luz, el otro se los peleó) es lo que hace
##   que la regla no se note como regla.
##
## **2. AGRUPAMIENTO.** La densidad es un campo con zonas nombradas (abajo),
## multiplicado por un ruido de grumos que abre calvas y senderos adentro de
## cada masa. Una distribución pareja es lo que más grita "computadora".
##
## **3. SILUETA ANTES QUE HOJA.** Dos mallas y nada más: una aguja de cinco
## caras y una copa redonda de cinco caras, treinta triángulos cada una, con
## sombreado plano. No hay una sola hoja. Todo el presupuesto está en el
## contorno contra el cielo, que es lo único que existe a la distancia de la
## cámara (DISENO.md §6 fijó el piso de zoom en silueta, postura y ropa —
## nunca una expresión).
##
## ===========================================================================
## ESTILIZADO, Y COMPROMETIDO (DISENO.md §6, decidido el 17 de agosto)
## ===========================================================================
##
## *"Lo que se lee como barato no es la simpleza: es la indecisión."* Este
## archivo está del lado de la decisión, y eso se ve en tres cosas concretas:
##
##  · **Cinco caras y facetas duras.** Un árbol acá es de la misma familia de
##    formas que un techo del valle: prisma de pocas caras, sombreado plano,
##    contorno neto. No hay ruido de superficie que finja corteza ni hojas: el
##    sacudón del torneado es del 12 %, apenas lo justo para que dos árboles no
##    sean el mismo, y **la variedad sale de la proporción, no del ruido.** Un
##    árbol nudoso a medio camino de lo real es exactamente el plástico bajo
##    luz de verdad que la dirección de arte nombró.
##  · **El color separa, no imita.** El verde de una copa no es el verde de una
##    hoja: es el peldaño de valor que la despega del suelo V4 y de la montaña.
##    Por eso todos salen de `paleta.gd` y por eso el rango es angosto.
##  · **Menos geometría, no más.** Cada vez que había que elegir entre agregar
##    detalle y comprometerse con lo simple, se eligió lo simple: dos mallas y
##    no seis, cinco gajos y no ocho, cero tapa arriba del tronco, cero hoja.
##
## ===========================================================================
## EL MAPA DE LO QUE CRECE — cada masa dice algo
## ===========================================================================
##
##  · **LA RIBERA.** Bosque de galería pegado al río, de punta a punta del
##    valle. El río ya es la línea más fuerte del encuadre (V2 sobre un suelo
##    V4); flanquearlo de copas V2 la duplica y la vuelve legible desde
##    cualquier lado. **Y tiene un corte: el vado.** Frente a la aldea la
##    arboleda se abre — por eso el pueblo se llama Vado Bajo, y por ahí
##    arranca el camino al norte. Un hueco en una línea continua se lee como
##    decisión; el mismo hueco en un campo parejo no se lee como nada.
##
##  · **EL SOTOBOSQUE.** Robles viejos, la mancha más oscura y más densa del
##    valle, con sotobosque tupido abajo. Sale de la montaña por una lengua de
##    bosque al suroeste: **no es una isla, es de dónde viene la gente que
##    vive ahí.** Y del lado que mira a la aldea tiene una **tala**: una cuña
##    de tocones y matorral donde el bosque se termina de golpe y no por
##    naturaleza. Los del Sotobosque tienen un agravio con la aldea; la cuña
##    lo cuenta sin una línea de diálogo.
##
##  · **EL PÁRAMO DE LA CASA QUEMADA.** Vacío, y **declarado** (DISENO.md
##    §7.4: el vacío tiene que ser intencional y estar señalado). Adentro no
##    crece nada vivo: sólo troncos secos parados, grises y fríos como el muro
##    de la ruina. Alrededor, a cuarenta metros, un anillo de renoval joven y
##    apretado — coníferas, otra especie que la que había — **el bosque
##    cerrándose sobre el claro.** Y contra las casas quemadas, un puñado de
##    plantines: el bosque comiéndose la ruina. Nadie la reconstruye y se ve.
##
##  · **EL FALDEO.** Un anillo de coníferas que sube del prado a la base de la
##    cordillera. Es lo que cose el suelo del valle con la montaña, que hoy
##    aparece de la nada. **Y se abre al norte**, exactamente en el portal que
##    dibuja `_armar_cordillera()`: la única salida del valle tiene que verse
##    desde adentro.
##
##  · **EL CAMINO DEL NORTE.** Alameda: dos hileras que flanquean el camino y
##    convergen hacia la abertura. Los árboles plantados por gente son
##    **regulares** —poca variación de tamaño, poca dispersión— y los
##    silvestres no. Esa diferencia es la señal más barata de "acá alguien
##    hizo algo".
##
##  · **LA FRAGUA.** Talada. Ilde quema carbón: alrededor hay tocones y
##    renoval flaco, y ningún árbol grande a menos de veinte metros.
##
##  · **LA ALDEA.** Despejada, son los campos. Sobreviven cinco **árboles
##    testigo**: solos, enormes, en medio del pasto. Son los que nadie cortó.
##
##  · **EL PRADO.** Densidad de fondo bajísima con bosquecillos ocasionales.
##    Es el lienzo, y tiene que seguir leyéndose como pastura abierta.
##
## ===========================================================================
## LOS COLORES SALEN DE `paleta.gd` Y DE NINGÚN OTRO LADO
## ===========================================================================
##
## `Paleta.COPA` (h96 s0.30 v0.21, peldaño V2) es el ancla. De ahí salen dos
## anclas derivadas **por construcción, no inventadas**: `copa_humeda()` baja
## el valor a 0.175 y corre el matiz 8° al verde frío; `copa_seca()` lo sube a
## 0.262 y lo corre 11° al oliva. Todo el follaje del valle vive entre esas
## dos, o sea **dentro de un solo peldaño de la escalera de valor**: el bosque
## se modela por adentro sin dejar de ser UNA mancha oscura, que es
## literalmente lo que dice paleta.gd de las copas.
##
## **Cuál va dónde lo decide la composición, no la botánica.** La copa oscura
## va abajo y cerca —la ribera, la vaguada, el corazón del Sotobosque— y la
## clara va arriba y lejos —el faldeo, las lomas—, así las masas se separan
## por profundidad en vez de amontonarse en una sola papilla verde. Que eso
## coincida con dónde hay agua es la razón de que además se lea verdadero,
## pero el criterio es el otro: **si el verde correcto no separa, el correcto
## está mal.**
##
## Troncos: `Paleta.TRONCO`. Tocones: el mismo, más oscuro. Arbustos: COPA a
## v0.155, un peldaño abajo de las copas, porque el sotobosque es la sombra de
## abajo y no una segunda capa de verde. Secos: `Paleta.MURO_RUINA` —el único
## color frío de lo construido— mezclado con TRONCO.
##
## **PEDIDO AL DUEÑO DE LA PALETA:** las dos anclas derivadas (`COPA_HUMEDA` y
## `COPA_SECA`) y el verde de arbusto deberían vivir en `paleta.gd` como
## constantes. Acá se derivan de `Paleta.COPA` con deltas fijos justamente
## para no inventar un verde nuevo, pero el lugar donde eso se decide es la
## paleta, no este archivo.
##
## ===========================================================================
## EL COSTO — la vara es "no puede matarte la PC más que el Dota 2"
## ===========================================================================
##
##  · **Todo en MultiMesh, cortado en baldosas de 34 m**, igual que el pasto y
##    las piedras de `detalles.gd`. Un bosque de 360 metros en un solo
##    MultiMesh es una sola caja para el motor: se dibuja entero aunque estés
##    mirando para el otro lado. Ese error ya se arregló una vez, no se repite.
##  · **Como mucho tres MultiMesh por baldosa**: coníferas, frondas (con los
##    arbustos atrás) y troncos (con tocones y secos). Los arbustos van
##    *después* de los árboles en el mismo buffer a propósito: así
##    `visible_instance_count` ralea el sotobosque sin tocar un solo árbol.
##  · **Los troncos se dibujan hasta la mitad de distancia que las copas.** A
##    cien metros el tronco son dos píxeles tapados por la copa; la silueta ya
##    la puso la copa. Es la mitad de las llamadas de dibujo a cambio de nada.
##  · **Sin colisión. Ninguna.** Un bosque con colisión por árbol es caro y
##    hace que caminar sea pelearse con el mapa.
##  · **El bosque no se ralea en calidad baja: se acorta.** El pasto es adorno
##    y se puede diezmar; el bosque es la estructura del paisaje y sacarle la
##    mitad cambia la composición del mundo según la máquina. Lo que baja con
##    la calidad es la distancia de dibujado y las sombras. Los arbustos sí se
##    ralean: eso sí es adorno.
##
## Las cuentas exactas —instancias, baldosas, triángulos y densidad por zona—
## las imprime `escenas/prueba_vegetacion.tscn`, que corre sin servidor y sin
## el resto del juego.
class_name Vegetacion
extends Node3D

# ---------------------------------------------------------------------------
# Medidas
# ---------------------------------------------------------------------------

## La baldosa. 34 m, el mismo número que `Detalles.BALDOSA`, y por la misma
## razón: tiene que ser más chica que la distancia de dibujado más corta o
## ralear por distancia no hace nada.
const BALDOSA := 34.0

## El paso de la grilla de siembra. Una densidad de 1 en un paso de 2,4 m es
## una planta cada 5,8 m². Arrancó en 3,0 m y la primera medición dijo que no
## alcanzaba: el Sotobosque daba 266 árboles por hectárea, que es un monte
## abierto y no la mancha más oscura del valle. Este número se ajustó CONTRA LA
## TABLA de la escena de prueba, no a ojo.
const PASO := 2.4

## Hasta dónde se planta. El terreno mide 360 de lado (±180) y la cordillera
## arranca en r=300, así que 174 llega al borde sin pasarse.
const RADIO_PLANTABLE := 174.0

## Sólo para el suelo de la escena de prueba: es la constante de valle.gd.
const RADIO_VALLE := 165.0

## El río, tal como lo arma `valle.gd:_armar_rio()`: un plano de 430×15 en
## (0,−1.7,26) girado 9° en Y.
const RIO_CENTRO := Vector2(0.0, 26.0)
const RIO_GIRO := 9.0
const RIO_SEMI := 7.5

## Dónde está el vado: el hueco en la arboleda de ribera, frente a la aldea.
const VADO := Vector2(5.5, 26.0)

## Los lugares. Son los de `valle.gd:LUGARES` y están acá porque este módulo
## tiene que poder correr solo en la escena de prueba — pero `poblar()` acepta
## el diccionario de verdad y lo pisa, así que no hay dos fuentes de verdad
## cuando corre en el valle.
const LUGARES_DEFECTO := {
	"aldea": Vector3(0, 0, 0),
	"fragua": Vector3(62, 0, -18),
	"bosque": Vector3(-58, 0, -54),
	"ruina": Vector3(-26, 0, -108),
	"camino": Vector3(11, 0, 74),
}

## Tipos de planta. El tipo decide en qué MultiMesh cae.
enum {CONIFERA, FRONDA, ARBUSTO, TRONCO, TOCON, SECO}

@export var modo_prueba := false
@export var semilla := 20260817

var _alturas: Callable
var _lugares := LUGARES_DEFECTO.duplicate()
var _grumos := FastNoiseLite.new()
var _macro := FastNoiseLite.new()

var _nodos_copa: Array[MultiMeshInstance3D] = []
var _nodos_tronco: Array[MultiMeshInstance3D] = []
var _nivel_aplicado := -1
var _reloj := 0.0

## Para el informe de la escena de prueba.
var _cuenta := {}
var _por_zona := {}
var _baldosas := 0
var _ms_construir := 0.0
var _tris_copa := 0
var _tris_tronco := 0


# ===========================================================================
# EL AZAR QUE NO ES AZAR
# ===========================================================================

## Hash entero de tres números. Es el único generador de este archivo.
##
## Por qué a mano y no `RandomNumberGenerator`: el sembrado tiene que salir de
## la POSICIÓN y no de un orden de recorrido, así se puede sembrar por partes,
## en cualquier orden, y da lo mismo. Y por qué no `String.hash()`: no promete
## el mismo número entre versiones del motor, y esto es multijugador.
##
## **Todos los multiplicadores son menores que 2²⁷ a propósito.** Así ningún
## producto intermedio pasa los 63 bits y el desbordamiento —que en GDScript no
## está definido— no ocurre nunca. El mismo número en toda máquina.
static func revolver(a: int, b: int, c: int) -> int:
	var m := 0xFFFFFFFF
	var h := ((a * 73856093) ^ (b * 19349663) ^ (c * 83492791)) & m
	h = (h ^ (h >> 16)) & m
	h = (h * 0x45D9F3B) & m
	h = (h ^ (h >> 16)) & m
	h = (h * 0x45D9F3B) & m
	h = (h ^ (h >> 16)) & m
	return h


## El mismo hash, en [0,1).
static func azar(a: int, b: int, c: int) -> float:
	return float(revolver(a, b, c)) / 4294967296.0


static func _entre(a: int, b: int, c: int, desde: float, hasta: float) -> float:
	return desde + (hasta - desde) * azar(a, b, c)


# ===========================================================================
# LOS DOS VERDES DERIVADOS DE LA PALETA
# ===========================================================================

## Copa de vaguada y de ribera: más oscura y más fría que `Paleta.COPA`.
static func copa_humeda() -> Color:
	return Color.from_hsv(Paleta.COPA.h + 0.022,
		minf(Paleta.COPA.s + 0.02, Paleta.SATURACION_MUNDO), 0.175)


## Copa de loma y de faldeo: más clara y más oliva. Sigue abajo de V3.
static func copa_seca() -> Color:
	return Color.from_hsv(Paleta.COPA.h - 0.031,
		minf(Paleta.COPA.s, Paleta.SATURACION_MUNDO), 0.262)


## El arbusto. Un peldaño abajo de la copa: es sombra de abajo, no otro verde.
static func arbusto() -> Color:
	return Color.from_hsv(Paleta.COPA.h + 0.010, Paleta.COPA.s, 0.155)


## El tronco seco parado del páramo. El gris frío de la ruina con algo de
## madera adentro — el único color frío del valle que no es agua ni montaña.
static func tronco_seco() -> Color:
	return Paleta.MURO_RUINA.lerp(Paleta.TRONCO, 0.30)


# ===========================================================================
# ARMADO
# ===========================================================================

func _ready() -> void:
	set_process(false)
	if modo_prueba:
		_correr_prueba()


## La puerta de entrada. `alturas` es la función de terreno —en el valle es
## `altura_en`— y `lugares` es `valle.gd:LUGARES` (opcional: si no viene, usa
## las posiciones de arriba, que son las mismas).
func poblar(alturas: Callable, lugares: Dictionary = {}) -> void:
	_alturas = alturas
	for slug: String in lugares:
		var def: Variant = lugares[slug]
		if def is Dictionary and (def as Dictionary).has("pos"):
			_lugares[slug] = (def as Dictionary)["pos"]
		elif def is Vector3:
			_lugares[slug] = def

	var t0 := Time.get_ticks_usec()

	_grumos.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_grumos.seed = semilla
	_grumos.frequency = 0.045
	_grumos.fractal_octaves = 2
	_macro.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_macro.seed = semilla + 991
	_macro.frequency = 0.011
	_macro.fractal_octaves = 2

	_cuenta = {"conifera": 0, "fronda": 0, "arbusto": 0, "tocon": 0, "seco": 0}
	_por_zona = {}

	var celdas := _sembrar()
	_construir(celdas)

	_ms_construir = (Time.get_ticks_usec() - t0) / 1000.0
	_aplicar_nivel()
	set_process(true)


## Recorre la grilla y decide qué crece en cada celda. Devuelve las plantas ya
## agrupadas por baldosa: {Vector2i: {"conifera": [...], ...}}.
func _sembrar() -> Dictionary:
	var celdas := {}
	var n := int(RADIO_PLANTABLE / PASO) + 1

	for iz in range(-n, n + 1):
		for ix in range(-n, n + 1):
			var x := ix * PASO + (azar(ix, iz, 11) - 0.5) * PASO * 0.95
			var z := iz * PASO + (azar(ix, iz, 12) - 0.5) * PASO * 0.95
			var r := sqrt(x * x + z * z)
			if r > RADIO_PLANTABLE:
				continue

			var campo := _campo(x, z, r)
			var d: float = campo["d"]
			if d <= 0.001:
				continue

			# La alameda del camino la plantó gente: menos dispersión.
			var reg: float = campo["regular"]
			if reg > 0.0:
				x = lerp(x, float(ix) * PASO, reg * 0.8)
				z = lerp(z, float(iz) * PASO, reg * 0.8)

			if azar(ix, iz, 13) >= d:
				continue

			_plantar(celdas, ix, iz, x, z, campo)

	_testigos_de_la_aldea(celdas)
	_secos_del_paramo(celdas)
	return celdas


## Decide QUÉ planta va en un punto que ya salió sorteado, y la deja en su
## baldosa. Acá viven la variación y el tamaño.
func _plantar(celdas: Dictionary, ix: int, iz: int, x: float, z: float, campo: Dictionary) -> void:
	var d: float = campo["d"]
	var joven: float = campo["joven"]
	var seco: float = campo["seco"]
	var viejo: float = campo["viejo"]
	var talado: float = campo["talado"]
	var reg: float = campo["regular"]
	var p_conifera: float = campo["conifera"]

	# Cuanto más denso el vecindario, más chance de que lo que crece sea
	# sotobosque y no un árbol. Un bosque sin capa baja se ve a decorado.
	if azar(ix, iz, 21) < 0.22 + 0.26 * d:
		var alto := _entre(ix, iz, 22, 0.85, 2.30) * (1.0 - joven * 0.35)
		var ancho := alto * _entre(ix, iz, 23, 0.55, 0.95)
		var c := arbusto().lerp(copa_seca(), seco * 0.35)
		c = c.darkened(_entre(ix, iz, 24, -0.10, 0.14))
		_guardar(celdas, ARBUSTO, x, z,
			_pose(ix, iz, x, z, 0.0, Vector3(ancho, alto, ancho), 0.05),
			c, azar(ix, iz, 90))
		_cuenta["arbusto"] += 1
		_contar_zona(x, z, "arbusto")
		return

	# Tocones: sólo donde alguien taló. No hay tocones silvestres.
	if azar(ix, iz, 25) < talado:
		var alto_t := _entre(ix, iz, 26, 0.45, 0.95)
		var radio_t := _entre(ix, iz, 27, 0.22, 0.46)
		_guardar(celdas, TOCON, x, z,
			_pose(ix, iz, x, z, 0.0, Vector3(radio_t, alto_t, radio_t), 0.06),
			Paleta.TRONCO.darkened(0.22), azar(ix, iz, 91))
		_cuenta["tocon"] += 1
		_contar_zona(x, z, "tocon")
		return

	var conifera := azar(ix, iz, 28) < p_conifera

	# EL TAMAÑO. Tres cosas lo mueven, y la del medio es la importante:
	#   · la especie (la conífera es más alta y más flaca),
	#   · **la soledad**: un árbol aislado tuvo lugar y nadie lo cortó,
	#   · la juventud: el renoval del páramo y de la tala es chico y parejo.
	var soledad: float = lerp(1.38, 0.88, clampf(d, 0.0, 1.0))
	var alto := 0.0
	var esbeltez := 0.0
	if conifera:
		alto = _entre(ix, iz, 29, 7.0, 12.6)
		esbeltez = _entre(ix, iz, 30, 0.155, 0.215)
	else:
		alto = _entre(ix, iz, 29, 5.6, 10.4)
		esbeltez = _entre(ix, iz, 30, 0.255, 0.360)
	alto *= soledad
	# Los robles viejos del Sotobosque: es el bosque más viejo del valle y
	# tiene que leerse como tal desde el prado.
	alto *= 1.0 + viejo * 0.42
	# El renoval: chico, apretado y parejo.
	alto *= 1.0 - joven * 0.56
	# La alameda es regular. Un árbol plantado por gente no varía como uno que
	# creció solo, y esa diferencia es lo que dice "acá alguien hizo algo".
	if reg > 0.0:
		alto = lerp(alto, 8.4, reg * 0.75)

	var h_tronco: float = alto * (0.34 if conifera else 0.46)
	var radio_copa := alto * esbeltez
	var alto_copa: float = alto * (0.76 if conifera else 0.64)
	var radio_tronco: float = alto * (0.019 if conifera else 0.026)
	var caida: float = _entre(ix, iz, 31, 0.0, 0.10) * (1.0 - reg * 0.8)

	# El tono: seco arriba y lejos del agua, húmedo en la vaguada y la ribera.
	var c := copa_humeda().lerp(copa_seca(), seco)
	c = c.lerp(copa_humeda(), viejo * 0.5)
	c = c.darkened(_entre(ix, iz, 32, -0.09, 0.11))

	var orden := azar(ix, iz, 92)
	_guardar(celdas, CONIFERA if conifera else FRONDA, x, z,
		_pose(ix, iz, x, z, h_tronco * 0.92,
			Vector3(radio_copa, alto_copa, radio_copa), caida),
		c, orden)
	_guardar(celdas, TRONCO, x, z,
		_pose(ix, iz, x, z, 0.0,
			Vector3(radio_tronco, h_tronco, radio_tronco), caida),
		Paleta.TRONCO.darkened(_entre(ix, iz, 33, -0.10, 0.16)), orden)
	_cuenta["conifera" if conifera else "fronda"] += 1
	_contar_zona(x, z, "arbol")


## La pose de una instancia: apoyada en el terreno, girada, inclinada y
## escalada. El orden importa — se gira primero, después se inclina (así la
## caída apunta para cualquier lado) y recién ahí se sube por el tronco, para
## que la copa quede sobre la punta del tronco inclinado y no al lado.
func _pose(ix: int, iz: int, x: float, z: float, subir: float,
		escala: Vector3, caida: float) -> Transform3D:
	var t := Transform3D()
	t.origin = Vector3(x, _alturas.call(x, z) - 0.12, z)
	t = t.rotated_local(Vector3.UP, azar(ix, iz, 41) * TAU)
	t = t.rotated_local(Vector3.RIGHT, caida)
	if subir > 0.0:
		t = t.translated_local(Vector3(0.0, subir, 0.0))
	return t.scaled_local(escala)


func _guardar(celdas: Dictionary, tipo: int, x: float, z: float,
		t: Transform3D, c: Color, orden: float) -> void:
	var celda := Vector2i(floori(x / BALDOSA), floori(z / BALDOSA))
	if not celdas.has(celda):
		celdas[celda] = {CONIFERA: [], FRONDA: [], ARBUSTO: [], TRONCO: [],
			TOCON: [], SECO: []}
	(celdas[celda][tipo] as Array).append([t, c, orden])


# ===========================================================================
# EL CAMPO DE DENSIDAD — dónde crece qué, y por qué
# ===========================================================================

## Devuelve, para un punto del valle:
##   d         · cuánto crece ahí, de 0 a 1
##   conifera  · probabilidad de que lo que crezca sea conífera
##   seco      · 0 vaguada húmeda, 1 loma expuesta (mueve el tono)
##   viejo     · 1 en el corazón del Sotobosque
##   joven     · 1 en el renoval del páramo y de la tala
##   talado    · probabilidad de tocón
##   regular   · 1 en la alameda del camino: lo plantó gente
func _campo(x: float, z: float, r: float) -> Dictionary:
	var p := Vector2(x, z)

	# --- el río -------------------------------------------------------------
	var d_eje := _dist_rio(x, z)
	if d_eje < RIO_SEMI + 1.1:
		return {"d": 0.0}                       # adentro del agua no crece nada
	var d_orilla: float = d_eje - RIO_SEMI
	var ribera: float = smoothstep(34.0, 9.0, d_orilla) * 0.90

	# --- el Sotobosque ------------------------------------------------------
	var c_bosque: Vector3 = _lugares["bosque"]
	var d_soto := p.distance_to(Vector2(c_bosque.x, c_bosque.z))
	var soto: float = smoothstep(64.0, 24.0, d_soto) * 0.94
	# La lengua que lo ata a la montaña: el Sotobosque no es una isla.
	var hacia := Vector2(c_bosque.x, c_bosque.z).normalized()
	var punta := Vector2(c_bosque.x, c_bosque.z) + hacia * 66.0
	var d_lengua := _a_segmento(p, Vector2(c_bosque.x, c_bosque.z), punta)
	soto = maxf(soto, smoothstep(36.0, 13.0, d_lengua) * 0.80)

	# --- el faldeo ----------------------------------------------------------
	# Se abre en el portal, con la MISMA cuenta que usa _armar_cordillera():
	# la única salida del valle no puede quedar tapada de árboles.
	var norte := (p.normalized().dot(Vector2(0.12, 1.0).normalized()) + 1.0) * 0.5
	var portal: float = smoothstep(0.86, 0.995, norte)
	var faldeo: float = smoothstep(116.0, 152.0, r) * 0.88 * (1.0 - portal * 0.93)

	# --- la alameda del camino ---------------------------------------------
	var d_cam := _dist_camino(x, z)
	var alameda: float = smoothstep(4.6, 8.0, d_cam) * smoothstep(25.0, 13.0, d_cam) * 0.74
	var regular: float = smoothstep(26.0, 14.0, d_cam) if d_cam > 4.6 else 0.0

	# --- el prado ------------------------------------------------------------
	var macro := _macro.get_noise_2d(x, z) * 0.5 + 0.5
	var prado := 0.026 + 0.165 * pow(macro, 3.0)

	var d := maxf(maxf(ribera, soto), maxf(faldeo, maxf(alameda, prado)))

	# --- los claros, que son multiplicativos --------------------------------
	var d_aldea := p.length()
	var c_fragua: Vector3 = _lugares["fragua"]
	var d_fragua := p.distance_to(Vector2(c_fragua.x, c_fragua.z))
	var c_ruina: Vector3 = _lugares["ruina"]
	var d_ruina := p.distance_to(Vector2(c_ruina.x, c_ruina.z))

	d *= smoothstep(19.0, 42.0, d_aldea)        # los campos de la aldea
	d *= smoothstep(13.0, 25.0, d_fragua)       # Ilde quema carbón
	d *= smoothstep(4.6, 7.4, d_cam)            # el camino queda libre
	d *= smoothstep(11.0, 22.0, p.distance_to(VADO))   # el vado
	d *= smoothstep(36.0, 54.0, d_ruina)        # el páramo de la Casa Quemada

	# --- la tala del Sotobosque ---------------------------------------------
	# Una cuña del lado que mira a la aldea. El bosque no se termina así solo.
	var talado := 0.0
	if d_soto > 1.0:
		var hacia_aldea := (-Vector2(c_bosque.x, c_bosque.z)).normalized()
		var dir := (p - Vector2(c_bosque.x, c_bosque.z)) / d_soto
		var cuna: float = smoothstep(0.72, 0.925, dir.dot(hacia_aldea)) \
			* smoothstep(19.0, 26.0, d_soto) * smoothstep(58.0, 48.0, d_soto)
		# Dos movimientos, y el segundo es el que cuenta la historia: primero
		# el bosque no está, y después queda lo que dejaron. Un claro pelado
		# es un bache; un claro lleno de tocones es una tala.
		d *= 1.0 - cuna * 0.88
		d = maxf(d, cuna * 0.46)
		talado = cuna * 0.80

	# --- lo que vuelve a crecer ---------------------------------------------
	# El anillo de renoval que se cierra sobre el páramo, y los plantines que
	# se están comiendo la ruina.
	var anillo: float = smoothstep(40.0, 50.0, d_ruina) * smoothstep(68.0, 54.0, d_ruina) * 0.90
	var plantines: float = smoothstep(4.5, 9.0, d_ruina) * smoothstep(21.0, 12.0, d_ruina) * 0.11
	var joven := maxf(anillo / 0.90, plantines / 0.11)
	d = maxf(d, maxf(anillo, plantines))
	# Renoval flaco alrededor de la fragua, donde talaron.
	var renoval_fragua: float = smoothstep(12.0, 18.0, d_fragua) * smoothstep(36.0, 22.0, d_fragua)
	d = maxf(d, renoval_fragua * 0.30)
	talado = maxf(talado, renoval_fragua * 0.58)
	joven = maxf(joven, renoval_fragua)

	# --- el relieve: los árboles se juntan en la vaguada y ralean en la loma -
	# El desnivel local sale de la propia función de terreno, no de una copia
	# de su fórmula: así este módulo sirve para cualquier terreno.
	var h := _alturas.call(x, z) as float
	var prom: float = ((_alturas.call(x + 16.0, z) as float)
		+ (_alturas.call(x - 16.0, z) as float)
		+ (_alturas.call(x, z + 16.0) as float)
		+ (_alturas.call(x, z - 16.0) as float)) * 0.25
	var relieve := clampf((h - prom) / 1.6, -1.0, 1.0)
	d *= lerp(1.16, 0.58, relieve * 0.5 + 0.5)

	# --- los grumos: calvas, matas y sendas adentro de cada masa ------------
	# Es lo que hace que el Sotobosque tenga "sendas que cambian" y que el
	# faldeo no sea una cinta de ancho constante.
	var g := _grumos.get_noise_2d(x, z) * 0.5 + 0.5
	d *= 0.28 + 0.88 * smoothstep(0.20, 0.74, g)

	d = clampf(d, 0.0, 0.95)

	# --- especie y tono -----------------------------------------------------
	var conifera: float = clampf(smoothstep(104.0, 150.0, r), 0.0, 1.0)
	conifera *= 1.0 - smoothstep(68.0, 26.0, d_soto)     # el Sotobosque es roble
	conifera *= 1.0 - smoothstep(36.0, 8.0, d_orilla)    # la ribera es de hoja
	# El renoval del páramo es de OTRA especie que lo que había. Eso solo ya
	# dice que pasó algo y que lo que volvió no es lo que estaba.
	conifera = maxf(conifera, 0.62 * smoothstep(62.0, 40.0, d_ruina) * smoothstep(28.0, 38.0, d_ruina))

	var seco := clampf(0.50 + relieve * 0.30
		- smoothstep(44.0, 6.0, d_orilla) * 0.46
		+ smoothstep(96.0, 152.0, r) * 0.26
		- smoothstep(56.0, 18.0, d_soto) * 0.22, 0.0, 1.0)

	return {
		"d": d,
		"conifera": conifera,
		"seco": seco,
		"viejo": clampf(smoothstep(46.0, 16.0, d_soto), 0.0, 1.0),
		"joven": clampf(joven, 0.0, 1.0),
		"talado": talado,
		"regular": regular,
	}


## Distancia al eje del río. El plano de agua es largo en X y está girado 9°.
func _dist_rio(x: float, z: float) -> float:
	var a := deg_to_rad(RIO_GIRO)
	var n := Vector2(sin(a), cos(a))
	return absf((Vector2(x, z) - RIO_CENTRO).dot(n))


## El eje del Camino del Norte: del vado, por El Camino del Norte (11, 74),
## hasta la abertura de la cordillera. Serpentea, porque un camino recto de
## ciento cincuenta metros lo hizo una computadora.
func _camino_x(z: float) -> float:
	return 11.0 + sin((z - 74.0) * 0.035) * 3.0 + (z - 74.0) * 0.055


func _dist_camino(x: float, z: float) -> float:
	if z < 20.0 or z > 182.0:
		return 999.0
	return absf(x - _camino_x(z))


static func _a_segmento(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


# ===========================================================================
# LO QUE SE PLANTA A MANO — cinco árboles y catorce muertos
# ===========================================================================

## Los árboles testigo de la aldea. Los campos están limpios salvo estos: son
## los que nadie cortó, y solos en el pasto se leen enormes. Cinco piezas
## puestas a mano valen más que subirle la densidad a media hectárea.
func _testigos_de_la_aldea(celdas: Dictionary) -> void:
	for i in 5:
		var a := TAU * i / 5.0 + 0.9
		var rad := _entre(700, i, 1, 19.0, 27.0)
		var x := cos(a) * rad
		var z := sin(a) * rad
		if _dist_rio(x, z) < RIO_SEMI + 3.0:
			continue
		var alto := _entre(700, i, 2, 12.5, 16.0)
		var c := copa_humeda().lerp(copa_seca(), 0.55).darkened(_entre(700, i, 3, -0.06, 0.08))
		_guardar(celdas, FRONDA, x, z,
			_pose(700, i, x, z, alto * 0.44,
				Vector3(alto * 0.40, alto * 0.62, alto * 0.40), 0.03),
			c, azar(700, i, 9))
		_guardar(celdas, TRONCO, x, z,
			_pose(700, i, x, z, 0.0,
				Vector3(alto * 0.036, alto * 0.48, alto * 0.036), 0.03),
			Paleta.TRONCO, azar(700, i, 9))
		_cuenta["fronda"] += 1
		_contar_zona(x, z, "arbol")


## Los troncos secos parados de la Casa Quemada. Adentro del páramo no crece
## nada, y por eso mismo son lo único vertical que hay: catorce palos grises en
## un claro son mucho más elocuentes que cien árboles.
##
## Van en el MultiMesh de troncos, que se dibuja hasta 100 m. A esa distancia
## el páramo todavía no se distingue, así que no se pierde nada.
func _secos_del_paramo(celdas: Dictionary) -> void:
	var c_ruina: Vector3 = _lugares["ruina"]
	for i in 14:
		var a := azar(800, i, 1) * TAU
		var rad := _entre(800, i, 2, 7.0, 31.0)
		var x := c_ruina.x + cos(a) * rad
		var z := c_ruina.z + sin(a) * rad
		var alto := _entre(800, i, 3, 4.2, 9.2)
		var radio := _entre(800, i, 4, 0.13, 0.24)
		# Un muerto parado se inclina mucho más que uno vivo.
		var caida := _entre(800, i, 5, 0.03, 0.30)
		_guardar(celdas, SECO, x, z,
			_pose(800, i, x, z, 0.0, Vector3(radio, alto, radio), caida),
			tronco_seco().darkened(_entre(800, i, 6, -0.06, 0.12)), azar(800, i, 7))
		_cuenta["seco"] += 1
		_contar_zona(x, z, "seco")


# ===========================================================================
# LOS MULTIMESH
# ===========================================================================

func _construir(celdas: Dictionary) -> void:
	# Cinco gajos y cuatro puntos de perfil. Es el mínimo que todavía se lee
	# como aguja y como copa, y es una decisión, no un recorte: facetas grandes
	# y duras, de la misma familia que los techos de cuatro caras del valle.
	var malla_conifera := _malla_copa([
		Vector2(0.00, 0.52), Vector2(0.26, 1.00), Vector2(0.58, 0.66),
		Vector2(1.00, 0.00)], 5, 3)
	var malla_fronda := _malla_copa([
		Vector2(0.00, 0.34), Vector2(0.22, 0.92), Vector2(0.58, 1.00),
		Vector2(1.00, 0.00)], 5, 17)
	var malla_tronco := _malla_tronco(5)

	_tris_copa = _triangulos(malla_conifera)
	_tris_tronco = _triangulos(malla_tronco)

	var mat_copa := Paleta.follaje(Color.WHITE)
	# **Sin este flag el color por instancia se calcula y se tira.** Ya pasó
	# exactamente eso con el pasto de detalles.gd, que hoy sale todo del mismo
	# verde. Si el albedo va en blanco y el color lo pone la instancia, el flag
	# no es opcional: es la mitad del mecanismo.
	mat_copa.vertex_color_use_as_albedo = true

	var mat_tronco := Paleta.madera(Color.WHITE)
	mat_tronco.vertex_color_use_as_albedo = true

	var orden := func(a: Array, b: Array) -> bool: return a[2] < b[2]

	for celda: Vector2i in celdas:
		var bolsa: Dictionary = celdas[celda]
		var centro := _centro(celda)
		_baldosas += 1

		var coniferas: Array = bolsa[CONIFERA]
		coniferas.sort_custom(orden)
		if not coniferas.is_empty():
			_nodos_copa.append(_multi(coniferas, 0, malla_conifera, mat_copa,
				centro, celda, "coniferas"))

		# Los arbustos van DETRÁS de los árboles en el mismo buffer: así
		# `visible_instance_count` ralea el sotobosque y nunca un árbol.
		var frondas: Array = bolsa[FRONDA]
		frondas.sort_custom(orden)
		var arbustos: Array = bolsa[ARBUSTO]
		arbustos.sort_custom(orden)
		var mezcla := frondas + arbustos
		if not mezcla.is_empty():
			_nodos_copa.append(_multi(mezcla, arbustos.size(), malla_fronda,
				mat_copa, centro, celda, "frondas"))

		var maderas: Array = bolsa[TRONCO] + bolsa[TOCON] + bolsa[SECO]
		maderas.sort_custom(orden)
		if not maderas.is_empty():
			_nodos_tronco.append(_multi(maderas, 0, malla_tronco, mat_tronco,
				centro, celda, "troncos"))


## Una baldosa. El nodo va apoyado en el centro de la baldosa y NO en el origen
## del valle: la distancia de dibujado se mide contra la posición del nodo, y
## un nodo en (0,0,0) que abarca 350 metros nunca está lejos de la cámara.
func _multi(lista: Array, raleables: int, malla: Mesh, mat: Material,
		centro: Vector3, celda: Vector2i, tipo: String) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = malla
	mm.instance_count = lista.size()
	for i in lista.size():
		var t: Transform3D = lista[i][0]
		t.origin -= centro
		mm.set_instance_transform(i, t)
		mm.set_instance_color(i, lista[i][1])

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat      # SurfaceTool.set_material() no aplica
	mmi.position = centro
	mmi.name = "%s_%d_%d" % [tipo, celda.x, celda.y]
	mmi.set_meta("raleables", raleables)
	mmi.add_to_group("vegetacion")
	add_child(mmi)
	return mmi


func _centro(celda: Vector2i) -> Vector3:
	var x := (float(celda.x) + 0.5) * BALDOSA
	var z := (float(celda.y) + 0.5) * BALDOSA
	return Vector3(x, _alturas.call(x, z) as float, z)


# ===========================================================================
# LAS DOS MALLAS. Treinta triángulos la copa, diez el tronco, cero hojas.
# ===========================================================================

## Una copa: un perfil (altura, radio) torneado en cinco gajos. Se cierra abajo
## porque desde adentro del bosque se le ve la panza.
##
## El radio va sacudido apenas un 12 %. Es a propósito y es poco: alcanza para
## que la forma no sea un cono de tránsito perfecto y no alcanza para fingir
## una copa de verdad. Fingirla es el error que la dirección de arte nombró
## —geometría a medio camino de lo real bajo una luz que sí lo pretende— y
## además no se ve: a veinte metros lo único que llega es el contorno. **La
## variedad entre árboles la pone la proporción de cada instancia, no el ruido
## de la malla.**
##
## Sombreado PLANO a propósito: los vértices no se comparten, así que
## `generate_normals()` da una normal por cara. Es lo mismo que hace el terreno
## y es lo que hace que esto se lea como blockout iluminado y no como plástico.
##
## El orden de los vértices es horario visto desde afuera, que es lo que Godot
## toma por cara de adelante. Con el orden invertido las normales miran para
## adentro y la copa no recibe sol: queda gris muerta. Es la trampa anotada en
## CLAUDE.md y está verificada arriba, triángulo por triángulo.
func _malla_copa(perfil: Array, gajos: int, sal: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var punto := func(anillo: int, gajo: int) -> Vector3:
		var pr: Vector2 = perfil[anillo]
		var g := gajo % gajos
		var a := TAU * g / float(gajos)
		var sac: float = 1.0 + (azar(sal, anillo, g) - 0.5) * 0.12
		var y_sac: float = (azar(sal + 5, anillo, g) - 0.5) * 0.03
		return Vector3(cos(a) * pr.y * sac, pr.x + y_sac, sin(a) * pr.y * sac)

	# La panza.
	var centro_abajo := Vector3(0.0, perfil[0].x, 0.0)
	for g in gajos:
		st.add_vertex(centro_abajo)
		st.add_vertex(punto.call(0, g + 1))
		st.add_vertex(punto.call(0, g))

	for anillo in perfil.size() - 1:
		var arriba_es_punta: bool = perfil[anillo + 1].y < 0.0001
		for g in gajos:
			var b0: Vector3 = punto.call(anillo, g)
			var b1: Vector3 = punto.call(anillo, g + 1)
			if arriba_es_punta:
				st.add_vertex(b0)
				st.add_vertex(b1)
				st.add_vertex(Vector3(0.0, perfil[anillo + 1].x, 0.0))
				continue
			var t0: Vector3 = punto.call(anillo + 1, g)
			var t1: Vector3 = punto.call(anillo + 1, g + 1)
			st.add_vertex(b0); st.add_vertex(t1); st.add_vertex(t0)
			st.add_vertex(b0); st.add_vertex(b1); st.add_vertex(t1)

	st.generate_normals()
	return st.commit()


## Un tronco: un tubo de cinco caras que se afina, sin tapas. Abajo está
## enterrado y arriba lo tapa la copa; poner las tapas es pagar dos triángulos
## por instancia para nada. La misma malla hace de tocón (chata y gorda) y de
## tronco seco parado (larga, flaca y torcida).
func _malla_tronco(gajos: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var punto := func(y: float, radio: float, gajo: int) -> Vector3:
		var g := gajo % gajos
		var a := TAU * g / float(gajos)
		var sac: float = 1.0 + (azar(31, gajo % gajos, int(y * 10.0)) - 0.5) * 0.10
		return Vector3(cos(a) * radio * sac, y, sin(a) * radio * sac)
	for g in gajos:
		var b0: Vector3 = punto.call(0.0, 1.0, g)
		var b1: Vector3 = punto.call(0.0, 1.0, g + 1)
		var t0: Vector3 = punto.call(1.0, 0.62, g)
		var t1: Vector3 = punto.call(1.0, 0.62, g + 1)
		st.add_vertex(b0); st.add_vertex(t1); st.add_vertex(t0)
		st.add_vertex(b0); st.add_vertex(b1); st.add_vertex(t1)
	st.generate_normals()
	return st.commit()


static func _triangulos(m: Mesh) -> int:
	if m == null:
		return 0
	var t := 0
	for s in m.get_surface_count():
		var a := m.surface_get_arrays(s)
		if a.is_empty():
			continue
		var idx: Variant = a[Mesh.ARRAY_INDEX]
		if idx != null and (idx as PackedInt32Array).size() > 0:
			t += (idx as PackedInt32Array).size() / 3
		else:
			t += (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return t


# ===========================================================================
# LA CALIDAD
#
# `rendimiento.gd` ajusta el pasto, las piedras, el humo y los bichos por
# grupo. La vegetación no está en esa lista y ese archivo está tomado por otra
# rama, así que este módulo se ajusta SOLO: mira `Rendimiento.nivel` tres veces
# por segundo y reacciona a F1 igual que todo lo demás. El día que se toque
# rendimiento.gd, esto se puede mudar allá con el grupo "vegetacion".
# ===========================================================================

var _rendimiento: Node

func _nivel() -> int:
	if _rendimiento == null:
		_rendimiento = get_node_or_null(^"/root/Rendimiento")
	# Sin el autoload (una escena suelta, una prueba) se asume alto: nunca
	# degradar el paisaje por no haber encontrado el ajuste de calidad.
	return int(_rendimiento.nivel) if _rendimiento != null else 2


func _process(dt: float) -> void:
	_reloj += dt
	if _reloj < 0.34:
		return
	_reloj = 0.0
	if _nivel() != _nivel_aplicado:
		_aplicar_nivel()


func _aplicar_nivel() -> void:
	var n := _nivel()
	_nivel_aplicado = n

	# LAS COPAS SON LA SILUETA DEL VALLE: se ven de lejos en los tres niveles.
	# Lo que cambia es cuánto de lejos. De 190 a 120 metros hay un 60% menos de
	# baldosas dibujadas, que es un recorte de verdad y no le saca al paisaje
	# nada que no se estuviera comiendo el desenfoque de lejanía.
	var d_copa: float = [120.0, 155.0, 190.0][n]
	# Los troncos, la mitad. A cien metros un tronco son dos píxeles tapados
	# por su propia copa.
	var d_tronco: float = [70.0, 88.0, 105.0][n]
	# El sotobosque sí es adorno y sí se ralea. Los árboles nunca.
	var f_arbusto: float = [0.35, 0.68, 1.0][n]

	for mmi in _nodos_copa:
		var raleables: int = mmi.get_meta("raleables", 0)
		var total: int = mmi.multimesh.instance_count
		if raleables > 0:
			mmi.multimesh.visible_instance_count = maxi(1,
				total - raleables + int(raleables * f_arbusto))
		# La sombra de un árbol es un elemento del paisaje, no un detalle: es
		# lo que apoya la masa en el suelo y lo que hace las mañanas largas.
		# Se paga en alto y medio; en bajo se cae con SDFGI y la volumétrica.
		mmi.cast_shadow = (GeometryInstance3D.SHADOW_CASTING_SETTING_ON if n >= 1
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		_alcance(mmi, d_copa)

	for mmi in _nodos_tronco:
		# Los troncos nunca proyectan: la copa ya proyecta encima.
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_alcance(mmi, d_tronco)


func _alcance(g: GeometryInstance3D, hasta: float) -> void:
	g.visibility_range_end = hasta
	g.visibility_range_end_margin = 30.0
	# Se desvanece: una baldosa de bosque de 34 metros apareciendo entera se ve
	# aunque esté detrás del desenfoque.
	g.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


# ===========================================================================
# EL INFORME — lo único que se puede verificar sin ver la pantalla
# ===========================================================================

const ZONAS: Array[String] = ["ribera", "vado", "Sotobosque", "tala",
	"paramo ruina", "renoval ruina", "faldeo", "alameda", "aldea", "fragua",
	"prado"]


## En qué zona cae un punto. El orden importa y es el mismo que se usa para
## medir el área, así que las densidades que salen abajo son comparables.
func _zona(x: float, z: float) -> String:
	var p := Vector2(x, z)
	var r := p.length()
	var d_orilla: float = maxf(_dist_rio(x, z) - RIO_SEMI, 0.0)
	var c_bosque: Vector3 = _lugares["bosque"]
	var d_soto := p.distance_to(Vector2(c_bosque.x, c_bosque.z))
	var c_ruina: Vector3 = _lugares["ruina"]
	var d_ruina := p.distance_to(Vector2(c_ruina.x, c_ruina.z))
	var c_fragua: Vector3 = _lugares["fragua"]
	var d_fragua := p.distance_to(Vector2(c_fragua.x, c_fragua.z))

	if p.distance_to(VADO) < 20.0:
		return "vado"
	if r < 28.0:
		return "aldea"
	if d_fragua < 26.0:
		return "fragua"
	if d_ruina < 40.0:
		return "paramo ruina"
	if d_soto < 52.0:
		var hacia_aldea := (-Vector2(c_bosque.x, c_bosque.z)).normalized()
		var dir := (p - Vector2(c_bosque.x, c_bosque.z)).normalized()
		if d_soto > 20.0 and dir.dot(hacia_aldea) > 0.86:
			return "tala"
		return "Sotobosque"
	if d_ruina < 58.0:
		return "renoval ruina"
	if d_orilla < 26.0:
		return "ribera"
	if _dist_camino(x, z) < 24.0:
		return "alameda"
	if r > 118.0:
		return "faldeo"
	return "prado"


func _contar_zona(x: float, z: float, que: String) -> void:
	var zn := _zona(x, z)
	if not _por_zona.has(zn):
		_por_zona[zn] = {"arbol": 0, "arbusto": 0, "tocon": 0, "seco": 0}
	_por_zona[zn][que] += 1


## Área de cada zona, por muestreo. Es más honesto que una fórmula: usa
## exactamente el mismo clasificador que las cuentas, así que "árboles por
## hectárea" quiere decir algo.
func _areas() -> Dictionary:
	var salida := {}
	var n := 60000
	var area_total := PI * RADIO_PLANTABLE * RADIO_PLANTABLE
	for i in n:
		var a := azar(555, i, 1) * TAU
		var r := sqrt(azar(555, i, 2)) * RADIO_PLANTABLE
		var zn := _zona(cos(a) * r, sin(a) * r)
		salida[zn] = salida.get(zn, 0) + 1
	for zn: String in salida:
		salida[zn] = area_total * float(salida[zn]) / float(n) / 10000.0  # ha
	return salida


## Cuántas baldosas de bosque caen en el cono de cámara desde un punto. Es la
## cuenta que importa para las llamadas de dibujo: un MultiMesh que el motor
## descarta no cuesta nada.
##
## La cámara del juego es FOV 42° vertical a 16:9, o sea ~69° horizontal
## (valle.gd:477).
func _baldosas_en_camara(desde: Vector2, mirando: Vector2) -> int:
	var cuenta := 0
	var m := mirando.normalized()
	var medio := deg_to_rad(69.0 * 0.5)
	# Media diagonal de una baldosa: una baldosa cuyo centro quedó afuera del
	# cono puede tener una esquina adentro, y entonces se dibuja igual.
	var radio := BALDOSA * 0.7072
	for mmi in _nodos_copa + _nodos_tronco:
		var p := Vector2(mmi.position.x, mmi.position.z)
		var v := p - desde
		var d := v.length()
		if d > mmi.visibility_range_end + radio:
			continue
		if d < radio or absf(v.angle_to(m)) < medio + asin(clampf(radio / d, 0.0, 1.0)):
			cuenta += 1
	return cuenta


func informe() -> void:
	var n := _nivel()
	var inst_copa := 0
	var vis_copa := 0
	for mmi in _nodos_copa:
		inst_copa += mmi.multimesh.instance_count
		vis_copa += (mmi.multimesh.instance_count if mmi.multimesh.visible_instance_count < 0
			else mmi.multimesh.visible_instance_count)
	var inst_tronco := 0
	for mmi in _nodos_tronco:
		inst_tronco += mmi.multimesh.instance_count

	var arboles: int = _cuenta["conifera"] + _cuenta["fronda"]
	print("=== VEGETACIÓN (calidad %s) ===" % ["bajo", "medio", "alto"][n])
	print("construcción           %.0f ms" % _ms_construir)
	print("plantas                %d  (coníferas %d · frondas %d · arbustos %d · tocones %d · secos parados %d)"
		% [arboles + _cuenta["arbusto"] + _cuenta["tocon"] + _cuenta["seco"],
			_cuenta["conifera"], _cuenta["fronda"], _cuenta["arbusto"],
			_cuenta["tocon"], _cuenta["seco"]])
	print("instancias             %d  (copas %d, visibles %d · troncos %d)"
		% [inst_copa + inst_tronco, inst_copa, vis_copa, inst_tronco])
	print("MultiMesh              %d nodos en %d baldosas de %.0f m  (copas %d · troncos %d)"
		% [_nodos_copa.size() + _nodos_tronco.size(), _baldosas, BALDOSA,
			_nodos_copa.size(), _nodos_tronco.size()])
	print("malla                  copa %d triángulos · tronco %d triángulos"
		% [_tris_copa, _tris_tronco])
	print("triángulos             %d en total (todo el valle junto, sin descartar nada)"
		% (inst_copa * _tris_copa + inst_tronco * _tris_tronco))
	print("alcance de dibujado    copas %.0f m · troncos %.0f m"
		% [_nodos_copa[0].visibility_range_end if not _nodos_copa.is_empty() else 0.0,
			_nodos_tronco[0].visibility_range_end if not _nodos_tronco.is_empty() else 0.0])
	print("colisión               ninguna")

	print("")
	print("--- llamadas de dibujo: baldosas adentro del cono de cámara (FOV 69° horiz.) ---")
	var vistas := [
		["aldea mirando al norte", Vector2(0, 8), Vector2(0, 1)],
		["aldea mirando al Sotobosque", Vector2(0, 8), Vector2(-0.7, -0.7)],
		["adentro del Sotobosque", Vector2(-58, -54), Vector2(0.7, 0.7)],
		["el vado, mirando al camino", Vector2(5, 26), Vector2(0.1, 1)],
		["la Casa Quemada", Vector2(-26, -108), Vector2(0.3, 1)],
	]
	for v: Array in vistas:
		print("  %-30s %d llamadas de dibujo" % [v[0],
			_baldosas_en_camara(v[1], v[2])])

	print("")
	print("--- densidad por zona ---")
	print("  %-14s %7s %8s %9s %9s %8s %8s" % ["zona", "área ha", "árboles",
		"árb/ha", "arbustos", "tocones", "secos"])
	var areas := _areas()
	for zn: String in ZONAS:
		var c: Dictionary = _por_zona.get(zn, {"arbol": 0, "arbusto": 0, "tocon": 0, "seco": 0})
		var ha: float = areas.get(zn, 0.0)
		print("  %-14s %7.2f %8d %9.1f %9d %8d %8d" % [zn, ha, c["arbol"],
			(c["arbol"] / ha) if ha > 0.01 else 0.0,
			c["arbusto"], c["tocon"], c["seco"]])
	print("=== FIN ===")


# ===========================================================================
# LA ESCENA DE PRUEBA
#
# Corre sola: sin servidor, sin token y sin el resto del juego. Existe porque
# `valle.gd` está tomado por otra rama y esto igual tiene que poder mirarse y
# medirse. Mismo trato que `escenas/prueba_sonido.tscn`.
#
#   godot escenas/prueba_vegetacion.tscn              ← con pantalla, MIRALO
#   godot --headless escenas/prueba_vegetacion.tscn   ← imprime las cuentas
# ===========================================================================

var _ruido_prueba := FastNoiseLite.new()


## La misma cuenta que `valle.gd:altura_en()`. Es una copia y está bien que lo
## sea: existe para que la escena de prueba no dependa del valle. En el juego
## de verdad la altura entra por `poblar()` como Callable y esto no se usa.
func altura_de_prueba(x: float, z: float) -> float:
	var d := Vector2(x, z).length()
	var cuenco := -pow(d / RADIO_VALLE, 2.2) * 5.0
	return _ruido_prueba.get_noise_2d(x, z) * 2.4 + cuenco


func _correr_prueba() -> void:
	_ruido_prueba.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_ruido_prueba.frequency = 0.028
	_ruido_prueba.fractal_octaves = 3

	_suelo_de_prueba()
	_agua_de_prueba()
	_encuadrar_prueba()
	poblar(altura_de_prueba)
	informe()


## Apunta la cámara y las luces de la escena de prueba. Va acá y no en el
## .tscn porque una matriz de 3×4 escrita a mano en un archivo de escena no
## hay forma de revisarla: `look_at` sí.
##
## El encuadre: desde el sur de la aldea hacia el Sotobosque, con el río
## cruzando adelante. Sol bajo y cálido —el del valle está a −44°, ver
## CLAUDE.md— porque la silueta de un árbol contra el cielo se juzga a
## contraluz, no a mediodía.
func _encuadrar_prueba() -> void:
	var cam := get_node_or_null(^"Camara") as Camera3D
	if cam != null:
		var ojo := Vector3(26.0, altura_de_prueba(26.0, 30.0) + 24.0, 30.0)
		cam.position = ojo
		cam.look_at(Vector3(-58.0, altura_de_prueba(-58.0, -54.0) + 6.0, -54.0))
	var sol := get_node_or_null(^"Sol") as DirectionalLight3D
	if sol != null:
		sol.position = Vector3(60.0, 70.0, 90.0)
		sol.look_at(Vector3(-40.0, 0.0, -60.0))
		sol.light_color = Paleta.LUZ_ALBA
	var relleno := get_node_or_null(^"Relleno") as DirectionalLight3D
	if relleno != null:
		relleno.position = Vector3(-80.0, 60.0, -80.0)
		relleno.look_at(Vector3(20.0, 0.0, 30.0))
		relleno.light_color = Paleta.LUZ_CIELO


## Un suelo para que el bosque no flote, con los colores de la paleta. NO es el
## terreno del valle —ése lo arma valle.gd y tiene el triple de resolución—:
## es el mínimo para poder juzgar una silueta contra el cielo.
func _suelo_de_prueba() -> void:
	var lado := 360.0
	var pasos := 72
	var paso := lado / pasos
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in pasos:
		for ix in pasos:
			var x0 := -lado / 2.0 + ix * paso
			var z0 := -lado / 2.0 + iz * paso
			var e := [Vector2(x0, z0), Vector2(x0 + paso, z0),
				Vector2(x0 + paso, z0 + paso), Vector2(x0, z0 + paso)]
			var p: Array[Vector3] = []
			for q: Vector2 in e:
				p.append(Vector3(q.x, altura_de_prueba(q.x, q.y), q.y))
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				for k: int in tri:
					var t: float = clampf((p[k].y + 4.5) / 6.5, 0.0, 1.0)
					st.set_color(Paleta.PASTO.lerp(Paleta.PASTO_SECO, t))
					st.add_vertex(p[k])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = Paleta.terreno()
	add_child(mi)


## El río, igual que en valle.gd, para poder juzgar la arboleda de ribera y el
## hueco del vado.
func _agua_de_prueba() -> void:
	var agua := PlaneMesh.new()
	agua.size = Vector2(430, 15.0)
	var mi := MeshInstance3D.new()
	mi.mesh = agua
	mi.material_override = Paleta.agua()
	mi.position = Vector3(0, -1.7, 26)
	mi.rotation_degrees = Vector3(0, RIO_GIRO, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

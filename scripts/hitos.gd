## LOS HITOS DEL VALLE — lo que se ve desde lejos y dice dónde estás.
##
## Existe por un reclamo que se repitió durante semanas: *"el mundo sigue siendo
## muy de torta o de bebés"*, *"parece un mundo de disney"*. El diagnóstico que
## importa no es "faltan polígonos" —`DISENO.md` §6 dice lo contrario con todas
## las letras: **menos geometría, no más**— sino éste:
##
##   **No hay contraste de escala. Todo mide lo mismo: casas.**
##
## Un mundo se lee épico cuando hay algo enorme al lado de algo humano. Hasta
## hoy el punto más alto del valle era un techo de cinco metros, y la cordillera
## —lo único grande que había— vive a 300 metros y detrás de la niebla, o sea
## que es un telón, no un hito. Un telón no da escala: para dar escala hay que
## poder pararse al pie.
##
## ===========================================================================
## QUÉ SIGNIFICA. Es la primera pregunta que manda `CLAUDE.md`.
## ===========================================================================
##
## No se inventa nada. La ficción ya estaba escrita en dos lugares y nunca se
## había dibujado:
##
##   > La cordillera tiene **una sola abertura, al norte**, por donde entra El
##   > Camino del Norte. Un valle que se termina en niebla es un nivel; cercado
##   > con una salida es un lugar. **Cuando el mundo crezca, crece por ahí.**
##   >   — `CLAUDE.md` y `DISENO.md` §7.4
##
## Esa puerta merece leerse como una puerta. Así que el hito es **La Puerta**:
## las dos jambas de roca entre las que pasa el camino al salir del valle.
##
## Y de ahí salen las tres piezas, que son una sola cosa contada en tres
## tamaños — que es exactamente lo que faltaba:
##
##  1. **LA JAMBA** (oeste, 62 m). Sheer, con dos repisas y una cornisa que
##     vuela cerca de la punta. Es el punto más alto del valle por un factor de
##     doce contra un techo.
##  2. **EL MUÑÓN** (este, 41 m). Más baja, más ancha, y **cortada en diagonal**:
##     de acá se desprendió la lastra. Dos torres iguales se leen como un icono
##     de puerta —decoración—; una alta y sana y una baja y partida se leen como
##     algo que le pasó el tiempo encima.
##  3. **LA LASTRA** (30 m tirada en el suelo). Lo que se cayó, medio enterrado,
##     atravesado en el prado a mitad de camino. **Es la pieza que hace el
##     trabajo de escala**, porque es la única que vas a tener al lado del
##     cuerpo: treinta metros de piedra contra un tipo de 1,85.
##  4. **EL MOJÓN** (2,4 m, al borde del camino). Cinco piedras apiladas por
##     alguien. Es el metro patrón: sin una cosa de tamaño humano al pie, una
##     roca de sesenta metros puede ser una roca de seis. Y dice "hasta acá
##     llega el valle" sin un cartel.
##
## ===========================================================================
## LAS TRES DECISIONES DE FORMA, Y POR QUÉ NO SON "MÁS DETALLE"
## ===========================================================================
##
## **1. La silueta tiene eventos, no ruido.** Repisa, repisa, cornisa, corte.
## Cuatro accidentes grandes que se leen a 160 metros. Subirle facetas a la
## roca no se ve desde la cámara y es justo el camino que `DISENO.md` prohíbe.
##
## **2. El remate es plano o partido, nunca en punta.** Un cono es un juguete —
## es la forma que ya hace la aldea siete veces. Una meseta cortada es un
## acantilado. Es el mismo cambio que separa un pino de plástico de un risco.
##
## **3. Los estratos son una regla graduada.** Las bandas horizontales de valor
## no son textura: **son lo que hace que el ojo pueda medir la altura.** Una
## pared lisa de sesenta metros y una de seis se ven igual; con quince bandas
## contadas, no. Cuestan cero geometría —van en el color de vértice— y son la
## única "textura" del archivo.
##
## ===========================================================================
## EL COLOR SALE DE LA PALETA, Y LA DECISIÓN ES EL LAVADO
## ===========================================================================
##
## La cordillera del fondo lerpea 0,45 hacia `MONTE_AIRE` porque la distancia
## lava el color. La Puerta está a 160 m, no a 400: lerpea **0,14**. Ésa es toda
## la separación que necesita para recortarse CONTRA la cordillera en vez de
## fundirse con ella, y es una decisión de valor, no de matiz — que es la regla
## de la casa.
##
## Y va de oscuro abajo a claro arriba (V2 → V6 de la escalera). Un pie oscuro
## ancla la mole al suelo y una punta clara se recorta contra el cielo: los dos
## extremos de la escalera en el mismo objeto, que es lo que ningún otro objeto
## del valle tiene hoy.
##
## ===========================================================================
## CÓMO SE PRUEBA SIN EL VALLE
## ===========================================================================
##
## `modo_prueba` arma un suelo con la misma fórmula de terreno de `valle.gd`,
## planta La Puerta y saca capturas desde donde le digas, con el sol congelado.
## Es el mismo patrón que `vegetacion.gd`: un módulo que sólo se puede mirar
## dentro del juego es un módulo que nadie mira.
class_name Hitos
extends Node3D

# ---------------------------------------------------------------------------
# DÓNDE
# ---------------------------------------------------------------------------

## El eje del Camino del Norte, copiado de `vegetacion.gd:_camino_x()`. Es la
## misma curva y tiene que serlo: el camino pasa ENTRE las dos jambas, y si una
## de las dos fórmulas se mueve el camino atraviesa la roca.
static func camino_x(z: float) -> float:
	return 11.0 + sin((z - 74.0) * 0.035) * 3.0 + (z - 74.0) * 0.055


## La línea de la puerta. 162 m al norte: adentro del terreno (que llega a 180)
## y a 138 m del Camino del Norte, que está en z=74. Se llega caminando.
const PUERTA_Z := 162.0

## Las dos jambas, en X. El camino pasa por x≈16 a esa altura, así que el hueco
## libre es de unos 25 metros: ancho para pasar, angosto para que se lea como
## un hueco y no como dos rocas sueltas.
const JAMBA_X := -14.0
const MUNON_X := 46.0

const JAMBA_ALTO := 62.0
const JAMBA_RADIO := 17.0
const MUNON_ALTO := 41.0
const MUNON_RADIO := 15.0

## La lastra: dónde cayó. Entre la aldea y la puerta, corrida del camino para
## que se pase al lado y no por encima.
const LASTRA := Vector2(-6.0, 118.0)
const LASTRA_LARGO := 30.0

## El mojón, al borde del camino, mirando a la puerta.
const MOJON_Z := 146.0
const MOJON_APARTE := 4.2   ## metros al costado del eje del camino


# ---------------------------------------------------------------------------
# El azar que no es azar. Multijugador: la misma roca en todas las pantallas.
# Mismo hash que `vegetacion.gd`, y por el mismo motivo — los multiplicadores
# son todos menores que 2²⁷ para que ningún producto pase los 63 bits.
# ---------------------------------------------------------------------------

static func _azar(a: int, b: int, c: int) -> float:
	var m := 0xFFFFFFFF
	var h := ((a * 73856093) ^ (b * 19349663) ^ (c * 83492791)) & m
	h = (h ^ (h >> 16)) & m
	h = (h * 0x45D9F3B) & m
	h = (h ^ (h >> 16)) & m
	return float(h) / 4294967296.0


static func _entre(a: int, b: int, c: int, desde: float, hasta: float) -> float:
	return desde + (hasta - desde) * _azar(a, b, c)


# ---------------------------------------------------------------------------
# LOS PERFILES — la silueta, que es todo el trabajo
#
# Cada punto es (altura relativa, radio relativo). Dos puntos con alturas casi
# pegadas producen un ESCALÓN: la repisa. Un punto que ensancha después de uno
# que angostó produce una CORNISA que vuela. Eso es lo único que se lee a 160 m,
# y por eso la lista es corta y a mano en vez de ruido procedural.
# ---------------------------------------------------------------------------

const PERFIL_JAMBA: Array[Vector2] = [
	Vector2(0.00, 1.34), Vector2(0.09, 1.03),   # el faldón de derrubio del pie
	Vector2(0.33, 0.97), Vector2(0.355, 0.79),  # primera repisa
	Vector2(0.63, 0.74), Vector2(0.655, 0.56),  # segunda repisa
	Vector2(0.86, 0.51), Vector2(0.90, 0.62),   # la cornisa: vuela para afuera
	Vector2(0.965, 0.44), Vector2(1.00, 0.30),  # y el remate, chato
]

const PERFIL_MUNON: Array[Vector2] = [
	Vector2(0.00, 1.40), Vector2(0.11, 1.06),
	Vector2(0.41, 0.99), Vector2(0.44, 0.83),
	Vector2(0.80, 0.80), Vector2(0.83, 0.88),   # se ensancha justo antes de
	Vector2(1.00, 0.84),                        # cortarse: es un muñón, no una punta
]


var _alturas: Callable
var _tris := 0
var _cuerpos := 0

@export var modo_prueba := false


func _ready() -> void:
	if modo_prueba:
		_correr_prueba()


## La puerta de entrada. `alturas` es la función de terreno del valle
## (`valle.gd:altura_en`). No recibe la escena ni los lugares: este módulo
## planta una cosa sola y en un sitio que ya estaba decidido por el diseño.
func plantar(alturas: Callable) -> void:
	_alturas = alturas
	var t0 := Time.get_ticks_usec()

	_jamba()
	_munon()
	_lastra()
	_mojon()

	print("hitos: La Puerta — %d triángulos, %d cuerpos, %.1f ms" % [
		_tris, _cuerpos, (Time.get_ticks_usec() - t0) / 1000.0])


## Cuánto hay que dejar libre alrededor de los hitos, de 0 (despejado del todo)
## a 1 (plantá lo que quieras). Lo consulta `vegetacion.gd`: un árbol adentro de
## una roca de sesenta metros no es un detalle, es un error que se ve de lejos.
##
## Es `static` a propósito. Así el que lo consulta no necesita una referencia al
## nodo ni que el orden de `_ready()` en `valle.gd` sea el correcto — que es
## exactamente la trampa que este repo ya pisó dos veces con el cableado.
static func despeje(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var d := 1.0
	d = minf(d, smoothstep(JAMBA_RADIO * 1.30, JAMBA_RADIO * 2.10,
		p.distance_to(Vector2(JAMBA_X, PUERTA_Z))))
	d = minf(d, smoothstep(MUNON_RADIO * 1.30, MUNON_RADIO * 2.10,
		p.distance_to(Vector2(MUNON_X, PUERTA_Z))))
	d = minf(d, smoothstep(11.0, 21.0, p.distance_to(LASTRA)))
	return d


# ===========================================================================
# LAS DOS JAMBAS
# ===========================================================================

func _jamba() -> void:
	var p := Vector2(JAMBA_X, PUERTA_Z)
	# La cara plana mira al este, o sea al hueco: el acantilado da al camino, que
	# es por donde se lo va a ver. Y la deriva lleva la punta hacia el hueco: las
	# dos moles se inclinan una hacia la otra y por eso son una PUERTA y no dos
	# rocas que quedaron cerca.
	_penon(p, JAMBA_ALTO, JAMBA_RADIO, PERFIL_JAMBA, 5107,
		Vector2(7.0, -2.0), Vector2(0.10, 0.24), 0.20, Vector2(0.94, -0.34))


func _munon() -> void:
	var p := Vector2(MUNON_X, PUERTA_Z)
	# El corte fuerte (0,46) y apuntando al oeste: la tapa cae hacia el hueco de
	# la puerta, o sea hacia donde está tirada la lastra. La causa y el efecto
	# tienen que apuntar al mismo lado o son dos rocas sin relación.
	_penon(p, MUNON_ALTO, MUNON_RADIO, PERFIL_MUNON, 8831,
		Vector2(-6.0, 1.2), Vector2(-0.92, -0.39), 0.46, Vector2(-0.90, -0.44))


## Un peñón. Prisma vertical de sección irregular, `perfil` decide la silueta.
##
## **Una capa por punto del perfil, ni una más.** Es la decisión que separa un
## risco de una vela derretida, y se aprendió mirando: con 26 capas repartidas
## parejo, el sorteo de radio por capa produce una ondulación horizontal cada
## pocos metros y la mole se lee blanda. Con una capa por punto del perfil, cada
## quiebre de la silueta es una arista franca y no hay ninguna otra. Diez capas,
## siete gajos, 140 triángulos: **menos geometría, no más**, y se ve más duro.
##
## `deriva` es cuánto se corre la punta respecto del pie (una roca perfectamente
## vertical es una columna, y una columna es arquitectura). `corte_dir` y
## `corte` inclinan la tapa: 0 es una meseta horizontal, 0,46 es un muñón
## partido en diagonal. `cara` es hacia dónde mira el paredón: los gajos de ese
## lado se aplastan contra un plano vertical, y eso es lo que da **una sola
## superficie grande que toma el sol de una sola vez** — el acantilado. Sin eso
## la roca es un cilindro con bultos y cada faceta agarra una luz distinta, que
## es exactamente la papilla que la paleta trata de evitar.
func _penon(centro: Vector2, alto: float, radio: float, perfil: Array[Vector2],
		semilla: int, deriva: Vector2, corte_dir: Vector2, corte := 0.10,
		cara := Vector2.ZERO) -> void:
	var gajos := 7
	var capas := perfil.size()
	var base_y: float = (_alturas.call(centro.x, centro.y) as float) - 3.5
	var cd := corte_dir.normalized()
	var cara_n := cara.normalized() if cara.length() > 0.01 else Vector2.ZERO

	# El radio y el ángulo de cada gajo se sortean UNA vez y valen para toda la
	# altura: así las aristas corren verticales de arriba abajo, que es lo que
	# hace que la mole se lea como roca estratificada y no como una papa.
	var ang: Array[float] = []
	var rad: Array[float] = []
	for g in gajos:
		ang.append(float(g) / gajos * TAU + _entre(semilla, g, 1, -0.20, 0.20))
		rad.append(_entre(semilla, g, 2, 0.74, 1.26))

	var punto := func(g: int, capa: int) -> Vector3:
		var i: int = clampi(capa, 0, capas - 1)
		var t: float = perfil[i].x
		var a: float = ang[g % gajos]
		var dir := Vector2(sin(a), cos(a))
		# La tapa cortada: los gajos del lado del corte terminan más abajo.
		var techo: float = 1.0 - corte * maxf(dir.dot(cd), 0.0)
		var r: float = radio * rad[g % gajos] * perfil[i].y
		# El paredón: los gajos que miran a `cara` se apoyan contra un plano.
		if cara_n != Vector2.ZERO:
			var c := dir.dot(cara_n)
			if c > 0.42:
				r = minf(r, radio * perfil[i].y * 0.92 / c)
		var d := centro + deriva * pow(t, 1.5)
		return Vector3(d.x + dir.x * r, base_y + alto * t * techo, d.y + dir.y * r)

	# Los anillos de verdad: uno por punto del perfil.
	var anillos: Array[PackedVector3Array] = []
	for capa in capas:
		var anillo := PackedVector3Array()
		for g in gajos:
			anillo.append(punto.call(g, capa))
		anillos.append(anillo)

	# Y ahora se PARTE cada tramo en pedazos de ~2 m, interpolando lineal.
	#
	# Esto no cambia la forma ni un milímetro —partir una recta al medio da la
	# misma recta— y no hay ningún sorteo acá adentro: la silueta sigue siendo la
	# de los diez puntos del perfil. Lo único que compra son vértices, y los
	# vértices son los que llevan el color. Sin esto los estratos no existen: con
	# diez anillos, el degradé se estira entre repisa y repisa y la regla
	# graduada se pierde, que es justo lo que hace que la mole no se pueda medir.
	var finos: Array[PackedVector3Array] = []
	for capa in capas - 1:
		var a := anillos[capa]
		var b := anillos[capa + 1]
		var salto: float = absf(b[0].y - a[0].y)
		var pasos: int = maxi(1, ceili(salto / 2.0))
		for s in pasos:
			var u := float(s) / pasos
			var anillo := PackedVector3Array()
			for g in gajos:
				anillo.append(a[g].lerp(b[g], u))
			finos.append(anillo)
	finos.append(anillos[capas - 1])

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# FACETADO, NO SUAVE. `SurfaceTool.generate_normals()` promedia las normales
	# de los vértices que comparten posición, así que sin esta línea el peñón sale
	# con sombreado suave y se lee como plastilina — se vio en la primera captura
	# y era lo que más lo hacía parecer un juguete. Con el grupo de suavizado en
	# -1, cada cara tiene su normal y el risco pasa a ser un poliedro: es la misma
	# decisión que el terreno toma al revés (un prado sí es suave) y es lo que
	# `DISENO.md` §6 llama estar comprometido con lo estilizado.
	st.set_smooth_group(-1)
	var tris := 0

	for capa in finos.size() - 1:
		for g in gajos:
			var g2 := (g + 1) % gajos
			var p := [finos[capa][g], finos[capa][g2],
				finos[capa + 1][g2], finos[capa + 1][g]]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				for k: int in tri:
					var v: Vector3 = p[k]
					st.set_color(_color_roca(v.y - base_y, alto, semilla))
					st.add_vertex(v)
				tris += 1

	# La tapa. Va en abanico desde el centro, y el centro se hunde un poco: una
	# tapa perfectamente plana brilla toda igual y se ve como un corte de sierra.
	var arriba := finos[finos.size() - 1]
	var cima := Vector3.ZERO
	for g in gajos:
		cima += arriba[g]
	cima /= float(gajos)
	cima.y -= alto * 0.020
	for g in gajos:
		for v: Vector3 in [cima, arriba[g], arriba[(g + 1) % gajos]]:
			st.set_color(_color_roca(v.y - base_y, alto, semilla))
			st.add_vertex(v)
		tris += 1

	st.generate_normals()
	var malla := st.commit()
	_montar(malla, tris, true)


## El color de la roca a una altura dada.
##
## Dos cosas y nada más: la escalera de valor de la paleta (V2 abajo → V6
## arriba) y los ESTRATOS. Los estratos son la regla graduada de la que habla el
## encabezado: bandas cada ~4,2 m con ±0,055 de valor. Sin ellas una pared de
## sesenta metros y una de seis se ven idénticas, porque el ojo no tiene con qué
## contar. Con ellas, contás quince y sabés que es alta.
static func _color_roca(y: float, alto: float, semilla: int) -> Color:
	var h := clampf(y / alto, 0.0, 1.0)
	var c := Paleta.MONTE_BAJO.lerp(Paleta.MONTE_ALTO, sqrt(h))
	# Los estratos. El paso NO es exacto —cada banda tiene su propio grosor— o
	# se lee como un rayado de material y no como piedra.
	var banda := floori(y / 4.2)
	var d := (_azar(semilla, banda, 3) - 0.5) * 0.15
	c = Color.from_hsv(c.h, c.s, clampf(c.v + d, 0.06, 0.90))
	# Y sólo 0,14 hacia el aire, contra el 0,45 de la cordillera del fondo: está
	# a 160 metros, no a 400, y tiene que RECORTARSE contra ella.
	return c.lerp(Paleta.MONTE_AIRE, 0.14)


# ===========================================================================
# LA LASTRA — lo que se cayó
# ===========================================================================

## El bloque tirado en el prado. Es la pieza que da la escala de verdad, porque
## es la única del hito que vas a tener al lado del cuerpo.
##
## Va medio enterrada y atravesada, con un extremo levantado. Las tres cosas son
## la misma decisión: una piedra apoyada prolija encima del pasto es un prop; una
## piedra hundida en el suelo, con el pasto comiéndole el borde, es algo que está
## ahí desde antes que la aldea.
func _lastra() -> void:
	var base_y: float = (_alturas.call(LASTRA.x, LASTRA.y) as float)
	var largo := LASTRA_LARGO
	var ancho := 9.5
	var grueso := 6.4
	var semilla := 4409

	# Sección hexagonal irregular en el plano transversal, barrida a lo largo.
	var seccion: Array[Vector2] = []
	var lados := 7
	for i in lados:
		var a := float(i) / lados * TAU
		var r := _entre(semilla, i, 1, 0.74, 1.16)
		seccion.append(Vector2(sin(a) * ancho * 0.5 * r, cos(a) * grueso * 0.5 * r))

	var tramos := 7
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)   # facetada, como las jambas: ver `_penon()`
	var tris := 0

	# El eje: no es recto. Se dobla y se afina hacia la punta enterrada.
	var punto := func(i: int, u: int) -> Vector3:
		var t := float(u) / tramos
		var l := (t - 0.5) * largo
		# Afina hacia las dos puntas, más hacia la enterrada.
		var e: float = lerp(0.55, 1.0, sin(clampf(t, 0.0, 1.0) * PI)) * lerp(1.05, 0.72, t)
		var s: Vector2 = seccion[i % lados] * e
		s *= _entre(semilla, i, u, 0.92, 1.08)
		return Vector3(l, s.y, s.x)

	for u in tramos:
		for i in lados:
			var p := [punto.call(i, u), punto.call(i + 1, u),
				punto.call(i + 1, u + 1), punto.call(i, u + 1)]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				for k: int in tri:
					var v: Vector3 = p[k]
					st.set_color(_color_roca(v.y + grueso * 0.5, grueso * 2.6, semilla))
					st.add_vertex(v)
				tris += 1
	# Las dos tapas.
	for u: int in [0, tramos]:
		var centro := Vector3((float(u) / tramos - 0.5) * largo, 0, 0)
		for i in lados:
			var a: Vector3 = punto.call(i, u)
			var b: Vector3 = punto.call(i + 1, u)
			var orden: Array = [centro, a, b] if u == tramos else [centro, b, a]
			for v: Vector3 in orden:
				st.set_color(_color_roca(v.y + grueso * 0.5, grueso * 2.6, semilla))
				st.add_vertex(v)
			tris += 1

	st.generate_normals()
	var malla := st.commit()
	var mi := _montar(malla, tris, true)
	# Atravesada respecto del camino, con la punta sur hundida y la norte en
	# alto: una diagonal en planta y otra en alzado. Una piedra alineada con algo
	# la puso alguien.
	mi.rotation = Vector3(0.0, deg_to_rad(-34.0), deg_to_rad(13.0))
	mi.position = Vector3(LASTRA.x, base_y + grueso * 0.14, LASTRA.y)


# ===========================================================================
# EL MOJÓN — el metro patrón
# ===========================================================================

## Cinco cantos apilados al borde del camino, 2,4 m en total.
##
## Es lo más chico del archivo y lo más importante: **una roca de sesenta metros
## sin nada humano al lado puede ser una roca de seis.** El ojo no mide en
## metros, mide contra lo que reconoce. Y de paso dice, sin cartel, que hasta acá
## llega el valle y que alguien vino a marcarlo.
##
## LAS PIEDRAS SON NUESTRAS Y NO DEL KIT, Y NO ES CAPRICHO. Estaba escrito con
## `Kit.poner("naturaleza/rock_smallA", ...)` y salía naranja. El motivo, medido
## abriendo el `.glb`: **`rock_smallA` no tiene ninguna superficie de piedra.**
## Tiene dos, y se llaman `grass` y `dirt` — la roca de Kenney es un pegote de
## TIERRA sobre un parche de PASTO, pensado para apoyarse en un suelo verde. La
## aduana hace lo correcto con lo que recibe y lo manda a `TIERRA` (V4, marrón) y
## `COPA_CLARA` (V4, verde). Nada de eso es una piedra.
##
## (Y de paso: `detalles.gd:piedras()` siembra 320 de ésas diciendo en su
## comentario que son *"la puntuación clara del cuadro, V6, lo más claro del
## paisaje"*. **No lo son: son V4 marrón sobre V4 verde**, o sea el mismo peldaño
## que el suelo. No es de esta rama y queda anotado en el informe.)
func _mojon() -> void:
	var x := camino_x(MOJON_Z) - MOJON_APARTE
	var base_y: float = (_alturas.call(x, MOJON_Z) as float)
	var y := 0.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var tris := 0
	for i in 5:
		# De ancho abajo a angosto arriba: es una pila que alguien equilibró.
		var ancho: float = lerp(0.62, 0.26, float(i) / 4.0)
		var alto: float = lerp(0.62, 0.34, float(i) / 4.0)
		tris += _canto(st, Vector3(_entre(7717, i, 0, -0.09, 0.09), y + alto * 0.5,
			_entre(7717, i, 1, -0.09, 0.09)), ancho, alto, 7717 + i)
		y += alto * 0.86     # se encastran un poco: apiladas, no flotando
	st.generate_normals()
	var mi := _montar(st.commit(), tris, false)
	mi.position = Vector3(x, base_y - 0.12, MOJON_Z)


## Un canto rodado: dos anillos y dos tapas, facetado. 24 triángulos.
func _canto(st: SurfaceTool, centro: Vector3, ancho: float, alto: float,
		semilla: int) -> int:
	var lados := 6
	var anillo := func(t: float, e: float) -> PackedVector3Array:
		var r := PackedVector3Array()
		for i in lados:
			var a := float(i) / lados * TAU + _entre(semilla, i, 9, -0.22, 0.22)
			var rr: float = ancho * 0.5 * e * _entre(semilla, i, 3, 0.76, 1.24)
			r.append(centro + Vector3(sin(a) * rr, (t - 0.5) * alto, cos(a) * rr))
		return r
	var abajo: PackedVector3Array = anillo.call(0.0, 0.72)
	var medio: PackedVector3Array = anillo.call(0.42, 1.0)
	var arriba: PackedVector3Array = anillo.call(1.0, 0.62)
	var tris := 0
	for par: Array in [[abajo, medio], [medio, arriba]]:
		var a: PackedVector3Array = par[0]
		var b: PackedVector3Array = par[1]
		for i in lados:
			var j := (i + 1) % lados
			for tri: Array in [[a[i], a[j], b[j]], [a[i], b[j], b[i]]]:
				for v: Vector3 in tri:
					st.set_color(_color_canto(semilla))
					st.add_vertex(v)
				tris += 1
	for par: Array in [[arriba, centro + Vector3(0, alto * 0.5, 0), false],
			[abajo, centro - Vector3(0, alto * 0.5, 0), true]]:
		var anillo_t: PackedVector3Array = par[0]
		var polo: Vector3 = par[1]
		for i in lados:
			var j := (i + 1) % lados
			var tri: Array = ([polo, anillo_t[j], anillo_t[i]] if par[2]
				else [polo, anillo_t[i], anillo_t[j]])
			for v: Vector3 in tri:
				st.set_color(_color_canto(semilla))
				st.add_vertex(v)
			tris += 1
	return tris


## El color de un canto del mojón. **Plano y a media escalera, no en degradé.**
## `_color_roca()` va de V2 a V6 a lo largo de sesenta metros: aplicado a una
## piedra de medio metro le mete la escalera entera adentro y la pila sale con
## un canto casi negro al lado de uno casi blanco. Acá cada piedra es UN valor,
## con medio peldaño de diferencia entre una y otra — que es lo que dice
## "piedras distintas del mismo río" sin romper la mancha.
static func _color_canto(semilla: int) -> Color:
	var c := Paleta.MONTE_BAJO.lerp(Paleta.MONTE_ALTO, 0.62)
	var d := (_azar(semilla, 5, 3) - 0.5) * 0.13
	return Color.from_hsv(c.h, c.s, clampf(c.v + d, 0.20, 0.72))


# ===========================================================================
# Plomería
# ===========================================================================

## Cuelga la malla de la escena con material de monte y colisión de malla.
##
## Colisión SÍ, y es la única del archivo que la lleva: la cordillera del fondo
## no la necesita porque nadie llega, pero acá se camina al pie. Un jugador que
## atraviesa el objeto más grande del valle rompe la ilusión en un paso.
func _montar(malla: ArrayMesh, tris: int, colision: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = Paleta.monte()
	# Sombra sí: una mole de sesenta metros tirando sombra larga al amanecer es
	# la mitad del drama, y es gratis — la sombra del sol llega a 260 m y la
	# puerta está a 162.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
	_tris += tris
	if colision:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		forma.shape = malla.create_trimesh_shape()
		cuerpo.add_child(forma)
		mi.add_child(cuerpo)
		_cuerpos += 1
	return mi


# ===========================================================================
# LA ESCENA DE PRUEBA
# ===========================================================================

var _ruido_prueba := FastNoiseLite.new()


## La misma fórmula de `valle.gd:altura_en()`. Copiada y no importada porque el
## módulo tiene que poder correr solo; en el valle se le pasa la de verdad.
func altura_de_prueba(x: float, z: float) -> float:
	var d := Vector2(x, z).length()
	var cuenco := -pow(d / 165.0, 2.2) * 5.0
	return _ruido_prueba.get_noise_2d(x, z) * 2.4 + cuenco


func _arg(nombre: String, x: float) -> float:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % nombre):
			return float(a.split("=")[1])
	return x


func _correr_prueba() -> void:
	_ruido_prueba.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_ruido_prueba.frequency = 0.028
	_ruido_prueba.fractal_octaves = 3

	_suelo_de_prueba()
	plantar(altura_de_prueba)
	_referencia_de_prueba()
	_luz_de_prueba()
	if OS.get_cmdline_user_args().has("--captura"):
		_captura_de_prueba()


## Un suelo con la fórmula del valle y una fila de "casas" de 5 m: la referencia
## contra la que se mide si el hito empequeñece a la aldea o no.
func _suelo_de_prueba() -> void:
	var lado := 380.0
	var pasos := 76
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
					st.set_color(Paleta.PASTO)
					st.add_vertex(p[k])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = Paleta.terreno()
	add_child(mi)


## Siete cajas de 5,2 m en el sitio de la aldea. Es la unidad de medida del
## reclamo: "el punto más alto del valle es un techo".
func _referencia_de_prueba() -> void:
	for i in 7:
		var a := float(i) / 7.0 * TAU
		var x := sin(a) * 11.0
		var z := cos(a) * 11.0
		var caja := BoxMesh.new()
		caja.size = Vector3(4.2, 5.2, 4.2)
		var mi := MeshInstance3D.new()
		mi.mesh = caja
		mi.material_override = Paleta.muro()
		mi.position = Vector3(x, altura_de_prueba(x, z) + 2.6, z)
		add_child(mi)


func _luz_de_prueba() -> void:
	var amb := Ambiente.new()
	amb.set_script(preload("res://scripts/ambiente.gd"))
	add_child(amb)
	var sol := DirectionalLight3D.new()
	var frac := _arg("hora", 0.32)
	var angulo := (frac - 0.25) * TAU
	var altura := sin(angulo)
	var dir := Vector3(cos(angulo) * 0.82, altura, -0.38).normalized()
	sol.rotation = Transform3D().looking_at(-dir, Vector3.UP).basis.get_euler()
	# La MISMA cuenta que `ciclo.gd::_process()`, copiada a propósito: si la
	# sonda usara otra mezcla de color, el barrido de horas mediría un día que
	# el juego no tiene.
	var dd := clampf(remap(altura, -0.15, 0.25, 0.0, 1.0), 0.0, 1.0)
	var dorada: float = 1.0 - absf(clampf(remap(altura, -0.10, 0.45, 0.0, 1.0), 0.0, 1.0) * 2.0 - 1.0)
	var color := Ciclo.LUNAR.lerp(Ciclo.MEDIODIA, dd)
	color = color.lerp(Ciclo.OCASO if cos(angulo) < 0.0 else Ciclo.ALBA, dorada * 0.75)
	sol.light_color = color
	sol.light_energy = lerp(0.09, 2.1, dd)
	sol.light_angular_distance = lerp(2.6, 0.9, dd)
	sol.shadow_enabled = true
	sol.shadow_bias = _arg("bias", 0.1)
	sol.shadow_normal_bias = _arg("nbias", 2.0)
	# 260 es el número de `valle.gd`, y hay que respetarlo: con 400 el
	# atlas de sombra reparte menos téxeles por metro y aparece acné en las
	# caras verticales del peñón. Se midió, y era la sonda, no el hito.
	sol.directional_shadow_max_distance = _arg("sombra", 260.0)
	add_child(sol)
	var m := amb.environment.sky.sky_material as ShaderMaterial
	m.set_shader_parameter("sol_dir", dir)
	m.set_shader_parameter("altura_sol", altura)
	# Perillas de experimento: una variable por corrida.
	var ca := amb.camera_attributes as CameraAttributesPractical
	if ca != null and _arg("dof", -1.0) >= 0.0:
		ca.dof_blur_far_distance = maxf(_arg("dof", 0.0), 0.001)
		ca.dof_blur_far_enabled = _arg("dof", 0.0) > 0.0
	amb.environment.fog_sky_affect = _arg("cielofog", amb.environment.fog_sky_affect)


## Una captura desde donde se le diga. `--desde=x,z`, `--pitch=`, `--dist=`.
func _captura_de_prueba() -> void:
	var desde := Vector2(0, 0)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--desde="):
			var p := a.split("=")[1].split(",")
			desde = Vector2(float(p[0]), float(p[1]))
	var pitch := deg_to_rad(_arg("pitch", 38.0))
	var dist := _arg("dist", 40.0)
	var yaw := deg_to_rad(_arg("yaw", 180.0))   # 180 = mirando al norte (+Z)

	var blanco := Vector3(desde.x, altura_de_prueba(desde.x, desde.y) + 1.2, desde.y)
	var cam := Camera3D.new()
	cam.fov = _arg("fov", 42.0)
	cam.far = 2400.0
	var ojo := blanco + Vector3(sin(yaw) * cos(pitch), sin(pitch),
		cos(yaw) * cos(pitch)) * dist
	cam.current = true
	add_child(cam)
	cam.look_at_from_position(ojo, blanco, Vector3.UP)

	var salida := "hito.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--salida="):
			salida = a.split("=")[1]
	await get_tree().create_timer(1.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://" + salida)
	print("hito: ", salida)
	get_tree().quit()

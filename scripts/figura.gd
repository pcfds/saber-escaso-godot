## Un cuerpo articulado que se anima solo, sin un solo archivo de animación.
##
## Todo sale de senos y cosenos manejados por la velocidad real del personaje.
## Es el enfoque de juegos como Wobbly Life o Human Fall Flat: con formas
## simples y movimiento bien temporizado, el cerebro completa el resto — y se
## ve más vivo que un esqueleto mal riggeado.
##
## Cuatro cosas hacen que se lea como caminar y no como sacudirse:
##  1. Brazos y piernas en CONTRAFASE cruzada (brazo derecho con pierna
##     izquierda). Si van en fase parece que trota un pato.
##  2. El torso sube y baja al DOBLE de frecuencia que los pasos: hay un
##     rebote por pisada, no por ciclo.
##  3. El cuerpo se inclina hacia adelante en proporción a la velocidad.
##  4. Al frenar, la fase se apaga suave en vez de cortarse.
##
## Y cuatro más que hacen que se lea como GENTE y no como un maniquí de gimnasio:
##  5. Ojos enormes. La cámara del valle está a 27 m con FOV 42°: ahí la cabeza
##     entera mide 25 px de alto y baja a 16 px con el zoom afuera del todo. Un
##     ojo de tamaño humano (5 cm) es entre 1,7 y 2,6 px — no es un ojo chico,
##     es ruido. Los de acá miden 14 cm de diámetro (4,8 a 7,5 px) y son casi
##     negros contra piel clara. De cerca son de dibujito; de lejos son lo
##     único que llega. Ante la duda se agranda: achicar después es un número.
##  6. NO emiten luz. El brillo naranja es la firma de los monstruos: si la
##     gente también brilla, se pierde de un plumazo la única señal que dice
##     "eso de allá no es humano". Los ojos de acá se leen por CONTRASTE.
##  7. Parpadeo y respiración, desincronizados. Es lo más barato que existe
##     para que algo deje de parecer un objeto. Van en `_process()` y no en
##     `animar()` a propósito: a los NPC del valle nadie les llama `animar()`,
##     están parados, y son justamente los que parecen maniquíes.
##  8. Variación determinista por NOMBRE. Altura, corpulencia, piel, pelo y
##     ropa salen de un hash del nombre, nunca de `randf()`. Esto es
##     multijugador: si cada máquina tira sus dados, cada jugador ve una Ilde
##     distinta y deja de ser el mismo mundo. El hash es la identidad.
class_name Figura
extends Node3D

# Medidas de la cara. Están acá arriba y con nombre porque son la decisión de
# diseño, no un detalle de implementación: se ajustan mirando el juego de
# lejos, no leyendo el código.
const OJO_RADIO := 0.072      ## 14,4 cm de diámetro. Ver el punto 5 del encabezado.
const OJO_SEP := 0.098        ## separación: los ojos ocupan el 70% del ancho de la cara
const OJO_ALTO := 0.030       ## apenas arriba del centro de la cabeza
const OJO_CERRADO := 0.07     ## a cuánto se achata el ojo con el ojo cerrado
const PARPADEO_DURA := 0.12   ## segundos. Más largo se lee como sueño, no como parpadeo.

var altura := 1.85
var color := Color(0.30, 0.72, 0.62)
var color_piel := Color(0.82, 0.70, 0.56)
var brilla := false

## La identidad. De acá salen altura, corpulencia, tono de piel, pelo y el
## desfase del parpadeo. Vacío = sin variación (el jugador y el monstruo tienen
## alturas elegidas a mano y un colisionador que las acompaña; no se las toca).
var nombre := ""
## El oficio tal cual lo manda el servidor: "herrera", "cazadora", "guardia",
## "aprendiz", "destiladora", "chico del camino"... Se traduce a una prenda que
## se lea de lejos. Lo que no reconoce, cinturón y a otra cosa.
var oficio := ""
## Cara, pelo y ropa. El monstruo lo apaga solo — ver `_es_bicho()`.
var humano := true

var _torso: Node3D
var _cabeza: Node3D
var _brazo_i: Node3D
var _brazo_d: Node3D
var _pierna_i: Node3D
var _pierna_d: Node3D
var _raiz: Node3D
var _ojo_i: MeshInstance3D
var _ojo_d: MeshInstance3D

var _alto := 1.85          ## la altura ya corregida por el hash del nombre
var _fase := 0.0
var _intensidad := 0.0     ## 0 quieto, 1 caminando: suaviza el arranque y el freno
## La inclinación del torso por caminar, aparte de `_torso.rotation.x`. Ver el
## comentario en `animar()`: si el suavizado leyera del nodo, los desvíos del
## golpe y del dolor se realimentarían cuadro a cuadro.
var _inclinacion := 0.0
## Segundos que le quedan al swing. Cuenta hacia atrás desde `Impacto.SWING_TOTAL`
## (23 cuadros) y de ahí sale en qué fase está: anticipo, embate o recuperación.
var _golpe := 0.0
var _arma: MeshInstance3D
var _juntando := false
var _agache := 0.0
## El amago: 0 cuerpo normal, 1 cuerpo encabritado. Sube en `AMAGO_ALZA` y baja
## en `AMAGO_SUELTA`, o sea que no es un `lerp` con rapidez: es una rampa con
## los cuadros de `impacto.gd`. Ver `amagar()`.
var _amago := 0.0
var _amago_on := false
## Lo maltrecho que está, 0 entero y 1 en las últimas. Ver `maltratar()`.
var _maltrecho := 0.0
## El gesto social en curso y cuánto lleva, en segundos. Ver el bloque «Los
## gestos» más abajo.
var _gesto := Gesto.NINGUNO
var _gesto_reloj := 0.0
## La conversación, que no es un gesto de una vez sino un estado: mientras dura,
## el cuerpo está orientado al otro. `_charla_yaw` es el ángulo LOCAL hacia él.
var _charlando := false
var _charla_yaw := 0.0
var _charla_suave := 0.0
## ¿Alguien llamó a `animar()` en este cuadro? De eso depende quién aplica la
## pose del gesto. Ver `_process()`.
var _animado := false
## Segundos que le quedan al respingo de dolor, normalizado 1→0 sobre
## `DOLOR_DURA`. Ver `doler()`.
var _dolor := 0.0
## Las mallas del cuerpo, para el destello blanco del cuadro del impacto. Se
## juntan una sola vez (recursivo) y se invalidan al reconstruir o al equipar.
var _mallas: Array[MeshInstance3D] = []
var _destello: StandardMaterial3D
## ¿Hay overlay puesto ahora mismo? Antes esto se deducía de `_raiz.scale != ONE`,
## que dejó de valer cuando el amago pasó a escribir la escala también: un bicho
## encabritado tiene la escala distinta de 1 sin que nadie le haya pegado.
var _destello_puesto := false
var _vivo := true
var _reloj := 0.0          ## tiempo propio, para respirar y mirar alrededor
var _espera_parpadeo := 3.0
var _cierre := 0.0         ## 0 ojo abierto, 1 ojo cerrado
# Desfases sacados del nombre y guardados: hashear un string por cuadro y por
# personaje para obtener siempre el mismo número es pagar dos veces.
var _fase_resp := 0.0
var _fase_mira := 0.0


func construir() -> void:
	# Idempotente: `_ready()` puede tener que rehacer el cuerpo si recién ahí se
	# entera del nombre del personaje (ver más abajo).
	if _raiz != null:
		_raiz.queue_free()
	_ojo_i = null
	_ojo_d = null
	_mallas.clear()   # el cuerpo es otro: las mallas cacheadas ya no existen

	_raiz = Node3D.new()
	add_child(_raiz)

	# Cuerpo y corpulencia. La corpulencia toca el torso y el grosor de los
	# miembros, que es lo que cambia la silueta; tocar sólo la altura hace
	# gente distinta que sigue pareciendo la misma persona estirada.
	var corp := 1.0
	if nombre != "":
		_alto = altura * (0.90 + _dado("alto") * 0.20) * _factor_edad()
		corp = 0.86 + _dado("corp") * 0.32
	else:
		_alto = altura

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _color_ropa()
	mat.roughness = 0.72
	if brilla:
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 0.3

	var piel := StandardMaterial3D.new()
	piel.albedo_color = _tono_piel()
	piel.roughness = 0.86

	var largo_torso := _alto * 0.42
	# Godot recorta solo la altura de una cápsula si es menor que dos radios, y
	# ahí un gordito bajito sale como una pelota. Se recorta el radio, no el alto.
	var r_torso: float = minf(0.30 * corp, largo_torso * 0.499)

	_torso = Node3D.new()
	_torso.position.y = _alto * 0.52
	_raiz.add_child(_torso)
	_torso.add_child(_pieza(CapsuleMesh, mat, r_torso, largo_torso, Vector3.ZERO))

	# La cabeza casi no escala con la altura, y es a propósito: ahí está la
	# cara, y la cara es lo único que se lee de lejos. Un personaje bajo con
	# cabeza chica son dos motivos para no distinguirlo en vez de uno.
	var r_cabeza := 0.20 + _alto * 0.022
	_cabeza = Node3D.new()
	_cabeza.position.y = _alto * 0.30
	_torso.add_child(_cabeza)
	var esf := SphereMesh.new()
	esf.radius = r_cabeza
	esf.height = r_cabeza * 2.0
	esf.material = piel
	var mc := MeshInstance3D.new()
	mc.mesh = esf
	mc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_cabeza.add_child(mc)

	# Los miembros cuelgan de un pivote en el hombro/cadera, no del centro:
	# así rotan como articulaciones y no como hélices.
	var hombro := r_torso * 1.13
	_brazo_i = _miembro(mat, -hombro, _alto * 0.16, _alto * 0.30, 0.085 * corp)
	_brazo_d = _miembro(mat, hombro, _alto * 0.16, _alto * 0.30, 0.085 * corp)
	_torso.add_child(_brazo_i)
	_torso.add_child(_brazo_d)

	_pierna_i = _miembro(mat, -0.15 * corp, -_alto * 0.20, _alto * 0.32, 0.105 * corp)
	_pierna_d = _miembro(mat, 0.15 * corp, -_alto * 0.20, _alto * 0.32, 0.105 * corp)
	_torso.add_child(_pierna_i)
	_torso.add_child(_pierna_d)

	if humano and not _es_bicho():
		_armar_cara(r_cabeza)
		_armar_pelo(r_cabeza)
		_vestir(r_torso, largo_torso, r_cabeza)

	# Parpadeo desfasado desde el nombre: dos vecinos no arrancan sincronizados,
	# y arrancan igual en todas las máquinas.
	_espera_parpadeo = 0.6 + _dado("ojo") * 4.5
	_fase_resp = _dado("resp") * TAU
	_fase_mira = _dado("mira") * TAU


## El valle le pone `nombre` y `oficio` como metadatos al nodo que contiene a la
## figura, y lo hace DESPUÉS de construirla. Si nadie nos pasó el nombre a mano,
## lo levantamos de ahí al entrar al árbol y rehacemos el cuerpo: es la
## diferencia entre siete NPC idénticos y siete personas.
func _ready() -> void:
	if nombre != "":
		return
	var p := get_parent()
	if p == null or not p.has_meta("nombre"):
		return
	nombre = str(p.get_meta("nombre"))
	oficio = str(p.get_meta("oficio", ""))
	if _raiz != null:
		construir()


## El monstruo se cuelga sus propios ojos naranjas encima DESPUÉS de
## `construir()`. Si además le pusiéramos los humanos quedaría con cuatro ojos
## y, peor, con cara de persona: lo que lo vuelve ajeno es justamente que en la
## cara no tenga nada más que ese brillo.
##
## Lo reconocemos por pato: `murio` la declara sólo `monstruo.gd`. Preguntar
## `is Monstruo` desde acá sería más claro pero arma una referencia circular
## (monstruo.gd ya precarga este archivo) y Godot la escupe al parsear.
func _es_bicho() -> bool:
	var p := get_parent()
	return p != null and p.has_signal("murio")


# ---------------------------------------------------------------------------
# Identidad: todo lo que sigue tiene que dar lo mismo en todas las máquinas.
# ---------------------------------------------------------------------------

## FNV-1a de 32 bits, a mano. No uso `String.hash()` ni un RandomNumberGenerator
## sembrado porque ninguno de los dos promete el mismo número entre versiones
## del motor, y acá "el mismo número siempre" ES el requisito: si cambia, Ilde
## cambia de cara para todos a la vez y el mundo compartido deja de serlo.
static func _hash32(texto: String) -> int:
	var h := 2166136261
	for b: int in texto.to_utf8_buffer():
		h = (h ^ b) * 16777619 & 0xFFFFFFFF
	return h


## Un número 0..1 estable por personaje y por rasgo. Cada rasgo pide su propio
## canal para que dos nombres parecidos no salgan clonados en todo junto.
func _dado(canal: String) -> float:
	return float(_hash32(nombre + "/" + canal) % 100003) / 100003.0


## Los pibes son bajos. Es la única corrección de altura que viene del oficio y
## no del nombre, porque "chico del camino" es literalmente una edad.
func _factor_edad() -> float:
	var o := oficio.to_lower()
	if o.contains("chico") or o.contains("chica") or o.contains("niñ"):
		return 0.76
	if o.contains("aprendiz"):
		return 0.92
	return 1.0


## La piel se corre en tono, saturación y brillo desde el color base. Se mueve
## sobre todo el VALOR: a 27 m el matiz casi no llega, la claridad sí.
func _tono_piel() -> Color:
	if nombre == "":
		return color_piel
	var h := wrapf(color_piel.h + (_dado("piel_h") - 0.5) * 0.05, 0.0, 1.0)
	var s := clampf(color_piel.s + (_dado("piel_s") - 0.5) * 0.14, 0.05, 0.95)
	var v := clampf(color_piel.v * (0.66 + _dado("piel_v") * 0.42), 0.08, 1.0)
	return Color.from_hsv(h, s, v)


## Mismo criterio con la ropa. Sin esto, todos los NPC del valle son el mismo
## gris: el color que manda el valle es el punto de partida, no el resultado.
func _color_ropa() -> Color:
	if nombre == "":
		return color
	# El valle manda un gris para todos. Perturbarlo no alcanza: con saturación
	# casi cero el matiz no existe y salen siete grises. Hay que elegir un tinte.
	#
	# Y se elige de una lista, no de la rueda entera: tirar el tono al azar da
	# magentas y violetas, que son justo los colores que en un valle de lana
	# teñida en casa no existen — cuestan una fortuna y se leen como disfraz.
	# Estos son los que salen de raíces, cáscara y óxido.
	var tintes: Array[float] = [0.045, 0.075, 0.10, 0.13, 0.22, 0.31, 0.55]
	var h: float = tintes[int(_dado("ropa_h") * tintes.size()) % tintes.size()]
	var s := 0.14 + _dado("ropa_s") * 0.32
	# El VALOR es el que hace el trabajo a 27 m: a esa distancia el matiz de dos
	# personas cuesta compararlo y "uno oscuro y uno claro" se ve al toque. Por
	# eso el rango es ancho —de casi negro a casi blanco— y no un abanico de
	# medios tonos, que es lo que tenía antes y se veía como siete veces la
	# misma persona.
	var v := clampf(color.v * (0.42 + _dado("ropa_v") * 0.98), 0.09, 0.95)
	# Un pie en el color que mandó el valle: si mañana pinta a un bando de rojo,
	# la variación tiene que seguir leyéndose como ese bando.
	return Color.from_hsv(h, s, v).lerp(color, 0.18)


func _color_pelo() -> Color:
	# Pocos tonos y bien separados en valor. Cinco pelos parecidos son un pelo.
	var tonos: Array[Color] = [
		Color(0.09, 0.07, 0.07),   # negro
		Color(0.24, 0.15, 0.09),   # castaño oscuro
		Color(0.40, 0.24, 0.11),   # castaño
		Color(0.62, 0.47, 0.24),   # rubio ceniza
		Color(0.72, 0.70, 0.66),   # cano: además lee como edad
	]
	# El cano cuenta una edad. A un aprendiz o a un chico del camino le cuenta
	# la equivocada, así que a ellos no les toca.
	var cuantos := tonos.size() if _factor_edad() >= 1.0 else tonos.size() - 1
	return tonos[int(_dado("pelo_c") * cuantos) % cuantos]


## El servidor no manda género y el castellano alcanza para deducirlo: un oficio
## terminado en -a ("herrera", "cazadora", "destiladora") o un nombre con
## artículo femenino ("La vieja Ren") es ella. Se usa para una sola cosa —no
## repartir barbas a ciegas—, y ante la duda no hay barba: una Marta con barba
## se nota muchísimo más que un Bruno sin ella.
func _parece_ella() -> bool:
	var o := oficio.strip_edges().to_lower()
	if o.ends_with("a") and not o.contains("guard"):   # "guardia" no dice nada
		return true
	var n := nombre.to_lower()
	return n.begins_with("la ") or n.contains(" vieja") or n.ends_with("a")


# ---------------------------------------------------------------------------
# Cara, pelo y ropa
# ---------------------------------------------------------------------------

func _armar_cara(rc: float) -> void:
	# Casi negro, y liso: la poca rugosidad le deja agarrar un reflejo puntual
	# del sol. Ese destello es lo que hace que un ojo parezca húmedo y no un
	# agujero — y se consigue sin emisión, que es de los monstruos.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.045, 0.055)
	mat.roughness = 0.16
	mat.metallic_specular = 0.85

	for lado: int in [-1, 1]:
		var e := SphereMesh.new()
		e.radius = OJO_RADIO
		e.height = OJO_RADIO * 2.0
		e.material = mat
		var mi := MeshInstance3D.new()
		mi.mesh = e
		mi.position = Vector3(OJO_SEP * lado, OJO_ALTO, rc * 0.86)
		# Aplastado contra la cara para que sea un ojo y no un ojo saltón.
		mi.scale = Vector3(1.0, 1.0, 0.5)
		# Sin sombra: pegado a la cabeza no proyecta nada que se entienda, y a
		# esta distancia es una sombra de tres píxeles que sólo cuesta.
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_cabeza.add_child(mi)
		if lado < 0:
			_ojo_i = mi
		else:
			_ojo_d = mi

	# Las cejas no se leen como cejas a 27 m: se funden con el ojo y agrandan la
	# mancha oscura. Eso es exactamente para lo que están acá. El ángulo es lo
	# único de la cara que da gesto, y sale del nombre.
	var ceja := StandardMaterial3D.new()
	ceja.albedo_color = _color_pelo().darkened(0.3)
	ceja.roughness = 0.9
	var gesto := (_dado("ceja") - 0.45) * 0.5
	for lado: int in [-1, 1]:
		var b := BoxMesh.new()
		b.size = Vector3(0.125, 0.028, 0.05)
		b.material = ceja
		var mi := MeshInstance3D.new()
		mi.mesh = b
		mi.position = Vector3(OJO_SEP * lado, OJO_ALTO + 0.105, rc * 0.80)
		mi.rotation.z = gesto * lado
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_cabeza.add_child(mi)

	# Boca no hay: a esta distancia es un píxel de suciedad debajo de los ojos.
	# Si algún día la cámara baja de 9 m, ahí se discute.


func _armar_pelo(rc: float) -> void:
	var estilo := int(_dado("pelo_e") * 10.0)
	if nombre == "":
		estilo = 0   # sin nombre no hay identidad que expresar: pelo corto y listo
	if oficio.to_lower().contains("caz"):
		return       # la cazadora va encapuchada; el pelo quedaría dentro de la tela

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _color_pelo()
	mat.roughness = 0.95

	if estilo != 9:
		# El casquete está corrido hacia atrás y estirado en Z para que el borde
		# de adelante caiga por detrás de las cejas. Si no, el peinado se come
		# la cara, que es lo único que nos importaba.
		_cabeza.add_child(_esfera(mat, rc * 1.05, Vector3(1.0, 0.78, 1.22),
			Vector3(0, rc * 0.34, -rc * 0.46)))
	if estilo <= 2:
		# Melena hasta los hombros: cambia la silueta, que es lo que se ve
		# cuando el personaje está de espaldas — o sea, casi siempre.
		_cabeza.add_child(_esfera(mat, rc * 0.95, Vector3(1.05, 1.15, 0.75),
			Vector3(0, -rc * 0.30, -rc * 0.72)))
	elif estilo <= 4:
		_cabeza.add_child(_esfera(mat, rc * 0.52, Vector3.ONE,
			Vector3(0, rc * 0.62, -rc * 0.95)))   # rodete

	if nombre != "" and not _parece_ella() and _factor_edad() >= 1.0 and _dado("barba") > 0.5:
		_cabeza.add_child(_esfera(mat, rc * 0.62, Vector3(1.0, 0.9, 0.85),
			Vector3(0, -rc * 0.62, rc * 0.46)))


## La ropa es lo que contesta "¿quién es ese?" desde lejos, antes que el cartel
## con el nombre. Por eso son manchas grandes y de valor bien distinto al
## cuerpo: un bordado no existe a 25 px de alto, un delantal sí.
func _vestir(rt: float, largo: float, rc: float) -> void:
	var o := oficio.to_lower()

	if o.contains("herr") or o.contains("forj") or o.contains("aprendiz"):
		# Delantal de cuero: cae por debajo del torso, como cae un delantal.
		var cuero := _material(Color(0.29, 0.17, 0.10), 0.85)
		_torso.add_child(_caja(cuero, Vector3(rt * 1.55, largo * 0.86, rt * 0.30),
			Vector3(0, -largo * 0.20, rt * 0.86)))
		_torso.add_child(_caja(cuero, Vector3(rt * 0.42, largo * 0.55, rt * 0.26),
			Vector3(-rt * 0.35, largo * 0.28, -rt * 0.80)))
	elif o.contains("caz"):
		# Capucha y capa. La capucha va MUY corrida hacia atrás: tiene que
		# tapar el cráneo y dejar los ojos afuera, o perdimos la cara.
		var tela := _material(Color(0.19, 0.24, 0.17), 0.95)
		_cabeza.add_child(_esfera(tela, rc * 1.26, Vector3(1.0, 0.95, 1.05),
			Vector3(0, rc * 0.16, -rc * 0.62)))
		_torso.add_child(_caja(tela, Vector3(rt * 1.75, largo * 1.05, rt * 0.22),
			Vector3(0, -largo * 0.10, -rt * 0.92)))
	elif o.contains("guard") or o.contains("solda"):
		# Hombreras: ensanchan la silueta. Un guardia se reconoce por ancho.
		var metal := _material(Color(0.44, 0.46, 0.50), 0.35)
		metal.metallic = 0.7
		for lado: int in [-1, 1]:
			_torso.add_child(_esfera(metal, rt * 0.52, Vector3(1.0, 0.8, 1.0),
				Vector3(rt * 1.15 * lado, largo * 0.34, 0)))
		_torso.add_child(_caja(metal, Vector3(rt * 1.25, largo * 0.5, rt * 0.24),
			Vector3(0, largo * 0.05, rt * 0.88)))
	elif o.contains("dest") or o.contains("curan") or o.contains("cocin"):
		# Falda larga: cambia la mitad de abajo de la silueta, que es la mitad
		# que hoy son dos palos iguales en todo el mundo.
		var lino := _material(Color(0.64, 0.60, 0.48), 0.92)
		var f := CylinderMesh.new()
		f.top_radius = rt * 0.95
		f.bottom_radius = rt * 1.55
		f.height = _alto * 0.30
		f.material = lino
		var mi := MeshInstance3D.new()
		mi.mesh = f
		mi.position = Vector3(0, -largo * 0.62, 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		_torso.add_child(mi)
	else:
		# El default no es "nada": un cinturón oscuro parte el cuerpo en dos y
		# ya lo saca de maniquí de una pieza. Cuesta un box.
		var cinto := _material(Color(0.22, 0.16, 0.12), 0.8)
		_torso.add_child(_caja(cinto, Vector3(rt * 2.12, largo * 0.13, rt * 2.12),
			Vector3(0, -largo * 0.40, 0)))


func _material(c: Color, rugosidad: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rugosidad
	return m


func _esfera(mat: Material, radio: float, escala: Vector3, pos: Vector3) -> MeshInstance3D:
	var e := SphereMesh.new()
	e.radius = radio
	e.height = radio * 2.0
	e.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = e
	mi.position = pos
	mi.scale = escala
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


func _caja(mat: Material, tam: Vector3, pos: Vector3) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = tam
	b.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = b
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


func _pieza(tipo: Variant, mat: Material, radio: float, alto: float, pos: Vector3) -> MeshInstance3D:
	var m: Mesh
	if tipo == CapsuleMesh:
		var c := CapsuleMesh.new()
		c.radius = radio
		c.height = alto
		c.material = mat
		m = c
	else:
		var b := BoxMesh.new()
		b.size = Vector3(radio * 2, alto, radio * 2)
		b.material = mat
		m = b
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


func _miembro(mat: Material, x: float, y: float, largo: float, grosor: float) -> Node3D:
	var pivote := Node3D.new()
	pivote.position = Vector3(x, y, 0)
	var c := CapsuleMesh.new()
	c.radius = grosor
	c.height = maxf(largo, grosor * 2.05)
	c.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.position.y = -largo * 0.5   # cuelga del pivote
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	pivote.add_child(mi)
	return pivote


# ---------------------------------------------------------------------------
# Lo que se mueve
# ---------------------------------------------------------------------------

## Respirar, parpadear y mirar alrededor. Va acá y no en `animar()` porque los
## NPC del valle no llaman a `animar()` nunca: están parados en su lugar, y son
## los que más falta les hace parecer vivos. Un muerto no parpadea, así que
## `caer()` apaga todo esto.
func _process(dt: float) -> void:
	if _torso == null or not _vivo:
		return
	_reloj += dt

	# Sólo cuando está quieto: si camina, el rebote del paso ya hace el trabajo
	# y encima se pisan.
	var quieto := 1.0 - clampf(_intensidad, 0.0, 1.0)
	if quieto > 0.01:
		_torso.scale.y = 1.0 + sin(_reloj * 1.15 + _fase_resp) * 0.013 * quieto
		# La cabeza gira despacio y con dos frecuencias que no encajan, para
		# que no se le note el ciclo — el mismo truco que `parpadeo.gd` usa con
		# el fuego. Toca sólo el eje Y: el X es de `animar()`, y si los dos
		# escriben lo mismo se pelean cuadro por medio.
		#
		# **Salvo si está conversando**, y ahí lo escribe `_pose_de_charla()`:
		# alguien que te está hablando y mientras tanto mira alrededor con su
		# ciclo de siempre no está conversando, está esperando el colectivo.
	# Fuera del `if quieto`: este eje necesita que alguien lo asiente TODOS los
	# cuadros, camine o no, porque los gestos le suman encima. Con `quieto` en
	# cero la línea escribe cero, que es la base correcta.
	if _charla_suave <= 0.01:
		_cabeza.rotation.y = (sin(_reloj * 0.31 + _fase_mira) * 0.30
			+ sin(_reloj * 0.13 + _fase_mira * 2.0) * 0.16) * quieto

	# ── Los gestos, para los que nadie anima ────────────────────────────────
	#
	# `animar()` corre en el proceso de FÍSICA de quien tenga cuerpo —el jugador
	# y los bichos— y esto corre en el de dibujo. El que se anima ya aplicó su
	# gesto allá, encima de la pose de la caminata; el que no —los NPC del
	# valle, que son justamente los que reciben regalos y conversan— lo aplica
	# acá, que es el único lugar donde se mueve.
	if _animado:
		_animado = false
	else:
		# **Y acá hay que reponer la pose neutra a mano.** Los gestos suman con
		# `+=` contando con que alguien puso la base ese cuadro, que es lo que
		# hace `animar()` con `_inclinacion`. Sin este reset lo que suman se
		# acumula cuadro a cuadro y en dos segundos el NPC está doblado en dos:
		# es el mismo bug de la inclinación realimentada, en el otro extremo.
		_torso.rotation = Vector3.ZERO
		_cabeza.rotation.x = 0.0
		_brazo_i.rotation = Vector3.ZERO
		_brazo_d.rotation = Vector3.ZERO
		_gestos(dt)

	if _ojo_i == null:
		return
	_espera_parpadeo -= dt
	if _espera_parpadeo <= 0.0:
		_cierre = 1.0
		# Ya desincronizados por el nombre al nacer; de acá en más el intervalo
		# irregular alcanza y sobra para que no vuelvan a caer en fila.
		_espera_parpadeo = randf_range(2.4, 7.0)
	if _cierre > 0.0:
		_cierre = maxf(0.0, _cierre - dt / PARPADEO_DURA)
		# Cierra rápido y abre lento, como un párpado de verdad: el pow(t, 0.65)
		# corre el momento del ojo cerrado al primer tercio del parpadeo. Con un
		# seno simétrico se lee como pestañeo de muñeca.
		var t := 1.0 - _cierre
		var abertura: float = lerpf(1.0, OJO_CERRADO, sin(pow(t, 0.65) * PI))
		_ojo_i.scale.y = abertura
		_ojo_d.scale.y = abertura


## Se llama cada cuadro con la velocidad horizontal real del personaje.
##
## **Ojo: a los NPC del valle nadie les llama esto.** Están parados en su lugar
## y sólo corre su `_process()`. Por eso todo lo que tenga que verse en un NPC
## —respirar, parpadear, y ahora los gestos— tiene que poder aplicarse desde los
## dos lados. Ver `_gestos()`.
func animar(dt: float, velocidad: float, en_piso: bool) -> void:
	if _torso == null:
		return
	_animado = true

	var v := clampf(velocidad / 7.5, 0.0, 1.4)
	_intensidad = lerp(_intensidad, v, 9.0 * dt)          # (4) arranque y freno suaves
	_fase += dt * (5.6 + v * 3.4) * clampf(v, 0.15, 1.4)

	var amplitud := _intensidad * 0.85
	var s := sin(_fase)
	var s2 := sin(_fase * 2.0)

	# (1) contrafase cruzada
	_brazo_i.rotation.x = s * amplitud * 0.75
	_brazo_d.rotation.x = -s * amplitud * 0.75
	_pierna_i.rotation.x = -s * amplitud
	_pierna_d.rotation.x = s * amplitud

	# (2) un rebote por pisada, no por ciclo
	_torso.position.y = _alto * 0.52 + abs(s2) * 0.055 * _intensidad
	_torso.rotation.z = s * 0.05 * _intensidad
	# **La base del giro del torso, que faltaba.** Todos los ejes que reciben un
	# `+=` más abajo tienen que quedar asentados en algo cada cuadro; el `.x` sale
	# de `_inclinacion` y el `.z` de la línea de arriba, pero el `.y` no lo ponía
	# nadie: sólo lo ASIGNABA el swing, y el resto del tiempo quedaba flotando con
	# el último valor. Medido con el gesto de enseñar puesto, que le suma 15°
	# nominales: a los 6 cuadros el torso estaba a **55°**, porque los 15 se
	# sumaban a los 15 del cuadro anterior. Es, otra vez, el bug de la
	# inclinación realimentada.
	_torso.rotation.y = 0.0

	# (3) inclinación proporcional a la velocidad.
	#
	# **El suavizado va en `_inclinacion` y no en `_torso.rotation.x`, y eso es
	# un arreglo, no un refactor.** Estaba escrito como
	# `rotation.x = lerp(rotation.x, objetivo, ...)`, o sea leyendo del mismo
	# lugar donde después escriben el agache, el golpe y el dolor con `+=`. El
	# resultado es que esos aportes NO eran un desvío de un cuadro: se
	# realimentaban. Medido: los 46° de respingo del dolor llegaban a **112°**
	# —el personaje se doblaba hacia atrás como un arco— y el golpe dejaba al
	# torso 30° inclinado medio segundo después de terminar. Con la inclinación
	# guardada aparte, lo que suma cada efecto es exactamente lo que dice sumar.
	_inclinacion = lerp(_inclinacion, _intensidad * 0.16, 8.0 * dt)
	_torso.rotation.x = _inclinacion

	# La cabeza se estabiliza: mira al frente aunque el torso rebote. Es el
	# detalle que más aporta a que parezca un ser vivo.
	_cabeza.rotation.x = -_inclinacion * 0.7 + sin(_fase * 0.7) * 0.02

	if not en_piso:
		# En el aire: piernas recogidas, brazos arriba.
		_pierna_i.rotation.x = lerp(_pierna_i.rotation.x, -0.7, 10.0 * dt)
		_pierna_d.rotation.x = lerp(_pierna_d.rotation.x, -0.35, 10.0 * dt)
		_brazo_i.rotation.x = lerp(_brazo_i.rotation.x, -1.9, 10.0 * dt)
		_brazo_d.rotation.x = lerp(_brazo_d.rotation.x, -1.9, 10.0 * dt)

	# Agachado: el torso baja y se inclina, y el brazo derecho se estira al
	# suelo. Se entra y se sale suave, que es lo que lo hace leerse como un
	# movimiento y no como un salto de pose.
	_agache = lerp(_agache, 1.0 if _juntando else 0.0, 7.0 * dt)
	if _agache > 0.01:
		_torso.position.y -= altura * 0.22 * _agache
		_torso.rotation.x += 0.55 * _agache
		_brazo_d.rotation.x = lerp(_brazo_d.rotation.x, 1.15, _agache)
		_pierna_i.rotation.x = lerp(_pierna_i.rotation.x, -0.45, _agache)
		_pierna_d.rotation.x = lerp(_pierna_d.rotation.x, -0.25, _agache)

	# El orden de acá abajo no es casual y tiene DOS reglas, no una.
	#
	# **1. De lo más permanente a lo más instantáneo**, para todo lo que se suma
	# con `+=`: lo maltrecho dura minutos, el swing un tercio de segundo y el
	# respingo un sexto. Así, un bicho en las últimas que pega sigue estando
	# encorvado mientras pega.
	#
	# **2. El amago va DESPUÉS del swing, y ahí la regla se invierte a propósito.**
	# Los dos ASIGNAN `_brazo_*.rotation.x` en vez de sumarle, y los dos se
	# solapan durante los 4 cuadros en que el amago se deshace. Medido con el
	# orden al revés: en el cuadro del compromiso el brazo saltaba de -135° a
	# +17°, **152 grados en un cuadro**, justo en el cuadro que tiene que leerse
	# como el arranque del golpe. Poniendo el amago último, lo que hace es
	# interpolar `lerp(lo que dejó el swing, la pose del amago, a)` con `a`
	# bajando de 1 a 0: el brazo sale de la pose abierta y entra al swing sin
	# saltar un solo cuadro.
	# Los gestos sociales van antes que todo lo del golpe: si te están pegando
	# mientras regalás algo, gana el golpe, y está bien que gane.
	_gestos(dt)

	if _maltrecho > 0.01:
		_pose_de_maltrecho(_maltrecho)

	if _golpe > 0.0:
		_golpe = maxf(0.0, _golpe - dt)
		_pose_de_golpe(Impacto.SWING_TOTAL - _golpe)
		# Antes acá había un `_torso.rotation.y = 0.0` al terminar el swing. Ya no
		# hace falta: la base del eje se pone arriba, todos los cuadros.

	_correr_amago(dt)
	if _amago > 0.001:
		_pose_de_amago(_amago)

	# **`_raiz.position.x` y `_raiz.scale` los escriben DOS efectos cada uno** —el
	# respingo del dolor, el tambaleo del herido, el estirón del amago— así que se
	# acumulan en variables locales y se aplican UNA vez. Dos líneas escribiendo
	# la misma propiedad es el bug que ya costó caro dos veces en este proyecto
	# (la inclinación del torso acá arriba, el desenfoque entre `ambiente.gd` y
	# `rendimiento.gd`): gana el que corre último y lo que se ve no es lo que dice
	# el código.
	#
	# Y que el amago estire y el impacto aplaste no es coincidencia: es
	# **estirar y aplastar**, el principio más viejo que hay. El cuerpo se estira
	# al cargar y se achata al recibir, y cuando las dos cosas se pisan —te
	# pegaron en mitad del amago— se multiplican, que es exactamente lo que
	# corresponde.
	var desvio := 0.0
	var forma := Vector3.ONE
	if _amago > 0.001:
		forma = Vector3(1.0 - 0.035 * _amago, 1.0 + 0.11 * _amago, 1.0 - 0.035 * _amago)
	if _dolor > 0.0:
		_dolor = maxf(0.0, _dolor - dt / DOLOR_DURA)
		desvio = _pose_de_dolor(_dolor)
		forma *= _aplaste(_dolor)
	elif _destello_puesto:
		_apagar_destello()
	if _maltrecho > 0.01:
		desvio += _tambaleo(_maltrecho)
	if _raiz.position.x != desvio:
		_raiz.position.x = desvio
	if _raiz.scale != forma:
		_raiz.scale = forma


## El swing, cuadro por cuadro. `e` son los segundos transcurridos desde que
## empezó. Las tres fases están en `impacto.gd` con sus números.
##
## **Lo que cambió y por qué.** Antes esto era `sin(t*PI)` sobre el brazo
## derecho y medio radián de torso: 114 grados de brazo, medidos, y aun así el
## reclamo fue *"no mueve los brazos"*. El reclamo era correcto y la causa no:
## la cámara está a 40 m y a veces a 68, y ahí un brazo son dos píxeles. Lo que
## se lee a esa distancia es la SILUETA, así que ahora el que se mueve es el
## torso: 31° hacia un lado en el anticipo y 52° hacia el otro en el embate son
## 83 grados de cuerpo entero girando, y eso sí cambia el contorno.
##
## Y sin anticipo no hay golpe, hay teletransporte del brazo: los 5 cuadros en
## que el cuerpo se echa para atrás son los que hacen que el embate se lea como
## la consecuencia de algo.
func _pose_de_golpe(e: float) -> void:
	if e < Impacto.SWING_ANTICIPO:
		# ── Anticipo, cuadros 0-4 ──
		# Seno de cuarto de vuelta: sale rápido y se frena al llegar al tope,
		# que es como se carga un brazo de verdad.
		var u := sin(e / Impacto.SWING_ANTICIPO * PI * 0.5)
		_brazo_d.rotation.x = 0.95 * u          # el brazo va ATRÁS, no adelante
		_torso.rotation.y = 0.55 * u            # el hombro derecho se retrasa
		_torso.rotation.x -= 0.18 * u           # y el cuerpo se echa hacia atrás
		return

	var e2 := e - Impacto.SWING_ANTICIPO
	if e2 < Impacto.SWING_EMBATE:
		# ── Embate, cuadros 5-12. El contacto es el cuadro 5, o sea el primero. ──
		# `pow(u, 0.45)` pone la mitad del recorrido en los primeros 2 cuadros:
		# un golpe que reparte su velocidad parejo se ve como que empuja.
		var p := pow(e2 / Impacto.SWING_EMBATE, 0.45)
		_brazo_d.rotation.x = lerpf(0.95, -2.5, p)
		_torso.rotation.y = lerpf(0.55, -0.90, p)
		# Sale del -0,18 con que terminó el anticipo, no de cero: si arrancara
		# de cero el torso pegaría un salto de 10° en un cuadro justo en el
		# momento del contacto, que es el peor cuadro para tener un salto.
		_torso.rotation.x += lerpf(-0.18, 0.22, p)
		# El cuerpo BAJA seis centímetros al descargar. Es poco en metros y
		# mucho en peso: sin eso el golpe sale de un cuerpo que flota.
		_torso.position.y -= 0.06 * p
		return

	# ── Recuperación, cuadros 13-22 ──
	# `smoothstep` invertido: arranca despacio (el cuerpo se queda un instante
	# en el final del golpe) y vuelve. Cortar en seco acá se ve a rebobinado.
	var u := clampf((e2 - Impacto.SWING_EMBATE) / Impacto.SWING_RECUPERA, 0.0, 1.0)
	var k := 1.0 - u * u * (3.0 - 2.0 * u)
	_brazo_d.rotation.x = -2.5 * k
	_torso.rotation.y = -0.90 * k
	_torso.rotation.x += 0.22 * k
	_torso.position.y -= 0.06 * k


## El respingo de recibir un golpe, cuadro por cuadro. `d` va de 1 a 0 en los
## 10 cuadros de `DOLOR_DURA`.
##
## Todo acá es de cuerpo entero por el mismo motivo que el swing: a 40 metros
## los 13 cm de sacudida lateral que tenía antes son cuatro píxeles moviéndose
## medio pestañeo, o sea nada. Lo que sí se ve desde ahí es que la silueta
## cambie de forma.
##
## **Devuelve el desvío lateral en vez de escribirlo.** Ver el comentario de
## `animar()`: el tambaleo del herido escribe en el mismo `_raiz.position.x`, y
## dos escritores de una propiedad es un bug esperando.
func _pose_de_dolor(d: float) -> float:
	# Sacudida lateral: 19 cm y DOS vueltas enteras en los 10 cuadros.
	#
	# La fase se saca de lo TRANSCURRIDO (`1 - d`) y no de `d * 62`, que es como
	# estaba. Con `d * 62` el argumento del seno bajaba 6,2 rad por cuadro —una
	# vuelta y pico— así que el seno se muestreaba casi en la misma fase todos
	# los cuadros y **no oscilaba**: medido, la sacudida salía de -11,6 cm y
	# volvía a cero sin cruzar el cero ni una vez. Era un desplazamiento, no un
	# temblor. `TAU * 2` deja las dos vueltas escritas y a prueba de aliasing.
	var desvio := sin((1.0 - d) * TAU * 2.0) * d * 0.19
	# El tronco se dobla 46° hacia atrás. Es EL cambio de silueta del respingo.
	_torso.rotation.x -= d * 0.80
	_fundir_destello(d)
	return desvio


## El cuerpo entero se aplasta y se ensancha. `d*d` hace que el aplaste se vaya
## antes que la sacudida: primero el impacto deforma, después el cuerpo se sigue
## tambaleando ya recuperada la forma.
##
## Está aparte de `_pose_de_dolor()` porque `_raiz.scale` tiene otro escritor —el
## estirón del amago— y se componen multiplicando. Ver `animar()`.
func _aplaste(d: float) -> Vector3:
	var ap := d * d
	return Vector3(1.0 + ap * 0.16, 1.0 - ap * 0.17, 1.0 + ap * 0.16)


# ── El destello del impacto: 4 cuadros ──────────────────────────────────────
#
# Un fogonazo blanco encima de todo el cuerpo. Es lo más legible que hay a esta
# distancia porque no depende del tamaño de nada: la mancha entera cambia de
# valor un instante, y eso se ve igual a 12 m que a 68.
#
# Va como `material_overlay` y ADITIVO: no reemplaza el material —que trae la
# identidad del personaje, el color de la ropa, el oficio— sino que le suma
# luz encima. Se apaga poniendo el overlay en null, así que no deja rastro.

const DOLOR_DURA := 10.0 / 60.0   ## 10 cuadros: 5 de deformación, 5 de temblor
const DESTELLO_DESDE := 0.6       ## se apaga cuando `d` baja de acá: 4 cuadros


func _fundir_destello(d: float) -> void:
	var a := clampf((d - DESTELLO_DESDE) / (1.0 - DESTELLO_DESDE), 0.0, 1.0)
	if a <= 0.0:
		_apagar_destello()
		return
	if _destello == null:
		_destello = StandardMaterial3D.new()
		_destello.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_destello.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_destello.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	# El brillo va en el RGB y no en el alfa: con mezcla aditiva sumar un color
	# oscuro es no sumar nada, y así el desvanecido no depende de cómo el motor
	# interprete el alfa en modo aditivo.
	_destello.albedo_color = Color(a, a * 0.92, a * 0.80, 1.0)
	if _mallas.is_empty():
		_juntar_mallas(_raiz)
	for m in _mallas:
		if is_instance_valid(m) and m.material_overlay != _destello:
			m.material_overlay = _destello
	_destello_puesto = true


func _apagar_destello() -> void:
	for m in _mallas:
		if is_instance_valid(m) and m.material_overlay != null:
			m.material_overlay = null
	_destello_puesto = false


func _juntar_mallas(n: Node) -> void:
	for h in n.get_children():
		if h is MeshInstance3D:
			_mallas.append(h as MeshInstance3D)
		_juntar_mallas(h)


# ---------------------------------------------------------------------------
# Los gestos: el cuerpo participa de las cosas sociales
# ---------------------------------------------------------------------------
#
# *"si le doy algo que haya gestos, detalles, movimientos, falta todo"*. Hasta
# acá el cuerpo sabía caminar, pegar, dolerse, agacharse y sostener algo — o
# sea, todo lo que se hace SOLO. Las cosas que se hacen con otro, que son la
# mitad de este juego, no movían un músculo: regalar era un botón y un renglón
# de texto.
#
# ## La tabla de cuadros
#
# La tabla del GOLPE está en `impacto.gd` y no se toca. Ésta es la de los
# gestos, y vive acá porque `impacto.gd` es sobre choques y esto no lo es.
#
# | gesto      | cuadros | reparto                                          |
# |------------|---------|--------------------------------------------------|
# | dar        |   44    | 8 recoger · 10 extender · 16 SOSTENER · 10 volver |
# | recibir    |   30    | 6 sobresalto · 8 recoger contra el pecho · 16 volver |
# | enseñar    |   54    | tres ciclos de 18: mostrar, bajar, mostrar        |
# | conversar  |  sostenido, mientras el servidor diga que hay charla |
#
# **Los 16 cuadros de sostén de `dar` son el gesto.** Un brazo que se estira y
# vuelve en el mismo movimiento se lee como un tic; uno que se estira y SE
# QUEDA ahí un cuarto de segundo se lee como una oferta esperando respuesta. Es
# la misma razón por la que el amago del bicho tiene 14 cuadros quieto.
#
# ## Qué se mueve, y por qué no es el brazo
#
# Vale la misma aritmética que arrastró al amago a rehacerse: **en este cuerpo
# el brazo mide 43 cm y no puede asomar por encima de la cabeza**, así que un
# gesto de brazo no cambia la silueta y a 40 m no existe. Lo que sí cambia la
# silueta es el TRONCO:
#
#   · dar      → el cuerpo se inclina 23° HACIA EL OTRO. Dos cuerpos, uno
#                inclinado hacia el otro, es la imagen de dar. El brazo
#                extendido es el detalle de cerca, no la lectura de lejos.
#   · recibir  → primero se echa atrás (sobresalto) y después se inclina
#                adelante (agradecer). Es un balanceo entero, no una mano.
#   · enseñar  → el tronco gira hacia el aprendiz y vuelve, tres veces. El
#                brazo abierto ensancha, que es el otro eje que sí se lee.
#   · conversar→ **orientarse.** Es el más barato y el más fuerte de los
#                cuatro: dos figuras mirándose se leen como dos personas
#                hablando, y dos figuras mirando al mismo lado se leen como dos
#                maniquíes en el mismo metro cuadrado. Eso es literalmente el
#                reclamo, y se arregla con un ángulo.
#
# ## Lo que este bloque NO hace
#
# **No inventa un regalo ni una enseñanza.** Igual que el golpe: acá sólo está
# cómo se dobla un cuerpo. Que haya habido un regalo lo dice el servidor —los
# eventos `regalo`, `ensenanza` y `conversacion` ya existen— y quien los
# escucha es `valle.gd`. Si nadie llama a estas funciones, no pasa nada, que es
# exactamente lo que tiene que pasar cuando el mundo no dijo que pasó.

enum Gesto { NINGUNO, DAR, RECIBIR, ENSENAR }

const GESTO_DAR := 44.0 / 60.0
const GESTO_DAR_RECOGE := 8.0 / 60.0
const GESTO_DAR_EXTIENDE := 18.0 / 60.0   ## fin de la extensión (8 + 10)
const GESTO_DAR_SOSTIENE := 34.0 / 60.0   ## fin del sostén (18 + 16)

const GESTO_RECIBIR := 30.0 / 60.0
const GESTO_RECIBIR_SUSTO := 6.0 / 60.0
const GESTO_RECIBIR_RECOGE := 14.0 / 60.0

const GESTO_ENSENAR := 54.0 / 60.0
const GESTO_ENSENAR_CICLO := 18.0 / 60.0


## Ofrecer algo. Un solo tiro de 44 cuadros. Lo dispara el evento `regalo` del
## servidor, del lado del que da.
func dar() -> void:
	_gesto = Gesto.DAR
	_gesto_reloj = 0.0


## Acusar que te dieron algo. 30 cuadros. Lo dispara el mismo evento `regalo`,
## del lado del que recibe. **Sin esto un regalo es una transacción**: uno
## estira el brazo y el otro no se entera.
func recibir_regalo() -> void:
	_gesto = Gesto.RECIBIR
	_gesto_reloj = 0.0


## Mostrar cómo se hace. 54 cuadros, tres veces. Lo dispara `ensenanza`, del
## lado del que enseña — que es la operación central del juego y hasta ahora no
## se veía nada.
func ensenar() -> void:
	_gesto = Gesto.ENSENAR
	_gesto_reloj = 0.0


## Estar conversando. `yaw_local` es el ángulo hacia el otro **en el espacio de
## esta figura**: `atan2(d.x, d.z)` menos la rotación que ya tenga el cuerpo.
## Se pasa cada vez que se llama; con 0.0 el cuerpo no se orienta y sólo hace el
## movimiento de estar hablando.
func conversar(prendido: bool, yaw_local := 0.0) -> void:
	_charlando = prendido
	if prendido:
		_charla_yaw = clampf(yaw_local, -1.2, 1.2)


## Avanza los relojes y aplica la pose. Se llama desde `animar()` y, para los
## que no tienen quien se los anime —los NPC del valle, que son justamente los
## que conversan y reciben regalos—, desde `_process()`.
func _gestos(dt: float) -> void:
	# La charla primero: es el estado, y el gesto de una vez se suma encima.
	_charla_suave = lerp(_charla_suave, 1.0 if _charlando else 0.0, 5.0 * dt)
	if _charla_suave > 0.01:
		_pose_de_charla(_charla_suave)

	if _gesto == Gesto.NINGUNO:
		return
	_gesto_reloj += dt
	match _gesto:
		Gesto.DAR:
			if _gesto_reloj >= GESTO_DAR:
				_soltar_gesto()
			else:
				_pose_de_dar(_gesto_reloj)
		Gesto.RECIBIR:
			if _gesto_reloj >= GESTO_RECIBIR:
				_soltar_gesto()
			else:
				_pose_de_recibir(_gesto_reloj)
		Gesto.ENSENAR:
			if _gesto_reloj >= GESTO_ENSENAR:
				_soltar_gesto()
			else:
				_pose_de_ensenar(_gesto_reloj)


## El gesto terminó. **Los ejes `z` de los brazos hay que apagarlos a mano**: no
## los asienta nadie más, así que el último valor escrito se queda puesto para
## siempre. Los `x` no hacen falta —los repone `animar()` o el reset de
## `_process()`— pero se apagan igual, que es más barato que acordarse de cuál
## era cuál.
func _soltar_gesto() -> void:
	_gesto = Gesto.NINGUNO
	_gesto_reloj = 0.0
	_brazo_i.rotation.z = 0.0
	_brazo_d.rotation.z = 0.0


## Ofrecer. `e` son los segundos desde que empezó.
func _pose_de_dar(e: float) -> void:
	var inclina := 0.0    # cuánto se dobla el tronco hacia el otro
	var brazo := 0.0      # 0 colgando, 1 extendido al frente
	if e < GESTO_DAR_RECOGE:
		# Recoger: el cuerpo se echa un poco atrás y junta el brazo. Es el mismo
		# anticipo del golpe y por el mismo motivo — sin él, el brazo aparece.
		var u := e / GESTO_DAR_RECOGE
		inclina = -0.12 * sin(u * PI * 0.5)
		brazo = 0.18 * u
	elif e < GESTO_DAR_EXTIENDE:
		var u := (e - GESTO_DAR_RECOGE) / (GESTO_DAR_EXTIENDE - GESTO_DAR_RECOGE)
		var p := u * u * (3.0 - 2.0 * u)
		inclina = lerpf(-0.12, 0.40, p)
		brazo = lerpf(0.18, 1.0, p)
	elif e < GESTO_DAR_SOSTIENE:
		# El sostén. Quieto: es el cuadro en que el otro tiene que ver la oferta.
		inclina = 0.40
		brazo = 1.0
	else:
		var u := clampf((e - GESTO_DAR_SOSTIENE) / (GESTO_DAR - GESTO_DAR_SOSTIENE),
			0.0, 1.0)
		var k := 1.0 - u * u * (3.0 - 2.0 * u)
		inclina = 0.40 * k
		brazo = k

	_torso.rotation.x += inclina
	# La cabeza acompaña la mitad: mirar lo que ofrecés es la mitad de ofrecerlo.
	_cabeza.rotation.x += inclina * 0.45
	# El brazo derecho al frente. Negativo es adelante en este esqueleto (ver
	# `_pose_de_amago`), y el 0,22 de `rotation.z` lo saca del eje del tronco
	# para que no quede escondido detrás del cuerpo visto de costado.
	_brazo_d.rotation.x = lerpf(_brazo_d.rotation.x, -1.30, brazo)
	_brazo_d.rotation.z = 0.22 * brazo
	# Y lo que llevás en la mano va colgado del brazo derecho, así que un regalo
	# que tenés puesto se extiende solo. No hay que hacer nada más.


## Acusar el regalo: sobresalto y después agradecer.
func _pose_de_recibir(e: float) -> void:
	var inclina := 0.0
	var brazos := 0.0
	if e < GESTO_RECIBIR_SUSTO:
		var u := e / GESTO_RECIBIR_SUSTO
		inclina = -0.20 * sin(u * PI * 0.5)
		brazos = u * 0.5
	elif e < GESTO_RECIBIR_RECOGE:
		var u := (e - GESTO_RECIBIR_SUSTO) / (GESTO_RECIBIR_RECOGE - GESTO_RECIBIR_SUSTO)
		var p := u * u * (3.0 - 2.0 * u)
		inclina = lerpf(-0.20, 0.26, p)
		brazos = lerpf(0.5, 1.0, p)
	else:
		var u := clampf((e - GESTO_RECIBIR_RECOGE) / (GESTO_RECIBIR - GESTO_RECIBIR_RECOGE),
			0.0, 1.0)
		var k := 1.0 - u * u * (3.0 - 2.0 * u)
		inclina = 0.26 * k
		brazos = k

	_torso.rotation.x += inclina
	# La cabeza baja MÁS que el tronco: es lo que convierte la inclinación en un
	# agradecimiento y no en un tropezón.
	_cabeza.rotation.x += inclina * 1.3
	# Las dos manos contra el pecho. Los dos brazos y no uno: dos es recibir,
	# uno es señalar.
	_brazo_i.rotation.x = lerpf(_brazo_i.rotation.x, -1.05, brazos)
	_brazo_d.rotation.x = lerpf(_brazo_d.rotation.x, -1.05, brazos)
	_brazo_i.rotation.z = 0.30 * brazos
	_brazo_d.rotation.z = -0.30 * brazos


## Mostrar cómo se hace, tres veces. El tronco gira hacia el aprendiz y vuelve,
## y el brazo abierto se levanta con cada vuelta.
func _pose_de_ensenar(e: float) -> void:
	# Entrada y salida suaves para que los tres ciclos no arranquen ni corten en
	# seco: 6 cuadros de cada lado.
	var borde: float = minf(minf(e, GESTO_ENSENAR - e) / (6.0 / 60.0), 1.0)
	var u := e / GESTO_ENSENAR_CICLO
	var onda := sin(u * TAU)
	_torso.rotation.y += 0.26 * onda * borde
	# El brazo se abre al costado —eso es lo que ensancha la silueta— y sube y
	# baja con el ciclo.
	var alza: float = (0.5 - cos(u * TAU) * 0.5) * borde
	# **`rotation.z` se ASIGNA, no se interpola desde lo que había.** Nadie más
	# pone una base en ese eje, así que un `lerp(actual, objetivo, alza)` con
	# `alza` bajando a cero no vuelve: se queda clavado en el objetivo. Medido:
	# al terminar los 54 cuadros el brazo seguía abierto y la silueta quedaba en
	# 34,7 px de ancho en vez de los 25,0 de un cuerpo parado, para siempre.
	_brazo_d.rotation.z = 1.05 * alza
	_brazo_d.rotation.x = lerpf(_brazo_d.rotation.x, -0.55, alza)
	# La cabeza cuelga del torso, así que el giro del tronco ya se la lleva. Un
	# `+=` propio acá sólo agregaría un segundo escritor a un eje que es de
	# `_process()` y de la charla.
	# Un cabeceo por ciclo, al final de cada muestra: el "¿se entiende?".
	_cabeza.rotation.x += 0.12 * maxf(0.0, -cos(u * TAU * 2.0)) * borde


## Estar conversando. `f` es 0..1 y entra y sale suave.
##
## **Lo que hace el trabajo acá es la primera línea.** Orientar el cuerpo hacia
## el otro es lo que separa "dos personas hablando" de "dos maniquíes en el
## mismo metro cuadrado", y a 40 m se lee antes que cualquier otra cosa que
## pudiéramos animar.
func _pose_de_charla(f: float) -> void:
	_torso.rotation.y += _charla_yaw * f
	# La cabeza mira un poco más que el tronco, que es como mira la gente.
	_cabeza.rotation.y = _charla_yaw * 0.35 * f
	# Asentir. Va con dos frecuencias que no encajan y con una envolvente que
	# también, así que asiente a ratos en vez de todo el tiempo: hablar sin
	# parar de cabecear se lee como un muñeco de auto.
	var gana: float = maxf(0.0, sin(_reloj * 0.37 + _fase_mira))
	_cabeza.rotation.x += sin(_reloj * 2.6 + _fase_resp) * 0.10 * gana * f
	# Cambiar el peso de pie. Es lento y chico y es lo que hace que alguien
	# parado hablando no parezca clavado al piso.
	_torso.rotation.z += sin(_reloj * 0.47 + _fase_resp) * 0.045 * f


# ---------------------------------------------------------------------------
# El amago: el cuerpo avisa que va a pegar
# ---------------------------------------------------------------------------
#
# *"me ataca el monstruo sin decirme nada"*. Los 5 cuadros de anticipo del swing
# no alcanzan para eso y no están para eso: el anticipo hace que el golpe se lea
# como un golpe, no que se pueda ver venir. **83 ms no es un aviso**, es el
# tiempo que tarda una persona en pestañear una vez y media.
#
# Esto son 24 cuadros —400 ms— y el criterio de qué se mueve es el mismo que el
# del swing: **a 40 m no hay brazos, hay silueta**.
#
# ## La primera versión de esta pose NO SERVÍA, y lo dijo la medición
#
# Estaba escrita como se escribe siempre un encabritamiento: subir, echarse
# para atrás, los brazos arriba. Medida contra una cámara de 40 m con FOV 42° a
# 900p, la silueta pasaba de **43,0 x 24,9 px a 41,7 x 24,5 px**: el cuerpo se
# hacía MÁS CHICO. Es el mismo error que ya se había cometido con el swing —
# *"no mueve los brazos"* con el brazo a 114°— y por la misma razón, así que
# vale dejar la aritmética escrita para que no vuelva a pasar una tercera vez:
#
#   · el brazo mide `_alto * 0.30` = 43 cm y cuelga de un hombro a 99 cm
#   · o sea que con el brazo VERTICAL la mano llega a 1,42 m
#   · y la coronilla ya está en 1,42 m
#
# **En este cuerpo los brazos no pueden asomar por encima de la cabeza. Levantar
# los brazos no cambia la silueta, nunca, hagas lo que hagas.** Y encima
# echarse para atrás BAJA la coronilla, así que la pose "obvia" resta.
#
# ## Lo que sí cambia la silueta acá es el ANCHO
#
# Con los brazos abiertos al costado la mano llega a `0,34 + 0,43 = 77 cm` del
# eje: **1,55 m de ancho contra los 0,85 m del cuerpo con los brazos colgando.**
# Casi el doble, y eso son veinte píxeles a 40 m. Por eso esta pose es en cruz y
# no en Y:
#
#   · los brazos se abren 77° al costado  → el ancho casi se duplica
#   · las piernas se abren                → y la base se planta
#   · el cuerpo se estira un 11% en Y     → gana los píxeles de alto que el
#     (`_raiz.scale`, ver `animar()`)        echarse para atrás le sacaba
#   · sube 9 cm y se echa 10°             → poco: son los que pagan el resto
#
# La lectura que queda es "el bicho se abrió", que además es lo que hace un
# animal antes de tirarse encima. La pose correcta era también la barata.

func _correr_amago(dt: float) -> void:
	if _amago_on:
		if _amago < 1.0:
			_amago = minf(1.0, _amago + dt / Impacto.AMAGO_ALZA)
	elif _amago > 0.0:
		_amago = maxf(0.0, _amago - dt / Impacto.AMAGO_SUELTA)


## `a` va de 0 a 1. Todo lo de acá es `+=` o `lerp` desde lo que dejó la
## caminata: el bicho puede estar frenando cuando se encabrita.
func _pose_de_amago(a: float) -> void:
	# `a*a` en la subida y `a` en el resto: el cuerpo empieza a abrirse despacio
	# y termina de golpe, que es como se carga algo con peso. Al revés se ve como
	# un globo inflándose.
	var s := a * a
	_torso.position.y += _alto * 0.062 * s
	_torso.rotation.x -= 0.18 * a

	# **El ancho, que es todo el efecto.** 1,35 rad son 77°: abiertos del todo la
	# silueta casi se duplica. Los dos brazos y no uno — un brazo es la pose de
	# pegar, dos son la pose de estar por pegar.
	#
	# `rotation.z` de los miembros no lo escribe nadie más, así que se asigna y
	# vuelve solo a cero cuando `a` baja. `rotation.x` sí lo escriben la caminata
	# y el swing, así que ahí se interpola desde lo que dejaron: es lo que hace
	# que los 4 cuadros de suelta entren al golpe sin un salto. Ver `animar()`.
	#
	# **El signo importa y no es el que parece.** `_brazo_i` cuelga en x
	# negativo, así que para ABRIRLO hacia afuera su `rotation.z` va negativo.
	# Con los signos al revés —que fue como salió la primera vez— los dos brazos
	# se cruzan por delante del pecho y el ancho medido BAJA de 24,8 a 20,3 px:
	# el bicho se encoge justo cuando tenía que abrirse.
	_brazo_i.rotation.z = -1.35 * a
	_brazo_d.rotation.z = 1.35 * a
	_brazo_i.rotation.x = lerpf(_brazo_i.rotation.x, -0.85, a)
	_brazo_d.rotation.x = lerpf(_brazo_d.rotation.x, -0.85, a)

	# La base. Un cuerpo que se va a tirar encima planta los pies, y de paso
	# ensancha abajo lo que los brazos ensanchan arriba: sin esto la silueta
	# queda con forma de T y se lee como un espantapájaros.
	_pierna_i.rotation.z = -0.30 * a
	_pierna_d.rotation.z = 0.30 * a
	_cabeza.rotation.x += 0.22 * a


## Encabritarse (`true`) o deshacer la pose (`false`). El que decide cuándo es
## `monstruo.gd`, que es el que sabe si el jugador sigue al alcance.
func amagar(prendido: bool) -> void:
	_amago_on = prendido


# ---------------------------------------------------------------------------
# Maltrecho: el cuerpo se entera de que la vida bajó
# ---------------------------------------------------------------------------
#
# *"la vida baja en un número y el cuerpo no se entera."* Esto es la mitad de la
# respuesta —la otra mitad es la velocidad, y esa vive en `monstruo.gd`—, y son
# dos cosas: **una postura que se queda** y **un tambaleo que no para**.
#
# El tambaleo es el que hace el trabajo y por un motivo que vale escribir: a 40
# m, 17 cm de vaivén son cuatro píxeles, o sea nada **por cuadro**. Pero no se
# lee por cuadro. Un contorno que va y viene con período de 44 cuadros se lee
# como un cuerpo que no se puede sostener, y eso se ve de lejos igual que se ve
# de cerca, porque lo que se está leyendo es el MOVIMIENTO, no el tamaño.

func _pose_de_maltrecho(f: float) -> void:
	# Se encorva hacia adelante y se hunde. Es lo contrario exacto del amago, y
	# está bien que lo sea: uno es un cuerpo que puede y el otro uno que no.
	_torso.rotation.x += 0.34 * f
	_torso.position.y -= _alto * 0.055 * f
	_cabeza.rotation.x += 0.26 * f
	# Los brazos cuelgan. Sólo hasta la mitad: si se anulara del todo la
	# caminata, un bicho herido caminaría con los brazos clavados y se leería
	# como un bug de animación, no como cansancio.
	_brazo_i.rotation.x = lerpf(_brazo_i.rotation.x, 0.30, f * 0.55)
	_brazo_d.rotation.x = lerpf(_brazo_d.rotation.x, 0.30, f * 0.55)
	# El escoramiento del tambaleo. Va desfasado 1,1 rad del vaivén lateral: si
	# fueran en fase el cuerpo se movería en bloque y se leería como que el mundo
	# se inclina; desfasados, el cuerpo se cae hacia un lado y se recupera.
	_torso.rotation.z += sin(_reloj * TAU * Impacto.TAMBALEO_HZ + 1.1) * 0.20 * f


func _tambaleo(f: float) -> float:
	return sin(_reloj * TAU * Impacto.TAMBALEO_HZ) * Impacto.TAMBALEO_AMP * f


## Lo maltrecho que está: 0 entero, 1 en las últimas. Lo calcula `monstruo.gd`
## contra la vida que manda el SERVIDOR — acá no se decide ninguna vida, sólo
## cómo se para un cuerpo al que ya le bajaron la que tenía.
func maltratar(f: float) -> void:
	_maltrecho = clampf(f, 0.0, 1.0)


## Arranca el swing. 23 cuadros: 5 de anticipo, 8 de embate, 10 de recuperación.
## El contacto —el cuadro en que quien pega tiene que pintar la pausa, la
## sacudida y la chispa— es el cuadro 5, `Impacto.CONTACTO`.
##
## **Y acá sale el zumbido del aire**, que es la única cosa que distingue un
## golpe que erró de uno que no antes de leer un cartel: errar suena a aire
## solo, acertar suena a aire con el impacto encima 5 cuadros después. El pico
## del zumbido está puesto justo en ese cuadro 5 (ver `Impacto._zumbido`), así
## que sale de acá y no de un temporizador.
func atacar() -> void:
	_golpe = Impacto.SWING_TOTAL
	Impacto.zumbar(self)


## Lo que llevás en la mano.
##
## Hacía falta porque forjar una hoja y que viva en una lista de texto es
## exactamente el problema de fondo del juego: sistemas que existen y el
## jugador no puede ver. Si la hiciste vos, tiene que estar en tu mano, y tiene
## que verse cuando pegás.
##
## No es un modelo: es una caja alargada del color que le toque. A cuarenta
## metros lo que se lee es que TENÉS algo, no qué es — y esa diferencia entre
## manos vacías y manos con algo es toda la información que el jugador
## necesita a esta distancia.
func empunar(cosa: String) -> void:
	if _arma != null:
		_arma.queue_free()
		_arma = null
	if cosa == "":
		return

	var largo := 0.95
	var color := Color(0.62, 0.64, 0.68)   # acero
	if cosa.begins_with("frasco"):
		largo = 0.22
		color = Color(0.42, 0.56, 0.38)
	elif cosa.begins_with("mapa"):
		largo = 0.30
		color = Color(0.78, 0.72, 0.56)

	var m := BoxMesh.new()
	m.size = Vector3(0.07, largo, 0.07)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = 0.35 if largo > 0.5 else 0.0
	m.material = mat

	# El arma también destella cuando te pegan: es parte de la mancha del
	# cuerpo. La caché de mallas se rehace sola en el próximo destello.
	_mallas.clear()

	_arma = MeshInstance3D.new()
	_arma.mesh = m
	# Colgando de la mano: al final del brazo derecho, apuntando adelante y
	# abajo, que es como se lleva algo caminando.
	_arma.position = Vector3(0.0, -altura * 0.30, 0.04)
	_arma.rotation = Vector3(deg_to_rad(-24.0), 0.0, deg_to_rad(8.0))
	_brazo_d.add_child(_arma)


## Agacharse a juntar algo. Dura lo que dura el pedido al servidor.
##
## Existe porque apretar B y leer "buscando…" no es una acción: es un cartel.
## Que el cuerpo se agache y estire la mano es lo que convierte una llamada
## HTTP en algo que pasó en el mundo.
func juntar(prendido: bool) -> void:
	_juntando = prendido


## El respingo. 10 cuadros. Ver `_pose_de_dolor()` para qué se mueve y cuánto.
func doler() -> void:
	_dolor = 1.0
	# Un pestañeo al recibir el golpe. Es un cuadro y medio y se siente el
	# impacto en la cara, no sólo en el cuerpo.
	_cierre = 1.0
	_espera_parpadeo = randf_range(0.8, 2.0)


## Se desarma hacia adelante. Sin ragdoll: una caída bien temporizada alcanza.
func caer() -> void:
	_vivo = false
	# Si lo mataste con el destello prendido, el cuerpo se queda en el piso
	# brillando para siempre: `animar()` ya no va a volver a pasar por acá.
	_apagar_destello()
	# Lo mismo con el amago y con lo maltrecho. Un cadáver con los brazos
	# levantados y tambaleándose en el piso es de las cosas que más rompen la
	# escena, y pasa porque `animar()` deja de llamarse justo cuando el cuerpo
	# está en mitad de una pose. Se apagan acá, que es el único cuadro que queda.
	_amago_on = false
	_amago = 0.0
	_maltrecho = 0.0
	for m: Node3D in [_brazo_i, _brazo_d, _pierna_i, _pierna_d]:
		if m != null:
			m.rotation.z = 0.0
	_raiz.position.x = 0.0
	_raiz.scale = Vector3.ONE
	if _ojo_i != null:
		# Los ojos se cierran y se quedan cerrados. Es lo único que hace falta
		# para que el cuerpo en el piso lea como cuerpo y no como muñeco tirado.
		_ojo_i.scale.y = OJO_CERRADO
		_ojo_d.scale.y = OJO_CERRADO
	var t := create_tween().set_parallel(true)
	t.tween_property(_raiz, "rotation:x", -PI / 2.0 + 0.15, 0.55) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(_raiz, "position:y", -0.35, 0.55)
	t.tween_property(_brazo_i, "rotation:x", 1.2, 0.4)
	t.tween_property(_brazo_d, "rotation:x", 0.9, 0.4)

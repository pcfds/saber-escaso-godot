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
## Segundos que le quedan al respingo de dolor, normalizado 1→0 sobre
## `DOLOR_DURA`. Ver `doler()`.
var _dolor := 0.0
## Las mallas del cuerpo, para el destello blanco del cuadro del impacto. Se
## juntan una sola vez (recursivo) y se invalidan al reconstruir o al equipar.
var _mallas: Array[MeshInstance3D] = []
var _destello: StandardMaterial3D
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
		_cabeza.rotation.y = (sin(_reloj * 0.31 + _fase_mira) * 0.30
			+ sin(_reloj * 0.13 + _fase_mira * 2.0) * 0.16) * quieto

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
func animar(dt: float, velocidad: float, en_piso: bool) -> void:
	if _torso == null:
		return

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

	if _golpe > 0.0:
		_golpe = maxf(0.0, _golpe - dt)
		_pose_de_golpe(Impacto.SWING_TOTAL - _golpe)
		if _golpe <= 0.0:
			# La curva llega a cero sola, pero dejarla clavada en cero exacto
			# evita que un resto de 0,001 rad se quede peleando con `_process`.
			_torso.rotation.y = 0.0

	if _dolor > 0.0:
		_dolor = maxf(0.0, _dolor - dt / DOLOR_DURA)
		_pose_de_dolor(_dolor)
	elif _raiz.position.x != 0.0 or _raiz.scale != Vector3.ONE:
		_raiz.position.x = 0.0
		_raiz.scale = Vector3.ONE
		_apagar_destello()


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
func _pose_de_dolor(d: float) -> void:
	# Sacudida lateral: 19 cm y DOS vueltas enteras en los 10 cuadros.
	#
	# La fase se saca de lo TRANSCURRIDO (`1 - d`) y no de `d * 62`, que es como
	# estaba. Con `d * 62` el argumento del seno bajaba 6,2 rad por cuadro —una
	# vuelta y pico— así que el seno se muestreaba casi en la misma fase todos
	# los cuadros y **no oscilaba**: medido, la sacudida salía de -11,6 cm y
	# volvía a cero sin cruzar el cero ni una vez. Era un desplazamiento, no un
	# temblor. `TAU * 2` deja las dos vueltas escritas y a prueba de aliasing.
	_raiz.position.x = sin((1.0 - d) * TAU * 2.0) * d * 0.19
	# El tronco se dobla 46° hacia atrás. Es EL cambio de silueta del respingo.
	_torso.rotation.x -= d * 0.80
	# Y el cuerpo entero se aplasta y se ensancha. `d*d` hace que el aplaste se
	# vaya antes que la sacudida: primero el impacto deforma, después el cuerpo
	# se sigue tambaleando ya recuperada la forma.
	var ap := d * d
	_raiz.scale = Vector3(1.0 + ap * 0.16, 1.0 - ap * 0.17, 1.0 + ap * 0.16)
	_fundir_destello(d)


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


func _apagar_destello() -> void:
	for m in _mallas:
		if is_instance_valid(m) and m.material_overlay != null:
			m.material_overlay = null


func _juntar_mallas(n: Node) -> void:
	for h in n.get_children():
		if h is MeshInstance3D:
			_mallas.append(h as MeshInstance3D)
		_juntar_mallas(h)


## Arranca el swing. 23 cuadros: 5 de anticipo, 8 de embate, 10 de recuperación.
## El contacto —el cuadro en que quien pega tiene que pintar la pausa, la
## sacudida y la chispa— es el cuadro 5, `Impacto.CONTACTO`.
func atacar() -> void:
	_golpe = Impacto.SWING_TOTAL


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

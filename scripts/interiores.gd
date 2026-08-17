## Lo que hay adentro de las casas, y lo que hace falta para poder entrar.
##
## ===========================================================================
## PARA QUÉ EXISTE UN INTERIOR
##
## `CLAUDE.md` manda: *todo tiene vida o tiene algún sentido; antes de agregar
## algo a la escena, decí qué significa.* Un cuarto que sólo se puede mirar no
## pasa esa prueba. Éstas son las tres cosas que un interior deja hacer y afuera
## no se podían, y las tres son verificables:
##
##  1. **Adentro está la persona que el servidor dice que está.** La rutina del
##     valle ya manda a la gente a su casa al anochecer —`rutinaDe()` en el
##     servidor, `home_place_id` en la base— y hasta hoy eso era invisible: se
##     plantaban afuera igual, a la intemperie, con la ventana encendida
##     mintiendo. Ahora la ventana encendida **es cierta**: entrás y está.
##  2. **El oficio tiene un lugar donde pasa.** El cuarto de la herrera tiene el
##     yunque, el martillo y la piedra; el de la destiladora, el fuego, la olla
##     y los frascos. No es decoración: es el `trade` que ya viaja en `/mundo`,
##     dibujado. Un oficio que no tiene dónde no es un oficio, es un renglón.
##  3. **Es el único sitio del valle donde parar no es perder el tiempo.** Hay
##     un fuego, una banqueta y techo. El resto del valle es tránsito.
##
## Y una cosa que NO hace falta y conviene dejar escrita para que nadie la
## agregue: **entrar no es un verbo.** El interior está en el mismo `place` que
## la casa, `/estoy` ya reporta el lugar y las casas caen a doce metros del
## centro, muy adentro del radio de `ENTRAR`. No hay endpoint nuevo, no hay
## estado nuevo, y el invariante 4 se cumple sin escribir una línea de red.
##
## ===========================================================================
## UNA SOLA ESCENA, PARAMETRIZADA
##
## No hay —y no puede haber— una escena por casa. El valle crece por el norte y
## va a haber más casas; doce escenas hoy son cuarenta mañana y ninguna se
## actualiza cuando cambie el kit. Acá hay **un solo cuarto** y lo que lo
## distingue sale de los datos del servidor: quién vive ahí y de qué trabaja.
##
## El amoblado se parte en dos por eso mismo:
##
##   · `amueblar()` corre al construir el valle y pone lo que tiene toda casa
##     —hogar, leña, banqueta, cama, arcón, mesa—, que no depende de nadie.
##   · `habitar()` corre cuando llega `/mundo` y cuelga las herramientas del
##     oficio. Es lo único que se rehace si el que vive ahí cambia, y se rehace
##     entero: un nodo que se libera y se vuelve a armar, no un diff.
##
## ===========================================================================
## EL RECORTE
##
## La cámara vive a doce metros como mínimo (`Jugador.DIST_MIN`) y a 38° de
## inclinación. Un cuarto de 4,86 m con techo es, desde ahí, una caja cerrada:
## sin recorte, entrar a una casa es mirar tejas.
##
## Así que cuando estás adentro se le sacan a ESA casa el techo, la planta alta,
## la chimenea y los muros de abajo que la cámara tiene delante. No se ocultan:
## pasan a `SHADOWS_ONLY`, o sea que **siguen proyectando sombra**. La diferencia
## no es un detalle: apagarlos del todo llenaría el cuarto de sol y el interior
## dejaría de leerse como interior. Con la sombra puesta, lo único que ilumina
## adentro es el fuego — que es exactamente el argumento de esta rama y la regla
## de la casa (*la luz hace el trabajo, no los polígonos*).
##
## Es un recorte LOCAL: nadie más ve tu casa abierta, igual que en cualquier
## juego con esta cámara. No toca el servidor y no toca a los otros jugadores.
class_name Interiores
extends Node

## Hasta dónde se enciende el hogar de una casa, y cuántos a la vez.
##
## Son luces con sombra —sin sombra, un omni adentro de una caja de muros de 27
## cm se filtra y la casa entera queda con un halo de luciérnaga gigante— y una
## luz con sombra cuesta seis caras de mapa. Doce prendidas todo el tiempo no,
## las dos más cercanas sí: el resto está adentro de una caja cerrada y no se ve.
const LUZ_CERCA := 17.0
const LUZ_CUANTAS := 2

## Cuánta luz da un hogar. Es un fuego chico en un cuarto de cinco metros: con
## más, el cuarto se lava y deja de tener rincones, que es la mitad de lo que
## hace que un interior se sienta interior.
const LUZ_HOGAR := 5.2
const LUZ_ALCANCE := 8.0

## Cuánto tiene que estar la cámara del lado de afuera de un muro para que ese
## muro se apague. No es cero: con el umbral en cero, un muro que queda de
## costado entra y sale del recorte con el temblor de la cámara.
const RECORTE_MARGEN := 0.18


# ---------------------------------------------------------------------------
# LAS PUERTAS
# ---------------------------------------------------------------------------
#
# La hoja la construye `Detalles.casa()` —ver el bloque `LA PUERTA` de ese
# archivo, que es donde está el porqué— y quien la mueve es esto. Acá vive nada
# más que la regla: **cuándo se abre.**
#
# Y la regla es una sola con dos números: *una puerta se abre cuando vas hacia
# ella; de noche hay que llegar hasta la puerta.* De día se abre desde los
# escalones, o sea que la ves abrirse mientras subís; de noche no, y entonces
# hay que ir hasta el umbral y empujarla, más despacio. **No se traba nunca** —
# una puerta con llave es estado del mundo y el estado del mundo es del
# servidor (invariante 4). Lo que cambia de noche no es si podés entrar: es
# cuánto tenés que acercarte para que ceda.
#
# El radio de día es corto a propósito y por el mismo motivo por el que
# `puesto_cerca()` usa 2,2 m: con un radio grande, cruzar la plaza abre cuatro
# puertas de una y la aldea se lee como un supermercado. A 2,6 m del hueco ya
# estás en los escalones de ESA casa.

## Cuánto gira la hoja al abrirse, en radianes. 92°: pasado el ángulo recto, que
## es donde una puerta abierta de verdad se queda —contra la pared y no en el
## medio del paso.
const PUERTA_GIRO := 1.60
## A qué velocidad, en radianes por segundo. Da poco más de medio segundo de
## recorrido. **Una puerta tarda**: instantánea deja de ser una puerta y pasa a
## ser un cambio de estado.
const PUERTA_VEL := 2.8
## De día: desde dónde se abre sola. Ver arriba.
const PUERTA_CERCA := 2.6
## De noche: hasta dónde hay que llegar para empujarla.
const PUERTA_EMPUJE := 1.20
## Y cuánto se queda abierta después de que te fuiste. **Una puerta se queda
## abierta**: si se cerrara al instante sería una cortina de aire.
const PUERTA_QUEDA := 5.0
## Cuánto más lenta es de noche. La misma puerta, con el mismo gozne, pesa lo
## mismo — lo que cambia es que nadie la está esperando.
const PUERTA_NOCHE_VEL := 0.55


# ---------------------------------------------------------------------------
# EL CUARTO
# ---------------------------------------------------------------------------
#
# Todas las posiciones están en el marco de la casa, con la puerta en el frente
# (+Z) y del lado +X. Cuando a una casa le tocó la puerta del otro lado, el
# cuarto entero **se refleja en X** (`espejo` vale −1) y con eso solo la cama
# queda siempre en el rincón lejos de la puerta y el fuego siempre en el que da
# a la chimenea. Es una multiplicación y evita escribir dos plantas.
#
# El cuarto va de −2,43 a +2,43 en las dos direcciones (`Detalles.CASA_ADENTRO`)
# y de 2,56 a 3,10 de alto según qué altura de planta le tocó a esa casa.

## Dónde va el hogar. En el rincón del fondo, en diagonal a la puerta: es el
## punto más lejos de la corriente de aire y el que deja el cuarto entero entre
## el fuego y vos cuando entrás.
const HOGAR := Vector3(-1.45, 0.0, -1.45)

## Los sitios fijos del cuarto. Lo que tiene toda casa, viva quien viva.
const MUEBLES: Array = [
	# ruta                         pos                        giro   escala
	["naturaleza/log_stack",       Vector3(-2.00, 0, -0.30),  0.00,  1.70],
	["naturaleza/stump_round",     Vector3(-0.30, 0, -1.10),  0.60,  2.10],
	["utiles/bedroll",             Vector3(-1.80, 0,  1.30),  0.00,  3.10],
	["utiles/chest",               Vector3(-1.90, 0,  2.05),  0.00,  2.50],
	["utiles/workbench",           Vector3( 1.60, 0,  0.20), -0.45,  2.60],
]

## Y lo que queda de una casa que se quemó. La Casa Quemada ya es una mazmorra y
## no lo sabía: acá vivía Ren y con ella se fueron dos runas. Adentro no hay
## fuego, no hay cama y no hay luz — hay lo que nadie se llevó.
const MUEBLES_RUINA: Array = [
	["utiles/campfire-pit",        Vector3(-1.45, 0, -1.45),  0.00,  2.70],
	["utiles/chest",               Vector3( 1.70, 0, -1.60),  0.80,  2.50],
	["utiles/barrel",              Vector3(-1.95, 0,  0.90),  1.20,  2.40],
	["naturaleza/rock_smallB",     Vector3( 0.40, 0,  1.30),  2.10,  2.20],
]

## Qué se ve en el cuarto de cada oficio, en el mismo formato que `MUEBLES`.
##
## Se busca **por trozo de palabra y no por lista cerrada**, que es la misma
## lectura que hace `figura.gd` para vestirlos, y por el mismo motivo: el
## servidor manda `trade` en castellano y con género —"herrera", "cazadora",
## "chico del camino"—, así que el día que aparezca un "herrero" tiene que
## reconocerlo sin migrar nada.
##
## El rincón del oficio es el que da al fondo por el lado de la puerta: el que
## entra lo tiene de frente. Las tres piezas ocupan el banco (x 1,6 · z 0,2, con
## la tapa en 0,62), el rincón del fondo (x 1,7 · z −1,5) y el hueco entre los
## dos (x 0,45 · z −2,0).
const OFICIOS := {
	"herr": [
		["utiles/workbench-anvil",   Vector3( 1.70, 0.00, -1.50),  0.35, 2.40],
		["utiles/tool-hammer",       Vector3( 1.62, 0.72, -1.42),  0.90, 2.60],
		["utiles/resource-stone",    Vector3( 0.45, 0.00, -2.00), -0.60, 2.40]],
	"forj": [
		["utiles/workbench-anvil",   Vector3( 1.70, 0.00, -1.50),  0.35, 2.40],
		["utiles/tool-hammer",       Vector3( 1.62, 0.72, -1.42),  0.90, 2.60],
		["utiles/resource-stone",    Vector3( 0.45, 0.00, -2.00), -0.60, 2.40]],
	"aprendiz": [
		["utiles/workbench-grind",   Vector3( 1.72, 0.00, -1.45),  0.20, 2.40],
		["utiles/tool-hammer",       Vector3( 1.50, 0.62,  0.10),  1.30, 2.60],
		["utiles/resource-stone",    Vector3( 0.45, 0.00, -2.00), -0.60, 2.40]],
	"caz": [
		["utiles/tool-axe",          Vector3( 2.00, 0.00, -0.45),  0.30, 2.40],
		["naturaleza/crops_wheatStageB", Vector3( 0.45, 0.00, -2.00), 0.90, 1.20],
		["utiles/resource-wood",     Vector3( 1.55, 0.62,  0.25), -0.30, 2.40]],
	"dest": [
		["naturaleza/pot_large",     Vector3( 1.72, 0.00, -1.50),  0.40, 1.10],
		["utiles/bottle",            Vector3( 1.45, 0.62,  0.05),  0.00, 2.60],
		["utiles/barrel",            Vector3( 2.00, 0.00, -0.45),  0.70, 2.40]],
	"cocin": [
		["naturaleza/pot_large",     Vector3( 1.72, 0.00, -1.50),  0.40, 1.10],
		["utiles/bucket",            Vector3( 1.60, 0.62,  0.30),  0.00, 2.20],
		["utiles/barrel",            Vector3( 2.00, 0.00, -0.45),  0.70, 2.40]],
	"curan": [
		["utiles/bottle",            Vector3( 1.45, 0.62,  0.05),  0.00, 2.60],
		["naturaleza/mushroom_tan",  Vector3( 0.45, 0.00, -2.00),  1.40, 2.00],
		["utiles/box",               Vector3( 1.80, 0.00, -1.50),  0.25, 2.20]],
	"guard": [
		["utiles/box-large",         Vector3( 1.75, 0.00, -1.45),  0.20, 2.20],
		["utiles/tool-axe",          Vector3( 2.05, 0.00, -0.40),  0.30, 2.40],
		["utiles/box",               Vector3( 0.45, 0.00, -2.00), -0.40, 2.20]],
	"solda": [
		["utiles/box-large",         Vector3( 1.75, 0.00, -1.45),  0.20, 2.20],
		["utiles/tool-axe",          Vector3( 2.05, 0.00, -0.40),  0.30, 2.40],
		["utiles/box",               Vector3( 0.45, 0.00, -2.00), -0.40, 2.20]],
}

## El oficio que no está en la tabla igual tiene cosas. Una casa sin nada
## adentro es peor que una casa cerrada: dice que el juego se olvidó de ella.
const OFICIO_CUALQUIERA: Array = [
	["utiles/box",                   Vector3( 1.75, 0.00, -1.50),  0.25, 2.20],
	["utiles/barrel",                Vector3( 2.00, 0.00, -0.45),  0.70, 2.40],
	["utiles/bucket",                Vector3( 0.45, 0.00, -2.00),  0.00, 2.20]]

## Dónde se para el que está en su casa. Tres, por si comparten techo.
const ADENTRO_SITIOS: Array[Vector3] = [
	Vector3(-0.45, 0, -0.55),   # junto al fuego
	Vector3( 1.05, 0,  0.75),   # junto a la mesa
	Vector3(-1.55, 0,  0.55),   # a los pies de la cama
]


## Las casas del valle: clave -> lo que hay que saber de ella. La clave es
## `"<slug>/<índice>"`, que es como las nombra `valle.gd` al construirlas.
var _casas: Dictionary = {}
## En cuál estás parado ahora mismo. "" es afuera.
var _adentro := ""
## Qué muros de la planta baja están apagados, para no reescribir la propiedad
## de los ocho paneles en cada cuadro.
var _muros_fuera: Dictionary = {}
## El reloj del valle, para saber si es de noche. Es un HERMANO de este nodo
## —`valle.gd` cuelga los dos de la escena— y se busca una sola vez. Se busca en
## vez de recibirlo porque el cableado vive en `valle.gd`, que es de otra rama:
## esto anda hoy y sigue andando el día que alguien pase el ciclo por parámetro.
var _ciclo: Ciclo = null
var _ciclo_buscado := false


## Registra una casa recién construida y le pone el amoblado que no depende de
## nadie. `casa` es lo que devolvió `Detalles.casa()`.
func amueblar(clave: String, casa: Dictionary, quemada: bool,
		rng: RandomNumberGenerator) -> void:
	var g: Node3D = casa["nodo"]
	var puerta: Vector3 = casa["puerta"]
	# La puerta cae en x = +1,35 o en −1,35. El cuarto se escribe una vez, para
	# la primera, y para la otra se refleja.
	var espejo := 1.0 if puerta.x >= 0.0 else -1.0

	var cuarto := Node3D.new()
	cuarto.name = "Cuarto"
	cuarto.position.y = Detalles.CASA_PISO
	g.add_child(cuarto)

	for m: Array in (MUEBLES_RUINA if quemada else MUEBLES):
		var mueble := _poner(cuarto, m[0], m[1], m[2], m[3], espejo)
		# LA BANQUETA. Ya estaba puesta y no era nada: un tocón junto al fuego
		# que el juego no sabía que era un asiento. Marcarlo no agrega
		# geometría, agrega que se lo pueda encontrar — ver `asiento_cerca()`.
		# En la ruina no hay fuego al que mirar y no se marca.
		if not quemada and str(m[0]) == "naturaleza/stump_round":
			var hacia: Vector3 = HOGAR - (m[1] as Vector3)
			Detalles.asiento(mueble, 0.44,
				atan2(hacia.x * espejo, hacia.z))

	var luz: OmniLight3D = null
	if not quemada:
		luz = _hogar(cuarto, espejo, rng)

	var oficio := Node3D.new()
	oficio.name = "Oficio"
	cuarto.add_child(oficio)

	var centro := Vector2(g.global_position.x, g.global_position.z)
	# La hoja: su transformación de partida se guarda tal cual quedó al
	# construirla, porque abrir es exactamente eso girado sobre su gozne. La
	# malla se hizo con el origen EN el gozne justamente para que esto sea un
	# `rotated_local` y no una recomposición.
	var hoja: MeshInstance3D = casa.get("hoja")
	_casas[clave] = {
		"nodo": g, "cuarto": cuarto, "oficio": oficio, "luz": luz,
		"alta": casa["alta"], "baja": casa["baja"], "chimenea": null,
		"centro": centro, "piso": g.global_position.y, "alto": float(casa["alto"]),
		"giro": g.global_rotation.y, "espejo": espejo,
		"quemada": quemada, "quien": "", "gente": 0, "recortada": false,
		"hoja": hoja, "hoja_base": (hoja.transform if hoja != null else Transform3D()),
		"hoja_angulo": 0.0, "hoja_espera": 0.0,
		# El punto del hueco de la puerta, en el mundo. Es contra esto que se
		# mide si estás yendo a esa puerta, y no contra el centro de la casa:
		# desde el centro, las dos casas vecinas quedan a la misma distancia.
		"umbral": g.to_global(puerta),
	}


## La chimenea la pone `valle.gd` en el marco del LUGAR y no en el de la casa,
## así que llega por separado. Se anota para poder apagarla con el techo: una
## chimenea flotando sobre un cuarto abierto es peor que el techo entero.
func anotar_chimenea(clave: String, mi: MeshInstance3D) -> void:
	if mi != null and _casas.has(clave):
		_casas[clave]["chimenea"] = mi


## Quién vive acá y de qué trabaja. Se llama con lo que dice `/mundo`, y se
## rehace entero el nodo del oficio: es un puñado de mallas y la alternativa es
## llevar la cuenta de qué había antes.
##
## Devuelve el punto del mundo donde se para esa persona cuando está en su casa.
func habitar(clave: String, nombre: String, oficio: String) -> Vector3:
	var c: Dictionary = _casas.get(clave, {})
	if c.is_empty():
		return Vector3.ZERO
	var sitio: int = int(c["gente"])
	c["gente"] = sitio + 1

	# El oficio que se ve es el del PRIMERO que la reclama. Si dos comparten
	# techo, el cuarto es de uno solo — dos yunques y una olla en cinco metros
	# no es una casa, es un depósito.
	if sitio == 0 and str(c["quien"]) != nombre:
		c["quien"] = nombre
		if not bool(c["quemada"]):
			_puesto(c, oficio)
			# De quién es el puesto que quedó armado. Lo usa `puesto_cerca()`
			# para poder decir "el yunque de Ilde" y no "un puesto de trabajo":
			# un objeto sin dueño no significa nada en este juego.
			c["oficio_de"] = nombre

	var g: Node3D = c["nodo"]
	var p: Vector3 = ADENTRO_SITIOS[sitio % ADENTRO_SITIOS.size()]
	p.x *= float(c["espejo"])
	return g.to_global(p + Vector3(0, Detalles.CASA_PISO, 0))


## Se llama antes de repartir la gente de un `/mundo`: vuelve a cero la cuenta
## de quién vive dónde, para que un vecino que se mudó no deje su sitio ocupado.
func olvidar_gente() -> void:
	for clave: String in _casas:
		_casas[clave]["gente"] = 0


## Hacia dónde mira el que está adentro: al fuego. Es lo que hace que entrar y
## encontrarla sea encontrar a alguien haciendo algo y no un maniquí de espaldas.
func mirando_al_fuego(clave: String, desde: Vector3) -> float:
	var c: Dictionary = _casas.get(clave, {})
	if c.is_empty():
		return 0.0
	var g: Node3D = c["nodo"]
	var f := g.to_global(Vector3(HOGAR.x * float(c["espejo"]), Detalles.CASA_PISO, HOGAR.z))
	return atan2(f.x - desde.x, f.z - desde.z)


## ¿En qué casa está este punto? "" si está a la intemperie.
##
## Se resuelve por caja orientada y no por distancia al centro: las casas están
## giradas y un círculo que cubra la planta entera se come el metro de calle que
## hay entre dos, así que caminando por el medio de la aldea el recorte se
## prendería solo.
func donde_esta(p: Vector3) -> String:
	for clave: String in _casas:
		var c: Dictionary = _casas[clave]
		if p.y < float(c["piso"]) - 1.2 or p.y > float(c["piso"]) + float(c["alto"]):
			continue
		var d := (Vector2(p.x, p.z) - (c["centro"] as Vector2)).rotated(float(c["giro"]))
		if absf(d.x) < Detalles.CASA_ADENTRO and absf(d.y) < Detalles.CASA_ADENTRO:
			return clave
	return ""


## Una vez por cuadro. Decide en qué casa estás, recorta la que corresponda y
## enciende los hogares que se ven.
##
## `dt` en negativo —lo normal— significa "el tiempo de este cuadro". Se puede
## pasar a mano y eso es sólo para el banco: **una puerta que tarda medio segundo
## no se puede probar con el reloj real en una corrida headless**, donde un
## cuadro dura un milisegundo y esperar cinco segundos son cinco mil cuadros.
func actualizar(jugador: Vector3, camara: Vector3, dt := -1.0) -> void:
	var ahora := donde_esta(jugador)
	if ahora != _adentro:
		if _casas.has(_adentro):
			_recortar(_casas[_adentro], false, camara)
		_adentro = ahora
		_muros_fuera.clear()
	if _casas.has(_adentro):
		_recortar(_casas[_adentro], true, camara)

	_encender(jugador)
	# El delta sale del nodo y no del llamador: `valle.gd` llama a `actualizar()`
	# sin dt y esa firma es su cableado, no el mío. Esto es un `Node` colgado de
	# la escena, así que el tiempo del cuadro lo tiene a mano.
	_puertas(get_process_delta_time() if dt < 0.0 else dt, jugador)


## En qué casa estás. Lo lee `valle.gd` para decidir si tenés un puesto de
## trabajo al lado.
func adentro() -> String:
	return _adentro


## Cuánto está abierta la puerta de una casa, en radianes y con signo. Cero es
## cerrada. Existe para el banco: **una puerta que se abre no se puede verificar
## mirando una captura**, porque una captura es un instante y lo que hay que
## probar es que la hoja se mueve cuando alguien se acerca.
func puerta(clave: String) -> float:
	return float((_casas.get(clave, {}) as Dictionary).get("hoja_angulo", 0.0))


## Si estás parado junto al puesto de trabajo de la casa en la que estás, de
## quién es. Cadena vacía si no.
##
## Existe porque el oficio ya tenía DÓNDE pasar —el yunque, la piedra, la olla,
## puestos desde `trade`— y seguía sin poder invocarse: `trabajar` sólo aparecía
## como opción de una charla. O sea que había un yunque, sabías forjar, estabas
## parado al lado, y la única forma de trabajar era buscar a alguien y hablarle.
##
## El radio es corto a propósito. Un puesto que se ofrece desde la puerta hace
## que el cuarto entero sea un botón; a 2,2 m hay que ir hasta él, y esa
## caminata de dos metros es lo que hace que el yunque sea un lugar.
func puesto_cerca(p: Vector3, radio := 2.2) -> Dictionary:
	if _adentro == "":
		return {}
	var c: Dictionary = _casas.get(_adentro, {})
	if c.is_empty():
		return {}
	var nodo: Node3D = c.get("oficio")
	# Sin hijos no hay puesto: la casa no la reclamó nadie con oficio, o está
	# quemada. No se ofrece trabajar en un cuarto vacío.
	if nodo == null or not is_instance_valid(nodo) or nodo.get_child_count() == 0:
		return {}
	if p.distance_to(nodo.global_position) > radio:
		return {}
	return {"nodo": nodo, "de": str(c.get("oficio_de", ""))}


## ¿Hay dónde sentarse acá al lado? Devuelve `{"pos", "mirando", "nodo"}` o `{}`.
##
## Es el gemelo de `puesto_cerca()` y existe por el mismo motivo: el lugar ya
## estaba —la banqueta junto al hogar, los troncos del fogón de la plaza— y el
## juego no sabía que era un lugar. Un tocón que nadie puede usar es una malla.
##
## **Lo que falta para que esto sirva no es de esta rama.** Sentarse le toca a
## `jugador.gd` (parar el cuerpo, clavarlo en `pos`, mirar a `mirando`, soltarlo
## al primer WASD) y la postura a `figura.gd`. Del otro lado esto es un `if`.
##
## Sale del grupo `asientos` y no de un registro propio a propósito: los
## asientos de adentro los pone esta clase y los del fogón los pone
## `Detalles.labranza()`, que corre desde `vegetacion.gd` y no me ve. El grupo es
## el mismo mecanismo con el que `ciclo.gd` encuentra las ventanas.
##
## El radio es corto por lo mismo que el del yunque: un asiento que se ofrece a
## tres metros hace que la plaza entera sea un botón. A 1,5 hay que ir hasta él.
func asiento_cerca(p: Vector3, radio := 1.5) -> Dictionary:
	var mejor: Node3D = null
	var d_min := radio
	for n in get_tree().get_nodes_in_group("asientos"):
		var nodo := n as Node3D
		if nodo == null or not is_instance_valid(nodo):
			continue
		var d := p.distance_to(nodo.global_position)
		if d < d_min:
			d_min = d
			mejor = nodo
	if mejor == null:
		return {}
	return {
		"nodo": mejor,
		"pos": mejor.global_position
			+ Vector3(0.0, float(mejor.get_meta("asiento_alto", 0.45)), 0.0),
		# El giro guardado es relativo al padre; el del mundo se arma sumando el
		# propio del nodo. Ver `Detalles.asiento()`.
		"mirando": mejor.global_rotation.y + float(mejor.get_meta("asiento_mira", 0.0)),
	}


## Las puertas del valle, una vez por cuadro. Ver el bloque `LAS PUERTAS`.
##
## Cuesta doce distancias y, en el caso normal —ninguna puerta moviéndose—, cero
## asignaciones y cero escrituras de transformación.
func _puertas(dt: float, jugador: Vector3) -> void:
	var noche := _es_de_noche()
	var alcance := PUERTA_EMPUJE if noche else PUERTA_CERCA
	var vel := PUERTA_VEL * (PUERTA_NOCHE_VEL if noche else 1.0)
	for clave: String in _casas:
		var c: Dictionary = _casas[clave]
		var hoja: MeshInstance3D = c["hoja"]
		if hoja == null or not is_instance_valid(hoja):
			continue

		var espera := float(c["hoja_espera"])
		if jugador.distance_to(c["umbral"] as Vector3) < alcance:
			espera = PUERTA_QUEDA
		elif espera > 0.0:
			espera = maxf(espera - dt, 0.0)
		c["hoja_espera"] = espera

		# Hacia dónde abre: siempre para adentro, y el gozne está del lado de la
		# celda en que cayó la puerta —el mismo signo que el espejo del cuarto—,
		# así que el giro es el opuesto. Ver `Detalles._hoja()`.
		var quiero := (-float(c["espejo"]) * PUERTA_GIRO) if espera > 0.0 else 0.0
		var a := float(c["hoja_angulo"])
		if absf(a - quiero) < 0.0005:
			continue
		a = move_toward(a, quiero, vel * dt)
		c["hoja_angulo"] = a
		hoja.transform = (c["hoja_base"] as Transform3D).rotated_local(Vector3.UP, a)


## ¿Es de noche en el valle? La hora la manda el SERVIDOR y la tiene `ciclo.gd`;
## acá no se simula ninguna. Sin ciclo —el banco de prueba no tiene— es de día,
## que es el caso en que las puertas se portan bien.
func _es_de_noche() -> bool:
	if not _ciclo_buscado:
		_ciclo_buscado = true
		var p := get_parent()
		if p != null:
			for h in p.get_children():
				if h is Ciclo:
					_ciclo = h
					break
	return _ciclo != null and is_instance_valid(_ciclo) and _ciclo.es_de_noche()


## Abre TODAS las casas y les prende el fuego.
##
## Es para el banco de prueba —`escenas/prueba_casas.tscn -- --interior`— y para
## nada más. En el valle se abre **una sola**, la que estás pisando: abrirlas
## todas convierte un caserío en una maqueta seccionada, que es exactamente lo
## que un mundo curado no puede parecer. Está acá y no en el banco porque el
## registro de casas es privado y no vale la pena abrirlo por una captura.
## `recorte` en `false` deja los muros puestos y abre nada más que las puertas:
## es el A/B que hace falta para juzgar la hoja, porque con el frente recortado
## la puerta no se ve ni abierta ni cerrada.
func abrir_todas(camara: Vector3, recorte := true) -> void:
	for clave: String in _casas:
		var c: Dictionary = _casas[clave]
		if recorte:
			_recortar(c, true, camara)
		var luz: OmniLight3D = c["luz"]
		if luz != null:
			luz.visible = true
		# Y las puertas abiertas de par en par. En el banco no hay jugador que
		# las abra y lo que hay que poder mirar es la hoja donde queda.
		var hoja: MeshInstance3D = c["hoja"]
		if hoja != null and is_instance_valid(hoja):
			c["hoja_angulo"] = -float(c["espejo"]) * PUERTA_GIRO
			c["hoja_espera"] = PUERTA_QUEDA
			hoja.transform = (c["hoja_base"] as Transform3D).rotated_local(
				Vector3.UP, float(c["hoja_angulo"]))


# ---------------------------------------------------------------------------
# Lo de adentro
# ---------------------------------------------------------------------------

func _poner(cuarto: Node3D, ruta: String, pos: Vector3, giro: float,
		escala: float, espejo: float) -> MeshInstance3D:
	var mi := Kit.nodo(ruta)
	if mi == null:
		return null
	mi.position = Vector3(pos.x * espejo, pos.y, pos.z)
	# Reflejar el cuarto refleja también los giros, o el mueble apoyado contra
	# la pared izquierda termina mirando a la pared.
	mi.rotation.y = giro * espejo
	mi.scale = Vector3.ONE * escala
	cuarto.add_child(mi)
	return mi


## El hogar: el pozo, el trípode, la brasa y la luz.
##
## La brasa y la luz salen de la excepción 1 de la paleta —el fuego, el único
## lugar donde se gasta saturación—. La luz lleva `parpadeo.gd`, el mismo que
## el fuego de la fragua y los faroles: dos senos que no encajan entre sí. Un
## fuego que no titila es una lámpara.
func _hogar(cuarto: Node3D, espejo: float, rng: RandomNumberGenerator) -> OmniLight3D:
	_poner(cuarto, "utiles/campfire-pit", HOGAR, rng.randf() * TAU, 2.70, espejo)
	_poner(cuarto, "utiles/campfire-stand", HOGAR, 1.20, 2.40, espejo)

	var brasa := SphereMesh.new()
	brasa.radius = 0.19
	brasa.height = 0.26
	brasa.radial_segments = 8
	brasa.rings = 4
	brasa.material = Paleta.brasa()
	var mi := MeshInstance3D.new()
	mi.mesh = brasa
	mi.position = Vector3(HOGAR.x * espejo, 0.13, HOGAR.z)
	cuarto.add_child(mi)

	var luz := OmniLight3D.new()
	luz.light_color = Paleta.LUZ_FAROL
	luz.light_energy = LUZ_HOGAR
	luz.omni_range = LUZ_ALCANCE
	# Con sombra, y no es opcional: un omni adentro de una caja de muros de 27
	# cm se filtra por las paredes y la casa se ve desde afuera como un farol
	# de cinco metros. Con sombra, lo único que sale es lo que sale por la
	# puerta, que es justo lo que hay que ver desde la calle.
	luz.shadow_enabled = true
	luz.position = Vector3(HOGAR.x * espejo, 0.85, HOGAR.z)
	luz.visible = false
	luz.set_script(preload("res://scripts/parpadeo.gd"))
	cuarto.add_child(luz)
	return luz


## Las herramientas del oficio del que vive acá.
func _puesto(c: Dictionary, oficio: String) -> void:
	var nodo: Node3D = c["oficio"]
	for h in nodo.get_children():
		h.queue_free()

	var o := oficio.to_lower()
	var lista: Array = OFICIO_CUALQUIERA
	for clave: String in OFICIOS:
		if o.contains(clave):
			lista = OFICIOS[clave]
			break

	var espejo := float(c["espejo"])
	for d: Array in lista:
		_poner(nodo, str(d[0]), d[1], float(d[2]), float(d[3]), espejo)


# ---------------------------------------------------------------------------
# El recorte y las luces
# ---------------------------------------------------------------------------

func _recortar(c: Dictionary, si: bool, camara: Vector3) -> void:
	var modo := (GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if si
		else GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
	if bool(c["recortada"]) != si:
		c["recortada"] = si
		for h in (c["alta"] as Node3D).get_children():
			if h is GeometryInstance3D:
				(h as GeometryInstance3D).cast_shadow = modo
		var chim: MeshInstance3D = c["chimenea"]
		if chim != null and is_instance_valid(chim):
			chim.cast_shadow = modo
		if not si:
			for h in (c["baja"] as Node3D).get_children():
				if h is GeometryInstance3D:
					(h as GeometryInstance3D).cast_shadow = \
						GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			return

	if not si:
		return

	# Los muros de abajo que la cámara tiene delante. Se recalcula por cuadro
	# porque la cámara orbita, pero sólo se ESCRIBE cuando algo cambia: son
	# ocho productos escalares y ninguna asignación en el caso normal.
	var hacia := (Vector2(camara.x, camara.z) - (c["centro"] as Vector2)).normalized()
	for h in (c["baja"] as Node3D).get_children():
		var gi := h as GeometryInstance3D
		if gi == null or not gi.has_meta("afuera"):
			continue
		var a: Vector3 = gi.get_meta("afuera")
		var tapa := Vector2(a.x, a.z).dot(hacia) > RECORTE_MARGEN
		if bool(_muros_fuera.get(gi.get_instance_id(), false)) == tapa:
			continue
		_muros_fuera[gi.get_instance_id()] = tapa
		gi.cast_shadow = (GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if tapa
			else GeometryInstance3D.SHADOW_CASTING_SETTING_ON)


## Enciende los hogares que se pueden ver y apaga el resto. Ver `LUZ_CERCA`.
func _encender(jugador: Vector3) -> void:
	var yo := Vector2(jugador.x, jugador.z)
	var cerca: Array = []
	for clave: String in _casas:
		var c: Dictionary = _casas[clave]
		var luz: OmniLight3D = c["luz"]
		if luz == null:
			continue
		var d := yo.distance_to(c["centro"] as Vector2)
		if d < LUZ_CERCA:
			cerca.append([d, luz])
		elif luz.visible:
			luz.visible = false
	cerca.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for i in cerca.size():
		var luz: OmniLight3D = cerca[i][1]
		var quiero := i < LUZ_CUANTAS
		if luz.visible != quiero:
			luz.visible = quiero

extends Node3D

class_name Fauna

# ===========================================================================
# LOS BICHOS DEL VALLE
#
# Hasta acá el valle no tenía un solo animal. Se llenó de árboles, de humo, de
# luciérnagas y de gente, y seguía habiendo algo que no cerraba: **un valle sin
# un bicho vivo se lee como una maqueta.** Un ciervo parado en el borde del
# bosque hace más por que el lugar exista que veinte árboles más.
#
# ---------------------------------------------------------------------------
# QUÉ ES UN ANIMAL EN ESTE JUEGO. Contestar esto antes que nada.
# ---------------------------------------------------------------------------
#
# La versión anterior de este archivo tenía la respuesta escrita y era
# *"decoración, como el pasto y las luciérnagas"*. Se probó y el veredicto fue
# textual: **"los animales los traspasas, no se mueven, no comen, no atacan si
# se sienten atacados o lo que son friendly, no tenés acciones"**. Cuatro cosas
# y las cuatro ciertas. La primera sola ya alcanza: **nada que puedas atravesar
# caminando existe.** Un cartel con forma de vaca no es una vaca.
#
# Así que la pregunta no es cómo hacer que se muevan sino qué significa un
# animal acá, que es la regla de la casa (`CLAUDE.md`: *todo tiene vida o tiene
# algún sentido; antes de agregar algo, decí qué significa*).
#
# `DISENO.md` §8 tiene una regla dura y está escrita en los datos: **un objeto
# sólo existe si alguien vivo sabe hacerlo**, y lo único que aparece sin autor
# es lo que se junta del suelo (`objects.made_by = null`, y sólo el verbo
# `buscar` puede escribir ese null). O sea que el valle da exactamente una cosa
# gratis: la raíz que crece sola.
#
#   > **Un animal es la segunda cosa que el valle da sin que nadie la fabrique.
#   > La diferencia con la raíz es que el animal tiene una opinión sobre si lo
#   > dejás acercarte.**
#
# Esa opinión es todo el diseño de este archivo, y es lo que convierte al bicho
# en una regla del mundo en vez de en un adorno. Se llama `temple` y tiene tres
# valores, uno por cada cosa que el valle está diciendo:
#
#   · **MANSO** — vaca, burro, caballo. Te dejan llegar, porque alguien les da
#     de comer. Levantan la cabeza, te miran y siguen. **La mansedumbre ES el
#     dato**: un animal que no te tiene miedo es la prueba de que hay una
#     persona cerca que sabe tenerlo. Nadie tiene una vaca de adorno.
#   · **HURANO** — ciervo y venado. Te ven de lejos y se van. Lo que el valle
#     da gratis, lo da a distancia. Y `recelo` = 17 m contra los 15 de
#     `Monstruo.VISTA` no es casualidad: **el ciervo que sale disparado es la
#     alarma del bosque**, y te avisa antes que el bicho que te va a morder.
#   · **DUENO** — lobo y zorro. No corren. Se dan vuelta, te miran y se quedan.
#     Se van cuando deciden ellos y caminando. Es la línea que ya estaba
#     escrita acá —*el bosque tiene dueño y no sos vos*— pasada de dónde está
#     puesto el bicho a qué hace el bicho.
#
# Los tres salen de UN mecanismo con dos números (`recelo` y `cede`), no de
# tres máquinas distintas. Ver `ESPECIES`.
#
# ---------------------------------------------------------------------------
# DÓNDE ESTÁ LA LÍNEA DEL INVARIANTE, Y NO SE CRUZA
# ---------------------------------------------------------------------------
#
# **Invariante 4: lo que pasa en el cliente llega al servidor, o no pasó.** Ya
# se rompió entero una vez —monstruos, combate y muerte viviendo sólo en la
# máquina de cada jugador— y la línea acá es exactamente ésta:
#
#   · Un animal que **se mueve, se asusta, te bloquea el paso y se va** es
#     PRESENTACIÓN. Vive en el cliente y está bien que viva acá. No hay un
#     dato del mundo que cambie porque una vaca dio tres pasos.
#   · Un animal del que **sacás algo** NO. Eso es un objeto entrando al mundo y
#     tiene que pasar por el servidor, como la raíz pasa por `buscar`.
#
# Por eso acá no hay vida, no hay daño, no hay muerte y no hay botín. **Pegarle
# a un animal lo hace irse y nada más, y eso es literalmente cierto**: hoy nadie
# en este mundo sabe hacer nada con un animal. El día que exista el verbo, el
# bicho pasa a tener `id_servidor` como lo tiene `Monstruo`, y el verbo lo
# escribe el servidor. Ver el informe de la tanda: está pedido, no escrito.
#
# ---------------------------------------------------------------------------
# EL VOCABULARIO ES EL DEL MONSTRUO. A propósito.
# ---------------------------------------------------------------------------
#
# `monstruo.gd` ya tiene resuelto anticipación → contacto → consecuencia, y un
# segundo idioma para decir lo mismo sería un idioma peor. Los tiempos se
# TOMAN de ahí en vez de copiarse, así que no pueden separarse:
#
#   monstruo          animal            constante compartida
#   ---------------   ---------------   ---------------------------------
#   RONDA             PACE / ANDA       —
#   ALERTA (duda)     ATENTO            `Monstruo.DUDA` = 0,55 s = 33 cuadros
#   la pose se alza   la cabeza sube    `Impacto.AMAGO_ALZA`  = 10 cuadros
#   la pose se suelta la cabeza baja    `Impacto.AMAGO_SUELTA` = 4 cuadros
#   antirrebote       antirrebote       `Impacto.AMAGO_CORTE` = 0,45 s
#   PERSIGUE          HUYE              (mismo beat, sentido contrario)
#
# **El momento de duda es el mismo medio segundo y significa lo contrario.** El
# monstruo se queda quieto medio segundo y decide venir; el animal se queda
# quieto el mismo medio segundo y decide irse. Que sea el mismo número es lo
# que hace que el valle se lea escrito por la misma mano.
#
# Lo único que NO se copia son los ojos. La escalera de brillo `OJOS_*` es la
# firma del monstruo y un ciervo con los ojos encendidos sería otro monstruo.
# Acá la escalera es de POSTURA, que es lo otro que se lee a 40 m.
#
# ---------------------------------------------------------------------------
# CÓMO SE MIDIÓ, PORQUE SI NO SE MIDE NO SE SABE
# ---------------------------------------------------------------------------
#
# La lección de la tanda anterior: *la primera pose de amago encogía la silueta
# y sólo lo dijo la medición.* Acá se midió igual —**alto de la silueta en
# píxeles desde 40 m con FOV 42° a 900p**— y la escalera quedó así, comparando
# el MÍNIMO de una ventana de dos segundos, que es la medida correcta: lo que
# distingue pastar de estar atento es que **la cabeza deja de bajar**, y un
# promedio mezcla las dos cosas y no dice nada.
#
#            pastando   atento    huyendo    atento − pastando
#   Vaca        36        42        37-39      +6,5 px   +18%
#   Caballo     31        51        43-45     +20,3 px   +66%
#   Burro       23        38        31-33     +15,0 px   +66%
#   Ciervo      20        34        30-31     +14,3 px   +72%
#   Venado      27        41        35-36     +13,9 px   +52%
#   Lobo        17        27        21-22      +9,7 px   +58%
#   Zorro       10        15        12         +5,2 px   +50%
#
# Tres peldaños separados en las siete especies, y huyendo cae SIEMPRE entre los
# otros dos: el cuerpo se estira y baja. Y el reparto del ciclo de pastar mide
# 65% comiendo / 9% cabeza arriba / 26% caminando = **74,2% quieto**, contra el
# ~75% de la gente del valle. Camina 17 m en dos minutos y no se aleja más de
# 2,2 m de su sitio.
#
# Cuatro cosas salieron de medir y ninguna la daba el ojo:
#
#  1. **`MeshInstance3D.get_aabb()` NO SIRVE en una malla con esqueleto**: es el
#     de la pose de reposo y da idéntico en las cuatro animaciones. La silueta
#     se mide con la nube de orígenes de HUESO. La primera sonda dijo "las
#     cuatro poses son iguales al píxel" y eso era la sonda, no los modelos.
#  2. **La animación `Eating` ya baja la cabeza al piso y es casi todo el
#     efecto** — en el ciervo son 14 de los 14,3 px. Pastar contra estar atento
#     se lee solo y no hubo que dibujar nada. **Menos en la vaca**, cuya
#     `Eating` es plana (+1%): la vaca ya come con la cabeza baja. Ahí los 6,5
#     px los pone `ALZA_GRADOS` casi enteros (6,2 de 6,5), y por eso el pitch
#     existe: no para mejorar a los seis que ya se leen, sino para que el
#     séptimo exista. Y la vaca es 7 de las 24 cabezas y vive en la aldea.
#  3. **El pitch estuvo dado por muerto con un número que estaba mal.** Medido
#     con la cabeza congelada abajo daba −0,3 px y la decisión escrita era
#     borrarlo; medido con la animación andando da +2,6 a +6,2. La diferencia
#     es dónde estaba la cabeza: con la cabeza baja el techo de la silueta es
#     el lomo, y ahí inclinar el cuerpo lo BAJA. **La lección no es "medí" sino
#     "mirá qué estás midiendo": una medición mal montada miente con la misma
#     cara de autoridad que un número bueno.**
#  4. **El bicho corría a 7 m/s y avanzaba 0,00 m**, y eso no lo muestra ninguna
#     captura. Ver el comentario de `_pos` en `Bicho`.
#
# ---------------------------------------------------------------------------
# DÓNDE ESTÁ CADA UNO. Sigue igual y sigue valiendo.
# ---------------------------------------------------------------------------
#
#   · **Vaca, caballo, burro** — al lado de los lugares donde hay gente.
#   · **Ciervo y venado** — en el bosque y en el claro, lejos de las casas.
#   · **Lobo y zorro** — pocos, en el borde, nunca adentro de un lugar.
#
# DE DÓNDE SALEN. Quaternius, CC0 (ver `assets/PROCEDENCIA.md`). Vienen sin
# textura, con `albedo_color` y nada más, así que pasan por la misma aduana de
# `paleta.gd` que el resto del kit. Rondan los 2.000 triángulos cada uno.
#
# **Corrección al comentario que estaba acá:** decía que el pack *"trae `Walk` y
# `Gallop`"*. Trae `Idle`, `Idle_2`, `Eating` y `Walk`, y nada más. No hay
# galope y no hay muerte. La huida es `Walk` a 2,4× — que a 40 m es exactamente
# lo que se lee como correr, porque lo que dice "está corriendo" es que el bicho
# está TAPANDO TERRENO, no la frecuencia de las patas.
# ===========================================================================


## Qué hace el bicho cuando te ve. Es la única decisión de diseño de este
## archivo; todo lo demás son consecuencias suyas. Ver el encabezado.
enum Temple { MANSO, HURANO, DUENO }

## En qué anda cada bicho. Los tres primeros son el ciclo de pastar y los tres
## últimos son la reacción, en el orden del monstruo: aviso, acción, resaca.
enum Paso { PACE, MIRA, ANDA, ATENTO, HUYE, RECELA }


## Las especies.
##
## `alzada` es la altura en metros hasta lo más alto de la malla y es lo único
## que decide la escala: los `.glb` vienen en unidades de Blender y miden cuatro
## veces de más. Se normaliza contra el AABB, igual que
## `vegetacion.gd:_normalizada()`.
##
## **`recelo` y `cede` son el diseño entero, y son dos números y no dos
## sistemas.** `recelo` es a qué distancia te NOTA —levanta la cabeza y se da
## vuelta— y `cede` es a qué distancia se VA. Que estén juntos o separados es lo
## que produce los tres temples sin una sola rama de código extra:
##
##   · vaca:  recelo 3,5 / cede 2,2 → te nota cuando ya la tocás y se corre un
##            paso. Es la mansedumbre, y la mansedumbre es el dato.
##   · ciervo: recelo 17 / cede 15 → nota y se va casi en el mismo movimiento.
##   · lobo:  recelo 16 / cede 4,5 → **te nota a 16 m y no se mueve hasta los
##            4,5.** Once metros y medio de un bicho que te está mirando y no se
##            va. Eso es todo el "el bosque tiene dueño" que hacía falta.
##
## `paso` es la caminata de pastar y `trote` la de irse, en m/s. El lobo tiene
## el `trote` MÁS BAJO que el `paso` a propósito: no huye, se retira.
const ESPECIES := {
	"Cow":    {"alzada": 1.45, "peso": 796, "temple": Temple.MANSO,
		"recelo":  3.5, "cede":  2.2, "paso": 0.55, "trote": 2.6},
	"Horse":  {"alzada": 1.65, "peso": 690, "temple": Temple.MANSO,
		"recelo":  8.0, "cede":  4.5, "paso": 0.80, "trote": 5.5},
	"Donkey": {"alzada": 1.25, "peso": 662, "temple": Temple.MANSO,
		"recelo":  5.0, "cede":  3.0, "paso": 0.60, "trote": 3.2},
	"Deer":   {"alzada": 1.15, "peso": 690, "temple": Temple.HURANO,
		"recelo": 17.0, "cede": 15.0, "paso": 0.70, "trote": 7.0},
	"Stag":   {"alzada": 1.40, "peso": 690, "temple": Temple.HURANO,
		"recelo": 20.0, "cede": 17.0, "paso": 0.70, "trote": 7.2},
	"Wolf":   {"alzada": 0.85, "peso": 662, "temple": Temple.DUENO,
		"recelo": 16.0, "cede":  4.5, "paso": 0.90, "trote": 2.2},
	"Fox":    {"alzada": 0.50, "peso": 662, "temple": Temple.DUENO,
		"recelo": 11.0, "cede":  3.5, "paso": 1.00, "trote": 3.4},
}

## Los rebaños: qué especie, cuántos, alrededor de qué lugar y en qué radio.
##
## **Los números son chicos a propósito.** Veintiséis bichos en 34 hectáreas es
## un valle habitado; sesenta es un zoológico, y a la distancia a la que se
## juega la diferencia entre "hay animales" y "hay demasiados" se nota antes
## que cualquier otra cosa. Si alguna vez hay que subirlos, se sube el número
## de rebaños, no el de cabezas por rebaño: tres grupos de cuatro se leen mejor
## que uno de doce.
##
## **Ojo: piden 26 y entran 24.** Los dos ciervos de la ruina nunca se colocan,
## y no es azar: el corte `y < -0.6` de `_rebano()` está escrito para que no
## haya bichos flotando sobre el río, pero el valle es un CUENCO y a 111 m del
## centro —donde está la ruina— el suelo ya vale −3 m por el cuenco solo. El
## corte se come el rebaño entero antes de mirar si hay agua. El comentario
## decía 26 y eran 24; queda anotado en vez de arreglado porque tocar el corte
## mueve dónde está parado cada bicho del valle, y eso es otra tanda.
const REBANOS: Array = [
	# lugar,      especie,  cabezas, radio interior, radio exterior
	["aldea",     "Cow",     4,  14.0, 26.0],
	["aldea",     "Donkey",  2,  10.0, 18.0],
	["fragua",    "Horse",   3,   9.0, 17.0],
	["camino",    "Horse",   2,   8.0, 15.0],
	["camino",    "Cow",     3,  12.0, 24.0],
	["bosque",    "Deer",    4,  16.0, 34.0],
	["bosque",    "Stag",    1,  20.0, 30.0],
	["ruina",     "Deer",    2,  18.0, 32.0],
	["ruina",     "Wolf",    2,  22.0, 34.0],
	["bosque",    "Fox",     2,  24.0, 38.0],
	["bosque",    "Wolf",    1,  30.0, 40.0],
]

## Hasta dónde se dibujan. La cámara vive entre 40 y 68 m: a 130 un ciervo son
## tres píxeles y su esqueleto sigue costando.
const ALCANCE := 130.0

# ── El ciclo de pastar: por qué camina, que es la parte que faltaba ─────────
#
# El comentario anterior decía *"ningún bicho camina, porque un animal que
# camina hacia ningún lado en línea recta se lee como bug antes que como
# vida"*. La observación era correcta y la conclusión no: lo que se lee como
# bug es el "hacia ningún lado", no el caminar. Un animal que **agota el pasto
# donde está, levanta la cabeza, mira, camina cuatro metros y vuelve a bajar la
# cabeza** tiene un motivo, y el motivo se ve.
#
# El reparto sale de la misma regla que la gente del valle (*~3/4 del tiempo
# quietas*). Las tres duraciones son largas comparadas con todo lo demás de este
# proyecto, y tienen que serlo: un rebaño es lento o es un dibujo animado.
#
# **Y hay un segundo motivo para que MIRA sea corto, que se descubrió midiendo.**
# La primera tanda de números daba 53% comiendo / 18% cabeza arriba / 29%
# caminando, o sea **la cabeza arriba el 47% del tiempo** — y en ese valle el
# aviso no vale nada, porque estar atento ES tener la cabeza arriba. Un tell que
# se parece a la mitad de lo que el bicho hace normalmente no es un tell.
# Comiendo tiene que ser el estado por defecto y por goleada.
#
# Con estos números da **65% comiendo / 9% cabeza arriba / 26% caminando**, o
# sea 74,2% quieto contra el ~75% de la gente. Camina 17 m en dos minutos y no
# se va a más de 2,2 m de su sitio.

const PACE_MIN := 5.0    ## comiendo, en segundos (300 cuadros)
const PACE_MAX := 11.0   ## (660 cuadros)
const MIRA_MIN := 0.7    ## la cabeza arriba entre bocado y bocado (42 cuadros)
const MIRA_MAX := 1.6
const ANDA_MIN := 2.0    ## caminando al pasto de al lado (120 cuadros)
const ANDA_MAX := 4.0
## Cuánto se puede alejar de su sitio en el rebaño. Sin esto la manada se
## desarma en una tarde y las vacas terminan adentro de las casas.
const DERIVA := 6.0

# ── La reacción, con los tiempos del monstruo ───────────────────────────────

## El momento de duda. **Es el mismo `Monstruo.DUDA`, tomado y no copiado**: si
## alguien lo mueve allá se mueve acá, que es lo que se quiere. 0,55 s = 33
## cuadros de un bicho quieto que te está mirando y todavía no decidió.
const ATENTO_DURA := Monstruo.DUDA

## Cuánto corre como mucho. Sin techo, un bicho acorralado contra la cordillera
## corre para siempre contra la piedra, que es la peor imagen posible.
const HUYE_MAX := 4.0

## Después de correr se queda con la cabeza arriba mirando. **No vuelve a comer
## de una**: la consecuencia es lo que separa un susto de un tic.
const CALMA_MIN := 3.0
const CALMA_MAX := 6.0

## Antirrebote, y es el mismo número y el mismo motivo que el amago abandonado
## del monstruo: sin esto el que se para justo en el borde del `recelo` ve al
## bicho levantar y bajar la cabeza veinte veces por segundo.
const REPOSO_MIN := Impacto.AMAGO_CORTE

## A cuántos metros se contagia el susto. **Es lo que hace que un rebaño se lea
## como un rebaño**: uno sale disparado y un beat después los otros levantan la
## cabeza. La onda se ve porque los contagiados entran en ATENTO, no en HUYE:
## tardan sus 33 cuadros en decidirse, igual que el primero.
const CONTAGIO := 13.0

# ── La escalera de postura. Es la de los ojos del monstruo, en silueta ──────
#
# El monstruo dice qué va a hacer con el brillo de los ojos porque el valor se
# lee igual a 12 m que a 68. Un animal no tiene ojos que brillen, así que lo
# dice con la otra variable que no depende de cuántos píxeles mida: **el eje
# del cuerpo entero.**
#
# **El signo se midió, no se dedujo, y es la trampa de esta tanda.** Los `.glb`
# de Quaternius miran a **+Z** (hueso `Head` en z=+1,9 a +4,0; `Tail1` en
# negativo), o sea al revés de la convención de Godot. Con `rotation.x` positivo
# la nariz BAJA. Es exactamente el error que cometió la primera pose de amago
# del monstruo —encogía la silueta justo cuando tenía que abrirla— y la única
# forma de no repetirlo es medir el alto en píxeles y mirar el signo del delta.
const ALZA_GRADOS := -7.0     ## atento: la nariz sube. Negativo = arriba.
const TENDIDA_GRADOS := 5.0   ## huyendo: el cuerpo se estira y baja.

## **NO HAY LEVANTE, y el cero está medido.** Éste era 0,5 con el argumento de
## que "sin compensar, las patas de atrás se hunden", y el argumento estaba mal
## por dónde está el pivote: gira a la altura del SUELO, no del centro del
## cuerpo. Con 0,5 la vaca quedaba con las manos 28 cm en el aire y las patas
## 3,5 cm en el aire — **flotando entera**, y así salió en la hoja de poses.
##
## No existe un levante que plante las cuatro: un cuerpo rígido que se inclina
## sube una punta y baja la otra, y la única elección es cuál. Con 0 el error se
## reparte —12 cm arriba adelante, 12 cm abajo atrás— y la mitad que se hunde la
## tapa el pasto, que es la que conviene esconder.
##
## (Un animal de verdad no inclina el cuerpo: levanta el CUELLO. Eso pide tocar
## huesos por encima del `AnimationPlayer` y no vale la diferencia — ver el
## informe.)
const APOYO := 0.0

## Lo que tarda la postura en armarse y en deshacerse. Son los del amago del
## monstruo: 10 cuadros para alzarse, 4 para soltar. Con menos, el cambio de
## silueta se confunde con el rebote de la caminata.
const POSE_ALZA := Impacto.AMAGO_ALZA
const POSE_SUELTA := Impacto.AMAGO_SUELTA

## Multiplicador de la animación `Walk` al huir. El pack no tiene galope, así
## que corre es caminar rápido; lo que dice "está corriendo" a 40 m es que está
## tapando terreno, no la frecuencia de las patas.
const TROTE_ANIM := 2.4

## Más allá de esto el bicho ni mira: sigue pastando su ciclo pero no consulta
## nada del jugador. La cámara llega a 68 m y el `recelo` más largo es 20.
const ATENCION := 46.0

## A qué distancia del jugador tiene sentido oír un bicho, y cada cuánto puede
## sonar UNO cualquiera. Sin el segundo número, una estampida de siete ciervos
## son siete gritos en el mismo cuadro y eso no es un susto, es un error.
const VOZ_ALCANCE := 62.0
const VOZ_ESPERA := 1.1

## Alcance del golpe del jugador. **Es el mismo `ALCANCE_JUGADOR` de
## `valle.gd`** —6,5 m— y está repetido acá porque `valle.gd` no es de esta
## rama. Si alguna vez se cablea de verdad (ver el informe), esto se borra.
const ALCANCE_GOLPE := 6.5

## Los lugares de respaldo, para poder correr este módulo suelto. Los de verdad
## llegan por `poblar()`. Son los mismos de `vegetacion.gd`.
const LUGARES_DEFECTO := {
	"aldea": Vector3(0, 0, 0),
	"fragua": Vector3(62, 0, -18),
	"bosque": Vector3(-58, 0, -54),
	"ruina": Vector3(-26, 0, -108),
	"camino": Vector3(11, 0, 74),
}

@export var semilla := 20260817

var _alturas: Callable
var _lugares := LUGARES_DEFECTO.duplicate()
var _cabezas := 0
var _triangulos := 0
var _por_especie := {}

var _bichos: Array[Bicho] = []
## El jugador. No llega por cableado —`valle.gd` no es de esta rama— así que se
## busca solo en el árbol y se deja de buscar cuando aparece. Ver `_hallar()`.
var _jugador: Node3D
var _conectado := false
var _reloj_busca := 0.0
var _voz_espera := 0.0


## La puerta de entrada, igual que `Vegetacion.poblar()`: `alturas` es la
## función de terreno del valle y `lugares` es su diccionario `LUGARES`.
func poblar(alturas: Callable, lugares: Dictionary = {}) -> void:
	_alturas = alturas
	for slug: String in lugares:
		var def: Variant = lugares[slug]
		if def is Dictionary and (def as Dictionary).has("pos"):
			_lugares[slug] = (def as Dictionary)["pos"]
		elif def is Vector3:
			_lugares[slug] = def

	var rng := RandomNumberGenerator.new()
	rng.seed = semilla + 7717

	for r: Array in REBANOS:
		var slug: String = r[0]
		if not _lugares.has(slug):
			continue
		_rebano(_lugares[slug], r[1], r[2], r[3], r[4], rng)

	print("fauna: %d cabezas, %d triángulos, %s" % [
		_cabezas, _triangulos, _por_especie])
	set_physics_process(true)


## Un grupo de la misma especie repartido en un anillo alrededor de un lugar.
##
## El anillo —y no un círculo lleno— es lo que los mantiene fuera de las casas
## sin tener que saber dónde están las casas: `radio_min` es más grande que
## cualquier planta de lugar.
func _rebano(centro: Vector3, especie: String, cabezas: int,
		radio_min: float, radio_max: float, rng: RandomNumberGenerator) -> void:
	# El primero del grupo elige el rumbo; los demás se le parecen. Un rebaño
	# mirando todo para el mismo lado se lee como rebaño; uno con siete rumbos
	# al azar se lee como siete bichos sueltos que se cruzaron.
	var rumbo := rng.randf() * TAU
	var puesto := 0
	var intentos := 0

	while puesto < cabezas and intentos < cabezas * 12:
		intentos += 1
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * (radio_max - radio_min) + radio_min
		var p := Vector3(centro.x + cos(a) * r, 0.0, centro.z + sin(a) * r)
		var y := _altura(p)
		# Nada de bichos flotando sobre el río ni trepados a la cordillera.
		if y < -0.6 or Vector2(p.x, p.z).length() > 168.0:
			continue
		p.y = y
		if _poner(especie, p, rumbo + rng.randf_range(-0.9, 0.9), rng):
			puesto += 1


## Un bicho, ya colocado, escalado, con cuerpo y con su ciclo andando.
func _poner(especie: String, pos: Vector3, giro: float,
		rng: RandomNumberGenerator) -> bool:
	var n := Kit.escena("quaternius/animales/" + especie, Paleta.SATURACION_GENTE)
	if n == null:
		return false

	var b := Bicho.new()
	b.especie = especie
	b.datos = ESPECIES[especie]
	b.sitio = pos
	b.position = pos
	b.rotation.y = giro
	b.alturas = _alturas
	add_child(b)

	# EL CUERPO. Es la mitad del reclamo y es la más barata: sin esto el bicho
	# es una calcomanía y el jugador lo comprueba en el primer paso.
	#
	# `AnimatableBody3D` y no `StaticBody3D` porque **se mueve**: el cuerpo
	# animable arrastra y empuja al que tiene encima en vez de atravesarlo, que
	# es justo la diferencia entre una vaca y una vaca de utilería. Y no
	# `CharacterBody3D` porque el bicho no necesita gravedad: la altura sale del
	# terreno, que ya la sabemos exacta.
	b.sync_to_physics = true

	# La caja. Se saca del AABB de la malla y no de un número escrito: los siete
	# bichos miden cosas distintas y una cápsula genérica deja al zorro con la
	# colisión de un caballo. Se recorta el largo al 80% porque el AABB incluye
	# la cola y los cuernos, y frenarte contra la cola de una vaca es peor que
	# atravesarla.
	var s := _escala(n, especie)
	var caja := _footprint(n)
	var forma := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	var alto: float = float(ESPECIES[especie]["alzada"])
	bs.size = Vector3(maxf(caja.size.x * s, 0.25), alto,
		maxf(caja.size.z * s * 0.80, 0.40))
	forma.shape = bs
	forma.position = Vector3(caja.get_center().x * s, alto * 0.5,
		caja.get_center().z * s)
	b.add_child(forma)

	# El pivote: acá vive el pitch de la postura y el levante que lo acompaña,
	# separado del cuerpo físico. Si el pitch fuera del `AnimatableBody3D`, la
	# caja de colisión se inclinaría con él y el jugador chocaría con una vaca
	# torcida — lo que se inclina es lo que se ve, no lo que se toca.
	b.pivote = Node3D.new()
	b.add_child(b.pivote)
	b.pivote.add_child(n)
	n.scale = Vector3.ONE * s
	b.largo = caja.size.z * s

	# El pelaje de cada cabeza, un poco más claro o más oscuro que el de al
	# lado. **Es lo único que separa un rebaño de cuatro copias del mismo
	# archivo**, y a cuarenta metros la copia se nota antes que cualquier otra
	# cosa: es el mismo truco que usa `vegetacion.gd` con las copas.
	#
	# Se mueve el VALOR y nada más. El matiz sale de la paleta y no se toca:
	# una vaca violeta sería variedad, pero de la que rompe la escalera.
	var pelo := rng.randf_range(0.86, 1.16)
	for m in _mallas(n):
		m.visibility_range_end = ALCANCE
		m.visibility_range_end_margin = 12.0
		_triangulos += Kit.triangulos(m.mesh)
		Kit.tinte(m, Color(pelo, pelo, pelo))

	b.animador = _reproductor(n)
	b.arrancar(rng)

	_bichos.append(b)
	_cabezas += 1
	_por_especie[especie] = int(_por_especie.get(especie, 0)) + 1
	return true


# ---------------------------------------------------------------------------
# El pulso. Un solo bucle para los veintiséis.
# ---------------------------------------------------------------------------
#
# Va en `_physics_process` y no en `_process` por una razón dura:
# `sync_to_physics` exige que el cuerpo se mueva en el paso de física o el
# empujón al jugador sale a destiempo. Y de paso los bichos se congelan con
# `Impacto.congelar()` igual que todo lo demás, que es lo correcto: la pausa al
# impactar para el mundo, no sólo a los que pelean.

func _physics_process(dt: float) -> void:
	_hallar(dt)
	_voz_espera = maxf(0.0, _voz_espera - dt)

	var pos := Vector3.ZERO
	var hay := _jugador != null and is_instance_valid(_jugador)
	if hay:
		pos = _jugador.global_position

	for b in _bichos:
		# Los que están lejos siguen pastando —un rebaño congelado al que le
		# aparece la vida cuando lo mirás es peor que uno quieto— pero no
		# consultan al jugador. `ATENCION` es 46 m y el `recelo` más largo es
		# 20: no se pierde ninguna reacción que se pudiera ver.
		var d := INF
		if hay:
			d = b.global_position.distance_to(pos)
		if b.correr(dt, pos, d if d < ATENCION else INF):
			_espantar_vecinos(b)
			_hablar(b, d)


## El jugador no llega por cableado, así que se busca. Se busca **cada medio
## segundo hasta encontrarlo y nunca más**: recorrer el árbol sesenta veces por
## segundo para nada es exactamente la clase de cosa que después nadie encuentra.
##
## Y en el mismo momento se engancha el golpe. `Jugador.quiere_golpear` es una
## señal pública y escucharla desde acá es lo que evita pedirle una línea a
## `valle.gd`. Lo correcto de verdad es que `valle.gd` avise —está pedido en el
## informe— pero esto anda hoy y no toca un archivo ajeno.
func _hallar(dt: float) -> void:
	if _conectado:
		return
	_reloj_busca -= dt
	if _reloj_busca > 0.0:
		return
	_reloj_busca = 0.5
	var raiz := get_tree().current_scene
	if raiz == null:
		return
	for n in raiz.find_children("*", "Jugador", true, false):
		_jugador = n as Node3D
		break
	if _jugador == null:
		return
	_conectado = true
	if _jugador.has_signal("quiere_golpear"):
		_jugador.connect("quiere_golpear", _al_golpear)


## Le pegaste a algo. **Al más cercano en alcance, y nada más que uno.**
##
## Acá no se descuenta vida, no se avisa al servidor y no se congela el mundo:
## no hay nada que contar. Lo que pasa es lo que de verdad pasa —el bicho se va
## y arrastra al rebaño con él— y eso es honesto, porque hoy nadie en este mundo
## sabe hacer nada con un animal.
##
## La pausa al impactar (`Impacto.congelar`) queda AFUERA a propósito. Congelar
## el mundo es la marca de un golpe que cuenta; ponérsela a un golpe que no
## cuenta sería mentir con el énfasis, que es la forma difícil de mentir. Pegarle
## a una vaca se siente más liviano que pegarle a Kerrak, y eso es cierto.
func _al_golpear() -> void:
	if _jugador == null or not is_instance_valid(_jugador):
		return
	var pos := _jugador.global_position
	var elegido: Bicho = null
	var mejor := ALCANCE_GOLPE
	for b in _bichos:
		var d := b.global_position.distance_to(pos)
		if d < mejor:
			mejor = d
			elegido = b
	if elegido == null:
		return
	elegido.pegado(pos)


## El susto se contagia. Uno sale disparado y el resto levanta la cabeza.
func _espantar_vecinos(quien: Bicho) -> void:
	for b in _bichos:
		if b == quien:
			continue
		if b.global_position.distance_to(quien.global_position) < CONTAGIO:
			b.contagiar()


## La voz. Al huir, y con dos frenos: que el jugador esté cerca y que no haya
## sonado otro hace nada. Es la mitad del aviso que funciona con el bicho fuera
## de encuadre, que a esta cámara es la mitad de las veces — el mismo argumento
## por el que el monstruo gruñe.
func _hablar(b: Bicho, d: float) -> void:
	if _voz_espera > 0.0 or d > VOZ_ALCANCE:
		return
	_voz_espera = VOZ_ESPERA
	if int(b.datos["temple"]) == Temple.MANSO:
		Impacto.bramar(b)
	else:
		Impacto.bufar(b)


## La escala que lleva la malla a la alzada de la especie. El AABB de una malla
## con esqueleto es el de la pose de reposo, que para estos modelos es el bicho
## parado: sirve para esto (para la SILUETA no sirve, ver el encabezado).
func _escala(n: Node3D, especie: String) -> float:
	var alto := 0.0
	for m in _mallas(n):
		if m.mesh != null:
			alto = maxf(alto, m.mesh.get_aabb().size.y)
	if alto <= 0.01:
		return 1.0
	return float(ESPECIES[especie]["alzada"]) / alto


## El AABB de todas las mallas juntas, en unidades del `.glb`. De acá salen el
## ancho y el largo de la caja de colisión.
func _footprint(n: Node3D) -> AABB:
	var out := AABB()
	var primero := true
	for m in _mallas(n):
		if m.mesh == null:
			continue
		var a: AABB = m.mesh.get_aabb()
		out = a if primero else out.merge(a)
		primero = false
	return out


func _mallas(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		out.append(n as MeshInstance3D)
	for h in n.get_children():
		out.append_array(_mallas(h))
	return out


func _reproductor(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for h in n.get_children():
		var a := _reproductor(h)
		if a != null:
			return a
	return null


func _altura(p: Vector3) -> float:
	if _alturas.is_valid():
		return _alturas.call(p.x, p.z)
	return 0.0


## Para el censo. Devuelve `[cabezas, triángulos, {especie: cuántos}]`.
func censo() -> Array:
	return [_cabezas, _triangulos, _por_especie]


# ===========================================================================
# UN BICHO
# ===========================================================================
#
# Clase interna y no archivo aparte porque no tiene sentido sola: sin la tabla
# `ESPECIES` y sin el rebaño que la coloca, un `Bicho` es un `.glb` con un
# temporizador. La máquina de estados entera entra en `correr()` y está escrita
# con el mismo `match` que `Monstruo._physics_process`, a propósito.

class Bicho extends AnimatableBody3D:

	var especie := ""
	var datos := {}
	var alturas: Callable
	var animador: AnimationPlayer
	var pivote: Node3D
	## Largo del cuerpo en metros, ya escalado. Es lo que le da a la polvareda
	## del golpe una altura que depende del bicho: la de una vaca no puede caer
	## a la misma altura que la de un zorro.
	var largo := 1.0
	## Su sitio en el rebaño. Se aleja como mucho `DERIVA` de acá pastando; al
	## huir se lo lleva puesto y vuelve caminando desde donde quedó.
	var sitio := Vector3.ZERO

	var _paso: int = Fauna.Paso.PACE
	var _reloj := 0.0
	## De 0 a 1, igual que `Figura._amago`. 1 = postura armada del todo.
	var _pose := 0.0
	var _pose_on := false
	## Cuántos grados de pitch pide el estado actual.
	var _pitch_pide := 0.0
	var _destino := Vector3.ZERO
	var _vel := 0.0

	# ── UNA SOLA ESCRITURA DE TRANSFORMADA POR CUADRO. No es estilo. ────────
	#
	# `AnimatableBody3D` con `sync_to_physics` **difiere la transformada**: la
	# maneja el servidor de física y lo que le escribís no se ve hasta que el
	# paso de física la confirma, un cuadro después. Y ahí está la trampa:
	# escribir `rotation.y` es un lee-modifica-escribe de la transformada
	# ENTERA, así que lee la posición vieja —la que todavía no se confirmó— y
	# **pisa el movimiento que acabás de pedir.**
	#
	# El bicho corría a 7 m/s y avanzaba exactamente 0,00 m. Medido: con
	# `_mover()` solo, 0,1167 m por cuadro, clavado; con `_mirar_a()` detrás,
	# cero. No lo muestra ninguna captura y no lo grita ningún error.
	#
	# Por eso la posición y el rumbo son de ESTE objeto y el nodo se escribe una
	# sola vez, al final de `correr()`, con las dos cosas juntas.
	#
	# `_pos` es GLOBAL, no local: `jug` llega en coordenadas de mundo y mezclar
	# los dos espacios es el bug que aparece el día que alguien mueva el nodo
	# padre y nadie sepa por qué las vacas huyen para el lado equivocado.
	var _pos := Vector3.ZERO
	var _yaw := 0.0
	## Antirrebote: hasta cuándo no puede volver a asustarse.
	var _reposo := 0.0
	## Lo pone `_arrancar_huida()` y lo consume `correr()`. Ver ahí por qué el
	## aviso vive en la transición y no en cada rama del `match`.
	var _recien_huye := false
	var _rng := RandomNumberGenerator.new()


	func arrancar(rng: RandomNumberGenerator) -> void:
		_rng.seed = rng.randi()
		_pos = global_position
		_yaw = global_rotation.y
		_destino = sitio
		_pastar()
		# El desfasaje es lo que evita el peor efecto posible: cuatro vacas
		# masticando en el mismo cuadro exacto, que se lee como copia y pega y
		# arruina las cuatro de una.
		if animador != null and animador.current_animation != "":
			var a := animador.get_animation(animador.current_animation)
			if a != null:
				animador.advance(_rng.randf() * a.length)
		_reloj *= _rng.randf()


	## Un paso de la máquina. Devuelve `true` **el cuadro exacto en que arranca
	## a huir**, que es cuando hay que contagiar al rebaño y hacer ruido: el
	## que sabe que eso pasó es este objeto y nadie más.
	##
	## El aviso sale de una bandera que pone `_arrancar_huida()` y no de un
	## `return true` en cada rama, y eso es un arreglo, no un gusto: **hay
	## CUATRO puertas a HUYE** —el aviso, el recelo, el atajo de tenerte encima
	## y el golpe— y la versión con `return`s se olvidaba de la cuarta. Un bicho
	## al que le pegabas salía corriendo mudo y sin arrastrar al rebaño. Con la
	## bandera en la transición no hay quinta puerta que se pueda olvidar.
	func correr(dt: float, jug: Vector3, dist: float) -> bool:
		_reloj -= dt
		_reposo = maxf(0.0, _reposo - dt)

		match _paso:
			Fauna.Paso.PACE, Fauna.Paso.MIRA, Fauna.Paso.ANDA:
				_ciclo(dt, jug, dist)
			Fauna.Paso.ATENTO:
				# El momento de duda, y es el mismo medio segundo del monstruo.
				# Quieto, girado hacia vos, la cabeza arriba. Lo que decide al
				# final es `cede`, no `recelo`: el lobo llega hasta acá y se
				# queda, y ésos son los once metros y medio que lo definen.
				_mirar_a(jug, dt, 7.0)
				if _reloj <= 0.0:
					if dist < float(datos["cede"]):
						_arrancar_huida(jug)
					else:
						_recelar()
			Fauna.Paso.HUYE:
				_correr_huida(dt, jug, dist)
			Fauna.Paso.RECELA:
				# La consecuencia: no vuelve a comer de una. Se queda con la
				# cabeza arriba mirando para donde se asustó.
				if dist < INF:
					_mirar_a(jug, dt, 3.5)
				# **`_reposo` tiene que mirarse ACÁ TAMBIÉN.** Sin esta mitad de
				# la condición, un bicho arrinconado terminaba de huir, entraba
				# en RECELA y volvía a salir disparado **al cuadro siguiente**,
				# en bucle: medido, RECELA en el cuadro 409 y HUYE en el 410. Es
				# exactamente el rebote del amago abandonado del monstruo y se
				# arregla con la misma constante.
				if dist < float(datos["cede"]) and _reposo <= 0.0:
					_arrancar_huida(jug)
				elif _reloj <= 0.0:
					_pastar()

		_correr_pose(dt)
		_aplicar(dt)
		_asentar()
		var salio := _recien_huye
		_recien_huye = false
		return salio


	## Los tres estados de pastar.
	func _ciclo(dt: float, jug: Vector3, dist: float) -> void:
		if dist < float(datos["recelo"]) and _reposo <= 0.0:
			# Si ya lo tenés encima no hay tiempo de dudar: los 33 cuadros de
			# aviso son para el que se acerca, no para el que ya llegó.
			if dist < float(datos["cede"]) * 0.5:
				_arrancar_huida(jug)
			else:
				_atender()
			return

		match _paso:
			Fauna.Paso.PACE:
				if _reloj <= 0.0:
					_levantar()
			Fauna.Paso.MIRA:
				if _reloj <= 0.0:
					_andar()
			Fauna.Paso.ANDA:
				var d := _destino - _pos
				d.y = 0.0
				if _reloj <= 0.0 or d.length() < 0.5:
					_pastar()
				else:
					_vel = float(datos["paso"])
					_mover(dt, d.normalized())
					_mirar_a(_pos + d, dt, 2.5)


	# ── Las transiciones. Una función por estado, como el monstruo ──────────

	func _pastar() -> void:
		_paso = Fauna.Paso.PACE
		_reloj = _rng.randf_range(Fauna.PACE_MIN, Fauna.PACE_MAX)
		_pose_on = false
		_pitch_pide = 0.0
		# `Eating` es la que baja la cabeza al piso, y en el ciervo eso son
		# −36% de alto en pantalla. Es la pose más barata y la más legible que
		# hay en el pack: no hay que dibujar nada.
		_animar("Eating", _rng.randf_range(0.55, 0.85))

	func _levantar() -> void:
		_paso = Fauna.Paso.MIRA
		_reloj = _rng.randf_range(Fauna.MIRA_MIN, Fauna.MIRA_MAX)
		_pose_on = false
		_pitch_pide = 0.0
		_animar("Idle", _rng.randf_range(0.8, 1.1))

	func _andar() -> void:
		_paso = Fauna.Paso.ANDA
		_reloj = _rng.randf_range(Fauna.ANDA_MIN, Fauna.ANDA_MAX)
		_pose_on = false
		_pitch_pide = 0.0
		# El motivo de caminar: el pasto de al lado. Nunca en línea recta hacia
		# el infinito —eso es lo que se leía como bug— sino a un punto adentro
		# de `DERIVA` de su sitio en el rebaño.
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(1.5, Fauna.DERIVA)
		_destino = sitio + Vector3(cos(a) * r, 0.0, sin(a) * r)
		_animar("Walk", _rng.randf_range(0.9, 1.1))

	## El aviso. Mismo nombre de cosa que `Monstruo.Estado.ALERTA` y mismos 33
	## cuadros: se frena, te mira y recién ahí decide.
	func _atender() -> void:
		if _paso == Fauna.Paso.ATENTO:
			return
		_paso = Fauna.Paso.ATENTO
		_reloj = Fauna.ATENTO_DURA
		_pose_on = true
		_pitch_pide = Fauna.ALZA_GRADOS
		# `Idle` a velocidad casi cero: **la quietud es la mitad de la lectura.**
		# Un rebaño pastando es siete cuerpos moviéndose cada uno por su cuenta;
		# un rebaño asustado son siete cuerpos apuntando a lo mismo y ninguno
		# moviéndose. Eso se ve a 68 m aunque cada bicho mida diez píxeles.
		_animar("Idle", 0.12)

	func _arrancar_huida(jug: Vector3) -> void:
		# **La única puerta a HUYE, y por eso el aviso se pone acá.** Ver
		# `correr()`: con un `return true` por rama se olvidaba la del golpe.
		_recien_huye = true
		_paso = Fauna.Paso.HUYE
		_reloj = Fauna.HUYE_MAX
		_pose_on = true
		_pitch_pide = Fauna.TENDIDA_GRADOS
		var d := _pos - jug
		d.y = 0.0
		if d.length_squared() < 0.01:
			d = Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0))
		# Un poco de sesgo al azar por cabeza: siete ciervos huyendo por la
		# misma línea exacta se leen como un vagón, no como una manada.
		_destino = _pos + d.normalized().rotated(
			Vector3.UP, _rng.randf_range(-0.5, 0.5)) * 40.0
		_animar("Walk", Fauna.TROTE_ANIM)

	func _recelar() -> void:
		_paso = Fauna.Paso.RECELA
		_reloj = _rng.randf_range(Fauna.CALMA_MIN, Fauna.CALMA_MAX)
		# El freno de después de correr es el beat de decidir, no el del
		# antirrebote: si seguís ahí, el bicho se va DE NUEVO, pero volver a
		# irse tiene que verse como una segunda decisión y no como un tic.
		_reposo = Fauna.ATENTO_DURA
		_pose_on = true
		_pitch_pide = Fauna.ALZA_GRADOS
		_animar("Idle", 0.35)


	## Correr de verdad: hacia el destino, hasta que ya estés lejos o se acabe
	## el tiempo. El techo de tiempo existe para que un bicho acorralado contra
	## la cordillera no corra para siempre contra la piedra.
	func _correr_huida(dt: float, jug: Vector3, dist: float) -> void:
		var d := _destino - _pos
		d.y = 0.0
		if d.length() > 0.5:
			_vel = float(datos["trote"])
			_mover(dt, d.normalized())
			_mirar_a(_pos + d, dt, 6.0)
		if _reloj <= 0.0 or dist > float(datos["recelo"]) * 1.6:
			_recelar()


	## Le pegaste. **No hay vida, no hay daño y no hay servidor**: se va, y se
	## va ya, sin los 33 cuadros de duda — la anticipación de este golpe fueron
	## los 5 cuadros de tu swing y ya pasaron.
	##
	## La chispa cae en `Impacto.CONTACTO`, el mismo cuadro 5 que el monstruo, y
	## por el mismo motivo: el arma llega en el cuadro 5, no en el 0. Se pinta en
	## polvo (`PASTO_SECO`) y no en brasa, que es el color de un golpe que
	## cuenta.
	func pegado(desde: Vector3) -> void:
		_arrancar_huida(desde)
		_reposo = 0.0
		# El temporizador va `process_in_physics` para caer en el mismo reloj que
		# la máquina, y NO ignora `time_scale`: si el mundo está congelado por
		# otro golpe, la polvareda espera con todo lo demás.
		var t := get_tree().create_timer(Impacto.CONTACTO, true, true)
		t.timeout.connect(_polvareda)
		# El rebaño y la voz salen solos: `_arrancar_huida()` levantó
		# `_recien_huye` y `correr()` lo consume en el próximo paso de física.


	func _polvareda() -> void:
		if not is_inside_tree():
			return
		Impacto.estallar(self, _pos + Vector3.UP * (largo * 0.25),
			Paleta.PASTO_SECO, 0.7)


	## Lo agarró el susto de otro. Entra en ATENTO, no en HUYE: la onda se ve
	## porque cada uno se toma sus 33 cuadros para decidirse.
	func contagiar() -> void:
		if _paso == Fauna.Paso.HUYE or _paso == Fauna.Paso.ATENTO:
			return
		_atender()


	# ── Movimiento y postura ────────────────────────────────────────────────

	func _mover(dt: float, dir: Vector3) -> void:
		_pos += dir * _vel * dt
		_pos.y = _altura(_pos)


	## La única escritura al nodo, y va al final del cuadro. Ver el comentario
	## de `_pos` arriba: dos escrituras se pisan entre sí.
	func _asentar() -> void:
		global_transform = Transform3D(Basis(Vector3.UP, _yaw), _pos)


	## Los `.glb` de Quaternius miran a **+Z**, así que el yaw que apunta el
	## frente a `d` es `atan2(d.x, d.z)` y no el `atan2(-d.x, -d.z)` de la
	## convención de Godot. Está medido: el hueso `Head` cae en z positivo y
	## `Tail1` en z negativo en las siete especies.
	func _mirar_a(punto: Vector3, dt: float, rapidez: float) -> void:
		var d := punto - _pos
		d.y = 0.0
		if d.length_squared() < 0.01:
			return
		_yaw = lerp_angle(_yaw, atan2(d.x, d.z), minf(1.0, rapidez * dt))


	## La rampa de la postura, calcada de `Figura._correr_amago()`: sube en
	## `POSE_ALZA` cuadros y baja en `POSE_SUELTA`.
	func _correr_pose(dt: float) -> void:
		if _pose_on:
			if _pose < 1.0:
				_pose = minf(1.0, _pose + dt / Fauna.POSE_ALZA)
		elif _pose > 0.0:
			_pose = maxf(0.0, _pose - dt / Fauna.POSE_SUELTA)


	## Aplica la postura al pivote. `p*p` en la subida, igual que el amago del
	## monstruo: el cuerpo empieza a alzarse despacio y termina de golpe, que es
	## como se mueve algo con peso.
	##
	## El levante en `y` vale cero y eso está medido, no olvidado: ver `APOYO`.
	func _aplicar(dt: float) -> void:
		if pivote == null:
			return
		var p := _pose * _pose
		var ang := deg_to_rad(_pitch_pide) * p
		pivote.rotation.x = lerp_angle(pivote.rotation.x, ang, minf(1.0, 14.0 * dt))
		pivote.position.y = absf(sin(pivote.rotation.x)) * largo * Fauna.APOYO


	func _animar(cual: String, rapidez: float) -> void:
		if animador == null or not animador.has_animation(cual):
			return
		if animador.current_animation != cual:
			animador.play(cual)
		animador.speed_scale = rapidez


	func _altura(p: Vector3) -> float:
		if alturas.is_valid():
			return alturas.call(p.x, p.z)
		return p.y

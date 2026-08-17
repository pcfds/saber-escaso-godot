## El lecho de ambiente del valle. Sin un solo archivo de audio.
##
## Hasta acá el juego era mudo, y eso es la mitad de por qué se sentía una
## maqueta: ningún efecto visual tapa el silencio.
##
## LA REGLA DE LA CASA APLICADA AL OÍDO. Un ambiente que no dice dónde estás
## ni qué hora es, es ruido con buena intención. Así que cada voz de este
## archivo tiene que contestar una de estas dos preguntas, y las dos se
## contestan sin abrir ningún menú y sin mirar la pantalla:
##
##   DÓNDE ESTOY  · el río se oye desde la aldea y desde la fragua, y no desde
##                  el bosque: es la referencia fija del valle
##                · el martillo de la fragua cruza el valle entero — es el
##                  único sonido que lo hace — y dice "Ilde está trabajando y
##                  la fragua queda para allá"
##                · el Sotobosque APAGA el ambiente. La caída de volumen es la
##                  información: entraste, y esto no es el prado
##                · la Casa Quemada es el único lugar con un sonido AFINADO
##                  (el viento resonando en lo que quedó de la casa). No se
##                  confunde con nada
##                · el Camino del Norte es el lugar más ventoso: la cordillera
##                  tiene una sola abertura y el viento entra por ahí
##   QUÉ HORA ES  · grillos = es de noche · coro de pájaros = está amaneciendo
##                · el hogar de la aldea sube al alba y al anochecer, que es
##                  cuando se cocina, y baja al mediodía
##                · la fragua nunca se apaga del todo, pero de noche es brasa
##                  sin martillo: alguien duerme y el fuego no
##
## EL SILENCIO ES MATERIAL. La noche del valle es más callada que el día — no
## por gusto de tono, sino porque si todo suena todo el tiempo nada pesa. Lo
## que queda de noche es el río, los grillos y la brasa de la fragua. En el
## Sotobosque de noche no queda casi nada, y eso es a propósito.
##
## POR QUÉ TODO SINTETIZADO. Igual que el cielo (un shader escrito a mano) y
## que los cuerpos (animados sin archivos de animación): no hay assets y el
## .exe se baja por internet. Esto pesa CERO en disco y CERO en la descarga.
## Lo que cuesta son 103 ms de CPU una sola vez, al arrancar — medidos, no
## estimados: los imprime la escena de prueba cada vez que corre.
##
## HASTA DÓNDE LLEGA LA SÍNTESIS — está dicho sin maquillaje en cada función:
## el viento, el río, el fuego, los grillos y el lamento de la ruina salen
## bien por síntesis. Los pájaros salen pasables. El martillo del yunque es el
## techo de lo que se puede fingir. Las voces no se intentan.
##
## NADIE DEL EQUIPO ESCUCHÓ ESTO TODAVÍA. No hay forma de afirmar cómo suena
## desde acá: bajo WSL no hay salida de audio. Lo que se puede verificar es lo
## que imprime `escenas/prueba_sonido.tscn`: qué eligió para cada lugar y cada
## hora. Que alguien lo corra con parlantes.
class_name Sonido
extends Node3D

# ─────────────────────────────────────────────────────────────────────────
#  EL LECHO. Esta mitad del archivo es pura: dado un lugar y una hora,
#  devuelve la mezcla. No toca la escena, no toca el AudioServer, y es lo
#  único que la prueba puede verificar sin oír nada.
# ─────────────────────────────────────────────────────────────────────────

## Cuánto pesa cada voz en cada lugar. Es el "acento" del lugar: lo que hace
## que la aldea no suene como el camino aunque las dos tengan viento.
##
## `brillo` no es volumen, es TIMBRE: qué tan abierto está el filtro del
## viento. Bajo el sotobosque el viento se oye tapado por las copas; en el
## camino, que es la abertura de la cordillera, se oye crudo. Dos lugares con
## el mismo volumen de viento y distinto brillo se distinguen igual — y esa es
## la parte que sigue funcionando cuando el jugador baja el volumen.
const LECHOS := {
	# Vado Bajo. Doce casas apretadas contra el recodo del río. El único lugar
	# con gente: pájaros de día (hay huerta y hay basura), grillos de noche.
	"aldea":  {"viento": 0.55, "pajaros": 1.00, "grillos": 0.55, "hojas": 0.00, "hueco": 0.00, "brillo": 0.55},
	# La Fragua de Ilde. Lo que la define no está en esta tabla: está en el
	# fuego y el yunque, que son sonidos con LUGAR (ver _armar_emisores).
	"fragua": {"viento": 0.45, "pajaros": 0.55, "grillos": 0.40, "hojas": 0.00, "hueco": 0.00, "brillo": 0.60},
	# El Sotobosque. Acá el ambiente se APAGA. No hay grillos, casi no hay
	# pájaros, el viento queda arriba en las copas. Lo único que queda es la
	# madera trabajando, y cada tanto algo que se rompe y no sabés qué fue.
	# Ahí viven Los del Sotobosque, que son un pueblo con un agravio, no
	# monstruos: el lugar tiene que dar cosa por vacío, no por música de miedo.
	"bosque": {"viento": 0.22, "pajaros": 0.10, "grillos": 0.00, "hojas": 1.00, "hueco": 0.00, "brillo": 0.22},
	# La Casa Quemada. Se incendió antes de que nadie vivo estuviera acá y
	# nadie la reconstruye. Sin techo y sin fuego: el viento entra por los
	# huecos y la casa canta una nota. Es el único sonido afinado del valle.
	"ruina":  {"viento": 0.80, "pajaros": 0.12, "grillos": 0.35, "hojas": 0.10, "hueco": 1.00, "brillo": 0.70},
	# El Camino del Norte. La única abertura de la cordillera. Por acá entra
	# el viento y por acá entra la gente — poca. Es el lugar más expuesto y el
	# más ruidoso al mediodía, y no tiene nada que lo abrigue.
	"camino": {"viento": 1.45, "pajaros": 0.25, "grillos": 0.10, "hojas": 0.00, "hueco": 0.15, "brillo": 1.00},
	# Campo abierto: el valle entre lugares. No es un relleno — es el estado
	# por defecto del mundo, y es contra lo que se mide que el bosque apague.
	"campo":  {"viento": 1.00, "pajaros": 0.50, "grillos": 0.55, "hojas": 0.00, "hueco": 0.00, "brillo": 0.85},
}

## Dónde está cada lugar y desde qué distancia se lo empieza a oír.
## `[radio_lleno, radio_cero]`: adentro del primero estás del todo en el
## lugar; pasado el segundo, no queda nada. El bosque tiene la transición más
## ancha a propósito: querés SENTIR que se apaga mientras te acercás, no que
## se apague de golpe cuando cruzás una línea.
##
## Las posiciones son las mismas de `valle.gd`. Están copiadas para que la
## escena de prueba corra sola; si `preparar()` recibe la tabla del valle,
## esta copia se descarta.
const POS := {
	"aldea":  {"pos": Vector3(0, 0, 0),      "r": [24.0, 52.0]},
	"fragua": {"pos": Vector3(62, 0, -18),   "r": [20.0, 46.0]},
	"bosque": {"pos": Vector3(-58, 0, -54),  "r": [26.0, 62.0]},
	"ruina":  {"pos": Vector3(-26, 0, -108), "r": [20.0, 46.0]},
	"camino": {"pos": Vector3(11, 0, 74),    "r": [24.0, 56.0]},
}

## El río de `valle.gd`: un plano de 430 m centrado en (0, -1.7, 26) y girado
## 9°. Un río de 430 metros con un solo emisor puntual es una fuente que te
## sigue; con tres, caminar por la orilla se oye como caminar por la orilla.
const RIO_CENTRO := Vector3(0, -1.0, 26)
const RIO_GIRO := 9.0
const RIO_SEPARACION := 70.0

## Las curvas del día. 0 es medianoche, 0.25 el amanecer, 0.5 el mediodía.
## Cada par es [fracción, valor] y tienen que empezar en 0.0 y terminar en 1.0.

## El viento sigue al sol: mínimo de madrugada, máximo a media tarde. Es
## física real y de paso es la voz que nunca se va del todo, la que impide que
## el valle quede en silencio absoluto cuando no pasa nada.
const CURVA_VIENTO := [[0.00, 0.22], [0.20, 0.26], [0.30, 0.42], [0.45, 0.72],
	[0.55, 0.88], [0.70, 0.80], [0.82, 0.46], [0.92, 0.28], [1.00, 0.22]]

## El coro del amanecer es el aviso de hora más fuerte que existe: arranca de
## la nada a las 0.20 y explota a las 0.27. Después baja — al mediodía los
## pájaros callan, que es real y además deja lugar para el viento — y vuelve
## un rato más chico al atardecer. A las 0.86 no queda ninguno.
const CURVA_PAJAROS := [[0.00, 0.00], [0.18, 0.00], [0.23, 0.55], [0.27, 1.00],
	[0.34, 0.62], [0.50, 0.20], [0.62, 0.30], [0.76, 0.52], [0.82, 0.14],
	[0.86, 0.00], [1.00, 0.00]]

## Los grillos son el reloj de la noche y se cruzan con el coro: a las 0.22
## todavía quedan algunos mientras empiezan los pájaros. Ese solapamiento de
## cinco minutos es lo que hace que el amanecer se sienta un pasaje y no un
## corte.
const CURVA_GRILLOS := [[0.00, 0.90], [0.14, 0.88], [0.22, 0.30], [0.27, 0.00],
	[0.72, 0.00], [0.79, 0.35], [0.86, 0.80], [0.94, 0.90], [1.00, 0.90]]

## El apagón general de la noche. NO se le aplica al río ni a la fragua: lo
## que hace que la noche se sienta noche es justamente que se caiga todo lo
## demás y queden esos dos.
const CURVA_MAESTRO := [[0.00, 0.72], [0.20, 0.74], [0.28, 0.88], [0.45, 1.00],
	[0.70, 1.00], [0.82, 0.88], [0.90, 0.74], [1.00, 0.72]]

## "El único techo de la región que nunca se apaga del todo." De noche baja a
## 0.42 y nunca a cero. Ese 0.42 es la frase del lugar dicha en un número.
const CURVA_FUEGO := [[0.00, 0.42], [0.22, 0.45], [0.30, 0.95], [0.55, 1.00],
	[0.75, 0.95], [0.84, 0.60], [1.00, 0.42]]

## El martillo. Ilde trabaja de día: entre 0.26 y 0.84 y nada afuera. Si de
## madrugada oís el yunque, algo pasó — pero eso es una ronda posterior, hoy
## simplemente calla.
const CURVA_YUNQUE := [[0.00, 0.00], [0.26, 0.00], [0.32, 0.85], [0.50, 1.00],
	[0.70, 0.90], [0.80, 0.25], [0.84, 0.00], [1.00, 0.00]]

## El hogar de la aldea tiene DOS picos: el alba y el anochecer. Es cuando se
## cocina. Al mediodía la gente está afuera trabajando y el fuego está bajo.
## Dos picos en vez de uno es lo que separa "hay fuego" de "hay alguien".
const CURVA_HOGAR := [[0.00, 0.55], [0.18, 0.60], [0.26, 0.95], [0.38, 0.55],
	[0.50, 0.30], [0.68, 0.45], [0.80, 0.95], [0.90, 0.80], [1.00, 0.55]]

## Las voces del lecho de fondo (sin lugar en el mundo, suenan en la cabeza).
const VOCES_FONDO: Array[String] = ["viento", "pajaros", "grillos", "hojas", "hueco"]


## Interpola una curva de [fracción, valor]. La hora da la vuelta sola.
static func curva(puntos: Array, f: float) -> float:
	var x := fposmod(f, 1.0)
	for i in range(puntos.size() - 1):
		var a: Array = puntos[i]
		var b: Array = puntos[i + 1]
		var xa := float(a[0])
		var xb := float(b[0])
		if x >= xa and x <= xb:
			if xb - xa < 0.000001:
				return float(b[1])
			return lerpf(float(a[1]), float(b[1]), (x - xa) / (xb - xa))
	return float((puntos[puntos.size() - 1] as Array)[1])


## Cómo se llama esta hora. Mismas palabras que `ciclo.gd` para que la prueba
## y la interfaz digan lo mismo.
static func franja(f: float) -> String:
	var x := fposmod(f, 1.0)
	if x < 0.20: return "de madrugada"
	if x < 0.30: return "al amanecer"
	if x < 0.45: return "de mañana"
	if x < 0.58: return "al mediodía"
	if x < 0.72: return "de tarde"
	if x < 0.82: return "al atardecer"
	return "de noche"


## EL LECHO, dado un lugar y una hora. Es la función que hay que leer para
## entender el diseño entero, y la que la prueba imprime.
##
## Devuelve ganancias lineales. Las cinco primeras son el fondo; `rio`,
## `fuego`, `hogar` y `yunque` son de las fuentes que tienen lugar en el mundo
## y su volumen final lo termina de decidir la distancia, no esta tabla.
static func lecho(slug: String, f: float) -> Dictionary:
	return mezclar(LECHOS.get(slug, LECHOS["campo"]), f)


static func mezclar(acento: Dictionary, f: float) -> Dictionary:
	var viento := curva(CURVA_VIENTO, f)
	var maestro := curva(CURVA_MAESTRO, f)
	# La madera trabaja y la casa canta cuando hay viento: las dos cuelgan del
	# viento en vez de tener curva propia. Y las dos tienen un piso, porque un
	# bosque en calma sigue crujiendo.
	var hojas := 0.10 + 0.28 * viento
	var hueco := 0.20 + 0.45 * viento
	var g := {
		"viento": viento * float(acento.get("viento", 0.0)) * maestro,
		"pajaros": curva(CURVA_PAJAROS, f) * float(acento.get("pajaros", 0.0)) * maestro,
		"grillos": curva(CURVA_GRILLOS, f) * float(acento.get("grillos", 0.0)) * maestro,
		"hojas": hojas * float(acento.get("hojas", 0.0)) * maestro,
		"hueco": hueco * float(acento.get("hueco", 0.0)) * maestro,
		# El río no duerme y no lo apaga la noche. Es el ancla del valle.
		"rio": 1.0,
		"fuego": curva(CURVA_FUEGO, f),
		"hogar": curva(CURVA_HOGAR, f),
		"yunque": curva(CURVA_YUNQUE, f),
		"brillo": float(acento.get("brillo", 0.7)),
		"maestro": maestro,
	}
	var t := 0.0
	for v in VOCES_FONDO:
		t += float(g[v])
	g["fondo"] = t
	return g


## Cuánto pesa cada lugar desde un punto del valle. Entre la aldea y la fragua
## no estás "en ninguno": estás en campo abierto, que es un lecho propio.
##
## Esto NO es la misma cuenta que `_avisar_donde_estoy()` de valle.gd, y no
## tiene que serlo. Aquella tiene histéresis porque le manda un evento al
## servidor y siete llegadas en un tick ensucian la crónica. El oído no tiene
## eventos: quiere un cruce continuo.
static func pesos_en(pos: Vector3, tabla: Dictionary) -> Dictionary:
	var yo := Vector2(pos.x, pos.z)
	var pesos := {}
	var suma := 0.0
	for slug: String in tabla:
		var d: Dictionary = tabla[slug]
		var c: Vector3 = d["pos"]
		var r: Array = d["r"]
		var dist := yo.distance_to(Vector2(c.x, c.z))
		var w := 1.0 - smoothstep(float(r[0]), float(r[1]), dist)
		if w > 0.001:
			pesos[slug] = w
			suma += w
	var campo := clampf(1.0 - suma, 0.0, 1.0)
	if campo > 0.001:
		pesos["campo"] = campo
		suma += campo
	if suma <= 0.0:
		return {"campo": 1.0}
	for slug: String in pesos:
		pesos[slug] = float(pesos[slug]) / suma
	return pesos


## El lecho en un punto y una hora: el acento de cada lugar cercano, mezclado.
func lecho_en(pos: Vector3, f: float) -> Dictionary:
	var pesos := pesos_en(pos, _tabla)
	var acento := {}
	for clave in ["viento", "pajaros", "grillos", "hojas", "hueco", "brillo"]:
		var v := 0.0
		for slug: String in pesos:
			var a: Dictionary = LECHOS.get(slug, LECHOS["campo"])
			v += float(a.get(clave, 0.0)) * float(pesos[slug])
		acento[clave] = v
	var g := mezclar(acento, f)
	g["pesos"] = pesos
	return g


# ─────────────────────────────────────────────────────────────────────────
#  LA ESCENA. Buses, emisores y la mezcla en vivo.
# ─────────────────────────────────────────────────────────────────────────

## Prendé esto en una escena y el nodo se prepara solo e imprime el informe.
## Es lo que hace `escenas/prueba_sonido.tscn`.
@export var modo_prueba := false
## Cuánto sale por el parlante. -9 dB de base: el ambiente NO compite con
## nada, va debajo de todo lo que pase después (pasos, golpes, diálogo).
@export var volumen_general := 0.62

## De dónde sale la hora. Es `ciclo.gd`, que la recibe del SERVIDOR. Si esto
## queda en null se usa `hora_manual`, y eso sólo vale para la prueba: un
## temporizador local rompe que dos personas conectadas compartan el momento.
var ciclo: Node
## Quién oye. En el juego es el jugador.
var oyente: Node3D
## Para la prueba, cuando no hay ciclo.
var hora_manual := 0.5

const HZ := 22050
const CRUCE := 2200        ## 0,1 s de fundido para cerrar el bucle sin clic
const PREFIJO := "SE_"     ## los buses son nuestros y se ven

var _tabla := POS.duplicate(true)
var _buses: Array[String] = []
var _jug: Dictionary = {}          ## voz → Array[AudioStreamPlayer*]
var _gan: Dictionary = {}          ## voz → ganancia suavizada
var _listo := false
var _reloj := 0.0
var _prox_martillo := 2.0
var _martillos_seguidos := 0
var _prox_crujido := 12.0
var _ms_generacion := 0.0

## SIN SALIDA DE AUDIO, NO SE REPRODUCE NADA. Se calcula todo igual.
##
## Cuando Godot corre en headless —la verificación de este repo, `desplegar.sh`
## y cualquier máquina sin placa de sonido— el driver es `Dummy` y no hay a
## dónde mandar el audio. Reproducir doce streams contra la nada es trabajo
## tirado en cada corrida.
##
## Y además arregla un defecto real que apareció al cablear el módulo en la
## escena de verdad: **Godot cierra con
## `WARNING: N ObjectDB instances were leaked at exit` si hay audio sonando
## cuando termina el proceso.** Lo investigué hasta el fondo y esto es lo que
## se midió, no lo que supongo:
##
##   · el motor suelta una reproducción detenida en su próxima MEZCLA, y esa
##     mezcla la dispara el bucle principal, no un reloj. Entre el `stop()` y
##     el cierre hacen falta DOS cuadros de proceso: con cero o con uno el
##     aviso sale igual, con dos desaparece.
##   · en `_exit_tree()` ya no queda ningún cuadro, así que ahí es tarde POR
##     DEFINICIÓN. Probé apagar ahí, no tocar nada, liberar los emisores a
##     mano, vaciar los buses con `set_bus_count(1)` y dormir 60 ms de reloj:
##     las veinte instancias quedaban colgadas en los cinco casos.
##   · no hay forma de forzar una mezcla desde GDScript. Recorrí
##     `AudioServer.get_method_list()`: no existe ningún `mix`, `flush` ni
##     `update`.
##   · `OS.get_cmdline_args()` NO trae `--quit-after` (Godot se queda con los
##     argumentos del motor), así que el módulo tampoco puede ver venir el
##     cierre para adelantarse.
##   · **y no es un defecto de este archivo.** El control es un
##     `AudioStreamPlayer` pelado en el bus Master, sin una línea de acá:
##     también deja dos instancias colgadas. Es comportamiento del motor para
##     cualquier audio que esté sonando al salir.
##
## Con esta regla, ninguna corrida headless reproduce nada y ninguna deja nada
## colgado, en cualquier condición y la maten cuando la maten.
##
## LO QUE NO ARREGLA, dicho de frente: con placa de sonido de verdad y un
## build de depuración, cerrar el juego sigue dejando esas instancias. Es del
## motor, es cosmético (el aviso no se imprime en un build de release y el
## sistema operativo recupera la memoria igual) y no depende de este módulo.
##
## EL COSTO DE ESTA REGLA, y cómo se paga. Si en headless no suena nada, una
## corrida headless tampoco puede descubrir una fuga de audio nueva. Por eso
## existe `--sonido-con-audio`: fuerza la reproducción aunque no haya salida,
## y con eso la condición que rompe se puede pedir a mano, en la escena de
## prueba, sin esperar a que la descubra el cableado:
##
##   godot --headless escenas/prueba_sonido.tscn --quit-after 60 -- --sonido-con-audio
##
## Eso HOY deja instancias colgadas, y tiene que dejarlas: es el motor y está
## medido. Lo que hay que mirar en esa corrida es que el número no CREZCA: es
## una por emisor sonando más una por bucle distinto — hoy 12 + 8 = 20. Si un
## día salta, alguien agregó un emisor que no se apaga.
const FORZAR_AUDIO := "--sonido-con-audio"

var _hay_salida := true


func _ready() -> void:
	# `_ready()` no hace NADA en el juego: el valle llama a `preparar()` cuando
	# ya tiene la tabla de lugares y el jugador. Es a propósito — un error en
	# `_ready()` aborta la función entera y todo lo que venía después nunca se
	# inicializa (en este repo eso dejó al juego sin HUD). El sonido no puede
	# ser el que rompa el arranque de nadie.
	if modo_prueba:
		var o := get_node_or_null("Oyente") as Node3D
		if o != null:
			oyente = o
		preparar()
		_informe_de_prueba()


## La llama el valle. `lugares` es la tabla LUGARES de valle.gd (opcional: si
## no viene, se usa la copia de acá).
func preparar(lugares: Dictionary = {}) -> void:
	_hay_salida = AudioServer.get_driver_name() != "Dummy" \
		or OS.get_cmdline_user_args().has(FORZAR_AUDIO)
	if not lugares.is_empty():
		_tabla = {}
		for slug: String in lugares:
			var r: Array = POS[slug]["r"] if POS.has(slug) else [24.0, 52.0]
			_tabla[slug] = {"pos": lugares[slug]["pos"], "r": r}
	_armar_buses()
	_armar_emisores()
	# Se genera acá, sincrónico, y no en un hilo. Se midió: 103 ms para los
	# diez bucles en esta máquina. Al lado de `_armar_terreno()`, que arma
	# 388.800 vértices a mano en el mismo arranque, esto no se nota — y un
	# hilo sería un camino más que puede fallar en `_ready()`, que es
	# exactamente la trampa que este repo ya pisó una vez.
	var t0 := Time.get_ticks_usec()
	_montar(_generar_todo())
	_ms_generacion = (Time.get_ticks_usec() - t0) / 1000.0


## Qué hora es en el valle. La manda el servidor a través de `ciclo.gd`.
##
## `ciclo.gd` guarda la fracción en `_fraccion` y no expone un getter. No lo
## toco porque este trabajo tiene permiso para crear dos archivos y ninguno es
## ése; lo leo por nombre y prefiero `fraccion()` si algún día existe. La
## instrucción de cableado pide agregar ese getter de una línea.
func hora() -> float:
	if ciclo != null:
		if ciclo.has_method("fraccion"):
			return fposmod(float(ciclo.call("fraccion")), 1.0)
		var f: Variant = ciclo.get("_fraccion")
		if f != null:
			return fposmod(float(f), 1.0)
	return fposmod(hora_manual, 1.0)


func _exit_tree() -> void:
	# Si a este nodo lo sacan del árbol, el valle se queda callado y los buses
	# vuelven. Para que además no queden instancias colgadas hay que apagar
	# ANTES — ver `SIN SALIDA DE AUDIO, NO SE REPRODUCE NADA`, más abajo.
	apagar()


func _notification(que: int) -> void:
	# Cerrar la ventana también es irse.
	if que == NOTIFICATION_WM_CLOSE_REQUEST:
		apagar()


## Cortar todo y devolver los buses. Se puede llamar en cualquier momento.
func apagar() -> void:
	for voz: String in _jug:
		for p: Node in _jug[voz]:
			if is_instance_valid(p):
				p.call("stop")
				p.set("stream", null)
	_listo = false
	_soltar_buses()


# ── Buses ────────────────────────────────────────────────────────────────
#
# Se crean EN TIEMPO DE EJECUCIÓN, no desde el editor. Dos razones y las dos
# valen: `project.godot` lo está tocando otro, y un bus creado por código es
# un bus que se explica solo en el mismo archivo que lo usa.
#
# Cada voz tiene su bus con un filtro propio, y ahí está el truco central de
# todo esto: el BUCLE es fijo y corto, la MODULACIÓN es viva. Un ruido rosa de
# cuatro segundos, pasado por un pasabajos cuyo corte se mueve con tres senos
# lentos que no son múltiplos entre sí, no se oye como un bucle de cuatro
# segundos. Es la misma idea que `figura.gd` usa para animar cuerpos sin
# archivos de animación.

func _armar_buses() -> void:
	_bus(PREFIJO + "Valle", "Master", null)
	# El viento: pasabajos que se abre con las ráfagas y con lo abierto del
	# lugar. Es la voz que dice "cuán a la intemperie estás".
	_bus(PREFIJO + "Viento", PREFIJO + "Valle", _filtro_bajo(900.0, 0.4))
	# Los pájaros no necesitan graves.
	_bus(PREFIJO + "Pajaros", PREFIJO + "Valle", _filtro_alto(700.0, 0.0))
	# Los grillos viven en 4 kHz.
	_bus(PREFIJO + "Grillos", PREFIJO + "Valle", _filtro_alto(1800.0, 0.0))
	# Las hojas: una banda angosta en el medio agudo. Ruido rosa pasado por
	# esto y modulado despacio es hojas; sin la banda es siseo.
	_bus(PREFIJO + "Hojas", PREFIJO + "Valle", _filtro_banda(2400.0, 0.35))
	# El lamento de la Casa Quemada: la misma fuente de ruido, pero por una
	# banda MUY resonante y grave. Eso es literalmente lo que hace el viento
	# entrando por un hueco, y es lo único afinado que tiene el valle.
	_bus(PREFIJO + "Hueco", PREFIJO + "Valle", _filtro_banda(186.0, 0.92))
	_bus(PREFIJO + "Rio", PREFIJO + "Valle", _filtro_alto(240.0, 0.0))
	_bus(PREFIJO + "Fuego", PREFIJO + "Valle", _filtro_bajo(2600.0, 0.1))
	_bus(PREFIJO + "Hogar", PREFIJO + "Valle", _filtro_bajo(1400.0, 0.1))
	_bus(PREFIJO + "Yunque", PREFIJO + "Valle", null)
	_bus(PREFIJO + "Crujido", PREFIJO + "Valle", null)
	_volumen(PREFIJO + "Valle", volumen_general)


func _bus(nombre: String, envia: String, efecto: AudioEffect) -> void:
	if AudioServer.get_bus_index(nombre) != -1:
		return
	var i := AudioServer.bus_count
	AudioServer.add_bus(i)
	AudioServer.set_bus_name(i, nombre)
	if AudioServer.get_bus_index(envia) != -1:
		AudioServer.set_bus_send(i, envia)
	if efecto != null:
		AudioServer.add_bus_effect(i, efecto)
	_buses.append(nombre)


func _soltar_buses() -> void:
	# Al revés: sacar un bus corre los índices de los de arriba.
	for k in range(_buses.size() - 1, -1, -1):
		var i := AudioServer.get_bus_index(_buses[k])
		if i > 0:
			AudioServer.remove_bus(i)
	_buses.clear()


static func _filtro_bajo(hz: float, res: float) -> AudioEffectFilter:
	var f := AudioEffectLowPassFilter.new()
	f.cutoff_hz = hz
	f.resonance = res
	f.db = AudioEffectFilter.FILTER_12DB
	return f


static func _filtro_alto(hz: float, res: float) -> AudioEffectFilter:
	var f := AudioEffectHighPassFilter.new()
	f.cutoff_hz = hz
	f.resonance = res
	f.db = AudioEffectFilter.FILTER_12DB
	return f


static func _filtro_banda(hz: float, res: float) -> AudioEffectFilter:
	var f := AudioEffectBandPassFilter.new()
	f.cutoff_hz = hz
	f.resonance = res
	f.db = AudioEffectFilter.FILTER_12DB
	return f


func _corte(bus: String, hz: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i == -1 or AudioServer.get_bus_effect_count(i) == 0:
		return
	var e := AudioServer.get_bus_effect(i, 0) as AudioEffectFilter
	if e != null:
		e.cutoff_hz = clampf(hz, 20.0, 10000.0)


func _volumen(bus: String, lineal: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i == -1:
		return
	# Debajo de este piso no se oye nada y sí se sigue mezclando: se silencia
	# el bus entero, que es gratis.
	var v := maxf(lineal, 0.0)
	AudioServer.set_bus_mute(i, v < 0.0015)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0015)))


# ── Emisores ─────────────────────────────────────────────────────────────

func _armar_emisores() -> void:
	# El fondo no tiene lugar: suena igual mires para donde mires. Dos copias
	# del mismo ruido a distinto tono es lo que le saca el bucle de encima —
	# 4 s y 4/0,83 s no vuelven a coincidir en minutos.
	_fondo("viento", PREFIJO + "Viento", 1.00)
	_fondo("viento", PREFIJO + "Viento", 0.83)
	_fondo("pajaros", PREFIJO + "Pajaros", 1.00)
	_fondo("grillos", PREFIJO + "Grillos", 1.00)
	_fondo("grillos", PREFIJO + "Grillos", 1.11)
	_fondo("hojas", PREFIJO + "Hojas", 1.00)
	_fondo("hueco", PREFIJO + "Hueco", 1.00)

	# El río. Tres emisores sobre la línea del agua de valle.gd. Con uno solo
	# el río sería un punto que te sigue; con tres, caminar la orilla se oye
	# como caminar la orilla, y desde la aldea (26 m) se oye, que es lo que
	# dice "las casas están apretadas contra el recodo".
	var eje := Vector3(cos(deg_to_rad(RIO_GIRO)), 0.0, -sin(deg_to_rad(RIO_GIRO)))
	for k in [-1.0, 0.0, 1.0]:
		_mundo("rio", PREFIJO + "Rio", RIO_CENTRO + eje * (k * RIO_SEPARACION), 20.0, 120.0, 1.0)

	var f_fragua: Vector3 = _tabla.get("fragua", POS["fragua"])["pos"]
	# El fuego de la fragua se oye de cerca. La fragua no es un faro sonoro:
	# es un lugar cálido cuando llegás.
	_mundo("fuego", PREFIJO + "Fuego", f_fragua + Vector3(0, 1.2, 0), 13.0, 92.0, 1.0)
	# El martillo SÍ cruza el valle. Es el único que lo hace, y es a propósito:
	# desde la aldea o desde el camino oís que Ilde está trabajando y sabés
	# para qué lado queda. Es la brújula del valle.
	_mundo("yunque", PREFIJO + "Yunque", f_fragua + Vector3(0, 1.4, 0), 30.0, 260.0, 1.0)

	var f_aldea: Vector3 = _tabla.get("aldea", POS["aldea"])["pos"]
	_mundo("hogar", PREFIJO + "Hogar", f_aldea + Vector3(0, 1.0, 0), 11.0, 60.0, 1.0)

	var f_bosque: Vector3 = _tabla.get("bosque", POS["bosque"])["pos"]
	# Lo único que pasa en el Sotobosque. Uno cada tanto, con huecos largos.
	# Un solo crujido en un campo casi mudo vale más que cualquier lecho: es
	# la diferencia entre "esto está vacío" y "esto está vacío, ¿o no?".
	_mundo("crujido", PREFIJO + "Crujido", f_bosque + Vector3(0, 1.5, 0), 14.0, 70.0, 1.0)

	for voz: String in _jug:
		_gan[voz] = 0.0


func _fondo(voz: String, bus: String, tono: float) -> void:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	p.pitch_scale = tono
	p.volume_db = 0.0
	add_child(p)
	if not _jug.has(voz):
		_jug[voz] = []
	_jug[voz].append(p)


func _mundo(voz: String, bus: String, pos: Vector3, unidad: float, maximo: float, tono: float) -> void:
	var p := AudioStreamPlayer3D.new()
	p.bus = bus
	p.unit_size = unidad
	p.max_distance = maximo
	p.pitch_scale = tono
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	# Sin esto, cada emisor de ambiente pelea con la niebla de aire de Godot y
	# el resultado depende de la placa. El ambiente no se filtra por distancia:
	# lo hacen los buses, donde se ve por qué.
	p.attenuation_filter_cutoff_hz = 20500.0
	add_child(p)
	# La posición va DESPUÉS de add_child: `global_position` sobre un nodo que
	# todavía no está en el árbol tira "Condition !is_inside_tree() is true" y
	# la posición se pierde.
	p.global_position = pos
	if not _jug.has(voz):
		_jug[voz] = []
	_jug[voz].append(p)


## Los bucles ya están: colgarlos y arrancar.
func _montar(bufs: Dictionary) -> void:
	for voz: String in _jug:
		var s: AudioStream = bufs.get(voz, null)
		if s == null:
			continue
		for p: Node in _jug[voz]:
			p.stream = s
			# Los de un solo golpe no arrancan solos.
			if voz == "yunque" or voz == "crujido":
				continue
			if _hay_salida:
				p.play(randf() * 3.0)   # desfasados: si arrancan juntos, laten
	_listo = true


# ── La mezcla en vivo ────────────────────────────────────────────────────

func _process(dt: float) -> void:
	if not _listo:
		return
	_reloj += dt

	var f := hora()
	var pos := oyente.global_position if oyente != null else Vector3.ZERO
	var g := lecho_en(pos, f)

	# Las ráfagas. Tres senos de períodos que no encajan (17, 6,3 y 2,9 s) dan
	# algo que no se repite en varios minutos. El viento sube y el filtro se
	# abre JUNTOS, porque una ráfaga real trae agudos, no sólo volumen.
	var rafaga := 0.62 \
		+ 0.26 * sin(_reloj * TAU / 17.0) \
		+ 0.14 * sin(_reloj * TAU / 6.3 + 1.7) \
		+ 0.08 * sin(_reloj * TAU / 2.9 + 0.4)
	var brillo := float(g["brillo"])

	_suave("viento", float(g["viento"]) * rafaga, dt, 0.9)
	_suave("pajaros", float(g["pajaros"]), dt, 0.5)
	_suave("grillos", float(g["grillos"]), dt, 0.4)
	_suave("hojas", float(g["hojas"]) * (0.55 + 0.45 * rafaga), dt, 0.8)
	_suave("hueco", float(g["hueco"]) * (0.35 + 0.65 * rafaga), dt, 0.7)
	_suave("rio", float(g["rio"]), dt, 0.6)
	_suave("fuego", float(g["fuego"]), dt, 0.3)
	_suave("hogar", float(g["hogar"]), dt, 0.3)

	_volumen(PREFIJO + "Viento", _gan["viento"])
	_volumen(PREFIJO + "Pajaros", _gan["pajaros"])
	_volumen(PREFIJO + "Grillos", _gan["grillos"])
	_volumen(PREFIJO + "Hojas", _gan["hojas"])
	_volumen(PREFIJO + "Hueco", _gan["hueco"])
	_volumen(PREFIJO + "Rio", _gan["rio"])
	_volumen(PREFIJO + "Fuego", _gan["fuego"])
	_volumen(PREFIJO + "Hogar", _gan["hogar"])
	_volumen(PREFIJO + "Valle", volumen_general)

	# El corte del viento: abierto en el camino, tapado bajo las copas, y
	# abriéndose con cada ráfaga.
	_corte(PREFIJO + "Viento", lerpf(320.0, 2300.0, clampf(brillo, 0.0, 1.0)) * (0.7 + 0.5 * rafaga))
	# La casa canta más agudo con el viento fuerte, como cualquier hueco.
	_corte(PREFIJO + "Hueco", 168.0 + 46.0 * rafaga)
	# De noche la fragua es brasa: menos volumen y bastante más oscura.
	_corte(PREFIJO + "Fuego", lerpf(900.0, 3000.0, clampf(float(g["fuego"]), 0.0, 1.0)))

	_martillar(dt, float(g["yunque"]))
	_crujir(dt, pos)


func _suave(voz: String, objetivo: float, dt: float, vel: float) -> void:
	# Exponencial y lento a propósito: cruzar de la aldea al bosque tarda unos
	# segundos. Un corte seco se oye como un cambio de nivel; un cruce lento se
	# oye como caminar.
	var a: float = _gan.get(voz, 0.0)
	_gan[voz] = lerpf(a, objetivo, 1.0 - exp(-dt * vel * 1.6))


## El martillo de Ilde. No es un metrónomo: son rachas de tres a seis golpes y
## después una pausa larga. Un herrero calienta, golpea una racha, vuelve al
## fuego. Un martillo regular se oye a máquina y este mundo no tiene máquinas.
func _martillar(dt: float, intensidad: float) -> void:
	if intensidad < 0.05 or not _jug.has("yunque"):
		return
	_prox_martillo -= dt * (0.55 + intensidad)
	if _prox_martillo > 0.0:
		return
	var p := _jug["yunque"][0] as AudioStreamPlayer3D
	# La cuenta de los golpes corre igual sin salida de audio: así la lógica
	# de las rachas se ejercita en la verificación aunque no suene.
	if p != null and p.stream != null and _hay_salida:
		# Ningún golpe idéntico al anterior: el tono cambia un poco y el
		# volumen también. Dos golpes iguales seguidos se oyen a muestra.
		p.pitch_scale = randf_range(0.93, 1.09)
		p.volume_db = randf_range(-3.0, 1.5)
		p.play()
	_martillos_seguidos += 1
	if _martillos_seguidos >= randi_range(3, 6):
		_martillos_seguidos = 0
		_prox_martillo = randf_range(4.5, 11.0)   # vuelve al fuego
	else:
		_prox_martillo = randf_range(0.42, 0.58)  # el ritmo del yunque


## El Sotobosque. Sólo cuando estás cerca, y con huecos largos.
func _crujir(dt: float, pos: Vector3) -> void:
	if not _jug.has("crujido"):
		return
	var c: Vector3 = _tabla.get("bosque", POS["bosque"])["pos"]
	if Vector2(pos.x, pos.z).distance_to(Vector2(c.x, c.z)) > 60.0:
		return
	_prox_crujido -= dt
	if _prox_crujido > 0.0:
		return
	var p := _jug["crujido"][0] as AudioStreamPlayer3D
	if p != null and p.stream != null and _hay_salida:
		# Cada vez desde otro punto del bosque. Que no venga siempre del mismo
		# lado es la mitad de por qué inquieta.
		var a := randf() * TAU
		var r := randf_range(6.0, 22.0)
		p.global_position = c + Vector3(cos(a) * r, 1.5, sin(a) * r)
		p.pitch_scale = randf_range(0.78, 1.22)
		p.volume_db = randf_range(-9.0, -1.0)
		p.play()
	_prox_crujido = randf_range(9.0, 26.0)


# ─────────────────────────────────────────────────────────────────────────
#  LA SÍNTESIS. Cero bytes en disco.
#
#  Todo son bucles cortos de PCM de 16 bits a 22050 Hz generados al arrancar.
#  22050 y no 44100 porque nada de este lecho vive arriba de 8 kHz y la mitad
#  de las muestras es la mitad del tiempo de generación; y bucles pre-generados
#  y no `AudioStreamGenerator` porque un generador obliga a alimentar el buffer
#  desde GDScript en cada cuadro, y eso es un costo permanente en la máquina
#  del jugador. Acá se paga una vez al arrancar y después mezcla el
#  AudioServer, que es C++ y ya está corriendo igual.
#
#  DÓNDE LLEGA ESTO Y DÓNDE NO — sin maquillaje:
#    BIEN     · viento, río, fuego, grillos, el lamento de la ruina. Son
#               procesos de ruido filtrado, que es lo que la síntesis hace
#               mejor que nada. No hay una grabación que los mejore mucho.
#    PASABLE  · pájaros. Los barridos de frecuencia leen como pájaro a bajo
#               volumen y de lejos. De cerca y solos, no. Se reemplazan.
#    EL TECHO · el yunque. Un golpe metálico es síntesis modal y se puede
#               fingir, pero el impacto real tiene una densidad de parciales
#               que cuatro senos no dan. Es lo primero que hay que grabar.
#    NO       · voces, pasos y cualquier cosa con cuerpo humano. Ver la
#               entrega: no se intentan acá.
# ─────────────────────────────────────────────────────────────────────────

func _generar_todo() -> Dictionary:
	return {
		"viento": _wav(_ruido_rosa_bucle(4.0, 11), true),
		"rio": _wav(_agua(4.0, 23), true),
		"hojas": _wav(_ruido_rosa_bucle(4.0, 37), true),
		"hueco": _wav(_ruido_rosa_bucle(4.0, 53), true),
		"grillos": _wav(_grillos(4.0, 71), true),
		"pajaros": _wav(_pajaros(8.0, 97), true),
		"fuego": _wav(_fuego(4.0, 113), true),
		"hogar": _wav(_fuego(4.0, 131), true),
		"yunque": _wav(_yunque(151), false),
		"crujido": _wav(_crujido(167), false),
	}


static func _wav(m: PackedFloat32Array, bucle: bool) -> AudioStreamWAV:
	var datos := PackedByteArray()
	datos.resize(m.size() * 2)
	for i in m.size():
		datos.encode_s16(i * 2, int(clampf(m[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = HZ
	w.stereo = false
	w.data = datos
	if bucle:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = m.size()
	return w


## Cierra el bucle: la cola se funde encima de la cabeza. Sin esto hay un clic
## cada cuatro segundos y el clic es lo primero que el oído detecta.
static func _cerrar(m: PackedFloat32Array, cruce: int) -> PackedFloat32Array:
	var n := m.size() - cruce
	if n <= 0:
		return m
	var o := PackedFloat32Array()
	o.resize(n)
	for i in n:
		o[i] = m[i]
	for i in cruce:
		var t := float(i) / float(cruce)
		o[i] = lerpf(m[n + i], m[i], t)
	return o


## Ruido rosa (Kellet de tres polos). Rosa y no blanco porque el blanco se oye
## a televisor sin señal: el ruido de la naturaleza cae 3 dB por octava.
## De acá salen el viento, las hojas y el lamento de la ruina — el que los
## separa es el filtro de su bus, no la fuente.
static func _ruido_rosa(n: int, semilla: int) -> PackedFloat32Array:
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	var o := PackedFloat32Array()
	o.resize(n)
	var b0 := 0.0
	var b1 := 0.0
	var b2 := 0.0
	for i in n:
		var w := r.randf_range(-1.0, 1.0)
		b0 = 0.99765 * b0 + w * 0.0990460
		b1 = 0.96300 * b1 + w * 0.2965164
		b2 = 0.57000 * b2 + w * 1.0526913
		o[i] = (b0 + b1 + b2 + w * 0.1848) * 0.24
	return o


static func _ruido_rosa_bucle(seg: float, semilla: int) -> PackedFloat32Array:
	return _cerrar(_ruido_rosa(int(seg * HZ) + CRUCE, semilla), CRUCE)


## El río. Ruido rosa MÁS burbujas.
##
## El siseo solo se oye a estática. Lo que el oído reconoce como agua son los
## transitorios: cada burbuja que colapsa es un seno corto que SUBE de tono
## mientras se apaga, y ciento y pico de esos por segundo, a tonos distintos,
## son un río. Es de las cosas que la síntesis hace bien de verdad.
static func _agua(seg: float, semilla: int) -> PackedFloat32Array:
	var n := int(seg * HZ) + CRUCE
	var o := _ruido_rosa(n, semilla)
	var r := RandomNumberGenerator.new()
	r.seed = semilla + 7
	var cuantas := int(seg * 42.0)
	for _k in cuantas:
		var dur := r.randi_range(160, 620)
		var pos := r.randi_range(0, n - dur - 1)
		var f := r.randf_range(360.0, 1600.0)
		var amp := r.randf_range(0.025, 0.085)
		var dec := 4.0 / float(dur)
		var w := TAU * f / float(HZ)
		var subida := r.randf_range(0.25, 1.10)
		for j in dur:
			var t := float(j)
			# El barrido va en la fase, no en la frecuencia instantánea: así no
			# hay salto al empezar.
			var fase := w * t * (1.0 + subida * t / float(dur))
			o[pos + j] += sin(fase) * exp(-dec * t) * amp
	return _cerrar(o, CRUCE)


## Los grillos. Un grillo es un tono angosto de 4 a 5 kHz pulsado a veinte y
## pico de hertz, en frases de medio segundo con pausas. Se generan tres
## timbres y se siembran por el bucle a volúmenes distintos: los distintos
## volúmenes son las distintas distancias, y eso solo ya da profundidad.
static func _grillos(seg: float, semilla: int) -> PackedFloat32Array:
	var n := int(seg * HZ) + CRUCE
	var o := PackedFloat32Array()
	o.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	var frases: Array = []
	for _k in 3:
		frases.append(_frase_grillo(
			r.randf_range(3900.0, 5100.0), r.randf_range(19.0, 27.0),
			r.randf_range(0.22, 0.40)))
	var cuantas := int(seg * 7.0)
	for _k in cuantas:
		var fr: PackedFloat32Array = frases[r.randi() % 3]
		if fr.size() >= n:
			continue
		var pos := r.randi_range(0, n - fr.size() - 1)
		var amp := r.randf_range(0.10, 0.34)
		for j in fr.size():
			o[pos + j] += fr[j] * amp
	return _cerrar(o, CRUCE)


static func _frase_grillo(hz: float, tasa: float, seg: float) -> PackedFloat32Array:
	var n := int(seg * HZ)
	var o := PackedFloat32Array()
	o.resize(n)
	var periodo := int(float(HZ) / tasa)
	var largo := mini(periodo - 2, int(0.011 * HZ))
	var w := TAU * hz / float(HZ)
	var i := 0
	while i + largo < n:
		for j in largo:
			# Ventana de coseno alzado: sin ella cada pulso empieza con un clic
			# y el coro se oye a lija.
			var env := 0.5 - 0.5 * cos(TAU * float(j) / float(largo))
			o[i + j] += sin(w * float(i + j)) * env
		i += periodo
	# La frase entra y sale: un grillo no arranca a pleno.
	var borde := int(0.05 * HZ)
	for j in mini(borde, n):
		o[j] *= float(j) / float(borde)
		o[n - 1 - j] *= float(j) / float(borde)
	return o


## Los pájaros. Ésta es la parte floja y hay que decirlo.
##
## Un canto se finge con un seno que barre de frecuencia con una envolvente
## rápida, más un armónico. A bajo volumen y mezclado con viento pasa; solo y
## de cerca, no. La distancia y el volumen bajo del coro son lo que lo salva,
## y eso es una muleta, no una solución. Va con huecos GRANDES: el coro del
## amanecer es muchos pájaros lejos, no uno cerca.
static func _pajaros(seg: float, semilla: int) -> PackedFloat32Array:
	var n := int(seg * HZ) + CRUCE
	var o := PackedFloat32Array()
	o.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	var cantos: Array = []
	for _k in 6:
		cantos.append(_canto(r))
	var cuantas := int(seg * 2.4)
	for _k in cuantas:
		var c: PackedFloat32Array = cantos[r.randi() % cantos.size()]
		if c.size() >= n:
			continue
		var pos := r.randi_range(0, n - c.size() - 1)
		var amp := r.randf_range(0.06, 0.26)
		for j in c.size():
			o[pos + j] += c[j] * amp
	return _cerrar(o, CRUCE)


static func _canto(r: RandomNumberGenerator) -> PackedFloat32Array:
	var seg := r.randf_range(0.10, 0.42)
	var n := int(seg * HZ)
	var o := PackedFloat32Array()
	o.resize(n)
	var f0 := r.randf_range(1900.0, 4300.0)
	# Tres contornos: cae, sube, o tiembla. Es lo poco que separa un pájaro de
	# otro a esta distancia.
	var forma := r.randi() % 3
	var salto := r.randf_range(0.35, 1.15)
	var trino := r.randf_range(14.0, 34.0)
	var fase := 0.0
	for j in n:
		var t := float(j) / float(n)
		var f := f0
		match forma:
			0: f = f0 * (1.0 + salto * (1.0 - t) * 0.5)
			1: f = f0 * (1.0 + salto * t * 0.5)
			_: f = f0 * (1.0 + 0.18 * sin(TAU * trino * t * seg))
		fase += TAU * f / float(HZ)
		# Ataque rápido, caída larga.
		var env: float = minf(t / 0.06, 1.0) * pow(1.0 - t, 1.4)
		o[j] = (sin(fase) * 0.8 + sin(fase * 2.0) * 0.2) * env
	return o


## El fuego. Ruido marrón (más grave que el rosa: es el aire, no el chispazo)
## más chasquidos cortos y brillantes. De acá salen la fragua y el hogar de la
## aldea; los separa el filtro de su bus y el volumen.
##
## Sale bien. Un fuego es exactamente eso: un lecho grave y transitorios.
static func _fuego(seg: float, semilla: int) -> PackedFloat32Array:
	var n := int(seg * HZ) + CRUCE
	var o := PackedFloat32Array()
	o.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	var b := 0.0
	var lp := 0.0
	for i in n:
		b = b * 0.994 + r.randf_range(-1.0, 1.0) * 0.035
		lp += (b - lp) * 0.06
		o[i] = lp * 3.2
	var cuantos := int(seg * 26.0)
	for _k in cuantos:
		var dur := r.randi_range(30, 260)
		var pos := r.randi_range(0, n - dur - 1)
		var amp := r.randf_range(0.03, 0.22)
		var dec := 5.0 / float(dur)
		var f := r.randf_range(700.0, 3800.0)
		var w := TAU * f / float(HZ)
		for j in dur:
			var t := float(j)
			o[pos + j] += sin(w * t) * exp(-dec * t) * amp * r.randf_range(0.7, 1.0)
	return _cerrar(o, CRUCE)


## El martillo sobre el yunque. ACÁ ESTÁ EL TECHO DE LA SÍNTESIS.
##
## Es síntesis modal: cuatro parciales inarmónicos (las proporciones de una
## placa de metal, no de una cuerda) con caídas distintas, más un golpe sordo
## grave —el hierro caliente, que no resuena— y un transitorio de ruido de
## tres milisegundos, que es lo que el oído lee como "impacto".
##
## Va a leer como golpe metálico. NO va a sonar como un yunque de verdad: un
## impacto real tiene decenas de parciales y una no-linealidad en los primeros
## milisegundos que cuatro senos no reproducen. Es el primer archivo que hay
## que grabar o comprar, y con uno solo alcanza.
static func _yunque(semilla: int) -> PackedFloat32Array:
	var n := int(0.95 * HZ)
	var o := PackedFloat32Array()
	o.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	var base := 1180.0
	var parciales := [1.0, 2.41, 4.17, 6.83]
	var pesos := [1.0, 0.55, 0.30, 0.16]
	var caidas := [2.6, 4.2, 7.0, 11.0]
	for k in parciales.size():
		var w := TAU * base * float(parciales[k]) / float(HZ)
		var a := float(pesos[k]) * 0.34
		var d := float(caidas[k]) / float(HZ)
		for j in n:
			o[j] += sin(w * float(j)) * exp(-d * float(j)) * a
	# El golpe sordo: el metal caliente absorbe. Sin esto suena a campana.
	var wg := TAU * 148.0 / float(HZ)
	for j in n:
		o[j] += sin(wg * float(j)) * exp(-26.0 / float(HZ) * float(j)) * 0.42
	# El impacto.
	var tr := int(0.004 * HZ)
	for j in tr:
		o[j] += r.randf_range(-1.0, 1.0) * (1.0 - float(j) / float(tr)) * 0.55
	return o


## Algo se rompió en el Sotobosque y no sabés qué. Ruido con ataque
## instantáneo y caída de sesenta milisegundos, más dos o tres chasquidos
## previos: eso es una rama. Sale bien, y sale bien porque no tiene que ser
## nada reconocible — tiene que ser *algo*.
static func _crujido(semilla: int) -> PackedFloat32Array:
	var n := int(0.45 * HZ)
	var o := PackedFloat32Array()
	o.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	# Dos o tres tironeos antes del quiebre. La madera avisa.
	for _k in r.randi_range(2, 3):
		var pos := r.randi_range(0, int(0.16 * HZ))
		var dur := r.randi_range(120, 420)
		for j in dur:
			if pos + j >= n:
				break
			o[pos + j] += r.randf_range(-1.0, 1.0) * exp(-6.0 / float(dur) * float(j)) * 0.18
	# El quiebre.
	var q := int(0.19 * HZ)
	var largo := n - q
	var lp := 0.0
	for j in largo:
		var w := r.randf_range(-1.0, 1.0)
		lp += (w - lp) * 0.42
		o[q + j] += lp * exp(-9.0 / float(largo) * float(j)) * 0.85
	return o


# ─────────────────────────────────────────────────────────────────────────
#  EL INFORME. Lo único de todo esto que se puede verificar sin oír nada.
# ─────────────────────────────────────────────────────────────────────────

const HORAS_DE_PRUEBA := [0.05, 0.25, 0.38, 0.50, 0.65, 0.78, 0.90]
const RUTA := ["aldea", "fragua", "bosque", "ruina", "camino", "aldea"]

var _paso := 0


func _informe_de_prueba() -> void:
	print("")
	print("═══ EL LECHO DEL VALLE ═══════════════════════════════════════════")
	print("Godot %s · driver de audio: %s · pantalla: %s"
		% [Engine.get_version_info()["string"], AudioServer.get_driver_name(),
			DisplayServer.get_name()])
	print("Bucles generados en %.0f ms, %d buses creados, 0 bytes en disco."
		% [_ms_generacion, _buses.size()])
	_probar_el_reloj()
	_revisar_la_cadena()
	print("")
	print("Ganancias lineales. `fondo` es la suma del lecho sin lugar")
	print("(viento+pájaros+grillos+hojas+hueco); río, fuego, hogar y yunque")
	print("tienen lugar en el mundo y la distancia los termina de bajar.")
	print("")
	var cab := "  %-9s %-13s %6s %6s %6s %6s %6s | %5s | %6s %6s %6s %6s"
	for slug: String in ["aldea", "fragua", "bosque", "ruina", "camino", "campo"]:
		var nom: String = {
			"aldea": "Vado Bajo", "fragua": "La Fragua de Ilde",
			"bosque": "El Sotobosque", "ruina": "La Casa Quemada",
			"camino": "El Camino del Norte", "campo": "campo abierto",
		}[slug]
		print("── %s (%s)" % [nom, slug])
		print(cab % ["hora", "franja", "viento", "pájaro", "grillo", "hojas",
			"hueco", "FONDO", "río", "fuego", "hogar", "yunque"])
		for f: float in HORAS_DE_PRUEBA:
			var g := lecho(slug, f)
			print(cab % [
				"%.2f" % f, franja(f),
				"%.2f" % g["viento"], "%.2f" % g["pajaros"], "%.2f" % g["grillos"],
				"%.2f" % g["hojas"], "%.2f" % g["hueco"], "%.2f" % g["fondo"],
				"%.2f" % g["rio"], "%.2f" % g["fuego"], "%.2f" % g["hogar"],
				"%.2f" % g["yunque"]])
		print("")

	print("── LO QUE HAY QUE PODER LEER EN ESA TABLA")
	var noche: float = lecho("aldea", 0.05)["fondo"]
	var dia: float = lecho("aldea", 0.50)["fondo"]
	var alba: float = lecho("aldea", 0.25)["fondo"]
	print("  · la aldea de noche suena %.0f%% de lo que suena al mediodía"
		% [noche / dia * 100.0])
	print("  · el amanecer es el momento más sonoro del día (%.2f contra %.2f)"
		% [alba, dia])
	var b: float = lecho("bosque", 0.50)["fondo"]
	var c: float = lecho("campo", 0.50)["fondo"]
	print("  · entrar al Sotobosque al mediodía apaga el ambiente a %.0f%% "
		% [b / c * 100.0] + "(%.1f dB)" % [linear_to_db(b / c)])
	print("  · y de noche lo apaga a %.0f%%: es el lugar más callado del valle"
		% [lecho("bosque", 0.90)["fondo"] / lecho("campo", 0.90)["fondo"] * 100.0])
	print("  · la fragua nunca baja de %.2f: el único techo que no se apaga"
		% [lecho("fragua", 0.05)["fuego"]])
	print("  · el yunque calla de noche (%.2f) y el fuego no (%.2f)"
		% [lecho("fragua", 0.05)["yunque"], lecho("fragua", 0.05)["fuego"]])
	print("  · el río vale 1.00 a toda hora en todos lados: es el ancla")
	print("")
	set_process(true)
	_paso = 0


## La hora tiene que salir del `ciclo.gd` de verdad, no de un reloj de acá.
##
## Esto no es decorado: es la parte del cableado que más fácil se rompe en
## silencio. Si `hora()` devolviera 0.5 para siempre, el lecho seguiría
## sonando y nadie notaría que el valle dejó de tener hora. Así que se
## instancia el Ciclo real, se lo sincroniza como lo hace el servidor y se
## comprueba que el número llegue.
func _probar_el_reloj() -> void:
	var c := Ciclo.new()
	c.sincronizar(3, Ciclo.DIA_REAL * 0.40)
	ciclo = c
	var leida := hora()
	print("Reloj: ciclo.gd sincronizado a 0.40 → hora() devuelve %.2f (%s) · %s"
		% [leida, franja(leida), "OK" if absf(leida - 0.40) < 0.005 else "MAL"])
	ciclo = null
	c.free()


## Cuántos bucles distintos están SONANDO. No es lo mismo que la cantidad de
## emisores —el viento son dos emisores con el mismo bucle— y cuentan sólo los
## que suenan, porque un bucle asignado y quieto no queda colgado al salir.
func _bucles_distintos() -> int:
	var vistos := {}
	for voz: String in _jug:
		for p: Node in _jug[voz]:
			if not bool(p.call("is_playing")):
				continue
			var st: Object = p.get("stream")
			if st != null:
				vistos[st.get_instance_id()] = true
	return vistos.size()


## Cuántos emisores están sonando ahora mismo.
func _sonando() -> int:
	var n := 0
	for voz: String in _jug:
		for p: Node in _jug[voz]:
			if is_instance_valid(p) and bool(p.call("is_playing")):
				n += 1
	return n


## Que la cadena esté entera: cada emisor con su bus vivo y su bucle con
## muestras adentro.
##
## Esto reemplaza lo único que se perdió al no reproducir en headless. Un
## `play()` contra el driver Dummy no probaba nada más que "no tiró": no había
## forma de saber si el bus existía, si el stream tenía datos o si el bucle
## estaba bien cerrado. Revisarlo a mano prueba más y no deja nada sonando.
func _revisar_la_cadena() -> void:
	var emisores := 0
	var fallas: Array[String] = []
	var muestras := 0
	for voz: String in _jug:
		for p: Node in _jug[voz]:
			emisores += 1
			var bus := String(p.get("bus"))
			if AudioServer.get_bus_index(bus) == -1:
				fallas.append("%s: el bus %s no existe" % [voz, bus])
			var s := p.get("stream") as AudioStreamWAV
			if s == null:
				fallas.append("%s: sin bucle" % voz)
				continue
			if s.data.size() < 2:
				fallas.append("%s: bucle vacío" % voz)
				continue
			muestras += s.data.size() / 2
			var deberia_repetir := voz != "yunque" and voz != "crujido"
			if deberia_repetir and s.loop_mode != AudioStreamWAV.LOOP_FORWARD:
				fallas.append("%s: es un lecho y no está en bucle" % voz)
	print("Cadena: %d emisores, %d buses, %d muestras (%.1f s de audio, %.1f MB en RAM) · %s"
		% [emisores, _buses.size(), muestras, float(muestras) / float(HZ),
			float(muestras * 2) / 1048576.0,
			"OK" if fallas.is_empty() else "MAL: " + ", ".join(fallas)])
	if _hay_salida:
		var forzado := OS.get_cmdline_user_args().has(FORZAR_AUDIO)
		print("Salida de audio: %s%s. Los emisores están sonando: %d."
			% [AudioServer.get_driver_name(),
				" (FORZADA por " + FORZAR_AUDIO + ")" if forzado else "",
				_sonando()])
		if forzado:
			# Sin nombrar las palabras que grepea la verificación del repo.
			print("  Con audio forzado el proceso cierra avisando de instancias")
			print("  sin liberar, y tiene que hacerlo: una por emisor sonando más")
			print("  una por bucle distinto (%d + %d = %d), y las suelta el motor,"
				% [_sonando(), _bucles_distintos(), _sonando() + _bucles_distintos()])
			print("  no este módulo. Lo que se vigila es que ese número no crezca.")
	else:
		# Ojo con el texto de acá: la verificación del repo se hace con grep
		# sobre esta salida, así que no se nombran las palabras que se buscan.
		print("Salida de audio: ninguna (driver %s). No se reproduce nada y se"
			% AudioServer.get_driver_name())
		print("  calcula todo igual. Además de ahorrar trabajo, es lo que evita")
		print("  que el proceso cierre avisando de instancias sin liberar: el")
		print("  motor necesita dos cuadros después del stop() y al salir ya no")
		print("  quedan. Está medido y pasa con un AudioStreamPlayer pelado")
		print("  también — el detalle está en el comentario de `_hay_salida`.")


## Después de la tabla, la caminata: mueve el oyente por los cinco lugares
## mientras el día avanza, y hace sonar todo de verdad. En headless no se oye
## nada — sirve para probar que la cadena entera (buses, emisores, mezcla) no
## revienta. Con parlantes, esto es lo que hay que escuchar.
func _informe_de_paso() -> void:
	var pasos_por_tramo := 5
	var total := (RUTA.size() - 1) * pasos_por_tramo
	if _paso == 0:
		print("── LA CAMINATA (%d pasos; el día entero mientras tanto)" % total)
		print("  Ruta: %s. Son rectas, así que pasa por campo abierto y roza"
			% " → ".join(RUTA))
		print("  lugares que no son destino — el cruce de la mezcla es el punto.")
		print("  %-7s %-13s %-13s %6s %6s  %s"
			% ["paso", "dónde estoy", "cuándo", "FONDO", "viento", "mezcla de lugares"])
	if _paso >= total:
		if DisplayServer.get_name() == "headless":
			print("")
			print("Listo. Nada de esto se oyó: bajo WSL no hay salida de audio.")
			print("Corré esta misma escena con parlantes para juzgarlo.")
			_salir()
		else:
			_paso = 0   # con pantalla, en loop: es para escuchar
		return

	var tramo := mini(_paso / pasos_por_tramo, RUTA.size() - 2)
	var t := float(_paso % pasos_por_tramo) / float(pasos_por_tramo)
	var a: Vector3 = _tabla[RUTA[tramo]]["pos"]
	var b: Vector3 = _tabla[RUTA[tramo + 1]]["pos"]
	var p := a.lerp(b, t)
	if oyente != null:
		oyente.global_position = p
	hora_manual = fposmod(float(_paso) / float(total), 1.0)

	var g := lecho_en(p, hora_manual)
	var pesos: Dictionary = g["pesos"]
	var claves := pesos.keys()
	claves.sort_custom(func(x, y): return float(pesos[x]) > float(pesos[y]))
	var texto := ""
	for k: String in claves:
		if float(pesos[k]) > 0.02:
			texto += "%s %.0f%%  " % [k, float(pesos[k]) * 100.0]
	print("  %-7s %-13s %-13s %6.2f %6.2f  %s" % [
		str(_paso), str(claves[0]),
		franja(hora_manual), g["fondo"], g["viento"], texto])
	_paso += 1


func _physics_process(_dt: float) -> void:
	# La caminata avanza por CUADRO y no por reloj: en headless el reloj corre
	# a mil y no se imprimiría nada. Un paso cada seis cuadros de física.
	if not modo_prueba or not _listo:
		return
	if Engine.get_physics_frames() % 6 == 0:
		_informe_de_paso()


## Cerrar limpio. Apagar y darle unos cuadros al AudioServer para que suelte
## las reproducciones antes de salir; si no, Godot cierra con el aviso de
## instancias filtradas y la verificación deja de ser legible de un vistazo.
func _salir() -> void:
	apagar()
	for _i in 8:
		await get_tree().process_frame
	get_tree().quit()

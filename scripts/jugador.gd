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
## Te sentaste o te paraste. Existe para que la interfaz pueda cambiar el cartel
## sin preguntar todos los cuadros; hoy no lo escucha nadie y no pasa nada.
signal sentado(si: bool)

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

## ── MIRAR EL CIELO ──────────────────────────────────────────────────────────
##
## La órbita sola **no puede mirar para arriba, y no es cuestión de aflojarle el
## tope.** Con la cámara en una esfera alrededor del jugador y la mira siempre
## puesta en él, inclinarse hacia el cielo significa bajar la cámara por debajo
## de los pies: se mete abajo del terreno y se ve el mundo desde el revés. Por
## eso `PITCH_MIN` ya se movió una vez —de 28° a 2°— y no alcanzó: a 2° se mira
## un pelo por encima del horizonte y nada más. **El tope no era el problema; el
## modelo lo era.**
##
## Lo que hay ahora son DOS cosas y no una. El arrastre acumula un solo número
## (`_mirada`), y ese número se reparte:
##
##   · mientras es positivo, es la inclinación de la ÓRBITA — la cámara sube y
##     mira al jugador desde arriba, que es la vista de trabajo;
##   · cuando llega al piso de la órbita y seguís arrastrando, lo que sigue
##     **levanta la MIRA** sin mover la cámara de lugar. La cámara se queda
##     donde está, arriba del suelo, y gira la cabeza.
##
## Y esto no es una comodidad: en el cielo hay un reloj y un calendario. El sol
## da una vuelta cada día del valle —seis horas reales— y **la fase de la luna
## es el día del valle**, ocho por vuelta. Mirás para arriba y sabés cuánto hace
## que no entrás, sin abrir ningún menú. Todo eso estaba construido y era
## inalcanzable por un número.
##
## 85° deja ver casi el cenit. No se llega a 90 a propósito: con la mira
## exactamente vertical, `look_at()` y el vector "arriba" se alinean y la
## orientación se vuelve indefinida.
const ALZA_MAX := deg_to_rad(85.0)
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
##
## ── 26° y no 38°, y esto es LA razón de "parece una torta" ────────────────
##
## Se midió, no se opinó: con `_pitch` en 38° y el FOV en 42°, el borde
## SUPERIOR del cuadro apunta 17° **por debajo** de la horizontal. O sea que la
## vista muere a **ochenta metros** y **el horizonte no entra en pantalla, para
## nada**. Lo único que se ve es un disco de pasto — y un disco de pasto es
## exactamente lo que alguien describe como *"un mundo de torta"*.
##
## La consecuencia práctica es que **ningún hito servía**: se levantó una
## puerta de roca de 62 m a la entrada del valle, que mide 340 píxeles de alto
## sobre 900 —el 38% de la pantalla—, y con este número no se veía nunca. La
## escala no se arregla agrandando las cosas si la cámara mira al piso.
##
## A 26° el horizonte y la cordillera entran, y no se pierde nada de lo de
## arriba: siguen viéndose las fachadas, los troncos y la silueta de la gente
## contra el suelo, que es lo que hace legible un mundo visto de lejos.
var _pitch := deg_to_rad(26.0)
## Lo que pidió el arrastre, de `-ALZA_MAX` a `PITCH_MAX`. De acá salen `_pitch`
## y `_alza`: ver `_repartir_mirada()`.
var _mirada := deg_to_rad(26.0)
## Cuánto levanta la cabeza la cámara sin moverse de lugar. Cero casi siempre.
var _alza := 0.0
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

## ── LA CÁMARA DE CONVERSACIÓN ──────────────────────────────────────────────
##
## Dicho jugando: *"perdés la persona, no sabés si te mira o no"*. Y es cierto
## con la cámara libre: le hablás a alguien parado adentro de una casa, la
## cámara sigue donde la dejaste, y en pantalla hay una pared. Los dos cuerpos
## ya se orientaban entre sí desde hace rato (`Figura.conversar()`), y eso no
## servía de nada porque **no se veían**.
##
## Mientras la caja está abierta, la cámara se va sola detrás tuyo, mirando al
## otro. Es lo que hace cualquier juego con una charla, y acá hace falta más que
## en otros: la mitad de lo que este juego te dice de alguien está en cómo te
## mira, y hasta hoy eso se estaba dibujando fuera de cuadro.
##
## Tres decisiones y ninguna es de gusto:
##
##   · **Se mueve el YAW y nada más.** Ni el `pitch`, ni la distancia, ni un
##     plano cerrado sobre la cara: el piso de zoom es silueta y postura, nunca
##     la expresión (`DISENO.md` §6, decisión cerrada), y no hay caras que
##     mostrar. Girar alcanza para que los dos entren en cuadro.
##   · **Lerp lento y no un corte.** Un corte de cámara al abrir una charla se
##     lee como un cambio de escena; el giro se lee como que te diste vuelta.
##   · **Se suelta al cerrar** y la cámara se queda donde quedó, sin volver de
##     un salto a donde estaba. El jugador ya está mirando ahí.
var _encuadre: Node3D = null
## Cuánto del giro va por segundo. 2,4 da poco menos de medio segundo para
## media vuelta, que es lo que tarda alguien en darse vuelta.
const ENCUADRE_VEL := 2.4
## Retroceso al recibir un golpe. Se suma a `velocity` y se apaga por
## rozamiento; ver `empujar()`.
var _empuje := Vector3.ZERO

## ── SENTARSE ────────────────────────────────────────────────────────────────
##
## QUÉ SIGNIFICA, que es la pregunta que manda `CLAUDE.md` antes de agregar nada:
## **el mundo es multijugador y la gente aparece y desaparece.** Si estás
## esperando a alguien que se está conectando, hoy el juego te deja parado en un
## prado apretando teclas. Sentarse al fuego es cómo se espera a alguien, y al
## anochecer el fogón de la plaza es lo único encendido al aire libre en el medio
## de un anillo de puertas cerradas. La razón la puso la rama de arquitectura al
## poner los asientos y la comparto: es un lugar donde estar sin hacer nada, y un
## mundo donde no se puede estar sin hacer nada se juega apurado.
##
## **Y no hace nada más.** No cura, no pasa el tiempo, no manda nada. Cualquiera
## de esas tres cosas sería estado del mundo y el estado del mundo es del
## servidor: sentarse es una postura, y una postura vive entera en el cliente.
##
## El radio es el mismo de `Interiores.asiento_cerca()` y por el mismo motivo:
## un asiento que se ofrece a tres metros hace que la plaza entera sea un botón.
## **1,5 m era imposible.** La cámara juega a cuarenta metros, el personaje mide
## 1,85, y no hay ningún cartel que avise que hay un asiento cerca: apretabas F
## en todos lados y no pasaba nada, sin una palabra. Dicho por quien lo jugó:
## *"no te podés sentar"*. A 3,2 m se acierta caminando, que es como se tiene
## que sentir.
const ASIENTO_RADIO := 3.2
## Cuánto tarda el cuerpo en llegar al asiento. 8 cuadros: menos se lee como un
## teletransporte y más se lee como que el juego te arrastra.
const SENTARSE_VEL := 18.0
## A cuánto del asiento se da por perdido el asiento. Al sentarte podés estar
## hasta 1,5 m (el radio de búsqueda); tres metros sólo pasan si te movió otro.
const SENTADO_LEJOS := 3.0

## ── EL PESO DE LO QUE LLEVÁS ────────────────────────────────────────────────
##
## Cuántas cosas encima hacen falta para que el cuerpo se vea cargado del todo.
## Doce y no cuarenta porque la carga tiene que empezar a notarse mucho antes del
## techo: con cuarenta, las primeras diez cosas no cambiarían un píxel.
##
## **Esto NO es un límite de carga.** El límite es una regla del mundo y las
## reglas del mundo son del servidor (INVARIANTE 4): acá no se rechaza levantar
## nada, no se descuenta velocidad y no se prohíbe nada. Lo único que pasa es que
## el cuerpo se ve cargado, que es la mitad que faltaba de la regla 2 de
## `DISENO.md` §8.3 —*"lo que llevás encima, sí"*— y la única mitad que es mía.
const CARGA_LLENA := 12.0

var _sentado := false
var _asiento := Vector3.ZERO       ## dónde queda el cuerpo
var _asiento_mira := 0.0           ## hacia dónde mira el que se sienta
var _antes_de_sentarse := Vector3.ZERO  ## dónde estabas parado, para volver ahí
var _en_piso_antes := true         ## para oír la caída
## Un paso que hay que hacer sonar en el próximo cuadro de FÍSICA. Ver
## `_esquivar()`: saber qué hay bajo los pies es una consulta al espacio físico.
var _paso_pendiente := 0.0
var _cableado := false             ## ¿ya escuchamos los pasos de la figura?
var _son: Node = null              ## el módulo de sonido, buscado por grupo
var _refresco_carga := 0.0

@onready var _pivote: Node3D = $Pivote
@onready var _camara: Camera3D = $Pivote/Camara
@onready var _malla: Node3D = $Malla
var figura: Figura
## Lo setea el valle: mientras devuelva true, el teclado es del chat y no
## del personaje. Sin esto escribirle "andá" a un NPC te hace caminar.
var tecleando := Callable()


func _ready() -> void:
	_camara.current = true
	_repartir_mirada()
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
		_mirada = clampf(_mirada + m.relative.y * 0.004, -ALZA_MAX, PITCH_MAX)
		_repartir_mirada()
	elif evento.is_action_pressed("interactuar"):
		quiere_interactuar.emit()
	elif evento.is_action_pressed("golpear"):
		# Pegar te para. Es lo mismo que el WASD: cualquier cosa que hagas con el
		# cuerpo te saca del asiento, y así no hay ningún estado del que no se
		# sepa salir.
		if _sentado:
			pararse()
		# No se pega en el medio de una rodada. Es el costo que hace que
		# esquivar sea una elección: mientras te sacás, no estás pegando.
		elif _esquive <= 0.0:
			quiere_golpear.emit()
	elif evento is InputEventKey and (evento as InputEventKey).pressed \
			and not (evento as InputEventKey).echo \
			and (evento as InputEventKey).keycode == KEY_Q:
		# Tecla cruda y no una acción del mapa de entrada porque `project.godot`
		# no se toca en esta rama. Cuando se agregue, esto pasa a "esquivar".
		_esquivar()
	elif evento is InputEventKey and (evento as InputEventKey).pressed \
			and not (evento as InputEventKey).echo \
			and (evento as InputEventKey).keycode == KEY_F:
		# La F la propuso la rama de arquitectura. Cruda por lo mismo que la Q.
		_tentar_asiento()


## Un solo arrastre, dos efectos. Arriba del piso de la órbita mueve la cámara;
## debajo, la deja quieta y le levanta la mira. El reparto es continuo —no hay
## salto en el cruce— porque las dos mitades salen del mismo número.
## Hacia dónde está mirando el cuerpo, en radianes.
##
## Existe porque **el que gira no es este nodo sino su malla**: el
## `CharacterBody3D` no rota nunca, así que `global_rotation.y` da siempre lo
## mismo y cualquiera que lo lea desde afuera se lleva un dato falso sin que
## nada se queje. Ya casi me pasa dibujando la cuña de dirección del mapa.
##
## Y de paso queda escrita la convención de este archivo, que **no es la de
## Godot**: acá el frente es `(sin θ, 0, cos θ)`, o sea +Z, y no el −Z de
## `basis.z`. Está así en `_esquivar()` desde antes; lo que faltaba era que se
## pudiera preguntar sin ir a leer un miembro privado.
func mira_hacia() -> float:
	return _malla.rotation.y


## El mismo dato como vector, para el que lo necesita para dibujar o apuntar.
func frente() -> Vector3:
	return Vector3(sin(_malla.rotation.y), 0.0, cos(_malla.rotation.y))


func _repartir_mirada() -> void:
	_pitch = maxf(_mirada, PITCH_MIN)
	_alza = maxf(0.0, PITCH_MIN - _mirada)


## Rodar. Se compromete a una dirección y no se puede corregir a mitad de
## camino: eso es lo que la vuelve una decisión en vez de un botón de "no me
## pegues".
func _esquivar() -> void:
	# Sentado no se rueda: primero te parás. Una tecla, una cosa.
	if _sentado:
		pararse()
		return
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
		# **Siempre al mismo lado, y esto es el arreglo de un bug de verdad.**
		#
		# Acá había un `randf() < 0.5` que sorteaba izquierda o derecha, y quien
		# lo jugó lo dijo con esas palabras: *"apretás la Q y se mueve para
		# cualquier lado"*. Tenía razón — con el sorteo, la misma tecla en la
		# misma situación hace dos cosas distintas, así que **no se puede
		# aprender a esquivar**: no podés apuntar a dónde te sacás, no podés
		# encadenar esquive y contragolpe, y cuando te sale mal no sabés si
		# fue tu culpa o del dado.
		#
		# Un esquive es una decisión, y una decisión con un dado adentro no es
		# una decisión. Sale siempre hacia la derecha del cuerpo; el que quiera
		# el otro lado tiene el WASD, que es la forma de apuntarlo.
		dir = frente().cross(Vector3.UP)
	_dir_esquive = dir.normalized()
	_esquive = ESQUIVE_DURA
	_espera_esquive = ESQUIVE_ESPERA
	esquivo.emit(ESQUIVE_ESPERA)
	# Un cuerpo que se tira al piso suena, y suena más que un paso: mismo sonido
	# y mismo suelo, lo que cambia es la fuerza. **Se anota y no se dispara acá**:
	# esto corre en el manejo de teclas y averiguar qué hay bajo los pies es una
	# consulta al espacio físico, que sólo se pide adentro del proceso de física.
	_paso_pendiente = 1.0


func _physics_process(dt: float) -> void:
	var mudo := _tecleando()
	_espera_esquive = maxf(0.0, _espera_esquive - dt)
	_escuchar_los_pasos()
	_pesar_lo_que_llevo(dt)
	if _sentado:
		_estar_sentado(dt, mudo)
		return
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
	# LA CAÍDA. Va entre `move_and_slide()` y `animar()` a propósito: acá el
	# choque con el piso es de ESTE cuadro y las colisiones que mira
	# `_piso_bajo_los_pies()` todavía están frescas. Un cuerpo de 1,85 m que cae
	# y no hace ruido es de las cosas que más rápido delatan que el mundo es una
	# maqueta, y era gratis.
	var en_piso := is_on_floor()
	if en_piso and not _en_piso_antes:
		_paso_pendiente = 1.0
	_en_piso_antes = en_piso
	if _paso_pendiente > 0.0:
		_al_pisar(_paso_pendiente)
		_paso_pendiente = 0.0
	if figura != null:
		figura.animar(dt, Vector2(velocity.x, velocity.z).length(), en_piso)

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


# ─────────────────────────────────────────────────────────────────────────────
#  SENTARSE
# ─────────────────────────────────────────────────────────────────────────────

## ¿Hay dónde sentarse acá al lado? Devuelve `{"nodo", "pos", "mirando"}` o `{}`.
##
## **Es el mismo grupo y las mismas metas que `Interiores.asiento_cerca()`**, que
## es la función gemela y la que escribió la rama de arquitectura para esto. La
## copia no es por gusto: el `Interiores` del valle es un miembro de `valle.gd` y
## este archivo no lo tiene a mano, y **buscarlo entre los hermanos del árbol es
## exactamente el cable que funciona por casualidad** que este repo ya se sacó de
## encima una vez (el `Sonido` enganchándose solo al `Api` que colgaba del mismo
## padre). El grupo `asientos`, en cambio, es el contrato publicado: es el mismo
## mecanismo con el que `ciclo.gd` encuentra las ventanas.
##
## Queda pública para que la interfaz pueda dibujar el cartel sin tener que
## repetir la búsqueda por tercera vez.
##
## LA DEUDA, dicha para que no se pierda: el radio y las metas están escritos en
## dos archivos. El día que `valle.gd` se pueda tocar, esto es
## `interiores.asiento_cerca(global_position)` y se borran quince líneas.
func asiento_cerca(radio := ASIENTO_RADIO) -> Dictionary:
	var mejor: Node3D = null
	var d_min := radio
	for n in get_tree().get_nodes_in_group("asientos"):
		var nodo := n as Node3D
		if nodo == null or not is_instance_valid(nodo):
			continue
		var d := global_position.distance_to(nodo.global_position)
		if d < d_min:
			d_min = d
			mejor = nodo
	if mejor == null:
		return {}
	return {
		"nodo": mejor,
		"pos": mejor.global_position
			+ Vector3(0.0, float(mejor.get_meta("asiento_alto", 0.45)), 0.0),
		# El giro guardado es relativo al padre. Ver `Detalles.asiento()`.
		"mirando": mejor.global_rotation.y + float(mejor.get_meta("asiento_mira", 0.0)),
	}


## Apretaste F y no había dónde sentarse. Lo escucha la interfaz para decirlo.
signal sin_asiento


func _tentar_asiento() -> void:
	if _sentado:
		pararse()
		return
	var a := asiento_cerca()
	if a.is_empty():
		# **Callarse es lo peor.** Una tecla que a veces hace algo y a veces no
		# dice nada es indistinguible de una tecla rota, y así se sintió.
		sin_asiento.emit()
		return
	sentarse(a["pos"], float(a["mirando"]))


## Clavar el cuerpo en un asiento y mirar hacia `mirando`.
##
## `pos` es donde se apoya el cuerpo —la cara de arriba del tronco—, tal cual lo
## devuelve `asiento_cerca()`. El nodo del jugador tiene el origen en los PIES,
## así que lo que se le pasa a la física es esa altura menos la cadera: la
## constante sale de `figura.gd` para que el cuerpo y el hueco donde se sienta
## salgan del mismo número.
func sentarse(pos: Vector3, mirando: float) -> void:
	if _sentado:
		return
	# Dónde estabas parado. Al pararte volvés exactamente ahí, y eso no es
	# comodidad: el tronco tiene un cuerpo estático alrededor (`Detalles._tope`)
	# y el asiento está ADENTRO de él. Mientras estás sentado el cuerpo no pasa
	# por `move_and_slide()` —está clavado— pero en el cuadro en que te parás sí,
	# y si te soltara adentro de la caja el motor te escupiría para cualquier
	# lado. Volver al punto de donde saliste es la única posición de la que se
	# sabe con certeza que está libre.
	_antes_de_sentarse = global_position
	_asiento = Vector3(pos.x, pos.y - Figura.SENTADO_ALTO, pos.z)
	_asiento_mira = mirando
	_sentado = true
	# Nada a medio hacer entra al asiento: ni un swing, ni una rodada. La
	# estocada y la vuelta de campana escriben en el contenedor `Malla` y se
	# apagan solas contando el tiempo; cortadas de una hay que devolverlo a cero,
	# y una sola vez — dejarlo clavado todos los cuadros le comería a `valle.gd`
	# la inclinación con la que te tumba.
	_golpe = 0.0
	_esquive = 0.0
	_malla.position = Vector3.ZERO
	_malla.rotation.x = 0.0
	_malla.rotation.z = 0.0
	velocity = Vector3.ZERO
	if figura != null:
		figura.sentado(true)
	sentado.emit(true)


func pararse() -> void:
	_soltar_asiento(true)


## `volver` dice si el cuerpo vuelve a donde estaba parado. Es true cuando te
## parás vos y false cuando el asiento se soltó porque el mundo te movió.
func _soltar_asiento(volver: bool) -> void:
	if not _sentado:
		return
	_sentado = false
	if volver:
		global_position = _antes_de_sentarse
	velocity = Vector3.ZERO
	if figura != null:
		figura.sentado(false)
	sentado.emit(false)


## El cuadro del que está sentado. No pasa por la física: el cuerpo está clavado.
##
## **La cámara sigue viva**, y no es un detalle: si sentarse apagara la cámara,
## sentarse sería un menú. Podés girar, alejarte y mirar el cielo sentado al
## fuego, que es más o menos todo lo que uno quiere hacer sentado al fuego.
func _estar_sentado(dt: float, mudo: bool) -> void:
	# **Cualquier intención de moverse te para**, y se comprueba antes de mover
	# nada: el primer WASD tiene que soltar el cuerpo en el mismo cuadro en que
	# se apretó. Un asiento del que cuesta salir es una trampa, no un asiento.
	if not mudo and (Input.get_vector("izquierda", "derecha", "adelante", "atras").length_squared() > 0.01
			or Input.is_action_pressed("saltar")):
		pararse()
		return
	# **Si alguien te movió, el asiento se suelta solo y NO te devuelve.** Pasa de
	# verdad: cuando te tumban, `valle.gd` te reaparece en otro lado, y sin esto
	# el cuerpo se volvería arrastrando al tronco desde donde el mundo lo puso.
	# Quien te movió tenía un motivo y este archivo no lo conoce.
	if global_position.distance_to(_asiento) > SENTADO_LEJOS:
		_soltar_asiento(false)
		return
	velocity = Vector3.ZERO
	global_position = global_position.lerp(_asiento, 1.0 - exp(-dt * SENTARSE_VEL))
	_malla.rotation.y = lerp_angle(_malla.rotation.y, _asiento_mira, 10.0 * dt)
	_en_piso_antes = true
	if figura != null:
		figura.animar(dt, 0.0, true)
	_dist = lerp(_dist, _dist_objetivo, 8.0 * dt)
	_recolocar_camara(false)


# ─────────────────────────────────────────────────────────────────────────────
#  LOS PASOS
# ─────────────────────────────────────────────────────────────────────────────
#
# Quién decide QUÉ suena es `sonido.gd`; lo que decide este archivo son las dos
# cosas que sólo sabe el cuerpo: CUÁNDO toca el piso un pie (lo avisa `figura.gd`
# con la señal `piso`, sacada de la fase de la zancada) y QUÉ HAY DEBAJO.
#
# El "qué hay debajo" sale de la COLISIÓN de verdad y no de una tabla de zonas, y
# ésa es la parte que vale: el motor ya sabe contra qué chocaron los pies, y la
# forma del colisionador dice de qué está hecho sin tener que preguntarle nada a
# nadie. El terreno del valle es una malla de triángulos
# (`ConcavePolygonShape3D`, la arma `valle.gd::_armar_terreno`); todo lo
# construido son cajas. Y entre las cajas, la única que mide más de cuatro metros
# de lado es el basamento de una casa —5,64 m: `CASA_LADO` más dos veces
# `ZOCALO_VUELO`, en `detalles.gd`— cuya cara de arriba es, literalmente, el piso
# de tablas del cuarto. Los escalones de la puerta miden 2,11 y los troncos del
# fogón 1,2: ésos son piedra y madera suelta, que suenan igual de duro.
const CAJA_CASA := 4.0


## Enganchar la señal de la figura. Una vez, y en el proceso de física porque la
## figura la cuelga `valle.gd` DESPUÉS de construir el jugador: en `_ready()`
## todavía no está.
func _escuchar_los_pasos() -> void:
	if _cableado or figura == null or not is_instance_valid(figura):
		return
	_cableado = true
	if not figura.piso.is_connected(_al_pisar):
		figura.piso.connect(_al_pisar)


## El módulo de sonido, por el grupo en el que se anota solo. Si no está —la
## escena de prueba, un arranque a medias— no suena nada y no se rompe nada.
func _sonido() -> Node:
	if _son != null and is_instance_valid(_son):
		return _son
	_son = get_tree().get_first_node_in_group("sonido")
	return _son


func _al_pisar(fuerza: float) -> void:
	var s := _sonido()
	if s == null or not s.has_method("pisar"):
		return
	var suelo := _suelo_bajo_los_pies()
	s.call("pisar", str(suelo["piso"]), fuerza, float(suelo["llano"]))


## Qué hay bajo los pies: `{"piso", "llano"}`.
##
## **Va por rayo y no por `get_slide_collision()`, y eso es el arreglo de un bug
## que encontró la sonda y no el razonamiento.** Lo natural era leer la colisión
## que ya hizo `move_and_slide()` —el motor acaba de tocar el piso, para qué
## preguntar de nuevo— y está mal: caminando en llano el cuerpo **no choca
## contra el suelo**. `move_and_slide()` le come la componente vertical a la
## velocidad al aterrizar, y a partir de ahí el movimiento es horizontal puro y
## no genera ninguna colisión con el piso. Medido con una sonda de física de
## verdad: parado arriba del zócalo de una casa la función contestaba
## `"terreno"`, o sea que **el piso de tablas no iba a sonar nunca** y no había
## forma de notarlo mirando el código.
##
## El rayo cuesta una consulta al espacio físico por paso, o sea tres por
## segundo, contra los ochenta mil que ya hace el valle por cuadro.
func _suelo_bajo_los_pies() -> Dictionary:
	var espacio := get_world_3d().direct_space_state
	# Desde medio metro arriba de los pies hasta un metro abajo: agarra el
	# escalón que estás subiendo sin agarrar el piso de la casa de al lado.
	var consulta := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.6, global_position - Vector3.UP * 1.0)
	consulta.exclude = [get_rid()]
	var r := espacio.intersect_ray(consulta)
	if r.is_empty():
		return {"piso": "terreno", "llano": 1.0}
	var llano := clampf((r.get("normal", Vector3.UP) as Vector3).y, 0.0, 1.0)
	var cuerpo := r.get("collider") as CollisionObject3D
	if cuerpo == null:
		return {"piso": "terreno", "llano": llano}
	var duenio := cuerpo.shape_find_owner(int(r.get("shape", 0)))
	if duenio < 0 or cuerpo.shape_owner_get_shape_count(duenio) == 0:
		return {"piso": "terreno", "llano": llano}
	var forma := cuerpo.shape_owner_get_shape(duenio, 0)
	if forma is BoxShape3D:
		var caja := forma as BoxShape3D
		return {"piso": "tabla" if caja.size.x > CAJA_CASA else "losa", "llano": llano}
	# La malla de triángulos del terreno, y cualquier otra cosa: el valle.
	return {"piso": "terreno", "llano": llano}


# ─────────────────────────────────────────────────────────────────────────────
#  EL PESO
# ─────────────────────────────────────────────────────────────────────────────

## Cuántas cosas llevás encima. Lo llama quien tenga la bolsa en la mano.
##
## **No hay límite acá y no puede haberlo**: cuánto se puede llevar es una regla
## del mundo, y las reglas del mundo son del servidor. Esto sólo hace que el
## cuerpo se vea cargado.
func cargar(cosas: int) -> void:
	if figura != null:
		figura.cargado(clampf(float(cosas) / CARGA_LLENA, 0.0, 1.0))


## De dónde sale hoy ese número, dicho sin maquillaje.
##
## La bolsa llega en `/mundo` y el único archivo de esta rama al que `valle.gd`
## se la pasa entera es `sonido.gd`, que la necesita igual —un cuerpo cargado
## pisa más fuerte—. Así que el peso se PIDE, no se recibe: es una consulta a un
## módulo público, guardada por `has_method`, y si el módulo no está el cuerpo se
## queda liviano y no se rompe nada.
##
## **No es donde tiene que vivir.** Lo correcto es una línea en
## `valle.gd::_al_recibir_mundo()` —`jugador.cargar(bolsa.size())`, al lado del
## `figura.empunar()` que ya está ahí— y entonces esta función se borra entera.
## Está pedido en el informe. Se hace cuatro veces por segundo porque la bolsa
## cambia una vez por minuto y esto es un rebote de diccionario, no un cálculo.
func _pesar_lo_que_llevo(dt: float) -> void:
	_refresco_carga -= dt
	if _refresco_carga > 0.0:
		return
	_refresco_carga = 0.25
	var s := _sonido()
	if s == null or not s.has_method("carga"):
		return
	cargar(int(s.call("carga")))


## Mirá a esto mientras dure. `null` la suelta. Ver `_encuadre`.
func encuadrar(quien: Node3D) -> void:
	_encuadre = quien


func _recolocar_camara(inmediato: bool) -> void:
	# La cámara de conversación. Va antes de todo lo demás porque lo único que
	# hace es mover `_yaw`: de ahí para abajo, esta función no se entera.
	if _encuadre != null and is_instance_valid(_encuadre):
		var d := global_position - _encuadre.global_position
		if d.length_squared() > 0.04:
			# La cámara va del lado OPUESTO al otro, o sea que mira desde atrás
			# tuyo hacia él. Que quede él de espaldas sería la misma toma al
			# revés y perdería justamente lo que se quiere ver.
			var quiero := atan2(d.x, d.z)
			# Por el camino corto. Sin esto, ir de +170° a −170° da la vuelta
			# larga y la cámara pega un giro de 340° en media charla.
			_yaw += wrapf(quiero - _yaw, -PI, PI) \
				* clampf(get_process_delta_time() * ENCUADRE_VEL, 0.0, 1.0)

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
	# Y después de apuntar al jugador, la cabeza se levanta. Va acá y no en el
	# `look_at` —moviendo el punto mirado hacia arriba— porque con la cámara a
	# 40 m habría que subir el punto cuarenta metros para girar 45°, y en el
	# camino el jugador se sale de cuadro de costado. Rotar sobre el eje X local
	# de la cámara gira exactamente lo que se pidió y nada más.
	if _alza > 0.0:
		_camara.rotate_object_local(Vector3.RIGHT, _alza)


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

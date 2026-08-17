## La interfaz. Mínima a propósito: en una vista de diorama, cada panel que
## agregás tapa lo que hace que el juego se vea bien.
extends CanvasLayer

# ── Las franjas de la pantalla ──────────────────────────────────────────────
#
# Cada panel se anclaba por su cuenta con números a ojo y el resultado fue que
# se pisaban entre sí: el diálogo encima de la vida, la lista de qué hacer
# encima del diálogo. Declarar las zonas de una vez no es prolijidad — es lo
# que hace que agregar el panel número ocho no sea una lotería.
#
# **La regla es que ningún panel elige su Y: sale de acá o no existe.** El
# diálogo la rompía —se apoyaba en un 70 escrito a mano y se comía la barra de
# vida, la pista de acción y la línea de teclas, o sea las tres cosas que
# necesitás mirar justo mientras hablás con alguien—. Por eso la caja ahora se
# apoya en `Y_PISO_CAJA`, que **no es un número nuevo sino una cuenta**: mover
# el saludo mueve la caja sola y no hay forma de que se vuelvan a pisar.
#
# De abajo hacia arriba, en píxeles desde el borde inferior:
#
# **La banda de la pista se eliminó y no se reemplaza por otra.** Decía
# "[E] hablar con X" abajo al centro, o sea a media pantalla de la persona con
# la que ibas a hablar: el jugador tenía que mirar una esquina para saber qué
# podía hacer con lo que tenía delante. Ahora eso se dibuja **encima de la
# cosa** (ver `_colocar()`), que es lo mismo escrito en el lugar donde importa.
const Y_AYUDA     := 30    # la línea de teclas, siempre última
const Y_VIDA      := 74    # la barra y el número
const Y_SALUDO    := 152   # lo que te dicen al pasar…
const ALTO_SALUDO := 34    # …y cuánto ocupa, que es lo que fija el techo de abajo
const Y_PISO_CAJA := Y_SALUDO + ALTO_SALUDO + 16   # el piso del diálogo
const ALTO_CAJA     := 540 # y lo más alto que se le permite ponerse
const ALTO_CAJA_MIN := 200 # …y lo más bajo, para una crónica de dos renglones
const ANCHO_CAJA    := 380 # a cada lado del centro
# Y a los costados y arriba:
const X_MARGEN    := 22
const Y_TECHO     := 96    # el título del lugar y su subtítulo viven arriba de esto

# Las dos columnas. Arrancan las dos debajo del título y a la misma altura:
# a la izquierda qué hacer ahora, a la derecha la bolsa (tecla I). Abajo al
# centro está todo lo que hay que mirar peleando, así que ninguna baja de acá.
const Y_COLUMNA     := Y_TECHO
const ANCHO_COLUMNA := 380
const ANCHO_BOLSA   := 330
const Y_BOLSA       := Y_COLUMNA

## Los colores de la interfaz, juntos. No es prolijidad: eran quince literales
## repetidos y cambiar el tono de "algo apagado" costaba buscarlos de a uno.
## (`paleta.gd` es de la escena 3D; esto es la capa 2D, que se lee sobre
## cualquier cosa que haya atrás y por eso tiene su propia escala de grises.)
const TINTA       := Color(0.87, 0.89, 0.87)
const TINTA_TENUE := Color(0.60, 0.65, 0.62)
const TINTA_APAGADA := Color(0.45, 0.50, 0.48)
const VERDE       := Color(0.44, 0.73, 0.62)
const AMBAR       := Color(0.85, 0.78, 0.55)
## El mismo rojo apagado que este archivo ya usa para "hostil" y para "te teme"
## (`ce8b84`). Va como constante y no como literal suelto porque ahora lo usan
## tres lugares, y un color que se repite escrito a mano se desincroniza.
const HOSTIL      := Color(0.808, 0.545, 0.518)
const ROJO        := Color(0.81, 0.55, 0.52)
const FONDO       := Color(0.06, 0.08, 0.09, 0.92)

## Las dos mitades de la caja de diálogo, rotuladas.
##
## No es decoración: es la diferencia de diseño más grande del juego escrita en
## pantalla. **Las opciones mueven el mundo** —van a `/act`, cambian estado y
## quedan escritas en la base—; **lo que escribís es sólo conversación** —va a
## `/hablar`, el NPC contesta y no pasa nada más—. Las dos cosas eran el mismo
## gris con la misma forma, una encima de la otra, así que nadie podía saber
## cuál era cuál: *"no sabés cuándo escribir o elegir las respuestas rápidas ya
## puestas"*.
const ROTULO_ACTOS  := "ELIGE UNA — ESTO PASA DE VERDAD EN EL VALLE"
const ROTULO_NO     := "TODAVÍA NO PUEDES"
const ROTULO_CHARLA := "O DILE ALGO — ES SÓLO CHARLA, EL MUNDO NO SE MUEVE"

## Qué hace cada verbo, en un renglón.
##
## El servidor manda `verbo`, `texto`, `posible` y `porque`, y hace bien en no
## explicar el verbo: **los nueve verbos son fijos y son de este lado.** Sin
## esto el jugador aprieta «Enseñarle Destilado de raíz» sin tener idea de qué
## está por regalar, que es exactamente el reclamo de que las opciones no dicen
## qué hacen.
const QUE_HACE := {
	"aprender": "un saber suyo pasa a tu cabeza. No se lo quitas: ahora lo saben dos.",
	"ensenar": "un saber tuyo pasa a la suya. Deja de perderse cuando te mueras — y deja de ser sólo tuyo.",
	"encargarse": "te apuntas a conseguirle lo que le falta. Nadie te espera: si no vuelves, se lo resuelve solo.",
	"dar": "el objeto sale de tu bolsa y queda en sus manos.",
	"trabajar": "te quedas trabajando cerca. Con el tiempo te va conociendo.",
}

## Cuánto alto pide el bloque de texto de la caja, y por qué hay que estimarlo.
##
## **Se midió en una captura: una crónica de cinco renglones salía cortada a la
## mitad del cuarto.** La caja pedía siempre lo mismo para el texto —64 px, o
## sea dos renglones y medio— porque el alto se calculaba contando OPCIONES, y
## la crónica no tiene ninguna. Con el saludo de un NPC casi nunca se notaba
## (son una o dos líneas); con la crónica del valle, que son cinco o diez, se
## notaba siempre.
##
## Sigue siendo una cuenta gruesa y a propósito: medir de verdad pide esperar un
## cuadro de layout, y una caja que salta de tamaño un cuadro después de abrirse
## se lee peor que una que sale holgada. Lo que se pase, scrollea.
const CHARS_POR_RENGLON := 78.0
const ALTO_RENGLON := 24.0

## El campo de texto dice en qué estado está, porque su estado te apaga el WASD.
## Lo que ocupa la caja sin contar lo que scrollea: el encabezado, la línea, el
## rótulo de la charla, el campo de texto, el botón de cerrar y los márgenes.
const ALTO_FIJO_CAJA := 176.0

const PISTA_QUIETO := "  [Enter] para escribirle algo…"
const PISTA_TECLEANDO := "escribe y mándalo con Enter  ·  WASD apagado mientras escribes  ·  [Esc] salir"

## Qué se puede juntar donde estás parado. Lo setea el valle.
##
## Con setter porque el cartel que lo anuncia vive pegado a los pies del
## jugador y tiene que cambiar en el mismo cuadro en que cambia el lugar. El
## valle sigue escribiéndolo como una variable cualquiera.
var lugar_da := "": set = _poner_lugar_da
var npc_cercano := ""

var _api: Api
var _decir: LineEdit
var _bolsa: RichTextLabel
var _pasos: RichTextLabel
var _saludo: RichTextLabel
var _flash: ColorRect
var _volumen := 0.45
var _ficha: PanelContainer
var _ficha_texto: RichTextLabel
var _ficha_datos: Dictionary = {}
var _bienvenida: PanelContainer
var _tw_flash: Tween
var _tw_aviso: Tween
var _fundido: Tween
var _ya_saludamos := false
var _ultima_region: Dictionary = {}
var _ultimos_pasos: Array = []
var _titulo: Label
var _sub: Label
var _caja: PanelContainer
var _texto: RichTextLabel
var _opciones: VBoxContainer
var _quien: Label
var _rotulo_actos: Label
var _alto_deseado := float(ALTO_CAJA_MIN)
var _alto_texto := 64.0

var _bolsa_panel: PanelContainer
var _bolsa_chip: Label
var _bolsa_dar: VBoxContainer
var _pip_esquive: Label
var _tw_esquive: Tween
var _objetos: Array = []
var _buscando := false
var _bolsa_cuantos := -1
var _tw_bolsa: Tween

# ── Los carteles de acción, pegados a la cosa ───────────────────────────────
#
# Esto es el cambio de fondo del HUD y conviene decir por qué, porque parece un
# detalle de posición y no lo es. El reclamo fue *"apretás B y es buscando…
# ¿qué es eso?"*, y la respuesta no era escribir mejor el renglón de abajo: era
# que el renglón estuviera en otro lado. **Una acción se anuncia sobre la cosa
# con la que se hace.** El nombre de lo que vas a juntar aparece a tus pies; el
# nombre de con quién vas a hablar, sobre su cabeza. Si no hay nada que juntar,
# no hay cartel — y eso también es información.
#
# Se dibuja en 2D y no con `Label3D` a propósito: un cartel 3D con la cámara a
# 40 m mide ocho píxeles de alto (los nombres de la gente ya lo demuestran) y
# esto tiene que leerse. Se proyecta el punto del mundo a la pantalla y se
# escribe ahí, con el tamaño de siempre.
var _jugador: Node3D
var _camara: Camera3D
var _npc_nodo: Node3D
var _amenaza_nodo: Node3D
var _amenaza_nombre := ""
var _marca_npc: Label
var _marca_piso: Label
var _marca_bicho: Label
var _vida_ultima := -1


## Que un texto se lea sobre pasto, sobre cielo y sobre nieve.
##
## Un contorno oscuro y no una caja detrás de cada renglón: la vista es un
## diorama y cada panel opaco que agregás tapa lo único que hace que el juego
## se vea bien. La caja se la ganan los bloques que agrupan cosas (el diálogo,
## la bolsa); el texto suelto se defiende con el contorno.
##
## `Label` y `RichTextLabel` usan los mismos nombres de tema para esto, así que
## una función sirve para los dos.
static func _legible(c: Control, grosor := 5) -> void:
	c.add_theme_constant_override("outline_size", grosor)
	c.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.04, 0.9))


## El color del ánimo. Estaba escrito tres veces igual —diálogo, saludo y
## adelanto— y agregar un ánimo nuevo era acordarse de los tres.
static func _tono(animo: Variant) -> String:
	return {
		"calido": "6fb99e", "neutral": "dde3de", "seco": "98a29c", "hostil": "ce8b84",
	}.get(str(animo), "dde3de")


## El fondo de los bloques que sí llevan caja. Todos iguales, y con el borde de
## color arriba que ya usaban el diálogo y la caída: es lo que dice de un
## vistazo qué clase de cosa es la que se abrió.
static func _caja_de(borde: Color) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = FONDO
	e.border_color = borde
	e.border_width_top = 2
	e.content_margin_left = 20
	e.content_margin_right = 20
	e.content_margin_top = 16
	e.content_margin_bottom = 16
	return e


func _ready() -> void:
	var fuente_color := TINTA

	_titulo = Label.new()
	_titulo.position = Vector2(28, 22)
	_titulo.add_theme_font_size_override("font_size", 26)
	_titulo.add_theme_color_override("font_color", fuente_color)
	_legible(_titulo, 6)
	add_child(_titulo)

	_sub = Label.new()
	_sub.position = Vector2(28, 56)
	_sub.add_theme_font_size_override("font_size", 15)
	_sub.add_theme_color_override("font_color", TINTA_TENUE)
	_legible(_sub)
	add_child(_sub)

	_marca_npc = _marca()
	_marca_piso = _marca()
	# El del bicho va en otro color: es lo único de los tres que te puede matar,
	# y un cartel que avisa de un peligro no puede tener el mismo ámbar que uno
	# que ofrece charlar. El valor es lo que se lee a cuarenta metros, no el
	# texto.
	_marca_bicho = _marca()
	_marca_bicho.add_theme_color_override("font_color", HOSTIL)

	# La línea de teclas, en dos renglones y ordenada por para qué sirve cada
	# una: primero lo que hacés con el cuerpo, después lo que abre algo, y al
	# final los ajustes. Antes era una sola tira alfabéticamente al azar donde
	# "E hablar" pesaba lo mismo que "+/− volumen", y encima había dos
	# `horizontal_alignment` seguidos: el segundo ganaba y el primero era
	# ruido.
	var ayuda := Label.new()
	ayuda.anchor_left = 0.0
	ayuda.anchor_right = 1.0
	ayuda.anchor_top = 1.0
	ayuda.anchor_bottom = 1.0
	ayuda.offset_left = X_MARGEN
	ayuda.offset_right = -X_MARGEN
	ayuda.offset_top = -Y_AYUDA - 14
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# **`E hablar` y `B buscar` ya no están acá**, y no es un olvido: las dos
	# aparecen escritas encima de la cosa con la que se hacen, en el momento en
	# que se pueden hacer. Repetirlas en la esquina es enseñarle al jugador a
	# mirar la esquina.
	#
	# Y entró lo que faltaba, que era peor que sobrar: **el botón derecho gira
	# la cámara y mira el cielo, y no estaba escrito en ningún lado.** El valle
	# tiene un sol que es el reloj y una luna que es el calendario, y el que
	# jugó no sabía que se podía levantar la cabeza.
	ayuda.text = "\n".join([
		"WASD caminar · shift correr · espacio saltar · clic pegar · Q esquivar"
			+ " · clic derecho arrastrar: girar y mirar el cielo · rueda: acercar",
		# "quién eres" y no "quién sos": el mundo habla castellano llano y esa
		# decisión estaba escrita en el prompt del director pero no en la
		# interfaz, así que la pantalla vosea mientras la crónica tutea. Se
		# midió del otro lado (`pnpm registro`) y se barrieron trece cadenas
		# del servidor; el resto de este archivo se barrió después.
		"I bolsa · M mapa · C quién eres · P runas del día · R trazar"
			+ " · G grimorio · Esc cerrar · F1 calidad · +/− volumen",
	])
	ayuda.add_theme_font_size_override("font_size", 12)
	ayuda.add_theme_color_override("font_color", TINTA_APAGADA)
	_legible(ayuda, 4)
	add_child(ayuda)

	_armar_vida()
	_armar_caja()
	_armar_bolsa()
	_cargar_volumen()
	# Último a propósito: un error acá no puede dejar el juego sin HUD. Es la
	# trampa de `_ready()` que ya costó una tarde —una excepción aborta la
	# función entera— y el indicador de esquive es lo menos importante de todo
	# lo que se arma en esta función.
	_enganchar_jugador()


## Un cartel de acción: chico, ámbar y con el contorno de siempre. No lleva
## caja — va encima del pasto y del cuerpo de alguien, y una caja opaca ahí
## tapa justo lo que el cartel está señalando.
func _marca() -> Label:
	var l := Label.new()
	l.visible = false
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", AMBAR)
	_legible(l, 5)
	add_child(l)
	return l


## Lo que la interfaz necesita del jugador: la cámara (para saber dónde cae en
## la pantalla un punto del mundo), la señal de esquive y el cuerpo que se
## agacha a juntar.
##
## Se lo busca sola en vez de que lo cablee `valle.gd`, porque ese archivo no
## se toca en esta rama. Si algún día no lo encuentra, no pasa nada grave: se
## pierden los carteles y el indicador, y todo lo demás sigue igual.
##
## **`valle.gd` arma al jugador ANTES que a la interfaz**, así que acá ya
## existen tanto el nodo como su figura. Si algún día se da vuelta ese orden,
## esto se apaga en silencio y el síntoma es que no aparece ningún cartel.
func _enganchar_jugador() -> void:
	var v := get_parent()
	if v == null:
		return
	var j: Variant = v.get("jugador")
	if not (j is Jugador):
		return
	_jugador = j as Node3D
	_camara = (j as Node).get_node_or_null("Pivote/Camara") as Camera3D

	# El cuerpo se agacha mientras junta. La animación estaba escrita en
	# `figura.gd` desde hace días y **no la disparaba nadie**: la señal salía de
	# acá y no la escuchaba nadie del otro lado. Un cartel que dice "buscando"
	# con el personaje parado es exactamente el reclamo original.
	var f: Variant = (j as Jugador).figura
	if f is Figura:
		quiere_juntar.connect((f as Figura).juntar)

	_pip_esquive = Label.new()
	_pip_esquive.anchor_left = 0.5; _pip_esquive.anchor_right = 0.5
	_pip_esquive.anchor_top = 1.0; _pip_esquive.anchor_bottom = 1.0
	_pip_esquive.offset_left = 152; _pip_esquive.offset_right = 300
	_pip_esquive.offset_top = -Y_VIDA - 4
	_pip_esquive.text = "Q esquivar"
	_pip_esquive.add_theme_font_size_override("font_size", 12)
	_pip_esquive.add_theme_color_override("font_color", VERDE)
	_legible(_pip_esquive, 4)
	add_child(_pip_esquive)

	(j as Jugador).esquivo.connect(func(espera: float) -> void:
		# Se apaga y vuelve. La espera se ve, que es lo que hace que rodar sea
		# un recurso y no una tecla que apretás todo el tiempo.
		if _tw_esquive != null and _tw_esquive.is_valid():
			_tw_esquive.kill()
		_pip_esquive.add_theme_color_override("font_color", TINTA_APAGADA)
		_tw_esquive = create_tween()
		_tw_esquive.tween_interval(espera)
		_tw_esquive.tween_callback(func() -> void:
			_pip_esquive.add_theme_color_override("font_color", VERDE)))


## Los carteles siguen a lo que señalan, cuadro a cuadro. Es lo único que esta
## capa hace por cuadro, y son dos proyecciones de un punto: barato.
func _process(_dt: float) -> void:
	if _camara == null:
		return
	# Con algo abierto encima no hay carteles: el jugador está mirando el panel,
	# no el valle, y dos textos peleando por el mismo momento es cómo se llega a
	# "todo el UI es malo".
	var tapado := (_caja != null and _caja.visible) \
		or (_bienvenida != null and is_instance_valid(_bienvenida)) \
		or _caida != null \
		or (_ficha != null and _ficha.visible)
	# Uno arriba de la cabeza del otro y el otro debajo de tus pies. No es
	# simetría: son dos cosas distintas y tienen que verse como dos cosas
	# distintas, aunque las dos estén en pantalla al mismo tiempo.
	_colocar(_marca_npc, _npc_nodo, 2.75, tapado, false)
	_colocar(_marca_piso, _jugador, 0.02, tapado, true)
	# Más alto que el de la gente: los bichos son más grandes, y si los dos
	# carteles salen a la misma altura se solapan justo cuando hay alguien
	# peleando al lado de una persona, que es el momento en que más importan.
	_colocar(_marca_bicho, _amenaza_nodo, 3.4, tapado, false)


## Poner un cartel encima de un punto del mundo. `alto` son los metros por
## encima del origen del nodo, y el cartel queda centrado y apoyado ahí.
##
## `is_position_behind` no es una prolijidad: sin eso, un punto que quedó atrás
## de la cámara se proyecta **espejado** al otro lado de la pantalla y el cartel
## aparece señalando el aire.
func _colocar(l: Label, ancla: Node3D, alto: float, tapado: bool,
		debajo: bool) -> void:
	if l == null:
		return
	if tapado or l.text == "" or ancla == null or not is_instance_valid(ancla):
		l.visible = false
		return
	var p := ancla.global_position + Vector3.UP * alto
	if _camara.is_position_behind(p):
		l.visible = false
		return
	var s := _camara.unproject_position(p)
	var t := l.get_minimum_size()
	l.position = Vector2(s.x - t.x * 0.5, s.y + 6.0 if debajo else s.y - t.y)
	l.visible = true


func _poner_lugar_da(que: String) -> void:
	lugar_da = que
	_refrescar_marcas()


## Qué dice cada cartel. Sale de dos datos y de nada más: a quién tenés al lado
## y qué hay para juntar donde estás parado. **Si no hay nada, no hay cartel** —
## ofrecerse cuando no se puede es exactamente cómo `[B] buscar` terminó
## significando nada.
func _refrescar_marcas() -> void:
	if _marca_npc != null:
		_marca_npc.text = "[E] hablar con %s" % npc_cercano if npc_cercano != "" else ""
	if _marca_bicho != null:
		# «pegarle a Kerrak el que quedó», con el nombre propio que la base ya
		# tiene y que hasta hoy no salía de ahí. Un bicho con nombre no es un
		# mob: es alguien de un pueblo, y el `CLAUDE.md` lo tenía anotado como
		# pendiente — "el bicho no dice quién es", con el dato viajando ya en
		# `/mundo`.
		_marca_bicho.text = ("clic — pegarle a %s" % _amenaza_nombre) if _amenaza_nombre != "" else ""
	if _marca_piso == null:
		return
	if lugar_da == "":
		_marca_piso.text = ""
	elif _buscando:
		# Mientras dura el pedido, el cartel dice qué está pasando y el cuerpo se
		# agacha. Antes decía "buscando…" en el medio de la pantalla y el
		# personaje no se movía.
		_marca_piso.text = "juntando %s…" % lugar_da
	else:
		_marca_piso.text = "[B] juntar %s" % lugar_da


var _vida_barra: ColorRect
var _vida_numero: Label
var _aviso: Label
var _caida: PanelContainer

func _armar_vida() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.07, 0.08, 0.85)
	fondo.anchor_left = 0.5; fondo.anchor_right = 0.5
	fondo.anchor_top = 1.0; fondo.anchor_bottom = 1.0
	fondo.offset_left = -140; fondo.offset_right = 140
	fondo.offset_top = -Y_VIDA; fondo.offset_bottom = -Y_VIDA + 12
	add_child(fondo)

	_vida_barra = ColorRect.new()
	_vida_barra.color = Color(0.44, 0.73, 0.62)
	_vida_barra.anchor_left = 0.5; _vida_barra.anchor_right = 0.5
	_vida_barra.anchor_top = 1.0; _vida_barra.anchor_bottom = 1.0
	_vida_barra.offset_left = -139; _vida_barra.offset_right = 139
	_vida_barra.offset_top = -Y_VIDA + 1; _vida_barra.offset_bottom = -Y_VIDA + 11
	add_child(_vida_barra)

	# El número, además de la barra. Una barra dice "poco"; un número dice
	# cuántos golpes te quedan, y con bichos que pegan de a ocho o dieciséis
	# eso es la diferencia entre volver a la aldea o quedarse un rato más.
	_vida_numero = Label.new()
	_vida_numero.anchor_left = 0.5; _vida_numero.anchor_right = 0.5
	_vida_numero.anchor_top = 1.0; _vida_numero.anchor_bottom = 1.0
	_vida_numero.offset_left = -140; _vida_numero.offset_right = 140
	_vida_numero.offset_top = -Y_VIDA - 20
	_vida_numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vida_numero.add_theme_font_size_override('font_size', 13)
	_vida_numero.add_theme_color_override('font_color', Color(0.62, 0.68, 0.65))
	_legible(_vida_numero)
	add_child(_vida_numero)

	_aviso = Label.new()
	_aviso.anchor_left = 0.5; _aviso.anchor_right = 0.5
	_aviso.anchor_top = 0.5; _aviso.anchor_bottom = 0.5
	_aviso.offset_left = -320; _aviso.offset_right = 320
	_aviso.offset_top = -140
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_font_size_override('font_size', 20)
	_aviso.add_theme_color_override('font_color', Color(0.90, 0.72, 0.62))
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Los avisos del servidor son frases enteras —"Marta ya casi lo tiene
	# resuelto y no necesita que nadie se meta"— y sin corte de línea se salían
	# de la pantalla por los dos lados.
	_legible(_aviso, 6)
	add_child(_aviso)


## La barra NO es un contador de esta máquina: dibuja el último número que dijo
## el servidor. Por eso viene el máximo también — el día que alguien tenga otra
## vida máxima, la barra ya lo sabe leer en vez de asumir cien.
func mostrar_vida(v: int, maximo: int = 100) -> void:
	var parte := clampf(float(v) / maxf(float(maximo), 1.0), 0.0, 1.0)
	var t := create_tween()
	t.tween_property(_vida_barra, 'offset_right', -139.0 + 278.0 * parte, 0.18)
	_vida_barra.color = Color(0.44, 0.73, 0.62) if parte > 0.5 else (Color(0.79, 0.64, 0.31) if parte > 0.2 else Color(0.81, 0.55, 0.52))
	if _vida_numero != null:
		_vida_numero.text = "%d / %d" % [v, maximo]
	# Cuánto cambió, encima de tu propio cuerpo. La barra dice en qué estado
	# estás; esto dice **qué acaba de pasarte**, que es otra cosa y es la que
	# faltaba: *"me ataca el monstruo sin decirme nada"*. Mirando al bicho no
	# ves la barra, y un número que sale de tu cabeza y sube no te obliga a
	# dejar de mirarlo.
	#
	# No inventa nada: son dos números del servidor restados. El primer aviso
	# del mundo no dispara nada, porque pasar de "no sé" a 100 no es curarse.
	if _vida_ultima >= 0 and v != _vida_ultima:
		_flotar(v - _vida_ultima)
	_vida_ultima = v


## Un número que sale del cuerpo y se va hacia arriba. Se limpia solo.
func _flotar(delta: int) -> void:
	if delta == 0 or _camara == null or _jugador == null \
			or not is_instance_valid(_jugador):
		return
	var p := _jugador.global_position + Vector3.UP * 2.1
	if _camara.is_position_behind(p):
		return
	var l := Label.new()
	l.text = "%+d" % delta
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", ROJO if delta < 0 else VERDE)
	_legible(l, 6)
	add_child(l)
	var s := _camara.unproject_position(p)
	l.position = Vector2(s.x - l.get_minimum_size().x * 0.5, s.y)
	# Se queda donde salió mientras sube: es un número, no un objeto del mundo,
	# y seguirlo con la cámara durante un segundo lo haría temblar.
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 64.0, 1.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	t.set_parallel(false)
	t.tween_callback(l.queue_free)


## Un aviso en el medio de la pantalla, que se va solo.
##
## El tiempo en pantalla lo decide el largo, y no es cosmética: por acá pasan
## ahora las respuestas del servidor a las acciones, que son frases enteras
## ("Marta ya casi lo tiene resuelto y no necesita que nadie se meta"). Con los
## 2,2 s fijos de antes, una frase larga se iba antes de terminar de leerla y
## el jugador quedaba igual que si no le hubieran contestado nada.
func avisar(texto: String) -> void:
	if texto.strip_edges() == "":
		return
	_aviso.text = texto
	_aviso.modulate.a = 1.0
	if _tw_aviso != null and _tw_aviso.is_valid():
		_tw_aviso.kill()
	_tw_aviso = create_tween()
	_tw_aviso.tween_interval(clampf(1.6 + texto.length() * 0.045, 2.2, 6.5))
	_tw_aviso.tween_property(_aviso, 'modulate:a', 0.0, 0.8)


## Estás en el piso. Este panel es lo único que hay entre caer y volver a
## jugar, y es a propósito que sea un botón y no un temporizador: el juego
## espera que vos decidas, no te hace mirar una barra llenarse. Nada de acá
## cobra tiempo — lo que cuesta caer es la caminata de vuelta y la cara.
##
## Botón sin grab_focus() a propósito: un control con foco empieza a comerse
## teclas, y la última vez que pasó eso fue el LineEdit tragándose el WASD.
func mostrar_caida(al_levantarse: Callable) -> void:
	if _caida != null:
		return

	_caida = PanelContainer.new()
	_caida.anchor_left = 0.5; _caida.anchor_right = 0.5
	_caida.anchor_top = 0.5; _caida.anchor_bottom = 0.5
	_caida.offset_left = -300; _caida.offset_right = 300
	_caida.offset_top = -110; _caida.offset_bottom = 110

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.06, 0.05, 0.05, 0.95)
	estilo.border_color = Color(0.81, 0.55, 0.52)
	estilo.border_width_top = 2
	estilo.content_margin_left = 28
	estilo.content_margin_right = 28
	estilo.content_margin_top = 24
	estilo.content_margin_bottom = 24
	_caida.add_theme_stylebox_override("panel", estilo)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	_caida.add_child(col)

	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.custom_minimum_size = Vector2(540, 110)
	t.text = "\n".join([
		"[b][color=#ce8b84]Estás en el piso.[/color][/b]",
		"",
		"No perdiste lo que sabes — eso vive en tu cabeza, y ninguna caída te lo saca.",
		"[color=#7d867f]Vas a levantarte en la aldea. Volver hasta aquí es caminarlo.[/color]",
	])
	col.add_child(t)

	var b := Button.new()
	b.text = "levantarse"
	b.pressed.connect(func() -> void:
		# Se apaga apenas lo apretás y recién se cierra cuando contesta el
		# servidor: mover al personaje antes de que el mundo lo escriba es
		# caminar por la aldea mientras la base te tiene tirado en la ruina.
		b.disabled = true
		b.text = "levantándote…"
		al_levantarse.call())
	col.add_child(b)

	add_child(_caida)


func ocultar_caida() -> void:
	if _caida == null:
		return
	_caida.queue_free()
	_caida = null


## La caja de diálogo. Es la superficie que más se usa del juego, y era la
## peor: se apoyaba a 70 px del piso —o sea encima de la vida, de la pista y de
## la línea de teclas—, no decía cómo se cerraba, y mezclaba las dos cosas que
## más importa distinguir.
##
## Ahora son tres franjas de arriba hacia abajo y cada una dice qué es:
##
##   ┌ NOMBRE DEL NPC                                        [Esc] cerrar ┐
##   │ “lo que te dijo”                                                   │  ← scrollea
##   │ ELEGÍ UNA — ESTO PASA DE VERDAD EN EL VALLE                        │
##   │ › Pedirle que te enseñe                                            │
##   │      un saber suyo pasa a tu cabeza…                               │
##   ├────────────────────────────────────────────────────────────────────┤
##   │ O DECILE ALGO — ES SÓLO CHARLA, EL MUNDO NO SE MUEVE               │  ← fijo
##   │ [ …                                                              ] │
##   │ [ dejar de hablar    [Esc] ]                                       │
##   └────────────────────────────────────────────────────────────────────┘
##
## Lo de arriba scrollea y lo de abajo queda fijo, y eso no es estética: la
## lista de opciones crece (y ahora crece más, con los saberes para elegir).
## Es la trampa de la bienvenida otra vez — un panel que crece se lleva su
## propio botón abajo del borde de la pantalla y deja el juego trabado.
func _armar_caja() -> void:
	_caja = PanelContainer.new()
	_caja.anchor_left = 0.5
	_caja.anchor_right = 0.5
	_caja.anchor_top = 1.0
	_caja.anchor_bottom = 1.0
	_caja.visible = false

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.07, 0.09, 0.10, 0.94)
	estilo.border_color = VERDE
	estilo.border_width_top = 2
	estilo.content_margin_left = 22
	estilo.content_margin_right = 22
	estilo.content_margin_top = 13
	estilo.content_margin_bottom = 13
	_caja.add_theme_stylebox_override("panel", estilo)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_caja.add_child(col)

	# Con quién estás hablando, y cómo se sale. Lo segundo andaba desde siempre
	# y en pantalla no había una sola letra que lo dijera: *"¿cómo lo cierro si
	# no quiero hablar?"*. Una tecla que existe y no se ve es una tecla que no
	# existe.
	var barra := HBoxContainer.new()
	_quien = Label.new()
	_quien.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quien.add_theme_font_size_override("font_size", 18)
	_quien.add_theme_color_override("font_color", TINTA)
	_legible(_quien)
	barra.add_child(_quien)
	var salida := Label.new()
	salida.text = "[Esc] cerrar"
	salida.add_theme_font_size_override("font_size", 13)
	salida.add_theme_color_override("font_color", TINTA_TENUE)
	_legible(salida, 4)
	barra.add_child(salida)
	col.add_child(barra)

	var rollo := ScrollContainer.new()
	rollo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rollo.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(rollo)

	var adentro := VBoxContainer.new()
	adentro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	adentro.add_theme_constant_override("separation", 10)
	rollo.add_child(adentro)

	_texto = RichTextLabel.new()
	_texto.bbcode_enabled = true
	_texto.fit_content = true
	_texto.scroll_active = false
	_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texto.add_theme_font_size_override("normal_font_size", 17)
	adentro.add_child(_texto)

	_rotulo_actos = _rotulo(ROTULO_ACTOS, VERDE)
	adentro.add_child(_rotulo_actos)

	_opciones = VBoxContainer.new()
	_opciones.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opciones.add_theme_constant_override("separation", 8)
	adentro.add_child(_opciones)

	col.add_child(HSeparator.new())

	# La otra mitad: escribirle lo que se te cante. Va con su propio rótulo y
	# del otro lado de una línea porque **es otra cosa** — esto no toca el
	# mundo, y hasta hoy se veía igual que las opciones que sí lo tocan.
	col.add_child(_rotulo(ROTULO_CHARLA, TINTA_APAGADA))

	_decir = LineEdit.new()
	_decir.placeholder_text = PISTA_QUIETO
	_decir.max_length = 300
	# Apagado hasta que entres: un campo de texto encendido pide que escribas, y
	# lo que este juego quiere que mires primero son las opciones.
	_decir.modulate.a = 0.72
	_decir.focus_entered.connect(func() -> void:
		_decir.placeholder_text = PISTA_TECLEANDO
		_decir.modulate.a = 1.0)
	_decir.focus_exited.connect(func() -> void:
		_decir.placeholder_text = PISTA_QUIETO
		_decir.modulate.a = 0.72)
	# Escape cierra. Sin esto quedás atrapado tecleando y el juego se siente
	# roto en el primer minuto.
	_decir.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventKey and e.pressed and (e as InputEventKey).keycode == KEY_ESCAPE:
			cerrar_caja()
			_decir.accept_event())
	_decir.text_submitted.connect(func(t: String) -> void:
		if t.strip_edges() == "":
			return
		_decir.editable = false
		_texto.text = "[color=#7d867f]…[/color]"
		_api.hablar(npc_cercano, t))
	col.add_child(_decir)

	var cerrar := Button.new()
	cerrar.text = "dejar de hablar    [Esc]"
	cerrar.pressed.connect(cerrar_caja)
	col.add_child(cerrar)

	add_child(_caja)

	# La caja se recoloca contra el tamaño real de la ventana, no contra el que
	# tenía el que la escribió. Con 900 px de alto sobra; en una ventana chica,
	# sin esto, el techo de la caja se va arriba del borde y el jugador pierde
	# el nombre del lugar y la lista de qué hacer.
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_recolocar_caja):
		vp.size_changed.connect(_recolocar_caja)
	_recolocar_caja()


## Un rótulo de sección: chico, en mayúsculas y del color de lo que rotula.
static func _rotulo(texto: String, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", color)
	_legible(l, 4)
	return l


## Dónde va la caja: apoyada en `Y_PISO_CAJA` y creciendo hacia arriba hasta
## `ALTO_CAJA`, sin pasarse del techo ni de los bordes.
func _recolocar_caja() -> void:
	if _caja == null:
		return
	var vp := get_viewport()
	var pantalla := Vector2(1280, 720) if vp == null else Vector2(vp.get_visible_rect().size)
	var techo := clampf(pantalla.y - Y_PISO_CAJA - Y_TECHO, 120.0, float(ALTO_CAJA))
	var alto := clampf(_alto_deseado, minf(float(ALTO_CAJA_MIN), techo), techo)
	var ancho := minf(float(ANCHO_CAJA), pantalla.x * 0.5 - X_MARGEN)
	_caja.offset_left = -ancho
	_caja.offset_right = ancho
	_caja.offset_bottom = -float(Y_PISO_CAJA)
	_caja.offset_top = -float(Y_PISO_CAJA) - alto


func conectar_api(api: Api) -> void:
	_api = api
	_api.dialogo_recibido.connect(_al_dialogo)
	_api.cronica_recibida.connect(_al_cronica)
	# Lo que contestó el mundo cuando mandaste una acción. Es la mitad que
	# faltaba: hasta ahora apretar «Pedirle que te enseñe» no decía nada, y un
	# botón que no dice nada es indistinguible de un botón roto. Ver el
	# comentario largo en `Api.actuar()` — la respuesta llegaba y se tiraba.
	_api.aviso_recibido.connect(_al_aviso)


func _al_aviso(texto: String) -> void:
	_buscando = false
	quiere_juntar.emit(false)
	_refrescar_marcas()
	avisar(texto)


func mostrar_region(region: Dictionary, jugador: Dictionary) -> void:
	_ultima_region = region
	_titulo.text = region.get("name", "El valle")
	_sub.text = "día %s · eres %s" % [region.get("tick", 0), jugador.get("name", "?")]


## Quién tenés al lado, y **su nodo**. El nodo venía llegando y se tiraba
## (`_nodo`, con guion bajo de "no lo uso"): es el que hace posible escribir el
## cartel encima de la persona en vez de abajo al centro.
func mostrar_cercano(nombre: String, nodo: Node3D) -> void:
	var cambio := nombre != npc_cercano
	npc_cercano = nombre
	_npc_nodo = nodo
	_refrescar_marcas()
	# Los botones de dar son de quien tengas al lado, así que se rehacen cuando
	# cambia — pero sólo si la bolsa está abierta: rehacer una lista de nodos
	# cada vez que pasás cerca de alguien, con el panel cerrado, es trabajo
	# tirado en un bucle que corre por cuadro.
	if cambio and _bolsa_panel != null and _bolsa_panel.visible:
		_pintar_dar()


## Qué bicho tenés cerca, y su nodo. Es la hermana de `mostrar_cercano`, y
## existe porque **la interfaz no puede saberlo sola**: los monstruos viven en
## `valle.gd`, que es quien los crea y quien sabe cuál está más cerca.
##
## Con esto el tercer verbo deja de vivir en una esquina. Los otros dos ya se
## anuncian sobre la cosa —hablar sobre la persona, juntar a tus pies— y pegar
## era el único que seguía siendo una tecla que había que saberse.
func mostrar_amenaza(nombre: String, nodo: Node3D) -> void:
	_amenaza_nombre = nombre
	_amenaza_nodo = nodo
	_refrescar_marcas()


func _al_dialogo(d: Dictionary) -> void:
	if d.has("error"):
		_encabezar(npc_cercano, "dde3de")
		_texto.text = str(d["error"])
		_medir_texto(_texto.text)
		_pintar_opciones([])
		_abrir_caja()
		return

	_encabezar(npc_cercano, _tono(d.get("animo", "neutral")))
	# Cuando **arranca el NPC** —te cobra un encargo, te pide lo que le falta,
	# comenta algo que pasó— la frase no es una respuesta a nada tuyo, y tiene
	# que leerse distinto o la iniciativa no existe para el jugador.
	#
	# Se marca con un renglón corto arriba y NO con un color nuevo: el ánimo ya
	# usa el color y pisarlo perdería si te habla enojado o tranquilo, que es
	# información que costó plata producir.
	var arranca: bool = bool(d.get("arranca", false))
	_texto.text = ("[color=#c9a227]%s te habla primero.[/color]\n" % npc_cercano \
		if arranca else "") + "“%s”" % d.get("saludo", "…")
	_medir_texto(_texto.text)
	_pintar_opciones(d.get("opciones", []))
	_abrir_caja()


## Cuánto va a ocupar lo que se acaba de poner en `_texto`. Se llama ANTES de
## `_pintar_opciones()`, que es la que arma la cuenta final.
func _medir_texto(t: String) -> void:
	_alto_texto = maxf(48.0,
		ceilf(float(t.length()) / CHARS_POR_RENGLON) * ALTO_RENGLON + 14.0)


func _encabezar(nombre: String, tono: String) -> void:
	_quien.text = nombre
	_quien.add_theme_color_override("font_color", Color.html(tono))


## Las opciones las manda EL SERVIDOR y salen del estado del mundo: cuáles hay,
## si se pueden, y por qué no. Acá no se inventa ninguna — una opción de más es
## una promesa que el mundo no puede cumplir.
##
## Lo que cambió es cómo se leen, y son tres cosas:
##
## 1. **Lo que no se puede deja de tener forma de botón.** Antes era un `Button`
##    con `disabled = true`, que sigue pareciendo un botón: el ojo lo intenta,
##    la mano lo aprieta, no pasa nada. Ahora es un renglón de texto, debajo de
##    su propio rótulo y al final. El motivo que manda el servidor —"Sarn no le
##    enseña lo suyo a nadie", "nada de lo que llevas le sirve"— es lo que se
##    lee, porque es la información real: dice qué te falta.
## 2. **Lo que sí se puede va primero**, con marca y en verde, aunque el
##    servidor las mande mezcladas.
## 3. **Cada una dice qué hace**, con el renglón de `QUE_HACE`.
func _pintar_opciones(lista: Array) -> void:
	for hijo in _opciones.get_children():
		hijo.queue_free()

	var posibles := 0
	for o: Dictionary in lista:
		if not bool(o.get("posible", false)):
			continue
		posibles += 1
		_opciones.add_child(_fila_posible(o))

	if posibles == 0 and not lista.is_empty():
		# Que no haya nada que hacer con alguien es un dato del mundo, no un
		# error, pero en silencio se lee como que la caja está rota.
		var nada := Label.new()
		nada.text = "Con %s no hay nada que hacer todavía." % npc_cercano
		nada.add_theme_font_size_override("font_size", 13)
		nada.add_theme_color_override("font_color", TINTA_APAGADA)
		nada.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_opciones.add_child(nada)

	var imposibles := 0
	for o: Dictionary in lista:
		if bool(o.get("posible", false)):
			continue
		if imposibles == 0:
			_opciones.add_child(_rotulo(ROTULO_NO, TINTA_APAGADA))
		imposibles += 1
		_opciones.add_child(_fila_imposible(o))

	_rotulo_actos.visible = posibles > 0

	# Cuánto alto pedirle a la caja. Se cuenta acá, con los renglones que acabo
	# de dibujar, y NO se mide después: medir de verdad necesita esperar un
	# cuadro de layout, y una caja que salta de tamaño un cuadro después de
	# abrirse se lee peor que una que sale del tamaño correcto. Los números son
	# gruesos a propósito y el techo de `ALTO_CAJA` los ataja; lo que se pase,
	# scrollea.
	_alto_deseado = ALTO_FIJO_CAJA + _alto_texto + posibles * 58.0
	if posibles == 0 and not lista.is_empty():
		_alto_deseado += 40.0
	if imposibles > 0:
		_alto_deseado += 24.0 + imposibles * 30.0


## Una opción que sí se puede: el botón, y debajo qué hace en un renglón.
func _fila_posible(o: Dictionary) -> Control:
	var verbo := str(o.get("verbo", ""))
	var a_quien := npc_cercano

	var fila := VBoxContainer.new()
	fila.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_theme_constant_override("separation", 1)

	var b := Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_color_override("font_color", VERDE)
	b.add_theme_color_override("font_hover_color", TINTA)
	fila.add_child(b)

	var gloss := Label.new()
	gloss.text = "      " + str(QUE_HACE.get(verbo, ""))
	gloss.visible = QUE_HACE.has(verbo)
	gloss.add_theme_font_size_override("font_size", 12)
	gloss.add_theme_color_override("font_color", TINTA_TENUE)
	gloss.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fila.add_child(gloss)

	# Enseñar teniendo varias cosas en la cabeza: se despliega y elegís cuál.
	var elegir: Array = o.get("elegir", [])
	if verbo == "ensenar" and elegir.size() > 1:
		var cuales := _lista_saberes(elegir, a_quien)
		cuales.visible = false
		fila.add_child(cuales)
		b.text = "› %s  ▾" % str(o.get("texto", ""))
		b.pressed.connect(func() -> void:
			cuales.visible = not cuales.visible
			# El renglón de «qué hace» se va mientras elegís: la lista ya dice
			# lo mismo y con más cuidado, y dos veces la misma frase una arriba
			# de la otra hace dudar de cuál de las dos estás leyendo.
			gloss.visible = not cuales.visible
			# Y la caja pide el alto que ahora necesita, en vez de esconder
			# media lista detrás del scroll sin motivo.
			_alto_deseado += (26.0 + elegir.size() * 30.0) * (1.0 if cuales.visible else -1.0)
			_recolocar_caja())
	else:
		b.text = "› " + str(o.get("texto", ""))
		b.pressed.connect(func() -> void:
			cerrar_caja()
			_api.actuar(verbo, a_quien))
	return fila


## Elegir QUÉ le enseñás.
##
## **Regalar un saber es la decisión más grande del juego** — es lo único que
## hace que no se pierda cuando te morís, y también lo que deja de hacerte
## único. Elegía el servidor: al azar, salvo que el otro estuviera trabado
## esperando justo eso. O sea que podías tener dos oficios en la cabeza,
## apretar «Enseñarle», y enterarte después de cuál regalaste.
##
## La lista **no la inventa el cliente**: viene en `opciones[].elegir` y son los
## saberes tuyos que el otro todavía no tiene, que es lo único que el cliente no
## puede saber solo. Si el servidor no la manda —versión vieja, o un solo saber
## posible— el botón sigue siendo uno y el servidor sigue eligiendo. O sea que
## esto no puede romper nada: sólo agrega cuando hay algo que elegir.
func _lista_saberes(saberes: Array, a_quien: String) -> Control:
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_theme_constant_override("separation", 3)

	var aviso := Label.new()
	aviso.text = "      Se va uno solo y no hay forma de deshacerlo. Elige cuál le dejas."
	aviso.add_theme_font_size_override("font_size", 12)
	aviso.add_theme_color_override("font_color", AMBAR)
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(aviso)

	for s in saberes:
		var nombre := str(s).strip_edges()
		if nombre == "":
			continue
		var b := Button.new()
		b.text = "      enseñarle %s" % nombre
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", AMBAR)
		b.add_theme_color_override("font_hover_color", TINTA)
		b.pressed.connect(func() -> void:
			cerrar_caja()
			# Mismo formato que `dar`: "<qué> a <quién>", que es el que el
			# resolvedor ya sabe partir por el último " a ".
			_api.actuar("ensenar", "%s a %s" % [nombre, a_quien]))
		caja.add_child(b)
	return caja


## Una opción que NO se puede: sin forma de botón, y con el motivo adelante.
func _fila_imposible(o: Dictionary) -> Control:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("normal_font_size", 13)
	# En un renglón: el qué y el por qué juntos. El motivo es lo que importa —es
	# lo que te dice qué te falta— y partirlo en dos renglones le daba a cada
	# imposible el mismo peso vertical que a una acción que sí podés hacer.
	l.text = "[color=#737c77]%s[/color] [color=#5f6864]— %s[/color]" % [
		str(o.get("texto", "")), str(o.get("porque", "todavía no")),
	]
	return l


## Abrir y cerrar. Las dos son una sola cosa y las piden varios lugares —Escape,
## el botón, apretar una opción—, así que viven acá y no repetidas en cada uno.
func _abrir_caja() -> void:
	_recolocar_caja()
	_caja.visible = true
	_decir.editable = true
	_decir.text = ""
	# **No se roba el foco.** Antes sí, y era la mitad del enredo: abrías una
	# charla y de golpe el WASD no caminaba, sin que nada en pantalla lo
	# dijera. Ahora escribir es un acto aparte —[Enter] entra al campo— y lo
	# primero que ves son las opciones, que es lo que mueve el mundo.
	_decir.release_focus()
	# Los carteles del mundo se apagan solos mientras la caja está abierta
	# (ver `_process`), así que acá no hay nada que limpiar.


func cerrar_caja() -> void:
	if _caja == null:
		return
	_caja.visible = false
	if _decir != null:
		_decir.release_focus()
	# Y el cartel vuelve. **`mostrar_cercano(npc_cercano, null)` no**: eso
	# borraría el nodo al que el cartel está pegado y el "[E] hablar con X"
	# volvería sin saber sobre qué cabeza ponerse.
	_refrescar_marcas()


func _al_cronica(texto: String) -> void:
	# La primera crónica de la sesión no va a la cajita de diálogo: es la
	# bienvenida. Es lo que contesta "¿hay una historia que debo conocer?".
	if not _ya_saludamos:
		dar_bienvenida(_ultima_region, texto)
		return
	_encabezar("Lo que pasó aquí", "dde3de")
	_texto.text = texto
	_medir_texto(texto)
	_pintar_opciones([])
	_abrir_caja()


## Cuando no hay token guardado: se pide una vez y queda.
func pedir_token() -> void:
	var caja := LineEdit.new()
	caja.placeholder_text = "pega aquí tu enlace o tu token"
	caja.anchor_left = 0.5
	caja.anchor_right = 0.5
	caja.anchor_top = 0.5
	caja.anchor_bottom = 0.5
	caja.offset_left = -280
	caja.offset_right = 280
	caja.offset_top = -18
	caja.offset_bottom = 18
	var ayuda := Label.new()
	ayuda.text = "Pega tu enlace de jugador y pulsa Enter"
	ayuda.anchor_left = 0.5; ayuda.anchor_right = 0.5
	ayuda.anchor_top = 0.5; ayuda.anchor_bottom = 0.5
	ayuda.offset_left = -280; ayuda.offset_right = 280; ayuda.offset_top = -56
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(ayuda)
	caja.tree_exited.connect(func() -> void: ayuda.queue_free())
	add_child(caja)
	caja.grab_focus()
	caja.text_submitted.connect(func(t: String) -> void:
		var limpio := t.strip_edges()
		if limpio.contains("/j/"):
			limpio = limpio.split("/j/")[1].split("/")[0]
		_api.token = limpio
		_api.guardar_config()
		caja.queue_free()
		_api.pedir_mundo())


## ¿El jugador está tecleando? El jugador 3D lo consulta para no caminar
## mientras uno escribe — sin esto, "hola" te manda a saltar y a atacar.
func escribiendo() -> bool:
	return _decir != null and _decir.has_focus()


## La bolsa. Se abre con I.
##
## Antes era un renglón de texto flotando en una esquina que casi siempre decía
## "no llevás nada", y el que lo jugó lo resumió bien: *"el usuario no tiene
## inventario"*. Tenía razón — un objeto no se podía mirar, no se podía dar, y
## la línea que importa (**quién lo hizo**) entraba entre paréntesis en gris
## junto a la calidad, como si fuera un dato de ficha.
##
## Es al revés. **Quién lo hizo es la mitad del juego**: un cuchillo que dice
## "lo hizo Ilde" veinte días después de que Ilde no está es el juego entero en
## una línea. Por eso el nombre va en ámbar y en su propio renglón, y por eso
## los objetos que no hizo nadie lo dicen con todas las letras en vez de dejar
## un hueco — `made_by = null` significa que creció solo, y esa diferencia
## (la raíz la junta cualquiera, el frasco lo hace sólo quien sabe destilar) es
## una regla del mundo, no un campo vacío.
func _armar_bolsa() -> void:
	# El chip siempre visible. La bolsa completa tapa el diorama, así que se
	# abre a pedido; pero si no queda NADA en pantalla, el jugador no puede
	# saber que existe. Dos palabras y una tecla alcanzan.
	_bolsa_chip = Label.new()
	_bolsa_chip.anchor_left = 1.0; _bolsa_chip.anchor_right = 1.0
	_bolsa_chip.offset_left = -ANCHO_BOLSA
	_bolsa_chip.offset_right = -X_MARGEN
	_bolsa_chip.offset_top = Y_BOLSA - 30
	_bolsa_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_bolsa_chip.add_theme_font_size_override("font_size", 14)
	_bolsa_chip.add_theme_color_override("font_color", TINTA_TENUE)
	_legible(_bolsa_chip)
	add_child(_bolsa_chip)

	_bolsa_panel = PanelContainer.new()
	_bolsa_panel.anchor_left = 1.0; _bolsa_panel.anchor_right = 1.0
	_bolsa_panel.offset_left = -ANCHO_BOLSA
	_bolsa_panel.offset_right = -X_MARGEN
	_bolsa_panel.offset_top = Y_BOLSA
	_bolsa_panel.add_theme_stylebox_override("panel", _caja_de(AMBAR))
	_bolsa_panel.visible = false

	_bolsa = RichTextLabel.new()
	_bolsa.bbcode_enabled = true
	_bolsa.fit_content = true
	_bolsa.scroll_active = false
	_bolsa.add_theme_color_override("default_color", TINTA)
	_bolsa.add_theme_constant_override("line_separation", 3)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.add_child(_bolsa)
	_bolsa_dar = VBoxContainer.new()
	_bolsa_dar.add_theme_constant_override("separation", 4)
	col.add_child(_bolsa_dar)
	_bolsa_panel.add_child(col)
	add_child(_bolsa_panel)


func mostrar_inventario(objetos: Array) -> void:
	_objetos = objetos
	if _bolsa_chip != null:
		_bolsa_chip.text = "bolsa: %d   [I]" % objetos.size()
		# Que el mundo ACUSE lo que hiciste. Juntar algo cambiaba un número de
		# catorce píxeles en una esquina y nada más: el jugador se agachaba, el
		# servidor le daba una rama, y en pantalla no pasaba nada que se notara.
		# El chip se enciende un segundo y medio; no es un cartel nuevo, es el
		# que ya estaba haciéndose ver una vez.
		if _bolsa_cuantos >= 0 and objetos.size() != _bolsa_cuantos:
			if _tw_bolsa != null and _tw_bolsa.is_valid():
				_tw_bolsa.kill()
			_bolsa_chip.add_theme_color_override("font_color", AMBAR)
			_tw_bolsa = create_tween()
			_tw_bolsa.tween_interval(1.5)
			_tw_bolsa.tween_callback(func() -> void:
				_bolsa_chip.add_theme_color_override("font_color", TINTA_TENUE))
		_bolsa_cuantos = objetos.size()
	_pintar_bolsa()


## La calidad en palabras. Un número del 0 al 100 sin escala no dice nada, y
## "48" no le gana a "pasable" en ningún lado.
static func _que_tan_buena(cal: int) -> String:
	return "una porquería" if cal < 25 else \
		"pasable" if cal < 50 else \
		"buena" if cal < 75 else "muy buena"


func _pintar_bolsa() -> void:
	if _bolsa == null:
		return

	if _objetos.is_empty():
		# Que el vacío enseñe el verbo. Este es exactamente el momento en que
		# el jugador necesita saber que `buscar` existe: no tiene nada y no
		# sabe cómo conseguirlo.
		_bolsa.text = "\n".join([
			"[color=#98a29c]NO LLEVAS NADA[/color]",
			"",
			"[color=#7d867f]Pulsa [b]B[/b] para juntar lo que haya donde estás parado.",
			"Sin materia prima no puedes cumplirle nada a nadie.[/color]",
		])
	else:
		var lineas: Array[String] = ["[color=#98a29c]LO QUE LLEVAS[/color]", ""]
		for o in _objetos:
			var d: Dictionary = o
			var cal := int(d.get("quality", 0))
			# OJO con `str()`: el servidor manda `made_by: null` para todo lo
			# que se junta del suelo, y `str(null)` en Godot es la cadena
			# "<null>". El panel viejo mostraba, literal, "la hizo <null>".
			var crudo: Variant = d.get("made_by")
			var quien := "" if crudo == null else str(crudo).strip_edges()
			var autor := "[color=#d9c78c]la hizo %s[/color]" % quien if quien != "" \
				else "[color=#5f6864]nadie la hizo — creció sola[/color]"
			lineas.append("[b]%s[/b]" % d.get("kind", "algo"))
			lineas.append("   [color=#7d867f]%s[/color] · %s" % [
				_que_tan_buena(cal), autor])
		_bolsa.text = "\n".join(lineas)

	_pintar_dar()


## Dar algo a quien tengas al lado.
##
## Va acá y NO en la caja de diálogo, y la diferencia importa: **las opciones
## del diálogo las manda el servidor** en la respuesta de `/hablar`, con su
## `posible` y su `porque`, y hoy manda tres (`aprender`, `ensenar`,
## `trabajar`). Inventar ahí un botón que el servidor no ofreció es exactamente
## cómo se llega a una opción que promete algo que no se puede.
##
## La bolsa es otra superficie: acá el objeto está en la mano y el destinatario
## es el que tenés a un metro. Se manda `dar "<cosa> a <persona>"`, que es el
## formato que el resolvedor parsea (parte por el último " a "), y el servidor
## valida todo lo demás y contesta con una frase que se muestra tal cual —
## medido: "Marta ya casi lo tiene resuelto y no necesita que nadie se meta".
## O sea que la opción nunca miente: el que decide sigue siendo el mundo.
func _pintar_dar() -> void:
	if _bolsa_dar == null:
		return
	for h in _bolsa_dar.get_children():
		h.queue_free()
	if _objetos.is_empty():
		return

	if npc_cercano == "":
		var l := Label.new()
		l.text = "Acércate a alguien para darle algo."
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", TINTA_APAGADA)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_bolsa_dar.add_child(l)
		return

	for o in _objetos:
		var d: Dictionary = o
		var cosa := str(d.get("kind", ""))
		if cosa == "":
			continue
		var b := Button.new()
		b.text = "dar %s a %s" % [cosa, npc_cercano]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 13)
		var a_quien := npc_cercano
		b.pressed.connect(func() -> void:
			b.disabled = true
			_api.actuar("dar", "%s a %s" % [cosa, a_quien]))
		_bolsa_dar.add_child(b)


func _alternar_bolsa() -> void:
	if _bolsa_panel == null:
		return
	_bolsa_panel.visible = not _bolsa_panel.visible
	if _bolsa_panel.visible:
		# Se repinta al abrir: el `npc_cercano` cambia mientras caminás y los
		# botones de dar son de quien tengas al lado AHORA.
		_pintar_bolsa()


## Juntar lo que haya en el lugar donde estás parado (tecla B).
##
## Es la acción que faltaba y sin la que no se cierra nada: no hay forma de
## cumplirle un encargo a nadie si no podés levantar una rama del piso. El
## bucle chico del diseño es *aprendés → buscás o fabricás → das → te ganás a
## la gente → te enseñan más*, y el cliente ofrecía el primero y el último.
##
## Se resuelve en el momento —medido contra producción, ~2,5 s— y lo que
## encontraste vuelve en el aviso.
##
## Y el personaje SE AGACHA mientras dura. El cartel "buscando…" solo no era
## una acción, era un cartel: "apretás B y dice buscando, ¿qué es eso, qué
## estás buscando, hace algo el personaje?". Ahora el cuerpo hace la acción y
## el texto dice qué se está juntando, no un gerundio suelto.
signal quiere_juntar(prendido: bool)

func _buscar() -> void:
	if _api == null or _buscando:
		return
	_buscando = true
	quiere_juntar.emit(true)
	# Sin aviso en el medio de la pantalla: lo que está pasando se lee en el
	# cartel de los pies, que es donde está pasando. Un cartel central para
	# decir que el personaje se agachó tapa al personaje agachándose.
	_refrescar_marcas()
	_api.actuar("buscar")
	# Red de seguridad: si la respuesta se pierde, la tecla tiene que volver a
	# andar. Sin esto un 504 deja `buscar` muerto hasta reiniciar el juego.
	var t := create_tween()
	t.tween_interval(12.0)
	t.tween_callback(func() -> void:
		_buscando = false
		quiere_juntar.emit(false)
		_refrescar_marcas())


## Qué hacer ahora. Lo manda el servidor y sale del estado del mundo, así que
## nunca te pide algo imposible.
##
## Es lo que le faltaba al primer minuto: llegabas a un valle, no conocías a
## nadie, no sabías qué había, y el juego te dejaba parado en un campo.
func mostrar_pasos(lista: Array) -> void:
	if _pasos == null:
		_pasos = RichTextLabel.new()
		_pasos.bbcode_enabled = true
		_pasos.fit_content = true
		_pasos.scroll_active = false
		_pasos.anchor_top = 0.0
		_pasos.anchor_bottom = 0.0
		_pasos.offset_left = X_MARGEN
		_pasos.offset_right = X_MARGEN + ANCHO_COLUMNA
		_pasos.offset_top = Y_COLUMNA
		_pasos.add_theme_constant_override("line_separation", 3)
		_legible(_pasos)
		add_child(_pasos)

	_ultimos_pasos = lista
	if lista.is_empty():
		_pasos.text = ""
		return
	# **Uno, no tres.** Los tres juntos eran ocho renglones de prosa en la
	# esquina de arriba a la izquierda, o sea una nota, no un juego: nadie lee
	# un párrafo para decidir un paso. El resto no se pierde —están todos en la
	# ficha, que se abre con C— y lo inmediato ya no se lee acá sino encima de
	# la cosa con la que se hace.
	var d: Dictionary = lista[0]
	var lineas: Array[String] = [
		"[color=#98a29c]QUÉ HACER AHORA[/color]",
		"· %s" % d.get("texto", ""),
	]
	if lista.size() > 1:
		lineas.append("[color=#5f6864]y %d cosa%s más — [b]C[/b][/color]" % [
			lista.size() - 1, "" if lista.size() == 2 else "s"])
	_pasos.text = "\n".join(lineas)


## La bienvenida. Una sola vez, al entrar: dónde estás y qué pasó acá.
## La puerta de entrada al mundo. Lo que faltaba.
##
## El reclamo fue: "el texto, no entendés la historia, ninguno tiene sentido
## con nada, no se sabe qué pasa en este mundo ni qué hay que hacer". Y era
## exacto: la bienvenida mostraba la crónica, que da por sabido quién es cada
## uno y qué está pasando. **A alguien que llega, la crónica no le dice nada.**
##
## Esto va antes que todo lo demás y contesta las cuatro preguntas que
## cualquiera se hace en los primeros diez segundos: dónde estoy, quién soy,
## qué está en juego, y qué hago ahora. Es texto fijo a propósito: es la
## premisa del juego, no un suceso, y no tiene que costar una llamada al modelo
## ni cambiar entre partidas.
const PREMISA := """[color=#c9a227]EL VALLE[/color]

Aquí el saber no está escrito en ningún lado: vive dentro de la gente, y la gente se muere. Alguien tiene que enseñarte a forjar, y para eso tiene que confiar en ti.

[color=#98a29c]Hace veinte días murió la vieja Ren y se llevó las dos únicas runas que había por aquí. Nadie las va a poder aprender nunca más.[/color]

Acabas de llegar y no sabes hacer nada."""

## El primer minuto, y es lo único que hay que leer.
##
## Antes esto era el final de una pared de texto: premisa, crónica del valle,
## tres pasos y once teclas. Alguien que abre el juego por primera vez no tiene
## que salir de acá con un plan, tiene que salir con **un movimiento y un
## encuentro**: camina, encuentra a alguien, hace una cosa. Todo lo demás lo
## dice el valle cuando corresponde, encima de la cosa que corresponde.
const PRIMER_PASO := """[color=#c9a227]LO PRIMERO[/color]

[b]Camina con WASD hasta que te cruces con alguien.[/b]

Lo que puedes hacer aparece encima de la cosa con la que se hace: sobre la cabeza del que tienes al lado, o a tus pies si hay algo que juntar. [color=#7d867f]No hay ninguna lista que mirar en una esquina.[/color]

Con el [b]botón derecho[/b] giras la cámara; arrastrando hacia arriba se mira el cielo, que es donde están la hora y el día del valle."""


func dar_bienvenida(region: Dictionary, cronica: String) -> void:
	if _ya_saludamos:
		return
	_ya_saludamos = true
	# Con `--captura` no se saluda, por el mismo motivo por el que esa bandera
	# ya fuerza calidad alta: **existe para juzgar el valle, y este panel ocupa
	# el centro de la pantalla.** Cada captura de verificación salía con dos
	# tercios del cuadro tapados por su propia bienvenida, que es tan inútil
	# como juzgar el look en calidad baja.
	if OS.get_cmdline_user_args().has("--captura") \
			or OS.get_cmdline_args().has("--captura"):
		return

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -340; panel.offset_right = 340
	# Creció con la lista de teclas: cuatro renglones más no entraban y el
	# botón de entrar quedaba fuera del panel.
	panel.offset_top = -285; panel.offset_bottom = 285
	panel.add_theme_stylebox_override("panel", _caja_de(VERDE))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)

	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.custom_minimum_size = Vector2(620, 320)
	# El orden es el que importa: la premisa, **qué hacer**, y recién después lo
	# que pasó. La crónica venía tercera de arriba y es lo más difícil de leer
	# que hay acá —da por sabido quién es cada uno— así que ahora está abajo,
	# rotulada como lo que es: algo que ya pasó y que no hay que entender para
	# empezar a jugar.
	var partes: Array[String] = [
		PREMISA,
		"",
		PRIMER_PASO,
		"",
		"[b]%s[/b]  [color=#7d867f]· día %s[/color]" % [
			region.get("name", "El valle"), region.get("tick", 0)],
		"[color=#98a29c]lo último que pasó aquí[/color]",
		"[color=#8d968f]%s[/color]" % (cronica if cronica != ""
			else "Todavía nadie contó nada de este lugar."),
	]
	t.text = "\n".join(partes)

	# El texto va adentro de un contenedor que SCROLLEA, y el botón queda
	# afuera, abajo. Sin esto pasó lo peor que le puede pasar a una pantalla de
	# bienvenida: la premisa alargó el texto, el botón se fue abajo del borde de
	# la pantalla, y **el panel no se podía cerrar**. El juego quedaba trabado
	# en su propia introducción.
	t.fit_content = true
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(t)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)

	var b := Button.new()
	b.text = "entrar al valle    [Esc]"
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var cerrar := func() -> void:
		if is_instance_valid(panel):
			panel.queue_free()
		_bienvenida = null
	b.pressed.connect(cerrar)
	col.add_child(b)
	add_child(panel)
	# Y también se cierra con Escape, que es lo que cualquiera aprieta cuando
	# un cartel no se va.
	_bienvenida = panel


## Que alguien te reconozca al pasar.
##
## No es diálogo: es que el mundo admita que estás. Quien lo jugó lo pidió así:
## "si me acerco, ¿no deberían saludarme al menos? ya saben que estoy". Y tenía
## razón — un NPC que sólo habla cuando lo apretás es mobiliario.
##
## La línea la manda el servidor y sale del vínculo, no del modelo: tiene que
## aparecer en el mismo cuadro en que te acercás.
func reconocer(linea: String, animo: String) -> void:
	if _saludo == null:
		_saludo = RichTextLabel.new()
		_saludo.bbcode_enabled = true
		_saludo.fit_content = true
		_saludo.scroll_active = false
		_saludo.anchor_left = 0.5; _saludo.anchor_right = 0.5
		_saludo.anchor_top = 1.0; _saludo.anchor_bottom = 1.0
		_saludo.offset_left = -330; _saludo.offset_right = 330
		_saludo.offset_top = -Y_SALUDO - ALTO_SALUDO; _saludo.offset_bottom = -Y_SALUDO
		_saludo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_saludo)

	_saludo.text = "[center][color=#%s]%s[/color][/center]" % [_tono(animo), linea]
	_saludo.modulate.a = 1.0

	# Se desvanece sola. Un cartel que se queda deja de ser un momento y pasa
	# a ser interfaz.
	if _fundido != null and _fundido.is_valid():
		_fundido.kill()
	_fundido = create_tween()
	_fundido.tween_interval(3.2)
	_fundido.tween_property(_saludo, "modulate:a", 0.0, 1.1)


## Te pegaron: un flash rojo en los bordes y quién fue.
##
## La vida bajando sola no alcanza — el reclamo fue literal: "me ataca el
## monstruo sin decirme nada". Un golpe tiene que responder en el borde de la
## pantalla, que es donde el ojo lo ve sin estar mirando la barra.
func golpe_recibido(quien: String) -> void:
	if _flash == null:
		_flash = ColorRect.new()
		_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
		_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_flash.color = Color(0.7, 0.12, 0.08, 0.0)
		# El degradé va por shader: un rectángulo rojo plano tapa el juego, y
		# lo que queremos es que se encienda el marco y no la escena.
		var sh := Shader.new()
		sh.code = """
shader_type canvas_item;
uniform float fuerza = 0.0;
void fragment() {
	vec2 d = abs(UV - vec2(0.5)) * 2.0;
	float borde = max(d.x, d.y);
	COLOR = vec4(0.62, 0.08, 0.05, smoothstep(0.35, 1.0, borde) * fuerza);
}"""
		var m := ShaderMaterial.new()
		m.shader = sh
		_flash.material = m
		add_child(_flash)
		move_child(_flash, 0)

	var m2 := _flash.material as ShaderMaterial
	m2.set_shader_parameter("fuerza", 0.85)
	if _tw_flash != null and _tw_flash.is_valid():
		_tw_flash.kill()
	_tw_flash = create_tween()
	_tw_flash.tween_method(
		func(v: float) -> void: m2.set_shader_parameter("fuerza", v),
		0.85, 0.0, 0.45)

	if quien != "":
		avisar("%s te está pegando." % quien)


## Abre la charla ya, con lo que sabemos, mientras el modelo escribe.
##
## El "…" que aparece abajo no es decorativo: es la única señal de que hay algo
## en camino. Sin él, una respuesta que tarda un segundo se lee como que el
## juego se colgó.
func abrir_charla(quien: String, adelanto: String, animo: String) -> void:
	_encabezar(quien, _tono(animo))
	_texto.text = "%s\n\n[color=#5f6864]…[/color]" % adelanto
	_medir_texto(adelanto + "\n\n…")
	_pintar_opciones([])
	_recolocar_caja()
	if _decir != null:
		_decir.editable = false
		_decir.release_focus()
	_caja.visible = true


## El volumen, con las flechas de más y menos del teclado.
##
## Hace falta porque el ambiente es lo único que suena y todavía no lo escuchó
## casi nadie: hasta que alguien con orejas diga que está bien, el jugador
## tiene que poder bajarlo sin salir del juego. Se guarda igual que el nivel de
## calidad — que te obliguen a ajustarlo cada vez que entrás es peor que no
## tenerlo.
const _CONF_VOL := "user://volumen.json"

func _cargar_volumen() -> void:
	var v := 0.45
	if FileAccess.file_exists(_CONF_VOL):
		var t: Variant = JSON.parse_string(FileAccess.open(_CONF_VOL, FileAccess.READ).get_as_text())
		if t is Dictionary and (t as Dictionary).has("volumen"):
			v = clampf(float((t as Dictionary)["volumen"]), 0.0, 1.0)
	_volumen = v
	_aplicar_volumen(false)


func _aplicar_volumen(avisar_en_pantalla := true) -> void:
	var s := get_tree().get_first_node_in_group("sonido")
	if s != null:
		s.set("volumen_general", _volumen)
	if avisar_en_pantalla:
		avisar("Volumen %d%%" % roundi(_volumen * 100.0))
	var f := FileAccess.open(_CONF_VOL, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"volumen": _volumen}))


func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey and evento.pressed) or escribiendo():
		return
	var k := (evento as InputEventKey).keycode
	# Enter entra al campo de texto de la charla. Es la contracara de no robar
	# el foco al abrir: el campo está ahí, apagado y con la tecla escrita en el
	# placeholder, y escribir pasa a ser algo que decidís. Sólo hace algo con la
	# caja abierta, así que no le saca la tecla a nadie.
	if (k == KEY_ENTER or k == KEY_KP_ENTER) and _caja != null and _caja.visible \
			and _decir != null and _decir.editable:
		_decir.grab_focus()
		get_viewport().set_input_as_handled()
		return
	# I y B primero: son acciones del juego, el volumen es un ajuste. Las dos
	# salen por acá y no por `valle.gd` porque las dos son de esta capa —la
	# bolsa es un panel, y `buscar` no toca la escena 3D para nada.
	if k == KEY_I:
		_alternar_bolsa()
		get_viewport().set_input_as_handled()
		return
	if k == KEY_B:
		_buscar()
		get_viewport().set_input_as_handled()
		return
	if k == KEY_ESCAPE:
		# Escape cierra lo que esté encima, de arriba hacia abajo. Es lo que
		# cualquiera aprieta cuando algo no se va, y hasta hoy no hacía nada
		# fuera del chat.
		if _bienvenida != null and is_instance_valid(_bienvenida):
			_bienvenida.queue_free()
			_bienvenida = null
		elif _ficha != null and _ficha.visible:
			_ficha.visible = false
		elif _bolsa_panel != null and _bolsa_panel.visible:
			_bolsa_panel.visible = false
		elif _caja.visible:
			cerrar_caja()
		get_viewport().set_input_as_handled()
		return
	if k == KEY_C:
		alternar_ficha()
		get_viewport().set_input_as_handled()
		return
	if k == KEY_EQUAL or k == KEY_KP_ADD:
		_volumen = minf(1.0, _volumen + 0.1)
	elif k == KEY_MINUS or k == KEY_KP_SUBTRACT:
		_volumen = maxf(0.0, _volumen - 0.1)
	else:
		return
	_aplicar_volumen()
	get_viewport().set_input_as_handled()


## Quién sos. Se abre con C.
##
## Es la respuesta a "no hay stats", y la respuesta es que sí hay — sólo que
## los stats de este juego no son fuerza y destreza, son **lo que sabés, cuánta
## mano tenés en cada cosa, quién te lo enseñó y cómo te ve la gente.** Eso
## vivía entero en la base y el jugador no tenía dónde verlo, que es lo mismo
## que no existir.
##
## Sin un solo número, a propósito: "forja simple 47%" convierte un oficio en
## una barra de progreso, que es justo lo que este juego no quiere ser. El
## servidor manda las palabras ya elegidas.
func mostrar_ficha(vos: Dictionary) -> void:
	_ficha_datos = vos
	if _ficha == null:
		return
	# **Cómo te llama el valle.** El servidor manda `llaman` cuando te ganaste un
	# nombre —«el que le enseñó a Sarn»—, y manda `null` cuando no.
	#
	# Con `null` **no va nada**: ni un guion, ni "sin título", ni un hueco
	# rotulado. Es la parte que hay que resistirse a "arreglar": un casillero
	# vacío con nombre es una barra de progreso disfrazada, y esto no es un
	# nivel. Al que no hizo nada no se lo llama de ninguna manera, y el silencio
	# es exactamente el dato.
	#
	# Y de dónde sale importa: no del tiempo jugado sino de `events`, con
	# enseñar por encima de matar. Es la tesis del juego escrita en el renglón
	# con el que el jugador se mira a sí mismo.
	var l: Array[String] = ["[color=#c9a227]ERES %s[/color]" % vos.get("nombre", "")]
	var crudo_llaman: Variant = vos.get("llaman")
	var llaman := "" if crudo_llaman == null else str(crudo_llaman).strip_edges()
	if llaman != "" and llaman != "<null>":
		l.append("[color=#d9c78c]%s[/color]" % llaman)

	var saberes: Array = vos.get("saberes", [])
	l.append("")
	l.append("[color=#98a29c]LO QUE SABES HACER[/color]")
	if saberes.is_empty():
		l.append("[color=#7d867f]Nada todavía. Nadie nace sabiendo: alguien te lo tiene que enseñar.[/color]")
	for x in saberes:
		var d: Dictionary = x
		var quien: String = str(d.get("maestro", ""))
		l.append("· [b]%s[/b] — %s" % [d.get("nombre", ""), d.get("mano", "")])
		if quien != "" and quien != "<null>":
			l.append("   [color=#7d867f]te lo enseñó %s[/color]" % quien)

	# Los pasos enteros viven acá, y no arriba a la izquierda tapando el valle.
	# Es el mismo dato: lo que cambió es que hay que pedirlo.
	if not _ultimos_pasos.is_empty():
		l.append("")
		l.append("[color=#98a29c]QUÉ HACER AHORA[/color]")
		for p in _ultimos_pasos:
			l.append("· %s" % (p as Dictionary).get("texto", ""))

	l.append("")
	l.append("[color=#98a29c]CÓMO TE VE LA GENTE[/color]")
	for x in vos.get("gente", []):
		var d2: Dictionary = x
		l.append("· %s, %s: [color=#a8b0a6]%s[/color]%s" % [
			d2.get("nombre", ""), d2.get("trade", ""), d2.get("comoTeVe", ""),
			"  [color=#ce8b84]· te teme[/color]" if d2.get("teme", false) else ""])

	_ficha_texto.text = "\n".join(l)


func alternar_ficha() -> void:
	if _ficha == null:
		_ficha = PanelContainer.new()
		_ficha.anchor_left = 0.5; _ficha.anchor_right = 0.5
		_ficha.anchor_top = 0.5; _ficha.anchor_bottom = 0.5
		_ficha.offset_left = -320; _ficha.offset_right = 320
		_ficha.offset_top = -280; _ficha.offset_bottom = 280
		_ficha.add_theme_stylebox_override("panel", _caja_de(VERDE))
		_ficha_texto = RichTextLabel.new()
		_ficha_texto.bbcode_enabled = true
		_ficha_texto.fit_content = true
		_ficha_texto.scroll_active = true
		_ficha_texto.add_theme_constant_override("line_separation", 3)
		_ficha.add_child(_ficha_texto)
		add_child(_ficha)
		mostrar_ficha(_ficha_datos)
	_ficha.visible = not _ficha.visible

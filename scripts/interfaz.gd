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
# De abajo hacia arriba, en píxeles desde el borde inferior:
const Y_AYUDA   := 30     # la línea de teclas, siempre última
const Y_VIDA    := 74     # la barra y el número
const Y_PISTA   := 112    # "[E] hablar con X"
const Y_SALUDO  := 152    # lo que te dicen al pasar
const ALTO_CAJA := 330    # el diálogo, que es lo más alto que hay abajo
# Y a los costados:
const X_MARGEN  := 22

var npc_cercano := ""

var _api: Api
var _decir: LineEdit
var _bolsa: RichTextLabel
var _pasos: RichTextLabel
var _saludo: RichTextLabel
var _flash: ColorRect
var _volumen := 0.45
var _tw_flash: Tween
var _fundido: Tween
var _ya_saludamos := false
var _ultima_region: Dictionary = {}
var _ultimos_pasos: Array = []
var _titulo: Label
var _sub: Label
var _pista: Label
var _caja: PanelContainer
var _texto: RichTextLabel
var _opciones: VBoxContainer


func _ready() -> void:
	var fuente_color := Color(0.87, 0.89, 0.87)

	_titulo = Label.new()
	_titulo.position = Vector2(28, 22)
	_titulo.add_theme_font_size_override("font_size", 26)
	_titulo.add_theme_color_override("font_color", fuente_color)
	add_child(_titulo)

	_sub = Label.new()
	_sub.position = Vector2(28, 56)
	_sub.add_theme_font_size_override("font_size", 15)
	_sub.add_theme_color_override("font_color", Color(0.60, 0.65, 0.62))
	add_child(_sub)

	_pista = Label.new()
	_pista.anchor_left = 0.5
	_pista.anchor_right = 0.5
	_pista.anchor_top = 1.0
	_pista.anchor_bottom = 1.0
	_pista.offset_left = -260
	_pista.offset_right = 260
	_pista.offset_top = -Y_PISTA
	_pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pista.add_theme_font_size_override("font_size", 16)
	_pista.add_theme_color_override("font_color", Color(0.85, 0.78, 0.55))
	add_child(_pista)

	var ayuda := Label.new()
	ayuda.anchor_left = 0.0
	ayuda.anchor_right = 1.0
	ayuda.anchor_top = 1.0
	ayuda.anchor_bottom = 1.0
	ayuda.offset_left = X_MARGEN
	ayuda.offset_right = -X_MARGEN
	ayuda.offset_top = -Y_AYUDA
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ayuda.text = "WASD caminar · shift correr · E hablar · M mapa · F1 calidad · +/− volumen"
	ayuda.add_theme_font_size_override("font_size", 12)
	ayuda.add_theme_color_override("font_color", Color(0.45, 0.50, 0.48))
	add_child(ayuda)

	_armar_vida()
	_armar_caja()
	_cargar_volumen()


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
	add_child(_vida_numero)

	_aviso = Label.new()
	_aviso.anchor_left = 0.5; _aviso.anchor_right = 0.5
	_aviso.anchor_top = 0.5; _aviso.anchor_bottom = 0.5
	_aviso.offset_left = -320; _aviso.offset_right = 320
	_aviso.offset_top = -140
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_font_size_override('font_size', 20)
	_aviso.add_theme_color_override('font_color', Color(0.90, 0.72, 0.62))
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


func avisar(texto: String) -> void:
	_aviso.text = texto
	_aviso.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(2.2)
	t.tween_property(_aviso, 'modulate:a', 0.0, 0.8)


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
		"No perdiste lo que sabés — eso vive en tu cabeza, y ninguna caída te lo saca.",
		"[color=#7d867f]Vas a levantarte en la aldea. Volver hasta acá es caminarlo.[/color]",
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


func _armar_caja() -> void:
	_caja = PanelContainer.new()
	_caja.anchor_left = 0.5
	_caja.anchor_right = 0.5
	_caja.anchor_top = 1.0
	_caja.anchor_bottom = 1.0
	_caja.offset_left = -380
	_caja.offset_right = 380
	_caja.offset_top = -ALTO_CAJA  # 330
	_caja.offset_bottom = -70
	_caja.visible = false

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.07, 0.09, 0.10, 0.94)
	estilo.border_color = Color(0.44, 0.73, 0.62)
	estilo.border_width_top = 2
	estilo.content_margin_left = 26
	estilo.content_margin_right = 26
	estilo.content_margin_top = 22
	estilo.content_margin_bottom = 22
	_caja.add_theme_stylebox_override("panel", estilo)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	_caja.add_child(col)

	_texto = RichTextLabel.new()
	_texto.bbcode_enabled = true
	_texto.fit_content = true
	_texto.custom_minimum_size = Vector2(0, 92)
	_texto.add_theme_font_size_override("normal_font_size", 17)
	col.add_child(_texto)

	_opciones = VBoxContainer.new()
	_opciones.add_theme_constant_override("separation", 6)
	col.add_child(_opciones)

	# Escribirle lo que se te cante. Las opciones de abajo siguen siendo las
	# únicas que mueven el mundo; esto es la conversación.
	_decir = LineEdit.new()
	_decir.placeholder_text = "decile algo…  (Enter)"
	_decir.max_length = 300
	# Escape cierra. Sin esto quedás atrapado tecleando y el juego se siente
	# roto en el primer minuto.
	_decir.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventKey and e.pressed and (e as InputEventKey).keycode == KEY_ESCAPE:
			_caja.visible = false
			_decir.release_focus()
			_decir.accept_event())
	_decir.text_submitted.connect(func(t: String) -> void:
		if t.strip_edges() == "":
			return
		_decir.editable = false
		_texto.text = "[color=#7d867f]…[/color]"
		_api.hablar(npc_cercano, t))
	col.add_child(_decir)

	var cerrar := Button.new()
	cerrar.text = "seguir"
	cerrar.pressed.connect(func() -> void:
		_caja.visible = false
		_decir.release_focus())
	col.add_child(cerrar)

	add_child(_caja)


func conectar_api(api: Api) -> void:
	_api = api
	_api.dialogo_recibido.connect(_al_dialogo)
	_api.cronica_recibida.connect(_al_cronica)


func mostrar_region(region: Dictionary, jugador: Dictionary) -> void:
	_ultima_region = region
	_titulo.text = region.get("name", "El valle")
	_sub.text = "día %s · sos %s" % [region.get("tick", 0), jugador.get("name", "?")]


func mostrar_cercano(nombre: String, _nodo: Node3D) -> void:
	npc_cercano = nombre
	_pista.text = "" if nombre == "" or _caja.visible else "[E] hablar con %s" % nombre


func _al_dialogo(d: Dictionary) -> void:
	if d.has("error"):
		_texto.text = str(d["error"])
		_caja.visible = true
		return

	var tono: String = {
		"calido": "6fb99e", "neutral": "dde3de", "seco": "98a29c", "hostil": "ce8b84",
	}.get(d.get("animo", "neutral"), "dde3de")

	_texto.text = "[color=#%s][b]%s[/b][/color]\n“%s”" % [
		tono, npc_cercano, d.get("saludo", "…"),
	]

	for hijo in _opciones.get_children():
		hijo.queue_free()

	for o: Dictionary in d.get("opciones", []):
		var b := Button.new()
		var txt: String = o.get("texto", "")
		if not o.get("posible", false):
			txt += "  —  " + str(o.get("porque", "no se puede"))
			b.disabled = true
		b.text = txt
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var verbo: String = o.get("verbo", "")
		var quien: String = npc_cercano
		b.pressed.connect(func() -> void:
			_caja.visible = false
			_api.actuar(verbo, quien))
		_opciones.add_child(b)

	_caja.visible = true
	_decir.editable = true
	_decir.text = ""
	_decir.grab_focus()
	_pista.text = ""


func _al_cronica(texto: String) -> void:
	# La primera crónica de la sesión no va a la cajita de diálogo: es la
	# bienvenida. Es lo que contesta "¿hay una historia que debo conocer?".
	if not _ya_saludamos:
		dar_bienvenida(_ultima_region, texto, _ultimos_pasos)
		return
	_texto.text = texto
	for hijo in _opciones.get_children():
		hijo.queue_free()
	_caja.visible = true


## Cuando no hay token guardado: se pide una vez y queda.
func pedir_token() -> void:
	var caja := LineEdit.new()
	caja.placeholder_text = "pegá acá tu link o tu token"
	caja.anchor_left = 0.5
	caja.anchor_right = 0.5
	caja.anchor_top = 0.5
	caja.anchor_bottom = 0.5
	caja.offset_left = -280
	caja.offset_right = 280
	caja.offset_top = -18
	caja.offset_bottom = 18
	var ayuda := Label.new()
	ayuda.text = "Pegá tu link de jugador y apretá Enter"
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


## Lo que llevás encima, y quién lo hizo.
##
## El nombre del que lo forjó es la mitad del punto: un objeto que dice "lo
## hizo Ilde" veinte días después de que Ilde no está es el juego entero en una
## línea.
func mostrar_inventario(objetos: Array) -> void:
	if _bolsa == null:
		_bolsa = RichTextLabel.new()
		_bolsa.bbcode_enabled = true
		_bolsa.fit_content = true
		_bolsa.scroll_active = false
		_bolsa.anchor_left = 1.0
		_bolsa.anchor_right = 1.0
		_bolsa.offset_left = -290
		_bolsa.offset_right = -16
		_bolsa.offset_top = 92
		_bolsa.add_theme_color_override("default_color", Color(0.87, 0.89, 0.86))
		add_child(_bolsa)

	if objetos.is_empty():
		_bolsa.text = "[color=#7d867f]no llevás nada[/color]"
		return

	var lineas: Array[String] = ["[color=#98a29c]LLEVÁS[/color]"]
	for o in objetos:
		var d: Dictionary = o
		var quien: String = str(d.get("made_by", ""))
		var cal := int(d.get("quality", 0))
		# La calidad en palabras: un número sin escala no dice nada.
		var como := "una porquería" if cal < 25 else \
			"pasable" if cal < 50 else \
			"buena" if cal < 75 else "muy buena"
		lineas.append("· %s [color=#7d867f](%s%s)[/color]" % [
			d.get("kind", "algo"), como,
			", la hizo " + quien if quien != "" else ""])
	_bolsa.text = "\n".join(lineas)


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
		_pasos.offset_right = 430
		_pasos.offset_top = 96
		add_child(_pasos)

	_ultimos_pasos = lista
	if lista.is_empty():
		_pasos.text = ""
		return
	var lineas: Array[String] = ["[color=#98a29c]QUÉ HACER AHORA[/color]"]
	for p in lista:
		var d: Dictionary = p
		lineas.append("· %s" % d.get("texto", ""))
	_pasos.text = "\n".join(lineas)


## La bienvenida. Una sola vez, al entrar: dónde estás y qué pasó acá.
func dar_bienvenida(region: Dictionary, cronica: String, pasos: Array) -> void:
	if _ya_saludamos:
		return
	_ya_saludamos = true

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -340; panel.offset_right = 340
	panel.offset_top = -210; panel.offset_bottom = 210

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)

	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.custom_minimum_size = Vector2(640, 300)
	var partes: Array[String] = [
		"[b]%s[/b]  [color=#7d867f]· día %s[/color]" % [
			region.get("name", "El valle"), region.get("tick", 0)],
		"",
		"[color=#98a29c]Lo que pasó acá[/color]",
		cronica if cronica != "" else "[color=#7d867f]Todavía nadie contó nada de este lugar.[/color]",
	]
	if not pasos.is_empty():
		partes.append("")
		partes.append("[color=#98a29c]Por dónde empezar[/color]")
		for p in pasos:
			partes.append("· %s" % (p as Dictionary).get("texto", ""))
	partes.append("")
	partes.append("[color=#7d867f]WASD caminar · shift correr · E hablar · clic pegar · M mapa · F1 calidad · +/− volumen[/color]")
	t.text = "\n".join(partes)
	col.add_child(t)

	var b := Button.new()
	b.text = "entrar al valle"
	b.pressed.connect(func() -> void: panel.queue_free())
	col.add_child(b)
	add_child(panel)


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
		_saludo.offset_top = -Y_SALUDO - 34; _saludo.offset_bottom = -Y_SALUDO
		_saludo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_saludo)

	var tono: String = {
		"calido": "6fb99e", "neutral": "dde3de", "seco": "98a29c", "hostil": "ce8b84",
	}.get(animo, "dde3de")
	_saludo.text = "[center][color=#%s]%s[/color][/center]" % [tono, linea]
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
	var tono: String = {
		"calido": "6fb99e", "neutral": "dde3de", "seco": "98a29c", "hostil": "ce8b84",
	}.get(animo, "dde3de")
	_texto.text = "[color=#%s][b]%s[/b][/color]\n%s\n\n[color=#5f6864]…[/color]" % [
		tono, quien, adelanto if adelanto != "" else "",
	]
	for hijo in _opciones.get_children():
		hijo.queue_free()
	if _decir != null:
		_decir.editable = false
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
	if k == KEY_EQUAL or k == KEY_KP_ADD:
		_volumen = minf(1.0, _volumen + 0.1)
	elif k == KEY_MINUS or k == KEY_KP_SUBTRACT:
		_volumen = maxf(0.0, _volumen - 0.1)
	else:
		return
	_aplicar_volumen()
	get_viewport().set_input_as_handled()

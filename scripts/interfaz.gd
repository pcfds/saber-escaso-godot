## La interfaz. Mínima a propósito: en una vista de diorama, cada panel que
## agregás tapa lo que hace que el juego se vea bien.
extends CanvasLayer

var npc_cercano := ""

var _api: Api
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
	_pista.offset_top = -92
	_pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pista.add_theme_font_size_override("font_size", 16)
	_pista.add_theme_color_override("font_color", Color(0.85, 0.78, 0.55))
	add_child(_pista)

	var ayuda := Label.new()
	ayuda.anchor_left = 1.0
	ayuda.anchor_right = 1.0
	ayuda.anchor_top = 1.0
	ayuda.anchor_bottom = 1.0
	ayuda.offset_left = -420
	ayuda.offset_right = -24
	ayuda.offset_top = -44
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ayuda.text = "WASD caminar · espacio saltar · E hablar · botón derecho girar · rueda acercar"
	ayuda.add_theme_font_size_override("font_size", 12)
	ayuda.add_theme_color_override("font_color", Color(0.45, 0.50, 0.48))
	add_child(ayuda)

	_armar_caja()


func _armar_caja() -> void:
	_caja = PanelContainer.new()
	_caja.anchor_left = 0.5
	_caja.anchor_right = 0.5
	_caja.anchor_top = 1.0
	_caja.anchor_bottom = 1.0
	_caja.offset_left = -380
	_caja.offset_right = 380
	_caja.offset_top = -330
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

	var cerrar := Button.new()
	cerrar.text = "seguir"
	cerrar.pressed.connect(func() -> void: _caja.visible = false)
	col.add_child(cerrar)

	add_child(_caja)


func conectar_api(api: Api) -> void:
	_api = api
	_api.dialogo_recibido.connect(_al_dialogo)
	_api.cronica_recibida.connect(_al_cronica)


func mostrar_region(region: Dictionary, jugador: Dictionary) -> void:
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
	_pista.text = ""


func _al_cronica(texto: String) -> void:
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

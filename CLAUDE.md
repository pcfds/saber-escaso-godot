# Saber Escaso — cliente de Godot

El cliente 3D del valle. El mundo NO vive acá: vive en el servidor
(`../saber-escaso`, desplegado en https://saber-escaso.vercel.app). Esto es una
ventana a ese mundo.

## El invariante. No se negocia.

**Lo que pasa en el cliente tiene que llegar al servidor, o no pasó.**

Ya lo rompimos una vez, entero: monstruos con IA, combate, vida y muerte que
vivían sólo en la máquina de cada jugador. Se veía como un juego y no lo era.
Matabas algo y el mundo no se enteraba, no lo veía nadie más, no quedaba nada.
Toda mecánica nueva escribe en la base o es una demo.

## Cómo está armado

```
escenas/valle.tscn      la escena; todo lo demás lo arma valle.gd por código
scripts/valle.gd        terreno, lugares, NPCs, monstruos, el pegamento
scripts/jugador.gd      CharacterBody3D, cámara en órbita acotada
scripts/figura.gd       cuerpo articulado animado con senos, sin archivos de animación
scripts/monstruo.gd     máquina de tres estados con un momento de duda
scripts/detalles.gd     ventanas, humo, pasto y piedras en MultiMesh, luciérnagas
scripts/ambiente.gd     WorldEnvironment: SDFGI, niebla volumétrica, AgX, DOF
scripts/api.gd          habla con el servidor; el token sale de token.txt o --token=
scripts/interfaz.gd     HUD, diálogo, campo para escribirle a los NPCs
desplegar.sh            probar → exportar → cerrar el juego → instalar. UNA carpeta.
```

## Cómo se despliega

`./desplegar.sh`. Nada de copiar el `.exe` a mano: Windows lo bloquea mientras
corre y ahí es donde nacen las carpetas `SaberEscaso2`. El script corre el juego
headless primero y **aborta si hay `SCRIPT ERROR`** — un `--import` limpio no
prueba nada, los errores de orden de inicialización sólo aparecen en `_ready()`.

## Trampas ya pisadas. No las repitas.

- **`SurfaceTool.set_material()` no aplica.** Usá `material_override`.
- **Winding invertido = normales para abajo = el piso no recibe sol.** Usá
  `[0,1,2]/[0,2,3]` y `st.generate_normals()`.
- **Sol a -26° dejaba una banda negra** cruzando el valle (el borde del cuenco
  sombreaba todo). Está en -44°.
- **Bajo WSL no hay GPU** — Vulkan por software (llvmpipe). SDFGI y SSR salen
  basura acá y bien en el `.exe`. No los apagues por una captura hecha en WSL.
- **`Object._get()` ya existe.** No le pongas `_get` a un método propio.
- **Un `LineEdit` visible se come el WASD.** Todo campo de texto avisa con
  `Interfaz.escribiendo()`.
- **Un error en `_ready()` aborta la función entera** y el juego arranca sin
  HUD, sin API, sin nada. Fue exactamente el bug de `interfaz` usada seis
  líneas antes de existir.

## Lo que falta (al 17 de agosto de 2026)

- Los ojos: las figuras no tienen cara. Los monstruos sí (dos esferas emisivas).
- Inventario en pantalla: los objetos existen en el servidor y no se ven acá.
- Las amenazas del servidor no se dibujan; los monstruos de la escena todavía
  son locales y no están atados a la tabla `threats`.
- No hay otros jugadores visibles en la escena de Godot.

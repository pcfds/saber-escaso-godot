# Saber Escaso — cliente Godot

Cliente 3D del mismo mundo que corre en https://saber-escaso.vercel.app.
La base, la simulación, el director de IA y el diálogo de NPCs **no cambian**:
esto es sólo la capa de dibujo.

Motor: **Godot 4.7.1**, renderer Forward+.

## Correrlo

```bash
godot --path . -- --token=TU_TOKEN
```

El token sale de tu link en la web (`/j/<token>`). Si no lo pasás, el juego te
lo pide una vez y lo guarda.

## Controles

| | |
|---|---|
| WASD / flechas | caminar (relativo a la cámara) |
| Espacio | saltar |
| E | hablar con quien tengas al lado |
| Botón derecho + arrastrar | girar la cámara |
| Rueda | acercar / alejar |

## Cómo está armado

```
scripts/ambiente.gd   la luz — es el 80% del look, y no cuesta un asset
scripts/valle.gd      construye el mundo y lo puebla con lo que dice el servidor
scripts/jugador.gd    movimiento y cámara isométrica restringida
scripts/api.gd        cliente HTTP del mismo servidor que usa la web
scripts/interfaz.gd   HUD y diálogo
```

Todo procedural: no hay un solo asset importado. El terreno se genera con
ruido, los lugares se arman con primitivas, y lo que hace que se vea bien es
la iluminación.

## Las cuatro decisiones del look

1. **Profundidad de campo en vista isométrica.** Desenfocar lo lejano hace que
   el cerebro lea la escena como una maqueta. Es el efecto tilt-shift, y es lo
   distintivo del juego.
2. **Niebla volumétrica.** Convierte la luz direccional en rayos.
3. **SDFGI.** Iluminación global en tiempo real: la pared iluminada tiñe el piso.
4. **AgX** como tonemapper — filmic, no quema los naranjas de la fragua.

## ⚠ Sobre las capturas

Las capturas de este repo se sacaron en **WSL con llvmpipe, un renderer por
software sin GPU**. En esa configuración SDFGI y los reflejos en pantalla
producen basura, así que están **apagados** en el código.

**Al correrlo con GPU real, prendé estas tres líneas en `scripts/ambiente.gd`:**

```gdscript
e.sdfgi_enabled = true
e.ssr_enabled = true
```

Se ve bastante mejor con eso puesto.

## Lo que todavía no hay

Animación de personajes, monstruos, combate, multijugador y inventario. Están
en el navegador (menos animación y monstruos) y hay que portarlos.

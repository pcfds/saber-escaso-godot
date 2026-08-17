# Saber Escaso — cliente 3D

La ventana al valle. Godot 4.7, vista lejana tipo Stardew o Baldur's Gate, todo
procedural y sin un solo asset: el look sale de la luz.

**Bajar la demo:** [releases](https://github.com/pcfds/saber-escaso-godot/releases) ·
**El mundo vive acá:** [pcfds/saber-escaso](https://github.com/pcfds/saber-escaso) ·
**Sitio:** https://saber-escaso.vercel.app

## El invariante

**Lo que pasa en el cliente tiene que llegar al servidor, o no pasó.**

Ya lo rompimos entero una vez: monstruos con IA, combate, vida y muerte que
vivían sólo en la máquina de cada jugador. Se veía como un juego y no lo era —
matabas algo y el mundo no se enteraba. Toda mecánica nueva escribe en la base
o es una demo.

## Lo que hace

- **Terreno, cordillera y vegetación procedurales.** La cordillera tiene una
  sola abertura, al norte, por donde entra El Camino del Norte. Un valle que se
  termina en niebla es un nivel; cercado con una salida es un lugar.
- **Cielo con shader propio**: estrellas con magnitudes distintas, vía láctea,
  dos lunas y un gigante gaseoso. El `ProceduralSkyMaterial` de Godot no tiene
  noche — da un degradé y el mundo queda adentro de una caja azul.
- **Día y noche atados al reloj del servidor.** Un tick es un día del valle y
  el cron corre uno cada seis horas, así que **seis horas reales son una vuelta entera del
  sol**, y dos personas conectadas ven el mismo atardecer. La fase de la luna
  es el día del valle.
- **Cuerpos animados con senos**, sin un solo archivo de animación: brazos y
  piernas en contrafase cruzada, rebote del torso al doble de frecuencia que
  los pasos, cabeza estabilizada. Cada persona con su altura, corpulencia,
  piel y pelo, deterministas a partir del nombre — así Ilde es la misma Ilde
  en la pantalla de todos.
- **Los monstruos son las amenazas de la base.** Le pegás, se resuelve en el
  servidor al instante, y lo ve todo el mundo.

```
escenas/valle.tscn      la escena; todo lo demás lo arma valle.gd por código
scripts/valle.gd        terreno, lugares, NPCs, amenazas, el pegamento
scripts/cielo.gd        el shader del cielo
scripts/ciclo.gd        el reloj del mundo, dibujado
scripts/figura.gd       cuerpo articulado, cara, variación por nombre
scripts/monstruo.gd     tres estados y un momento de duda antes de atacar
scripts/detalles.gd     ventanas, humo, pasto y piedras en MultiMesh, luciérnagas
scripts/ambiente.gd     WorldEnvironment: SDFGI, niebla volumétrica, AgX, DOF
scripts/api.gd          habla con el servidor
scripts/interfaz.gd     HUD, diálogo, inventario
desplegar.sh            probar → exportar → cerrar el juego → instalar
```

## Compilar

```bash
./desplegar.sh
```

Corre el juego headless primero y **aborta si hay `SCRIPT ERROR`**: un
`--import` limpio no prueba nada, los errores de orden de inicialización sólo
aparecen ejecutando `_ready()`. Después exporta, cierra el juego si está
abierto —Windows bloquea el `.exe` mientras corre— y sobrescribe siempre la
misma carpeta.

Las trampas ya pisadas están en [`CLAUDE.md`](CLAUDE.md). Leelas antes de tocar
la escena: hay varias que cuestan una tarde cada una.

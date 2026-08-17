# De dónde salió cada sprite, y con qué permiso

Mismo criterio que `assets/PROCEDENCIA.md`, que es el del arte 3D: **los dos
repos son públicos y el juego se distribuye como `.exe`, así que acá no entra
nada sin licencia clara que permita uso comercial y redistribución.** Ante la
duda, no entra.

## Resumen

Todo el arte 2D es de **Dungeon Crawl Stone Soup** (el tileset que empezó
siendo *rltiles*) y está bajo **CC0 1.0 Universal** — dominio público. No
exige atribución. El crédito de abajo es voluntario y lo dejamos porque
corresponde.

> Los artistas de Dungeon Crawl Stone Soup / rltiles ·
> https://opengameart.org/content/dungeon-crawl-32x32-tiles · CC0 1.0

## El pack

| Pack | Página (dice la licencia) | Zip descargado | md5 del zip |
|---|---|---|---|
| Dungeon Crawl Stone Soup Full | https://opengameart.org/content/dungeon-crawl-32x32-tiles | `Dungeon Crawl Stone Soup Full_0.zip` | `355bec5e237e41ac461e29453784d59f` |

Espejos oficiales del mismo material, por si OpenGameArt se cae:
`https://github.com/crawl/tiles/tree/master/releases`.

### Dónde dice CC0, textualmente

1. **En la página de OpenGameArt**, campo "License(s)":

   ```html
   <div class="field-label">License(s):&nbsp;</div> CC0
   ```

   y en la descripción del autor:

   > You can use these tilesets in your program freely. No attribution is
   > required. As a courtesy, include a link to the OGA page […]

2. **Adentro del zip**, en `LICENSE.txt` — copiado a este repo sin tocar como
   `assets/2d/dcss/LICENSE-dcss.txt`:

   > No Copyright — The person who associated a work with this document has
   > dedicated the work to the Commons by waiving all of his or her rights to
   > the work worldwide under copyright law […]
   > http://creativecommons.org/publicdomain/zero/1.0/legalcode

3. **En el `README.txt` del zip** (también copiado, `README-dcss.txt`), que es
   la parte que importa porque explica *por qué* es CC0 y no la licencia vieja
   de Crawl:

   > The wonderful developers/artists who work on Crawl Stone Soup have signed
   > off their copyrights on the tiles enclosed in here, returning them back to
   > a state similar to public domain (CC Zero, see LICENSE.TXT). They are free
   > to use for any purpose.

   El `README.txt` trae además **la lista nominal de los artistas** que dieron
   el visto bueno en 2010. Esa lista es la evidencia real y por eso el archivo
   viaja en el repo y no se resume acá.

## Qué se bajó y cómo

```sh
curl -sL -A "Mozilla/5.0" -o dcss_full.zip \
  "https://opengameart.org/sites/default/files/Dungeon%20Crawl%20Stone%20Soup%20Full_0.zip"
```

Directo de OpenGameArt, sin intermediarios. El zip trae **6029 PNG**, todos de
**32×32 exactos** (se verificó leyendo la cabecera IHDR de los 6029: no hay ni
uno de otro tamaño).

## Por qué éste y no Kenney

Kenney también tiene packs 2D CC0 y se descartaron **a propósito**. El veredicto
de dirección sobre las mallas fue que el low-poly de Kenney se lee como *"mundo
de Disney para mujeres"*, y el 2D de Kenney tiene exactamente el mismo problema:
es plano, redondeado y pastel. Cambiar de 3D a 2D manteniendo al mismo autor
habría reproducido el defecto en otra técnica.

Crawl va para el otro lado y por eso está acá: **dibujado a mano, valores
oscuros, contorno negro, paleta terrosa, sin brillo.** Es el tileset de los
roguelikes, que es la familia de la referencia que se pidió (táctico denso, con
mugre). Sigue valiendo la regla de `assets/PROCEDENCIA.md`: **un solo autor.**
Si falta una pieza, se dibuja o no se hace; no se trae un segundo estilo.

Dos cosas que hay que saber igual:

- **Crawl es un dungeon.** Tiene mucha gente, mucho bicho y mucho mueble, y
  poca casa: no hay arquitectura de aldea. Los `shop_*.png` son lo más cercano
  y son fachaditas de una celda. Para el valle habría que dibujar los edificios.
- **Los árboles de Crawl son de otoño** (`tree_1_red`, `tree_1_yellow`,
  `tree_2_lightred`). Los verdes del juego se generan recoloreando, y acá no
  vinieron. Los `mangrove_*` son los únicos verdes. **En el prototipo eso se
  ve: el bosque de prueba es naranja.** Recolorear por matiz es una línea de
  shader; no se hizo porque no era lo que había que probar en esta ronda.

## Qué se importó, exactamente

Sólo lo que usa el prototipo — no el pack entero. **6029 sprites disponibles,
91 importados**, 408 KB en disco.

- `assets/2d/dcss/vegetacion/` — 19. Árboles, mangles, arbustos, zarzas,
  plantas, hongos.
- `assets/2d/dcss/gente/` — 30. Humanos, magos, orcos, elfos, enanos, medianos,
  faunos, centauros, ogros, trolls. La variedad de silueta que hace falta para
  que un pueblo no sea el mismo tipo repetido.
- `assets/2d/dcss/pueblo/` — 30. Fachadas de comercio, puertas, portones,
  estatuas, columnas, fuentes, cofres, cajones, un pedrusco.
- `assets/2d/dcss/bichos/` — 12. Osos, oveja, yak, elefante, cocodrilo, víbora,
  murciélago, mariposa, hormiga, escorpión, cangrejo.

Formato **PNG con alfa**, RGBA8, 32×32.

## Cómo están configurados los `.import`, y por qué

Los 91 `.png.import` se generaron con `godot --headless --import` y después se
les cambiaron dos claves a mano. **Las dos importan:**

```ini
mipmaps/generate=true     # sin esto, a 68 m el sprite chispea al girar la cámara
detect_3d/compress_to=0   # sin esto, al usarlos en 3D Godot los RE-IMPORTA solo
                          # a VRAM comprimido, que sobre pixel art de 32 px es
                          # basura: el bloque de BC1 mide 4×4 téxeles, o sea un
                          # octavo del sprite.
```

`compress/mode=0` (sin comprimir) ya venía por defecto y se deja: 91 sprites
de 32×32 con mipmaps son **485 KB en memoria de video**. No hay nada que
ahorrar.

El filtro **no** va acá: en 3D lo decide el material, y `tarjeta.gd` lo pone en
`NEAREST_WITH_MIPMAPS`. El ajuste de proyecto
`rendering/textures/canvas_textures/default_texture_filter` es sólo para 2D y
**no se tocó** — `project.godot` está intacto (md5 verificado antes y después
de importar).

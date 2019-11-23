<section class="segment">

### Color.set(col) :id=color-set

Applies a color preset for Reaper's gfx functions

| **Required** | []() | []() |
| --- | --- | --- |
| col | string&#124;array | An existing preset (`"elementBody"`, `"red"`) or an array of RGBA values (0-1): `{r, g, b, a}`. If an array doesn't include a value for alpha, it will default to 1. |

| **Returns** | []() |
| --- | --- |
| array | The RGBA values used (`{r, g, b, a}`); this may be useful when applying string presets. |

</section>
<section class="segment">

### Color.fromRgba(r, g, b, a) :id=color-fromrgba

Converts a color from 0-255 RGBA.

| **Required** | []() | []() |
| --- | --- | --- |
| r | number | Red, 0-255 |
| g | number | Green, 0-255 |
| b | number | Blue, 0-255 |
| a | number | Alpha, 0-255 |

| **Returns** | []() |
| --- | --- |
| array | Color components, with values from 0-1. (`{r, g, b, a}`) |

</section>
<section class="segment">

### Color.toRgba(r, g, b, a) :id=color-torgba

Converts a color to 0-255 RGBA.

| **Required** | []() | []() |
| --- | --- | --- |
| r | number | Red, 0-1 |
| g | number | Green, 0-1 |
| b | number | Blue, 0-1 |
| a | number | Alpha, 0-1 |

| **Returns** | []() |
| --- | --- |
| array | Color components, with values from 0-255. (`{127, 51, 127, 255}`) |

</section>
<section class="segment">

### Color.fromHex(hexStr) :id=color-fromhex

Converts a color from 0-255 RGBA in hexadecimal form

| **Required** | []() | []() |
| --- | --- | --- |
| hexStr | string | A color string of the form `FF34CA81`. The string may be prefixed with `#` or `0x`, as both are very common when using hex colors. |

| **Returns** | []() |
| --- | --- |
| array | Color components, with values from 0-1. (`{r, g, b, a}`) |

</section>
<section class="segment">

### Color.toHex(r, g, b, a) :id=color-tohex

Converts a color to 0-255 RGBA in hexadecimal form.

| **Required** | []() | []() |
| --- | --- | --- |
| r | number | Red, 0-1 |
| g | number | Green, 0-1 |
| b | number | Blue, 0-1 |
| a | number | Alpha, 0-1 |

| **Returns** | []() |
| --- | --- |
| string | A color string of the form `FF34CA81` |

</section>
<section class="segment">

### Color.toHsv(r, g, b, a) :id=color-tohsv

Converts a color to HSV (Hue, Saturation, Value).

| **Required** | []() | []() |
| --- | --- | --- |
| r | number | Red, 0-1 |
| g | number | Green, 0-1 |
| b | number | Blue, 0-1 |
| a | number | Alpha, 0-1 |

| **Returns** | []() |
| --- | --- |
| array | `{hue, saturation, value, alpha}`. `hue` is a number from 0 to 360, while the remaining values are from 0 to 1. |

</section>
<section class="segment">

### Color.fromHsv(h, s, v, a) :id=color-fromhsv

Converts a color from HSV (Hue, Saturation, Value).

| **Required** | []() | []() |
| --- | --- | --- |
| h | number | Hue angle, 0-360 |
| s | number | Saturation, 0-1 |
| v | number | Value, 0-1 |
| a | number | Alpha, 0-1 |

| **Returns** | []() |
| --- | --- |
| array | Color components, with values from 0-1. (`{r, g, b, a}`) |

</section>
<section class="segment">

### Color.gradient(b, pos[, a]) :id=color-gradient

Returns the color for a given position on an HSV gradient between two colors.

| **Required** | []() | []() |
| --- | --- | --- |
| a	string|array | A | preset strng, or color components with values from 0-1. (`{r, g, b, a}`) |
| b | string&#124;array | A preset strng, or color components with values from 0-1. (`{r, g, b, a}`) |
| pos | number | Position along the gradient from 0-1, where 0 == `a` and 1 == `b`. |

| **Returns** | []() |
| --- | --- |
| array | Color components, with values from 0-1. (`{r, g, b, a}`) |

</section>
<section class="segment">

### Color.addColorsFromRgba(colors) :id=color-addcolorsfromrgba

Adds colors to the available presets, or overrides existing ones.

| **Required** | []() | []() |
| --- | --- | --- |
| colors | hash | A table of preset arrays, in the form `{ presetName: {r, g, b, a} }`. Expects component values from 0-255. |

</section>
<section class="segment">

### Color.toNative([color]) :id=color-tonative

Converts a color to OS-native, for use with API functions such as `reaper.SetTrackColor`.

| **Required** | []() | []() |
| --- | --- | --- |
| array | Color | components, with values from 0-1. (`{r, g, b, a}`) |

| **Returns** | []() |
| --- | --- |
| number | An OS-native color |

</section>
<section class="segment">

### Color.fromNative([color]) :id=color-fromnative

Converts a color from OS-native, for use with API functions such as ` reaper.GetTrackColor`.

| **Required** | []() | []() |
| --- | --- | --- |
| number | An | OS-native color |

| **Returns** | []() |
| --- | --- |
| array | Color components, with values from 0-1. (`{r, g, b, a}`) |

</section>
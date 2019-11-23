<section class="segment">

### Text.initTextWidth() :id=text-inittextwidth

Iterates through all of the font presets, storing the widths of every printable
ASCII character in a table. Widths are directly accessable via:


```lua
Text.textWidth[font_num][char_num]
```


Notes:


- Requires a window to have been opened in Reaper
- 'getTextWidth' and 'wrapText' will automatically run this

</section>
<section class="segment">

### Text.getTextWidth(str, font) :id=text-gettextwidth

Returns the total width of a given string and font. Most of the time it's
simpler to use `gfx.measurestr()`, but scripts with a lot of text may find it
more performant to use this instead.

| **Required** | []() | []() |
| --- | --- | --- |
| str | string |  |
| font | number&#124;string | A font preset |

| **Returns** | []() |
| --- | --- |
| number | Width, in pixels. |

</section>
<section class="segment">

### Text.fitTextWidth(str, font, w) :id=text-fittextwidth

Measures a string to see how much of it will it in the given width

| **Required** | []() | []() |
| --- | --- | --- |
| str | string |  |
| font | number&#124;string | A font preset |
| w | number | Width, in pixels. |

| **Returns** | []() |
| --- | --- |
| string | The portion of `str` that will fit within `w` |
| string | The portion of `str` that will not fit within `w` |

</section>
<section class="segment">

### Text.wrapText(str, font, w[, indent, pad]) :id=text-wraptext

Wraps a string with new lines until it can fit within a given width


This function expands on the "greedy" algorithm found here:
https://en.wikipedia.org/wiki/Line_wrap_and_wrapText#Algorithm

| **Required** | []() | []() |
| --- | --- | --- |
| str | string | Can include line breaks/paragraphs; they should be preserved. |
| font | string&#124;number | A font preset |
| w | number | Width, in pixels |

| **Optional** | []() | []() |
| --- | --- | --- |
| indent | number | Number of spaces to indent the first line of each paragraph. Defaults to 0. <br> (The algorithm skips tab characters and leading spaces, so use this instead) |
| pad | number | Indents wrapped lines to match the first `pad` characters of a paragraph, for use with bullet point, etc. Defaults to 0. |

| **Returns** | []() |
| --- | --- |
| string | The wrapped string |

</section>
<section class="segment">

### Text.drawWithShadow(str, textColor, shadowColor) :id=text-drawwithshadow

Draws a string with the specified text and shadow colors. The shadow
will be drawn at 45' to the bottom-right.

| **Required** | []() | []() |
| --- | --- | --- |
| str | string |  |
| textColor | number&#124;string | A color preset |
| shadowColor | number&#124;string | A color preset |

</section>
<section class="segment">

### Text.drawWithOutline(str, textColor, outlineColor) :id=text-drawwithoutline

Draws a string with the specified text and outline colors.

| **Required** | []() | []() |
| --- | --- | --- |
| str | string |  |
| textColor | number&#124;string | A color preset |
| outlineColor | number&#124;string | A color preset |

</section>
<section class="segment">

### Text.drawBackground(str, color, align) :id=text-drawbackground

necessary for blitting some elements; antialiased text with a transparent
background looks terrible. This function draws a rectangle 2px larger than
the text on all sides.


Call with your position, font, and color already set:


```lua
gfx.x, gfx.y = self.x, self.y
Font.set(self.font)
Color.set(self.col)


Text.drawBackground(self.text)


gfx.drawstr(self.text)


Also accepts an optional background color:
Text.drawBackground(self.text, "backgroundDarkest")
```

| **Required** | []() | []() |
| --- | --- | --- |
| str | string |  |
| color | number&#124;string | A color preset |
| align | number | Alignment flags. See the documentation for `gfx.drawstr()`. |

</section>
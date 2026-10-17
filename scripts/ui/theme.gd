extends Node
## Paleta y helpers de UI. Autoload como BitTheme.

const BG_DARK   := Color(0.0509804, 0.0509804, 0.0588235)
const BG_CARD   := Color(0.101961, 0.101961, 0.121569)
const BG_HOVER  := Color(0.145098, 0.145098, 0.168627)
const SIDEBAR   := Color(0.0705882, 0.0705882, 0.0862745)
const ACCENT    := Color(0.486275, 0.301961, 1.0)
const ACCENT_2  := Color(0.0, 0.898039, 1.0)
const ACCENT_3  := Color(1.0, 0.25098, 0.505882)
const TEXT      := Color(1, 1, 1, 1)
const TEXT_DIM  := Color(0.627451, 0.627451, 0.658824)
const SUCCESS   := Color(0.0, 0.901961, 0.462745)
const WARNING   := Color(1.0, 0.670588, 0.0)
const DANGER    := Color(1.0, 0.0901961, 0.266667)

const PAD_SM := 8
const PAD_MD := 16
const PAD_LG := 24
const RADIUS_SM := 8
const RADIUS_MD := 14
const RADIUS_LG := 22

func hex(s: String) -> Color:
    return Color.html(s)

func stylebox(bg: Color, radius: int, pad: int) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.corner_radius_top_left = radius
    sb.corner_radius_top_right = radius
    sb.corner_radius_bottom_left = radius
    sb.corner_radius_bottom_right = radius
    sb.content_margin_left = pad
    sb.content_margin_right = pad
    sb.content_margin_top = pad
    sb.content_margin_bottom = pad
    return sb

func card(node: Control) -> PanelContainer:
    var p := PanelContainer.new()
    p.add_theme_stylebox_override("panel", stylebox(BG_CARD, RADIUS_MD, PAD_MD))
    p.add_child(node)
    return p

func button(text: String, primary := true) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(0, 42)
    b.add_theme_stylebox_override("normal", stylebox(ACCENT if primary else BG_HOVER, RADIUS_MD, 12))
    b.add_theme_stylebox_override("hover", stylebox((ACCENT if primary else BG_HOVER).lightened(0.1), RADIUS_MD, 12))
    b.add_theme_stylebox_override("pressed", stylebox((ACCENT if primary else BG_HOVER).darkened(0.1), RADIUS_MD, 12))
    b.add_theme_color_override("font_color", TEXT)
    b.add_theme_font_size_override("font_size", 15)
    return b

func label(text: String, size := 14, color := TEXT) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l

func title(text: String, size := 28) -> Label:
    var l := label(text, size, TEXT)
    l.add_theme_color_override("font_outline_color", Color(0,0,0,0))
    return l
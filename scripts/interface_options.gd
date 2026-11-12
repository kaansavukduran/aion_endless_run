class_name RunnerInterfaceOptions
extends RefCounted

const DARK := {
 "background":"181620", "surface":"27212e", "raised":"332b39", "hover":"493649", "pressed":"5b3d50",
 "text":"f5ebd9", "muted":"cfbec4", "accent":"ffcf8c", "primary":"81374e", "primary_hover":"93405b", "primary_pressed":"64263c", "on_primary":"fff5e5", "border":"ad8d9f", "danger":"f17a96", "success":"a2d999"
}
const LIGHT := {
 "background":"fbf4e6", "surface":"f2e5d0", "raised":"fff9ee", "hover":"e2cbd2", "pressed":"d5b6c3",
 "text":"30232d", "muted":"644b5c", "accent":"744622", "primary":"81374e", "primary_hover":"93405b", "primary_pressed":"64263c", "on_primary":"fff5e5", "border":"816474", "danger":"9a2442", "success":"285b32"
}
var touch_layout := "split"
var theme_mode := "dark"
var font_mode := "system"
var text_scale := 1.0
var reduced_motion := false
var dark := true
var colors: Dictionary = DARK
var body_font: Font

func load_from(cfg: ConfigFile) -> void:
 touch_layout=str(cfg.get_value("prefs","touch_layout","split"))
 if touch_layout not in ["split","right"]:touch_layout="split"
 theme_mode=str(cfg.get_value("prefs","theme_mode","dark"))
 if theme_mode not in ["dark","light","system"]:theme_mode="dark"
 font_mode=str(cfg.get_value("prefs","font_mode","system"))
 if font_mode not in ["system","pixel"]:font_mode="system"
 text_scale=clampf(float(cfg.get_value("prefs","text_scale",1.0)),1.0,2.0)
 var system_reduces:=DisplayServer.accessibility_should_reduce_animation()
 if OS.has_feature("web"):system_reduces=bool(JavaScriptBridge.eval("matchMedia('(prefers-reduced-motion: reduce)').matches"))
 reduced_motion=bool(cfg.get_value("prefs","reduced_motion",system_reduces))
 resolve_theme()

func save_to(cfg: ConfigFile) -> void:
 for key in ["theme_mode","font_mode","text_scale","reduced_motion","touch_layout"]:cfg.set_value("prefs",key,get(key))

func system_is_dark() -> bool:
 if OS.has_feature("web"):return bool(JavaScriptBridge.eval("matchMedia('(prefers-color-scheme: dark)').matches"))
 return DisplayServer.is_dark_mode() if DisplayServer.is_dark_mode_supported() else true

func resolve_theme() -> bool:
 var next: bool=theme_mode=="dark" or (theme_mode=="system" and system_is_dark())
 var changed:=next!=dark
 dark=next;colors=DARK if dark else LIGHT
 return changed

func font_for(pixel_font: Font) -> Font:
 if font_mode=="pixel":body_font=pixel_font;return body_font
 var system:=SystemFont.new()
 system.font_names=PackedStringArray(["system-ui","Segoe UI","Roboto","Helvetica Neue","Arial","sans-serif"])
 system.fallbacks=[ThemeDB.fallback_font]
 body_font=system
 return body_font

func color(key: String) -> Color:return Color(colors[key])
func authored(value: String,role: String="text") -> Color:
 var original:=Color(value)
 if original.a==0:return original
 var key:=value.left(6).to_lower()
 var target: String=role
 if role=="surface":
  if key in ["ad536e","cb7587","91415e"]:target={"ad536e":"primary","cb7587":"primary_hover","91415e":"primary_pressed"}[key]
  elif key in ["c75772","da8d77"]:target="danger" if key=="c75772" else "accent"
  elif key in ["332738","302437"]:target="raised"
  elif key=="4a3546":target="hover"
  elif key=="654455":target="pressed"
  else:target="surface"
 elif role=="border":target="accent" if key in ["ffe3a6","ecc692","f2b1a6"] else "border"
 else:
  if key in ["f8db96","f3c788","f8d9b1","f2d5a6","ffe1b9","ffe0a3"]:target="accent"
  elif key in ["c6a8a5","d4b6b2","a6b8d1","e6c8b0","eed3b4","a8bcd8","8e9fbb"]:target="muted"
  else:target="text"
 var result:=color(target);result.a=original.a
 return result

func style(surface: String,border: String="border",padding: int=12) -> StyleBoxFlat:
 var box:=StyleBoxFlat.new();box.bg_color=color(surface);box.border_color=color(border);box.set_border_width_all(2);box.set_corner_radius_all(0);box.set_content_margin_all(padding);return box

func theme(pixel_font: Font) -> Theme:
 var t:=Theme.new();t.default_font=font_for(pixel_font);t.default_font_size=22
 for widget in ["Label","Button","CheckButton","CheckBox","LineEdit","SpinBox","OptionButton","PopupMenu"]:
  for key in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:t.set_color(key,widget,color("text"))
  t.set_color("font_disabled_color",widget,color("muted"))
 for state in ["normal","hover","pressed","disabled"]:t.set_stylebox(state,"Button",style({"normal":"raised","hover":"hover","pressed":"pressed","disabled":"surface"}[state]))
 var focus:=style("surface","accent");focus.bg_color=Color.TRANSPARENT;focus.set_border_width_all(3);t.set_stylebox("focus","Button",focus)
 t.set_stylebox("panel","PanelContainer",style("surface"))
 for widget in ["VBoxContainer","HBoxContainer"]:t.set_constant("separation",widget,8 if widget=="VBoxContainer" else 12)
 return t

static func safe_layout(raw: Vector2,window: Rect2i,safe: Rect2i) -> Rect2:
 var area:=window.intersection(safe)
 if window.size.x<=0 or window.size.y<=0 or not area.has_area():return Rect2(Vector2.ZERO,raw)
 var unit:=raw/Vector2(window.size)
 return Rect2(Vector2(area.position-window.position)*unit,Vector2(area.size)*unit)

static func native_safe_layout(raw: Vector2) -> Rect2:
 return safe_layout(raw,Rect2i(DisplayServer.window_get_position(),DisplayServer.window_get_size()),DisplayServer.get_display_safe_area())

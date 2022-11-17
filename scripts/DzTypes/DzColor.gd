extends Reference
class_name DzColor


enum DzColorMode {
	ColorModeNone = 0,		# Illegal
	ColorModeWhite = 1,		# White. Valid fields: none
	ColorModeTemp = 2,		# White with color temperature. Valid fields: t
	ColorModeRGB = 3,		# Color. Valid fields: r, g, b.
	ColorModeCustom = 4,	# Custom (color + white). Valid fields: r, g, b, cw, ww, depending on device capabilities
}


var color_mode : int = DzColorMode.ColorModeNone
var temperature : int = 128 # Range:0..255, Color temperature (warm / cold ratio, 0 is coldest, 255 is warmest)
var color : Color = Color.black
var cold_white : int = 127 # Range:0..255, Cold white level
var warm_white : int = 127 # Range:0..255, Warm white level (also used as level for monochrome white)


func _init(var color_info := {}):
	assert(color_info is Dictionary)
	color_mode		= color_info.get("m", color_mode)
	temperature 	= color_info.get("t", temperature)
	color.r8 		= color_info.get("r", color.r8)
	color.g8		= color_info.get("g", color.g8)
	color.b8		= color_info.get("b", color.b8)
	cold_white		= color_info.get("cw", cold_white)
	warm_white		= color_info.get("ww", warm_white)


func to_dictionary():
	var dic = {
		"m" : color_mode,
		"t" : temperature,
		"r" : color.r8,
		"g" : color.g8,
		"b" : color.b8,
		"cw" : cold_white,
		"ww" : warm_white,
	}
	return dic

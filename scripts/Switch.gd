extends Device
class_name Switch


static func get_class_name():
	return "Switch"
func get_class():
	return get_class_name()


var status : String = ""


func _internal_init(device_info, dz_main_node):
	._internal_init(device_info, dz_main_node)
	status = device_info["Status"]


func switch_on():
	status = "Off"
	dzMainNode.request_switchlight(idx, "On")


func switch_off():
	status = "Off"
	dzMainNode.request_switchlight(idx, "Off")


func switch_toggle():
	status = "Off" if status == "On" else "On"
	dzMainNode.request_switchlight(idx, "Toggle")


func _to_string():
	return get_class() + ": " + name + "," + str(idx)

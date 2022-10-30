extends Resource
class_name Device

var name : String = ""
var idx : int = -1


static func get_class_name():
	return "Device"


func get_class():
	return get_class_name()


func _init(var device_info):
	name = device_info["Name"]
	idx = str2var(device_info["idx"])
	pass


func _ready():
	pass


func _to_string():
	return get_class() + ": " + name + "," + str(idx)

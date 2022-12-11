extends Resource
class_name DzServerSettings


# server settings
export var host := ""
export var port := 8080
export var use_ssl := true
export var verify_host := true
export var username_encoded := ""
export var password_encoded := ""

func _set(property, value):
	emit_changed()
	return true

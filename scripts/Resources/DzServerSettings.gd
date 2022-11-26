extends Resource
class_name DzServerSettings


# server settings
var host := ""
var port := 8080
var use_ssl := true
var verify_host := true
var username_encoded := ""
var password_encoded := ""

func _set(property, value):
	emit_changed()
	return true

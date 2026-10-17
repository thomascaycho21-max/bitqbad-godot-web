extends Node
## Router simple.

signal route_changed(name: String)

var container: Control = null
var current: String = ""
var _routes: Dictionary = {}

func register(name: String, builder: Callable) -> void:
    _routes[name] = builder

func go(name: String) -> void:
    if not _routes.has(name):
        push_warning("[Router] Ruta no encontrada: " + name)
        return
    if container == null:
        push_warning("[Router] container no asignado")
        return
    for c in container.get_children():
        c.queue_free()
    current = name
    var view = _routes[name].call()
    if view is Control:
        container.add_child(view)
    route_changed.emit(name)
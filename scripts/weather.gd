class_name Weather
extends Node
## 마을·숲 하늘빛과 비. 장면에 add_child 하면 돼요.
## 하늘빛은 CanvasModulate로 바닥 그림과 캐릭터에만 깔리고(창·글자는 그대로), 비는 화면 위에 내려요.

var tint := CanvasModulate.new()
var rain_layer := CanvasLayer.new()
var drops: Array = []
var rain_node := Node2D.new()


func _ready() -> void:
	tint.color = GameState.sky_color()
	get_parent().add_child.call_deferred(tint)
	if GameState.rain:
		rain_layer.layer = 5
		add_child(rain_layer)
		rain_layer.add_child(rain_node)
		rain_node.draw.connect(_draw_rain)
		for i in 140:
			drops.append(Vector3(randf() * 1408, randf() * 768, randf_range(0.7, 1.3)))


func _process(delta: float) -> void:
	tint.color = tint.color.lerp(GameState.sky_color(), minf(1.0, delta * 2.0))
	if drops.is_empty():
		return
	for i in drops.size():
		var d: Vector3 = drops[i]
		d.y += 620.0 * d.z * delta
		d.x -= 120.0 * d.z * delta
		if d.y > 780:
			d = Vector3(randf() * 1500, -10, d.z)
		drops[i] = d
	rain_node.queue_redraw()


func _draw_rain() -> void:
	for d in drops:
		rain_node.draw_line(Vector2(d.x, d.y), Vector2(d.x + 5 * d.z, d.y - 16 * d.z), Color(0.85, 0.9, 1.0, 0.45), 1.5)

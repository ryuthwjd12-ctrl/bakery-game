extends Node2D
## 걸어 들어오고 나가는 손님. 서 있는 그림을 통통 튀게 움직여요.

var sprite := Sprite2D.new()
var t := 0.0


func setup(animal: String) -> void:
	var tex := Sprites.tex("customers/%s_stand" % animal)
	sprite.texture = tex
	sprite.centered = false
	sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	add_child(sprite)


func _process(delta: float) -> void:
	t += delta
	sprite.position.y = -absf(sin(t * 9.0)) * 6.0


func walk(to: Vector2, speed := 150.0) -> void:
	sprite.flip_h = to.x < position.x
	var tw := create_tween()
	tw.tween_property(self, "position", to, position.distance_to(to) / speed)
	await tw.finished

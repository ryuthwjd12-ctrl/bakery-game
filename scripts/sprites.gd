class_name Sprites
extends RefCounted
## 잘라 둔 그림 줄(SpriteData.STRIPS)을 SpriteFrames로 바꿔 줘요.

const ANIMALS := ["rabbit", "cat", "deer", "chick", "bear", "squirrel"]
## 그림이 없는 동작은 비슷한 동작으로 대신해요.
const FALLBACK := {
	"back": ["front"], "right": ["front"], "wait": ["front"], "eat": ["wait", "front"],
	"happy": ["eat", "wait", "front"], "sad": ["wait", "front"],
}

static var _cache := {}


static func has_strip(key: String) -> bool:
	return SpriteData.STRIPS.has(key) or SpriteDataExtra.STRIPS.has(key)


static func info(key: String) -> Array:
	return SpriteData.STRIPS[key] if SpriteData.STRIPS.has(key) else SpriteDataExtra.STRIPS[key]


static func strip_count(key: String) -> int:
	return info(key)[3] if has_strip(key) else 0


static func _add(sf: SpriteFrames, anim: String, key: String, fps: float) -> void:
	var inf := info(key)
	var tex: Texture2D = load("res://assets/%s.png" % inf[0])
	sf.add_animation(anim)
	sf.set_animation_loop(anim, true)
	sf.set_animation_speed(anim, fps)
	for i in inf[3]:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * inf[1], 0, inf[1], inf[2])
		sf.add_frame(anim, at)


## 주인공, 강아지처럼 동작 이름이 정해진 캐릭터
static func frames_for(prefix: String, anims: Array) -> SpriteFrames:
	if _cache.has(prefix):
		return _cache[prefix]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim in anims:
		var key: String = prefix + "_" + anim
		sf.set_meta(anim, key)
		_add(sf, anim, key, 4.0 + strip_count(key))
	_cache[prefix] = sf
	return sf


## 동물 손님과 주민. 없는 동작은 FALLBACK으로 채워요.
static func animal_frames(kind: String) -> SpriteFrames:
	var ck := "animal_" + kind
	if _cache.has(ck):
		return _cache[ck]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim in ["front", "back", "right", "wait", "eat", "happy", "sad"]:
		var key: String = kind + "_" + anim
		if not has_strip(key):
			for f in FALLBACK.get(anim, []):
				if has_strip(kind + "_" + f):
					key = kind + "_" + f
					break
		var fps := 9.0 if anim in ["front", "back", "right"] else 2.0
		if anim == "eat":
			fps = 3.0
		_add(sf, anim, key, fps)
	_cache[ck] = sf
	return sf


static func frame_height(key: String) -> int:
	return info(key)[2]


static func first_frame(key: String) -> Texture2D:
	var inf := info(key)
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/%s.png" % inf[0])
	at.region = Rect2(0, 0, inf[1], inf[2])
	return at


static func tex(path: String) -> Texture2D:
	return load("res://assets/" + path + ".png")


static func item(id: String) -> Texture2D:
	return load("res://assets/items/" + id + ".png")

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
	return SpriteDataR7.STRIPS.has(key) or SpriteDataR6.STRIPS.has(key) or SpriteDataR5.STRIPS.has(key) or SpriteDataR4.STRIPS.has(key) or SpriteData.STRIPS.has(key) or SpriteDataExtra.STRIPS.has(key)


static func info(key: String) -> Array:
	if SpriteDataR7.STRIPS.has(key):
		return SpriteDataR7.STRIPS[key]
	if SpriteDataR6.STRIPS.has(key):
		return SpriteDataR6.STRIPS[key]
	if SpriteDataR5.STRIPS.has(key):
		return SpriteDataR5.STRIPS[key]
	if SpriteDataR4.STRIPS.has(key):
		return SpriteDataR4.STRIPS[key]
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
		# 다람쥐 주민(sq1~6)은 앉아 있을 때 탁자 쪽을 보는 앉은 옆모습을 써요
		if kind.begins_with("sq") and anim in ["wait", "eat", "happy", "sad"]:
			key = kind + "_sit"
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


## 새 주민 그림(다람쥐 sq, 토끼 rb, 펭귄 pg, 사슴 dr)은 예전 동물보다 크게 그려져 있어서 키를 맞추는 배율
static func size_fix(kind: String) -> float:
	return 121.0 / frame_height(kind + "_front") if kind.left(2) in ["sq", "rb", "pg", "dr", "ct"] else 1.0


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

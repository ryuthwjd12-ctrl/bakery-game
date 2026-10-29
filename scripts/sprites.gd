class_name Sprites
extends RefCounted
## 잘라 둔 걷기 그림(가로 한 줄)을 SpriteFrames로 바꿔 줘요.
## 값: [파일 이름, 한 칸 너비, 높이, 칸 수]

const STRIPS := {
	"female_front": ["female_walk_front", 112, 222, 8],
	"female_back": ["female_walk_back", 102, 222, 8],
	"female_right": ["female_walk_right", 100, 223, 8],
	"male_front": ["male_walk_front", 86, 223, 4],
	"male_back": ["male_walk_back", 80, 222, 6],
	"male_right": ["male_walk_right", 102, 227, 6],
	"puppy_front": ["puppy_front", 88, 122, 4],
	"puppy_back": ["puppy_back", 82, 122, 4],
	"puppy_right": ["puppy_right", 76, 123, 4],
	"puppy_tray": ["puppy_tray", 120, 122, 3],
	"puppy_sweep": ["puppy_sweep", 106, 122, 3],
}

static var _cache := {}


static func frames_for(prefix: String, anims: Array) -> SpriteFrames:
	if _cache.has(prefix):
		return _cache[prefix]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim in anims:
		var info: Array = STRIPS[prefix + "_" + anim]
		var tex: Texture2D = load("res://assets/characters/%s.png" % info[0])
		sf.add_animation(anim)
		sf.set_animation_loop(anim, true)
		# 칸 수가 적은 그림은 천천히 넘겨야 자연스러워요.
		sf.set_animation_speed(anim, 4.0 + info[3])
		for i in info[3]:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * info[1], 0, info[1], info[2])
			sf.add_frame(anim, at)
	_cache[prefix] = sf
	return sf


static func frame_height(prefix: String, anim: String) -> int:
	return STRIPS[prefix + "_" + anim][2]


static func tex(path: String) -> Texture2D:
	return load("res://assets/" + path + ".png")


static func item(id: String) -> Texture2D:
	return load("res://assets/items/" + id + ".png")

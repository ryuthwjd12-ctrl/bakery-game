shader_type canvas_item;
// 손님이 먹는 음식: progress(0~1)만큼 사라져요.
// mode 0 쿠키: 가장자리부터 동그랗게 한 입씩, 1 빵: 위쪽부터 큼직하게 한 입씩, 2 케이크·타르트: 포크로 부채꼴 조각씩
uniform float progress = 0.0;
uniform int mode = 0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 p = UV - vec2(0.5);
	if (mode == 2) {
		float t = (atan(p.y, p.x) + 3.14159) / 6.28318;
		float steps = floor(progress * 5.0) / 5.0;
		if (t < steps) c.a = 0.0;
	} else {
		int n = int(floor(progress * 6.0 + 0.001));
		float start = mode == 0 ? 0.4 : -1.9;
		float spread = mode == 0 ? 1.1 : 0.55;
		for (int i = 0; i < 6; i++) {
			if (i >= n) break;
			float ang = start + float(i) * spread;
			float ring = 0.48 - float(i / 2) * (mode == 0 ? 0.1 : 0.14);
			vec2 cen = vec2(cos(ang), sin(ang)) * ring;
			float r = (mode == 0 ? 0.2 : 0.26) + float(i) * 0.02;
			if (length(p - cen) < r) c.a = 0.0;
		}
	}
	c.a *= 1.0 - smoothstep(0.9, 1.0, progress);
	COLOR = c;
}

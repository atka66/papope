shader_type canvas_item;

void fragment() {
	if (smoothstep(0.5, 0.5, length(SCREEN_UV - vec2(0.5))) != 0.0) {
		COLOR.a = 0.0;
	}
}

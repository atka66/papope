shader_type canvas_item;

uniform sampler2D NOISE_PATTERN;

void fragment() {
	if (smoothstep(0.5, 0.5, length(UV - vec2(0.5))) == 0.0) {
    	COLOR.a = (sin((UV.x + (UV.y / 2.0)) * 3.0 + TIME * 5.0) - 0.5) * 3.0;
	} else {
		COLOR.a = 0.0;
	}
}
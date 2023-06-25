shader_type canvas_item;

uniform float width : hint_range(0.0, 0.5) = 0.46;
uniform vec4 fill_color : source_color = vec4(1.0);
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

vec4 circle(vec2 position) {
	if (smoothstep(0.5, 0.5, length(position - vec2(0.5))) == 0.0) {
		if (smoothstep(width, width, length(position - vec2(0.5))) == 0.0) {
			return fill_color;
		} else {
			return border_color;
		}
	}
	return vec4(0.0);
}

void fragment() {
	COLOR = circle(UV);
}

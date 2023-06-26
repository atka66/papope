shader_type canvas_item;
render_mode unshaded;

uniform float width : hint_range(0.0, 0.5) = 0.48;
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	
	if (smoothstep(0.5, 0.5, length(UV - vec2(0.5))) == 0.0) {
		if (smoothstep(width, width, length(UV - vec2(0.5))) != 0.0) {
			c = border_color;
		}
	} else {
		c = vec4(0.0);
	}
	
	COLOR *= c;
}

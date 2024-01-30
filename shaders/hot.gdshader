shader_type canvas_item;

uniform float val = 1.0;
uniform float speed = 3.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	col.y += sin(TIME * speed) * 0.1 * val;
	COLOR = col;
}
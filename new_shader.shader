shader_type canvas_item;

void fragment() {
	vec2 asd = UV;
	COLOR = texture(TEXTURE, asd);
}
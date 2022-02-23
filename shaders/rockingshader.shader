shader_type canvas_item;

void fragment()
{
	float strength = 0.003;
	float speed = 2.0;
	vec2 coord = SCREEN_UV;
	float offset = sin(TIME * speed) * strength;
	coord.y += offset;
	COLOR = texture(SCREEN_TEXTURE, coord);
}
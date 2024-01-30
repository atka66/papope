shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float strength = 0.0007;
uniform float frequency = 100.0;
uniform float speed = 7.0;

void fragment()
{
	vec2 coord = SCREEN_UV;
	float sineNoise = sin(frequency * coord.y - TIME * speed);
	float offset = sineNoise * strength;
	coord.x += offset;
	COLOR = texture(SCREEN_TEXTURE, coord);
}
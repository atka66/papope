shader_type canvas_item;

uniform sampler2D noise;

void fragment()
{
	/*
	vec2 res = 0.5 / SCREEN_PIXEL_SIZE;
	vec2 uv = round(UV * res) / res;
	*/
	vec2 uv = UV;
	float val = texture(noise, vec2(uv.x + (TIME * -0.0025), uv.y)).r - 0.2;
	
	float color_res = 10.0;
	float r = floor((0.2 * val) * color_res) / color_res;
	float b = floor((0.7 * val) * color_res) / color_res;
	
	COLOR.rgb = vec3(r, 0.0, b);
}
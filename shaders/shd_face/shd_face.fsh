//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float hurtIntensity;
uniform bool trapped;
uniform bool invulnerable;

void main()
{
	vec4 color = texture2D( gm_BaseTexture, v_vTexcoord );
	if (invulnerable) {
		color *= vec4(1.0, 1.0, 0.0, 1.0);
	} else {
		float mul = 1.0 - hurtIntensity;
		color *= vec4(1.0, mul, mul, 1.0);
		
		if (trapped) {
			color *= vec4(0.3, 0.3, 0.3, 1.0);
		}
	}
	
    gl_FragColor = v_vColour * color;
}

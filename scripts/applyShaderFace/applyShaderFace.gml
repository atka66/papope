function applyShaderFace(argument0, argument1, argument2) {
	shader_set(shd_face);
	shader_set_uniform_f(shader_get_uniform(shd_face, "hurtIntensity"), argument0);
	shader_set_uniform_f(shader_get_uniform(shd_face, "trapped"), argument1);
	shader_set_uniform_f(shader_get_uniform(shd_face, "invulnerable"), argument2);


}

applyShader(shd_outline, argument0);
var corners = shader_get_uniform(shd_outline,"corners");
shader_set_uniform_f(corners, argument1);
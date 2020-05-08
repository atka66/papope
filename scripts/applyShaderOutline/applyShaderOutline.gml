shader_set(shd_outline);
shader_set_uniform_f(shader_get_uniform(shd_outline,"pixelW"), texture_get_texel_width(argument0));
shader_set_uniform_f(shader_get_uniform(shd_outline,"pixelH"), texture_get_texel_height(argument0));
shader_set_uniform_f(shader_get_uniform(shd_outline,"corners"), argument1);
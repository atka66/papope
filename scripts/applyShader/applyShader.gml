shader_set(argument0);
var tex_width = texture_get_texel_width(argument1);
var tex_height = texture_get_texel_height(argument1);
var pixelW = shader_get_uniform(argument0,"pixelW");
shader_set_uniform_f(pixelW, tex_width);
var pixelH = shader_get_uniform(argument0,"pixelH");
shader_set_uniform_f(pixelH, tex_height);
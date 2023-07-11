shader_type canvas_item;

void fragment(){
  vec4 maincolor = vec4(0.5, 0.3, 0.1, 1.0);
  vec4 col = texture(TEXTURE, UV);
  COLOR = col.a * maincolor * (1.0 - col.g);
}
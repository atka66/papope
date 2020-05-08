/// @description Insert description here
// You can write your code in this editor
var baseAlpha = draw_get_alpha();
draw_set_alpha(0.5);
draw_rectangle_color(0, 0, room_width, room_height, c_black, c_black, c_black, c_black, false);
draw_set_alpha(baseAlpha);

drawText(room_width / 2, 10, "PAUSED", 3, c_white, 1.0, 1, true);

// pause controls
drawSpriteText(300, 120, "BACK", true, spr_controller_o);
drawSpriteText(300, 140, "RESTART", true, spr_controller_r);
drawSpriteText(300, 160, "QUIT TO LOBBY", true, spr_controller_t);

// in-game controls
drawText(100, 220, "CONTROLS", 2, c_white, 1.0, 0, true);
drawSpriteText(80, 250, "MOVEMENT", true, spr_controller_sl);
drawSpriteText(80, 270, "AIM", true, spr_controller_sr);
drawSpriteText(80, 290, "DASH", true, spr_controller_l1);
drawSpriteText(80, 310, "USE", true, spr_controller_r1);
// objects
drawText((room_width / 2) + 20, 220, "OBJECTS", 2, c_white, 1.0, 0, true);
drawSpriteText(room_width / 2, 250, "REVOLVER", true, spr_pwrup_revolver);
drawText((room_width / 2) + 130, 250, "(6 ROUNDS)", 2, c_white, 1.0, 0, true);
drawSpriteText(room_width / 2, 270, "DYNAMITE", true, spr_pwrup_dynamite);
drawText((room_width / 2) + 130, 270, "(1 STICK)", 2, c_white, 1.0, 0, true);
drawSpriteText(room_width / 2, 290, "WHIP", true, spr_pwrup_whip);
drawText((room_width / 2) + 130, 290, "(5 CRACKS)", 2, c_white, 1.0, 0, true);
drawSpriteText(room_width / 2, 310, "SHIELD", true, spr_pwrup_shield);
drawText((room_width / 2) + 130, 310, "(1 CHARGE)", 2, c_white, 1.0, 0, true);
drawSpriteText(room_width / 2, 330, "TRAP", true, spr_pwrup_trap);
drawText((room_width / 2) + 130, 330, "(1 CHARGE)", 2, c_white, 1.0, 0, true);
/// @description Insert description here
// You can write your code in this editor
var baseAlpha = draw_get_alpha();
draw_set_alpha(0.5);
draw_rectangle_color(0, 0, room_width, room_height, c_black, c_black, c_black, c_black, false);
draw_set_alpha(baseAlpha);

var color = getPlayerColor(pausingPlayerId);
drawText((room_width / 2) - 36, 10, "PAUSED", 2, color, 1.0, 0);

// pause controls
drawSpriteText(300, 120, spr_controller_o, "BACK");
drawSpriteText(300, 140, spr_controller_r, "RESTART");
drawSpriteText(300, 160, spr_controller_t, "QUIT TO LOBBY");

// in-game controls
drawText(100, 220, "CONTROLS", 2, c_white, 1.0, 0);
drawSpriteText(80, 250, spr_controller_sl, "MOVEMENT");
drawSpriteText(80, 270, spr_controller_sr, "AIM");
drawSpriteText(80, 290, spr_controller_l1, "DASH");
drawSpriteText(80, 310, spr_controller_r1, "SHOOT");
// objects
drawText((room_width / 2) + 20, 220, "OBJECTS", 2, c_white, 1.0, 0);
drawSpriteText(room_width / 2, 250, spr_pwrup_revolver, "REVOLVER");
drawText((room_width / 2) + 130, 250, "(6 ROUNDS)", 2, c_white, 1.0, 0);
drawSpriteText(room_width / 2, 270, spr_pwrup_dynamite, "DYNAMITE");
drawText((room_width / 2) + 130, 270, "(1 STICK)", 2, c_white, 1.0, 0);
drawSpriteText(room_width / 2, 290, spr_pwrup_whip, "WHIP");
drawText((room_width / 2) + 130, 290, "(5 CRACKS)", 2, c_white, 1.0, 0);
drawSpriteText(room_width / 2, 310, spr_pwrup_shield, "SHIELD");
drawText((room_width / 2) + 130, 310, "(1 CHARGE)", 2, c_white, 1.0, 0);
drawSpriteText(room_width / 2, 330, spr_pwrup_trap, "TRAP");
drawText((room_width / 2) + 130, 330, "(1 CHARGE)", 2, c_white, 1.0, 0);
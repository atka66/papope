/// @description Insert description here
// You can write your code in this editor
var baseAlpha = draw_get_alpha();
draw_set_alpha(0.5);
draw_rectangle_color(0, 0, room_width, room_height, c_black, c_black, c_black, c_black, false);
draw_set_alpha(baseAlpha);

var color = getPlayerColor(pausingPlayerId);
drawText((room_width / 2) - 36, 10, "PAUSED", 2, color, 1.0);

// pause controls
drawSpriteText(200, 120, spr_controller_o, "BACK");
drawSpriteText(200, 140, spr_controller_r, "RESTART");
drawSpriteText(200, 160, spr_controller_t, "QUIT TO LOBBY");

// in-game controls
drawText(70, 220, "CONTROLS", 2, c_white, 1.0);
drawSpriteText(50, 250, spr_controller_sl, "MOVEMENT");
drawSpriteText(50, 270, spr_controller_sr, "AIM");
drawSpriteText(50, 290, spr_controller_l1, "DASH");
drawSpriteText(50, 310, spr_controller_r1, "SHOOT");
// objects
drawText(240, 220, "OBJECTS", 2, c_white, 1.0);
drawSpriteText(220, 250, spr_pwrup_revolver, "REVOLVER");
drawText(350, 250, "(6 ROUNDS)", 2, c_white, 1.0);
drawSpriteText(220, 270, spr_pwrup_dynamite, "DYNAMITE");
drawText(350, 270, "(1 STICK)", 2, c_white, 1.0);
drawSpriteText(220, 290, spr_pwrup_whip, "WHIP");
drawText(350, 290, "(5 CRACKS)", 2, c_white, 1.0);
drawSpriteText(220, 310, spr_pwrup_shield, "SHIELD");
drawText(350, 310, "(1 CHARGE)", 2, c_white, 1.0);
drawSpriteText(220, 330, spr_pwrup_trap, "TRAP");
drawText(350, 330, "(1 CHARGE)", 2, c_white, 1.0);
/// @description Insert description here
// You can write your code in this editor
var player = getInstanceByPlayerId(obj_player_arena, playerId);
if (player != noone) {
	
	// calculate hud shake
	var shakeOffsetX = 0;
	var shakeOffsetY = 0;
	if (hudShakePwr > 0) {
		shakeOffsetX = irandom_range(-hudShakePwr, hudShakePwr);
		shakeOffsetY = irandom_range(-hudShakePwr, hudShakePwr);
		hudShakePwr--;
		gamepad_set_vibration(playerId, 1.0, 1.0);
	} else {
		gamepad_set_vibration(playerId, 0, 0);
	}
	var shakedX = x + shakeOffsetX;
	var shakedY = y + shakeOffsetY;

	// face sprite
	var playerColor = getPlayerColor(global.player_team[playerId]);
	draw_rectangle_color(shakedX + 16, shakedY, shakedX + 47, shakedY + 31,
		playerColor, playerColor, playerColor, playerColor, false);
		
	applyShaderFace(player.hurtIntensity, player.trapped, player.invulnerable);
	draw_sprite(spr_faces, global.player_skin[playerId], shakedX + 16, shakedY);
	shader_reset();
	
	if (hp < 1) {
		var baseAlpha = draw_get_alpha();
		draw_set_alpha(0.7);
		draw_rectangle_color(shakedX + 16, shakedY, 
		shakedX + 47, shakedY + 31,
		c_black, c_black, c_black, c_black, false);
		draw_set_alpha(baseAlpha);
	}

	// hp bar
	var x1 = 16;
	var y1 = 32;
	var x2 = x1 + 95;
	var y2 = y1 + 7;
	var barColor = player.invulnerable ? c_white : playerColor;
	var currHp = player.hp;
	if (currHp != undefined) {
		hp = currHp;
	}
	var maxHp = global.game_maxHp[global.selectedMaxHpIndex];
	var currX1 = x1;
	var currX2 = x1 + ((hp / maxHp) * 95);
	var currX1Delay = x1;
	var currX2Delay = x1 + ((hpDelay / maxHp) * 95);

	draw_rectangle_color(shakedX + x1, shakedY + y1, shakedX + x2, shakedY + y2,
		c_black, c_black, c_black, c_black, false);
	if (hp > (maxHp / 4) || current_time mod 8 < 4) {
		draw_rectangle_color(shakedX + currX1Delay, shakedY + y1, shakedX + currX2Delay, shakedY + y2,
		c_white, c_white, c_white, c_white, false);
		draw_rectangle_color(shakedX + currX1, shakedY + y1, shakedX + currX2, shakedY + y2,
		barColor, barColor, barColor, barColor, false);
	}

	// hud sprite
	draw_sprite(spr_hud, 0, shakedX, shakedY);

	// points
	drawText(shakedX + 3, shakedY + 27, global.player_points[playerId], 2, c_white, 1.0, 0, false);

	// item
	/// calculate item shake
	var ammoShakeOffsetX = 0;
	var ammoShakeOffsetY = 0;
	if (ammoShakePwr > 0) {
		ammoShakeOffsetX = irandom_range(-ammoShakePwr, ammoShakePwr);
		ammoShakeOffsetY = irandom_range(-ammoShakePwr, ammoShakePwr);
		ammoShakePwr--;
	}
	
	var itemX = shakedX + ammoShakeOffsetX + 66;
	var itemY = shakedY + ammoShakeOffsetY + 14;
	var ammo = player.ammo;
	switch (player.item) {
		case obj_pwrup_revolver: 
			draw_sprite(spr_hud_revolver_drum, 0, itemX, itemY);
			for (var i = 0; i < ammo; i++) {
				switch (i) {
					case 0: draw_sprite(spr_hud_revolver_ammo, 0, itemX, itemY - 10); break;
					case 1: draw_sprite(spr_hud_revolver_ammo, 0, itemX + 8, itemY - 5); break;
					case 2: draw_sprite(spr_hud_revolver_ammo, 0, itemX + 8, itemY + 5); break;
					case 3: draw_sprite(spr_hud_revolver_ammo, 0, itemX, itemY + 10); break;
					case 4: draw_sprite(spr_hud_revolver_ammo, 0, itemX - 8, itemY + 5); break;
					case 5: draw_sprite(spr_hud_revolver_ammo, 0, itemX - 8, itemY - 5); break;
				}
			}
			break;
		case obj_pwrup_dynamite:
			draw_sprite(spr_hud_dynamite_ammo, 0, itemX, itemY);
			break;
		case obj_pwrup_shield:
			draw_sprite_ext(spr_pwrup_shield, 0, itemX, itemY, 2.0, 2.0, 0, c_white, 1.0);
			break;
		case obj_pwrup_whip:
			for (var i = 0; i < ammo; i++) {
				draw_sprite(spr_hud_whip_ammo, 0, itemX + (i * 5), itemY);
			}
			break;
		case obj_pwrup_trap:
			draw_sprite_ext(spr_pwrup_trap, 0, itemX, itemY, 2.0, 2.0, 0, c_white, 1.0);
			break;
	}
	
	// disconnect
	if (!global.player_connected[playerId]) {
		drawText(shakedX + 56, shakedY + 20, "DISCONNECTED", 2, current_time mod 8 < 4 ? c_white : c_red, 1.0, 1, false);
	}
}
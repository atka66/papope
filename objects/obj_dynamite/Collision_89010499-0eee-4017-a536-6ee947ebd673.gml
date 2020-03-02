/// @description Insert description here
// You can write your code in this editor
if (other != getInstanceByPlayerId(obj_player_arena, originPlayer)) {
	instance_destroy(self)
	audio_play_sound(snd_player_hurt_dynamite, 10, false)
}
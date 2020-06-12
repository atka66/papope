/// @description reappear with different background
// You can write your code in this editor
dim = 1;
appearing = true;

lobbyBg = (lobbyBg + irandom(sprite_get_number(bg_lobby) - 2) + 1) mod sprite_get_number(bg_lobby);

layer_background_index(layer_background_get_id("Background"), lobbyBg);
layer_x(layer_get_id("Background"), 0);
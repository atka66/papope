// argument0 - xpos
// argument1 - ypos
// argument2 - text
// argument3 - scale
// argument4 - color
// argument5 - alpha
// argument6 - alignment
var strlen = string_length(argument2);

var letterImg = array_create(strlen);
var letterWidth = array_create(strlen);

var fullWidth = 0;
for (var i = 0; i < strlen; i++) {
	var subimg = 0;
	var spriteWidth = 5;
	switch (string_char_at(argument2, i + 1)) {
            case "A": subimg = 0; break;   case "B": subimg = 1; break;   case "C": subimg = 2; break;
            case "D": subimg = 3; break;   case "E": subimg = 4; break;   case "F": subimg = 5; break;
            case "G": subimg = 6; break;   case "H": subimg = 7; break;   case "I": subimg = 8; spriteWidth = 1; break;
            case "J": subimg = 9; break;   case "K": subimg = 10; break;  case "L": subimg = 11; break;
            case "M": subimg = 12; break;  case "N": subimg = 13; break;  case "O": subimg = 14; break;
            case "P": subimg = 15; break;  case "Q": subimg = 16; break;  case "R": subimg = 17; break;
            case "S": subimg = 18; break;  case "T": subimg = 19; break;  case "U": subimg = 20; break;
            case "V": subimg = 21; break;  case "W": subimg = 22; break;  case "X": subimg = 23; break;
            case "Y": subimg = 24; break;  case "Z": subimg = 25; break;  case "0": subimg = 26; break;
            case "1": subimg = 27; break;  case "2": subimg = 28; break;  case "3": subimg = 29; break;
            case "4": subimg = 30; break;  case "5": subimg = 31; break;  case "6": subimg = 32; break;
            case "7": subimg = 33; break;  case "8": subimg = 34; break;  case "9": subimg = 35; break;
            case ".": subimg = 36; spriteWidth = 1; break;  case ":": subimg = 37; spriteWidth = 1; break;
            case "-": subimg = 38; break;  case "!": subimg = 39; spriteWidth = 1; break;
            case "?": subimg = 40; break;  case "(": subimg = 41; spriteWidth = 2; break;
            case ")": subimg = 42; spriteWidth = 2; break;  case "/": subimg = 43; break;
            default : subimg = -1; break;
    }
	letterImg[i] = subimg;
	letterWidth[i] = spriteWidth;
	fullWidth += (spriteWidth + 1) * argument3;
}
fullWidth--;

var xx = 0;
switch (argument6) {
	case 0: xx = fullWidth; break; // left aligned
	case 1: xx = (fullWidth / 2); break; // centered
	case 2: xx = 0; break; // right aligned
}
for (var i = 0; i < strlen; i++) {
	if (letterImg[i] > -1) {
		draw_sprite_ext(spr_font, letterImg[i], argument0 - (fullWidth - xx), argument1, argument3, argument3, 0, argument4, argument5);
	}
	xx += (letterWidth[i] + 1) * argument3;
}
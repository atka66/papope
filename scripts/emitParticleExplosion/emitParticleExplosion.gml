function emitParticleExplosion(argument0, argument1) {
	for (var i = 0; i < 100; i++) {
		var s = random_range(0, 8);
		emitParticle(argument0, argument1, c_gray, irandom(360), s, 3 * s, 3);
	}


}

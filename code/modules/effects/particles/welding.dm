/particles/welding_sparks
	width = 124
	height = 124
	count = 1600
	spawning = 4
	lifespan = 1.5 SECONDS
	fade = 0.95 SECONDS
	position = generator("circle", -3, 3, NORMAL_RAND)
	gravity = list(0, -1)
	velocity = generator("box", list(-3, 2, 0), list(3, 12, 5), NORMAL_RAND)
	friction = 0.15
	gradient = list(0, "#e5e5e5", 1, "#ffa500")
	color = 0
	color_change = 0.05
//	transform = list(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)

/particles/welding_smoke
	width = 32
	height = 32
	count = 2000
	spawning = 20
	lifespan = 2 SECONDS
	fade = 1 SECONDS
	position = generator("circle", -5, 5, NORMAL_RAND)
	velocity = generator("box", list(-1, 2), list(1, 2), NORMAL_RAND)
	drift = generator("vector", list(-0.2, -0.3), list(0.2, 0.3))
	gravity = list(0.05, 0.1)
	color_change = 0.1
	friction = 0.01
	gradient = list(0, "#64788C", 1, "#2c3e50")
	color = 0

/particles/welding_flash
	width = 32
	height = 32
	count = 1
	spawning = 1
	lifespan = 0.2 SECONDS
	fade = 0.1 SECONDS

/obj/particle_emitter/welding_sparks
	particles = new/particles/welding_sparks
	layer = EFFECTS_ABOVE_LIGHTING_LAYER

	filters = list(type="bloom", threshold="#CCCCCC", offset=0.5, size=1, alpha=204)

/obj/particle_emitter/welding_sparks/set_dir(dir)
	..()
	var/list/min
	var/list/max
	if(dir == NORTH)
		min = list(-3, -1, 0)
		max = list(3, 11, 0)
	else if(dir == SOUTH)
		min = list(-3, -11, 0)
		max = list(3, 1, 1)
	else if(dir == EAST)
		min = list(-1, -3, 0)
		max = list(11, 3, 0)
	else
		min = list(-11, -3, 0)
		max = list(1, 3, 0)

	particles.velocity = generator("box", min, max, NORMAL_RAND)

/obj/particle_emitter/welding_smoke
	particles = new/particles/welding_smoke
	layer = ABOVE_MOB_LAYER
	filters = list(type="blur", size=1.5)

/obj/particle_emitter/welding_flash
	particles = new/particles/welding_flash
	layer = EFFECTS_ABOVE_LIGHTING_LAYER
	filters = list(type="bloom", size=generator("num", 1, 5, NORMAL_RAND), offset=generator("num", 0, 3, LINEAR_RAND), threshold="#000000")


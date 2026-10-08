// Solar System
//
// Shows the positions of the planets (plus Ceres and Pluto)
// for any year from 2000 to 2800, seen at an angle so that
// the orbits appear as ellipses.  Click or drag on the slider
// at the bottom of the screen to change the date, or click the
// Play button to advance the date automatically.
//
// Positions are computed from Keplerian orbital elements
// (JPL's "Approximate Positions of the Planets"), solving
// Kepler's equation for each body.  Reference:
// https://ssd.jpl.nasa.gov/planets/approx_pos.html
// Note: distances from the Sun are compressed so the inner 
// and outer planets both fit on screen; directions are accurate.

clear
spriteDisp = display(4)
display(7).mode = displayMode.pixel
bg = display(7)
display(6).mode = displayMode.pixel
orbitGfx = display(6)

// layout constants
cx = 465; cy = 375           // screen position of the Sun
rOffset = 26                 // screen radius of distance 0
rScale = 96                  // screen pixels per (AU ^ rPower)
rPower = 0.4                 // distance compression exponent
tilt = 30 * pi/180           // viewing angle above the ecliptic
sinT = sin(tilt); cosT = cos(tilt)
sliderLeft = 80; sliderRight = 880; sliderY = 40
playX = 920                  // center of the Play button
minYear = 2000; maxYear = 2800

// colors
orbitColor = "#4466AA88"
sliderColor = "#8888AA"
knobColor = "#FFCC44"

// Orbital elements at J2000 and their rates of change per century:
//   a (AU), e, I (deg), L (deg), long. perihelion (deg), long. asc. node (deg)
bodies = []
addBody = function(name, scale, elements, rates)
	b = new Sprite
	b.name = name
	b.el = elements
	b.rate = rates
	b.image = file.loadImage("/sys/pics/planets/" + name + ".png")
	b.scale = scale
	bodies.push b
	spriteDisp.sprites.push b
end function

addBody "Mercury", 0.5,
  [0.38709927, 0.20563593, 7.00497902, 252.25032350, 77.45779628, 48.33076593],
  [0.00000037, 0.00001906, -0.00594749, 149472.67411175, 0.16047689, -0.12534081]
addBody "Venus", 0.4,
  [0.72333566, 0.00677672, 3.39467605, 181.97909950, 131.60246718, 76.67984255],
  [0.00000390, -0.00004107, -0.00078890, 58517.81538729, 0.00268329, -0.27769418]
addBody "Earth", 0.4,
  [1.00000261, 0.01671123, -0.00001531, 100.46457166, 102.93768193, 0],
  [0.00000562, -0.00004392, -0.01294668, 35999.37244981, 0.32327364, 0]
addBody "Mars", 0.4,
  [1.52371034, 0.09339410, 1.84969142, -4.55343205, -23.94362959, 49.55953891],
  [0.00001847, 0.00007882, -0.00813131, 19140.30268499, 0.44441088, -0.29257343]
addBody "Ceres", 0.5,
  [2.7675, 0.0758, 10.59, 159.9, 153.84, 80.33],
  [0, 0, 0, 7826.2, 0, 0]
addBody "Jupiter", 0.6,
  [5.20288700, 0.04838624, 1.30439695, 34.39644051, 14.72847983, 100.47390909],
  [-0.00011607, -0.00013253, -0.00183714, 3034.74612775, 0.21252668, 0.20469106]
addBody "Saturn", 0.5,
  [9.53667594, 0.05386179, 2.48599187, 49.95424423, 92.59887831, 113.66242448],
  [-0.00125060, -0.00050991, 0.00193609, 1222.49362201, -0.41897216, -0.28867794]
addBody "Uranus", 0.5,
  [19.18916464, 0.04725744, 0.77263783, 313.23810451, 170.95427630, 74.01692503],
  [-0.00196176, -0.00004397, -0.00242939, 428.48202785, 0.40805281, 0.04240589]
addBody "Neptune", 0.5,
  [30.06992276, 0.00859048, 1.77004347, -55.12002969, 44.96476227, 131.78422574],
  [0.00026291, 0.00005105, 0.00035372, 218.45945325, -0.32241464, -0.00508664]
addBody "Pluto", 0.5,
  [39.48211675, 0.24882730, 17.14001206, 238.92903833, 224.06891629, 110.30393684],
  [-0.00031596, 0.00005170, 0.00004818, 145.20780515, -0.04062942, -0.01183482]

sun = new Sprite
sun.image = file.loadImage("/sys/pics/planets/Sun.png")
sun.scale = 0.5
sun.x = cx; sun.y = cy
sun.depth = 0
spriteDisp.sprites.push sun

// Compute the orbital elements of body b at time T (centuries since
// J2000), and store the values needed to find points on its orbit.
updateElements = function(b, T)
	el = []
	for i in b.el.indexes
		el.push b.el[i] + b.rate[i] * T
	end for
	b.a = el[0]
	b.e = el[1]
	incl = el[2] * pi/180
	peri = el[4]
	node = el[5] * pi/180
	w = peri * pi/180 - node   // argument of perihelion
	M = ((el[3] - peri) % 360 + 540) % 360 - 180
	b.M = M * pi/180
	// rotation from orbital plane to ecliptic coordinates
	cw = cos(w); sw = sin(w); cn = cos(node); sn = sin(node)
	ci = cos(incl); si = sin(incl)
	b.xx = cw*cn - sw*sn*ci; b.xy = -sw*cn - cw*sn*ci
	b.yx = cw*sn + sw*cn*ci; b.yy = -sw*sn + cw*cn*ci
	b.zx = sw*si;            b.zy = cw*si
end function

// Solve Kepler's equation (M = E - e sin E) for eccentric anomaly E.
solveKepler = function(M, e)
	E = M + e * sin(M)
	for i in range(1, 5)
		E -= (E - e * sin(E) - M) / (1 - e * cos(E))
	end for
	return E
end function

// Get the heliocentric ecliptic position [x,y,z] (in AU) of body b
// at eccentric anomaly E.
orbitPoint = function(b, E)
	px = b.a * (cos(E) - b.e)
	py = b.a * sqrt(1 - b.e^2) * sin(E)
	return [b.xx*px + b.xy*py, b.yx*px + b.yy*py, b.zx*px + b.zy*py]
end function

// Project a heliocentric position onto the screen.  Returns
// [screenX, screenY, depth], where greater depth is farther away.
project = function(p)
	r = sqrt(p[0]^2 + p[1]^2 + p[2]^2)
	if r == 0 then return [cx, cy, 0]
	f = (rOffset + rScale * r^rPower) / r
	x = p[0] * f; y = p[1] * f; z = p[2] * f
	return [cx + x, cy + y*sinT + z*cosT, y*cosT - z*sinT]
end function

drawOrbits = function
	orbitGfx.clear color.clear
	steps = 120
	for b in bodies
		pts = []
		for i in range(0, steps-1)
			pts.push project(orbitPoint(b, 2*pi * i/steps))[:2]
		end for
		orbitGfx.drawPoly pts, orbitColor
	end for
end function

positionBodies = function
	for b in bodies
		pos = project(orbitPoint(b, solveKepler(b.M, b.e)))
		b.x = pos[0]
		b.y = pos[1]
		b.depth = pos[2]
	end for
	// draw farther bodies first, so nearer ones appear in front
	spriteDisp.sprites.sort "depth", false
end function

monthNames = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split

xForYear = function(year)
	return sliderLeft + (year - minYear) / (maxYear - minYear) * (sliderRight - sliderLeft)
end function

yearForX = function(x)
	year = minYear + (x - sliderLeft) / (sliderRight - sliderLeft) * (maxYear - minYear)
	if year < minYear then year = minYear
	if year > maxYear then year = maxYear
	return year
end function

drawSlider = function(year)
	gfx.clear color.clear
	gfx.line sliderLeft, sliderY, sliderRight, sliderY, sliderColor, 3
	for y in range(minYear, maxYear, 100)
		x = xForYear(y)
		gfx.line x, sliderY-6, x, sliderY+6, sliderColor, 2
		gfx.print str(y), x - 18, sliderY - 30, sliderColor, "small"
	end for
	x = xForYear(year)
	gfx.fillEllipse x-10, sliderY-10, 20, 20, knobColor
	s = monthNames[floor((year % 1) * 12)] + " " + floor(year)
	gfx.print s, x - s.len * 7, sliderY + 14, knobColor
	if playing then
		// pause symbol (two bars)
		gfx.fillRect playX-9, sliderY-10, 6, 20, knobColor
		gfx.fillRect playX+3, sliderY-10, 6, 20, knobColor
	else
		// play symbol (triangle)
		gfx.fillPoly [[playX-8, sliderY-11], [playX-8, sliderY+11], [playX+11, sliderY]], sliderColor
	end if
end function

// Draw a static star field in the background.
bg.clear color.black
for i in range(300)
	c = color.lerp(color.black, ["#FFFFFF", "#AAAAFF", "#FFFFAA"][rnd*3], rnd)
	bg.setPixel rnd*960, rnd*640, c
end for

curYear = null
playing = false
orbitYear = null
showYear = function(year, forceOrbits=false)
	if year == curYear and not forceOrbits then return
	globals.curYear = year
	T = (year - 2000) / 100
	for b in bodies
		updateElements b, T
	end for
	// orbits change only very slowly, so redraw them only occasionally
	if forceOrbits or orbitYear == null or abs(year - orbitYear) > 25 then
		drawOrbits
		globals.orbitYear = year
	end if
	positionBodies
	drawSlider year
end function

nearSlider = function
	return abs(mouse.y - sliderY) < 30 and
	  mouse.x > sliderLeft - 30 and mouse.x < sliderRight + 20
end function

nearPlayButton = function
	return abs(mouse.y - sliderY) < 20 and abs(mouse.x - playX) < 20
end function

setPlaying = function(play)
	globals.playing = play
	globals.lastTime = time
	if play and curYear >= maxYear then showYear minYear
	showYear curYear, not play  // also redraws the button
end function

// Main loop
showYear 2026
wasDown = false
dragging = false
while true
	if key.available then
		k = key.get
		if k == char(27) or k == "q" then break
	end if
	if playing then
		// advance one year per second of real time
		now = time
		year = curYear + (now - lastTime)
		lastTime = now
		if year >= maxYear then
			showYear maxYear
			setPlaying false
		else
			showYear year
		end if
	end if
	if mouse.button then
		if not wasDown then
			if playing then
				setPlaying false	// any click stops playback
			else if nearPlayButton then
				setPlaying true
			else
				dragging = nearSlider
			end if
		end if
		if dragging then showYear yearForX(mouse.x)
		wasDown = true
	else
		if dragging then showYear curYear, true
		wasDown = false
		dragging = false
	end if
	yield
end while
key.clear

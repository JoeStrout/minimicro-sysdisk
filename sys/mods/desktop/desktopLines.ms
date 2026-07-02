// This Desktop mod draws animated lines that bounce around the desktop, 
// behind all windows.

// Convenience function to return an integer in [-n, n]
rand = function(n)
	return floor(rnd * (n*2+1) - n)
end function

// Our lines are represented by four parallel lists:
x0 = [0]
y0 = [0]
x1 = [400]
y1 = [0]
// ...and our state also includes the velocity of each endpoint:
vx0 = rand(6)
vy0 = rand(6)
vx1 = rand(6)
vy1 = rand(6)
// and hue
lineHue = 200

setup = function
	// Change the background display from solid color to Pixel
	// (but note the color).
	idx = gui.backgroundDisp.index
	outer.bgColor = gui.backgroundDisp.color
	display(idx).mode = displayMode.pixel
	gui.backgroundDisp = display(idx)
	gui.backgroundDisp.clear bgColor, 960+20, 640+20
	gui.backgroundDisp.scrollX = 10
	gui.backgroundDisp.scrollY = 10
end function

setup

update = function
	// Update line hue
	outer.lineHue = (lineHue + 1) % 255
	
	// Push coordinates for the next line.
	x0.push x0[-1] + vx0
	y0.push y0[-1] + vy0
	x1.push x1[-1] + vx1
	y1.push y1[-1] + vy1
	gui.backgroundDisp.line x0[-1], y0[-1], x1[-1], y1[-1], 
	  color.hsv(lineHue, 255, 255)

	// Then, if we've hit the edge at any point, update velocity
	if (x0[-1] < 10 and vx0 < 0) or (x0[-1] > 970 and vx0 > 0) then
		outer.vx0 = -vx0 + rand(2)
		outer.vy0 += rand(2)
	else if (x1[-1] < 10 and vx1 < 0) or (x1[-1] > 970 and vx1 > 0) then
		outer.vx1 = -vx1 + rand(2)
		outer.vy1 += rand(2)
	end if
	if (y0[-1] < 10 and vy0 < 0) or (y0[-1] > 650 and vy0 > 0) then
		outer.vy0 = -vy0 + rand(2)
		outer.vx0 += rand(2)
	else if (y1[-1] < 10 and vy1 < 0) or (y1[-1] > 650 and vy1 > 0) then
		outer.vy1 = -vy1 + rand(2)
		outer.vx1 += rand(2)
	end if
	
	// Finally, erase the last line if we've got too many
	if x0.len > 100 then
		gui.backgroundDisp.line x0.pull, y0.pull, x1.pull, y1.pull, bgColor		
	end if
end function

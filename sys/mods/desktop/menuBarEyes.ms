// This Desktop mod adds a pair of eyes in the menu bar which track the mouse.

update = function
	g = gui.menuDisp
	x = 608 + g.scrollX
	y = 630 + g.scrollY
	r = 8  // radius
	for i in [0,1]
		g.fillEllipse x-r, y-r, r*2, r*2, color.white
		g.drawEllipse x-r, y-r, r*2, r*2, color.black
		ang = atan(mouse.y - y, mouse.x - x)
		px = x + (r-3) * cos(ang)
		py = y + (r-3) * sin(ang)
		g.fillEllipse px-2, py-2, 5, 5, color.black
		x += r*2 + 8
	end for
end function


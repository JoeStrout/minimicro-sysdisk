// This Desktop mod adds a pair of eyes in the menu bar which track the mouse.

// Required stuff for all mods: menuItemText, enable, disable, update.
menuItemText = "Menubar Eyes"

kLeft = 608
kMidY = 630

enable = null

disable = function
	g = gui.topDrawing
	g.fillRect kLeft + g.scrollX-2, gui.kMenuBarBottom, 54, 32, color.clear
end function

update = function
	r = 8  // radius
	g = gui.topDrawing
	x = kLeft + r + g.scrollX
	y = kMidY + g.scrollY
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


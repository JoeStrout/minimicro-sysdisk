while true
	yield
	gfx.clear
	gfx.fillEllipse mouse.x-150, mouse.y-150, 200, 300, color.blue
	gfx.drawEllipse mouse.x-150, mouse.y-150, 200, 300, color.yellow, 5
end while
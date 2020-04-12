// Fun little graphical demo.

screen = {"width":960, "height":640}
gfx.clear

// Draw the sky, in blocks that get darker/redder with each step.
horizon = screen.height * 0.4
y = horizon
h = 3
step = 0
while y < screen.height
	c = rgb(180 - step*5, 5 + step*5, 10 + step*20)
	gfx.fillRect 0, y, screen.width, h, c
	y = y + h
	h = h * 1.5
	step = step + 1
end while

// Draw the sun.
midx = screen.width/2
c = rgb(240,200,100)
gfx.fillEllipse midx-100, horizon-80, 200, 160, c

// Draw the water (just a solid dark blue)
gfx.fillRect 0, 0, screen.width, horizon, rgb(0,0,50)

// Draw the reflection lines.
y = horizon
h = 3
w = 100
c = rgb(120,100,75)
while y > 0
	dx = (rnd-0.5) * w/10 + (rnd-0.5) * w/10
	gfx.fillRect midx-w+dx, y-h, w*2, 1, c
	h = h * 1.1
	w = w * 1.02
	y = y - h
end while

// Remember, to clear the screen, just do: gfx.clear

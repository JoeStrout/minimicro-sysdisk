// Scribble
// A simple demonstration of mouse input & Graphics drawing.
// Press Escape or Control-C to exit.

colors = ["red","green","blue","yellow","purple","aqua"]
clear
gfx.clear
textColor = text.color

setColor = function(n)
	globals.colorNum = n
	gfx.color = color[colors[n]]
	text.row = 25
	text.column = 0
	text.color = gfx.color
	text.print colors[n] + " "*20
	text.color = textColor
end function
setColor 0

text.delimiter = ""
text.row = 0
print "Left mouse button: sketch      Right mouse button: change color"
text.delimiter = char(13)

// Main loop:

prev = {}
lastRMB = false  // (RMB = Right Mouse Button)
while not key.pressed("escape")
	// The mouse might move within this loop, so let's grab a copy
	// of it right away as "m", and use only that.
	m = {"x": mouse.x, "y": mouse.y}
	
	// If the button is down, draw a line from our previous mouse position.
	if mouse.button then gfx.line prev.x, prev.y, m.x, m.y
	// ...and then remember that as the previous position next time.
	prev = m
	
	// If the right mouse button is clicked, change the color.
	rmb = mouse.button(1)
	if rmb and not lastRMB then	setColor (colorNum + 1) % colors.len
	lastRMB = rmb
	
	yield
end while

key.clear

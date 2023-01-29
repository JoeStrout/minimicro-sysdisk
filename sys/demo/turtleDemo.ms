// Simple demonstration of "turtle graphics"
// (using the turtle module in /sys/lib/turtle)

import "turtle"
clear

// Clear the display the turtle is using.
// (You could assign a different display if you like.)
display(Turtle.displayNum).clear

// Create and show the turtle
t = new Turtle
t.show  // omit this, or call t.hide, for an invisible turtle

// Define the colors we want to use
colors = [color.red, color.purple, color.blue,
   color.green, color.yellow, color.orange]

// Loop and draw
for x in range(0,300)
	// set turtle ink color
	t.color = colors[x % 6]
	
	// set the pen size
	t.penSize = round(1 + x/100)
	
	// turn left 59°, then move forward some amount
	t.left 59
	t.forward x
	
	// wait (optional; makes it slow enough to see!)
	wait 0.01
end for

text.row = 0

// If we are returning to the shell, wait for a keypress
if env.hasIndex("shell") and env.shell then key.get

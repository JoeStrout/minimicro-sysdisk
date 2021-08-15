// Sprite Demo
// 
// This is a simple demo in which you move the Wumpus
// around the screen to catch the heart.
// Press Escape or Control-C to exit.

// Prepare the displays
text.clear
gfx.clear
c = text.color
text.color = color.gray
text.row = 25
print "(Use arrows or joystick to move; Esc to exit.)"
text.color = c

display(4).mode = displayMode.sprite
disp = display(4)
disp.clear

// Prepare the "target" (heart) sprite
target = new Sprite
target.image = file.loadImage("/sys/pics/Heart.png")
disp.sprites.push target

// Prepare the player (wumpus) sprite
wumpus = new Sprite
wumpus.image = file.loadImage("/sys/pics/Wumpus.png")
disp.sprites.push wumpus
wumpus.x = 100
wumpus.y = 100

// Move the target to a new random position
moveTarget = function()
	target.x = 100 + 760*rnd
	target.y = 100 + 440*rnd
end function
moveTarget

// Handle catching the target
catchTarget = function()
	// move the target to a new position
	moveTarget
	// draw a star in the background (because why not?)
	c = color.rgb(100+155*rnd, 100+155*rnd, 100+155*rnd)
	gfx.setPixel 960*rnd, 640*rnd, c
end function	

// Main loop
while not key.pressed("escape")
	// move/rotate the wumpus using arrow keys, WASD, or a gamepad
	inputH = key.axis("Horizontal")
	wumpus.x = wumpus.x + 10 * inputH
	if inputH < -0.5 then
		if wumpus.rotation < 10 then wumpus.rotation = wumpus.rotation + 2
	else if inputH > 0.5 then
		if wumpus.rotation > -10 then wumpus.rotation = wumpus.rotation - 2
	else if wumpus.rotation != 0 then
		wumpus.rotation = wumpus.rotation - sign(wumpus.rotation)
	end if
	inputV = key.axis("Vertical")
	wumpus.y = wumpus.y + inputV * 10
	if key.pressed("escape") then exit
	
	// animate the target, and check for collision
	target.scale = 1 + abs(sin(time*3) * 0.2)
	dist = sqrt((wumpus.x-target.x)^2 + (wumpus.y-target.y)^2)
	if dist < 64 then catchTarget
	
	// wait for next frame
	yield
end while
key.clear

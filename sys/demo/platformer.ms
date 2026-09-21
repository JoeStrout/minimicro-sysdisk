// Platformer demo
//
// This program creates a simple platformer game, with
// a character that can run, jump, and climb ladders.

// Import helper libraries (from /sys/lib)
import "spriteControllers"
import "tileUtil"
import "sounds"

// Since we'll be using spriteControllers.newAnimation
// a lot, let's copy it into a global variable
newAnimation = @spriteControllers.newAnimation

// Set up the displays
clear
display(4).mode = displayMode.sprite
disp = display(4)
disp.clear
disp.scrollX = 0
disp.scrollY = 0

display(5).mode = displayMode.tile
tiles = display(5)
tiles.clear
tileUtil.loadFromFile "/sys/data/platformDemoMap.txt", tiles
tiles.scrollX = 0
tiles.scrollY = 0
grid = tileUtil.sizeToXY(tiles.cellSize)

// Define special tile types
ladders = [49, 63, 64, 65, 66]
passableGround = [null, 48, 49, 62]  // things you can fall through
solid = [0, 1, 2, 4, 12, 13, 15, 16, 28, 40, 52]

// Create the player character (kip), derived from
// the spriteControllers.Platformer class (which 
// handles most of the messy details for us)
kip = new spriteControllers.Platformer
disp.sprites.push kip
kip.x = 480
kip.y = 320
kip.idleAnim = newAnimation(file.loadImage("/sys/pics/KP/KP-stand.png"))
kip.runAnim = newAnimation([
   file.loadImage("/sys/pics/KP/KP-run1.png"),
   file.loadImage("/sys/pics/KP/KP-run2.png")], 10)
kip.jumpUpAnim = newAnimation(file.loadImage("/sys/pics/KP/KP-jump.png"))
kip.fallDownAnim = kip.jumpUpAnim
kip.climbAnim = newAnimation([
   file.loadImage("/sys/pics/KP/KP-climb1.png"),
   file.loadImage("/sys/pics/KP/KP-climb2.png")], 10)
kip.curAnim = kip.runAnim

// determine whether kip has solid ground below him
kip.groundBelow = function(x,y)
	col = floor(x / grid.x)
	row = floor(y / grid.y) - 1
	while true
		if row < 0 then return 0
		tile = tiles.cell(col, row)
		if passableGround.indexOf(tile) == null then return (row+1) * grid.y
		row = row - 1
	end while
end function

// determine whether kip is standing in front of a ladder
kip.canClimb = function(dir)
	col = floor(self.x / grid.x)
	row = floor((self.y - self.footOffset * (1 - 0.1*dir)) / grid.y)
	if ladders.indexOf(tiles.cell(col, row)) == null then return false
	// since we can climb, we probably are about to do so...
	// so let's center ourselves horizontally on the ladder
	self.x = (col + 0.5) * grid.x
	return true
end function

// adjust kip's X position to avoid penetrating walls or stage bounds
kip.checkLeftRight = function
	if self.x < 20 then
		self.x = 20
		return
	end if
	if self.vy > 0 then return
	y = self.y
	row = floor(y / grid.y)
	
	col = floor((self.x + 20) / grid.x)
	tile = tiles.cell(col, row)
	if solid.indexOf(tile) != null then
		// not passable to the right; shift left
		self.x = col * grid.x - 20
		if self.vx > 0 then self.vx = 0
		return
	end if		
	col = floor((self.x - 20) / grid.x)
	tile = tiles.cell(col, row)
	if solid.indexOf(tile) != null then
		// not passable to the left; shift right
		self.x = (col+1) * grid.x + 20
		if self.vx < 0 then self.vx = 0
		return
	end if		
end function

// make sure we're not hitting our head, and if we are, move down
kip.checkAbove = function
	if self.vy <= 0 then return
	col = floor(self.x / grid.x)
	row = floor((self.y + 20) / grid.y)
	tile = tiles.cell(col, row)
	if solid.indexOf(tile) != null then
		// not passable above; shift down
		sounds.land.play
		self.y = row * grid.y - 20
		self.vy = 0
		return
	end if
end function
	
// code run (automatically by spriteControllers.Platformer)
// when our hero enters a new state; we use this to play
// appropriate sounds when we jump or land.
kip.enterState = function(newState)
	if newState == self.state then return
	if newState == spriteControllers.JUMPING then
		sounds.bounce.play
	else if (self.state == spriteControllers.JUMPING or
	self.state == spriteControllers.FALLING) and 
	newState != spriteControllers.FALLING then
		sounds.land.play
	end if
	// We have overridden the standard `enterState` behavior...
	// but that super class enterState does some important stuff,
	// so we need to call it now:
	super.enterState newState
end function

kip.updateState = function(dt)
	super.updateState dt
	self.checkAbove
	self.checkLeftRight
end function

// Define the area of the screen which we keep Kip in
// by scrolling
SCROLLBOX_LEFT = gfx.width * 0.25
SCROLLBOX_RIGHT = gfx.width * 0.75
SCROLLBOX_BOTTOM = gfx.height * 0.25
SCROLLBOX_TOP = gfx.height * 0.75

// Update the "camera" by scrolling the displays
updateCamera = function
	// scroll horizontally to keep Kip in the scroll box
	kx = kip.x - tiles.scrollX
	off = SCROLLBOX_LEFT - kx
	if off > 0 then
		tiles.scrollX = tiles.scrollX - off
		if tiles.scrollX < 0 then tiles.scrollX = 0
		disp.scrollX = tiles.scrollX
	else 
		off = kx - SCROLLBOX_RIGHT
		if off > 0 then
			tiles.scrollX = tiles.scrollX + off
			disp.scrollX = tiles.scrollX
		end if
	end if
	
	// scroll vertically (again to keep Kip in the box)
	ky = kip.y - tiles.scrollY
	off = SCROLLBOX_BOTTOM - ky
	if off > 0 then
		tiles.scrollY = tiles.scrollY - off
		if tiles.scrollY < 0 then tiles.scrollY = 0
		disp.scrollY = tiles.scrollY
	else 
		off = ky - SCROLLBOX_TOP
		if off > 0 then
			tiles.scrollY = tiles.scrollY + off
			disp.scrollY = tiles.scrollY
		end if
	end if	
end function

// Main loop:
mainLoop = function
	lastTime = time
	while not key.pressed("escape")
		dt = time - lastTime
		lastTime = time
		spriteControllers.updateSprites dt
		updateCamera
		yield
	end while
	key.clear
end function

mainLoop

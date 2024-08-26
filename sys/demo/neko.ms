// Neko!
//
// Try wiggling the mouse or tapping on the desktop to get Neko's attention.
// Or, wait a while, and let Neko sleep.

// (Still to-do: scratching the edges of the screen, and leaving footprints
// after walking through a puddle!)

import "mathUtil"
import "listUtil"

randRange = @mathUtil.randRange
randNormal = @mathUtil.randNormal
distance = @mathUtil.distance

gfx.clear color.clear, 64, 64
for ang in range(0, 2*pi, pi/6)
	gfx.line 32+cos(ang)*30, 32+sin(ang)*30, 32+cos(ang)*15, 32+sin(ang)*15
end for
tapSprite = new Sprite
tapSprite.image = gfx.getImage
gfx.clear

bonk = new Sound
bonk.init 0.1, 2, [1,0], Sound.noiseWave

// Function to load an image, given a partial path under pics
// (or the current directory), and divide it into 42 frames.
loadImage = function(name)
	pic = file.loadImage(name)
	if pic == null then pic = file.loadImage("/usr/pics/" + name)
	if pic == null then pic = file.loadImage("/sys/pics/" + name)
	
	outer.frames = []
	for i in range(0, 41)
		row = floor(i/8)
		col = i % 8
		frames.push pic.getImage(col * 32, pic.height - 32 - row*32, 32, 32)
	end for
end function

// We'll model our kitten as a simple state machine.
IDLE = "IDLE"
GROOMING = "GROOMING"
ITCHY = "ITCHY"
SLEEPY = "SLEEPY"
ASLEEP = "ASLEEP"
RUNNING = "RUNNING"
SCRATCHING = "SCRATCHING"
HEYHEY = "HEYHEY"

neko = new Sprite
neko.state = IDLE
neko.stateStartTime = time
neko.framesInState = 0
neko.target = {"x":100, "y":500}
neko.boredom = 5
neko.x = neko.target.x
neko.y = neko.target.y

neko.timeInState = function
	return time - self.stateStartTime
end function

neko.enterState = function(newState)
	if newState == IDLE then
		self.image = frames[0]
		self.stateEndTime = time + randRange(1, 3)
		self.boredom += 1
		if self.boredom > 20 then
			self.enterState SLEEPY
			return
		end if
	else if newState == GROOMING then
		self.stateEndTime = time + randRange(1, 3)
	else if newState == ITCHY then
		self.stateEndTime = time + randRange(1, 2)
	else if newState == RUNNING then
		self.image = frames[7]
		self.stateEndTime = time + 20
		self.boredom = 0
	else if newState == SLEEPY then
		self.image = frames[4]
		self.stateEndTime = time + randRange(2,4)
	else if newState == ASLEEP then
		self.stateEndTime = time + randRange(10, 20)
	else if newState == HEYHEY then
		self.image = frames[7]
		self.stateEndTime = time + 0.5
		self.boredom = -10
	end if
	self.state = newState
	self.stateStartTime = time
	self.framesInState = 0
end function

neko.exitState = function
end function

neko.pickNextState = function
	if self.state == IDLE then
		if distance(self, mouse) > 100 and mouseMovement.mean > 10 and rnd < 0.9 then
			self.enterState RUNNING
		else
			self.enterState [IDLE, GROOMING, ITCHY].any
		end if
	else if self.state == GROOMING then
		self.enterState [IDLE, IDLE, IDLE, ITCHY].any
	else if self.state == ITCHY then
		self.enterState [IDLE, GROOMING].any
	else if self.state == SLEEPY then
		self.enterState ASLEEP
	else if self.state == ASLEEP then
		self.boredom = 10
		self.enterState IDLE
	else if self.state == HEYHEY then
		self.enterState RUNNING
	end if
end function

neko.update = function
	self.framesInState += 1
//	text.row = 25; print self.state + " (" + self.boredom + ")" + " "*30  // for debugging!
	if time > self.stateEndTime then
		self.pickNextState
	end if
	if self.state == IDLE then
		if bonk.isPlaying and rnd < 0.01 then self.enterState HEYHEY
		
	else if self.state == GROOMING then
		self.image = frames[(self.timeInState / 0.5) % 2]
	else if self.state == ITCHY then
		self.image = frames[2 + (self.timeInState / 0.2) % 2]
	else if self.state == SLEEPY then
		self.image = frames[4 - 4 * floor((self.timeInState / 1.5) % 2)]
	else if self.state == ASLEEP then
		self.image = frames[5 + (self.timeInState / 0.6) % 2]
		if bonk.isPlaying and rnd < 0.1 then self.enterState HEYHEY
	else if self.state == RUNNING then
		self.target.x = mouse.x
		self.target.y = mouse.y
		if self.framesInState < 30 then return
		if distance(self, self.target) < 40 then
			self.enterState IDLE
			return
		end if
		radians = atan(self.target.y - self.y, self.target.x - self.x)
		angle = radians * 180 / pi
		direction = round(angle / 45)
		if direction < 0 then direction += 8
		baseFrame = 8 + ((direction + 2) * 2) % 16
//		text.row = 24; print round(angle) + "°, dir=" + direction + ", frame=" + baseFrame + "   "
		self.image = frames[baseFrame + (self.framesInState % 20 > 6)]
		self.x = mathUtil.clamp(self.x + 3 * cos(radians), 16, 960-16)
		self.y = mathUtil.clamp(self.y + 3 * sin(radians), 16, 640-16)
	end if
end function

clear
bgTint = "#91B2FF"
texture = file.loadImage("/sys/pics/textures/Fabric.png")
for y in range(0, 640, texture.height)
	for x in range(0, 960, texture.width)
		gfx.drawImage texture, x, y, -1, -1, 0, 0, -1, -1, bgTint
	end for
end for
display(7).color = bgTint
display(4).sprites.push neko
display(4).sprites.push tapSprite
loadImage "animals/neko.png"
neko.enterState IDLE

// main loop
lastMouse = {"x":mouse.x, "y":mouse.y}
lastButton = false
mouseMovement = [0]  // queue of recent mouse-movement distances
while true
	yield

	mouseMovement.push distance(mouse, lastMouse)
	if mouseMovement.len > 20 then mouseMovement.pull
	lastMouse = {"x":mouse.x, "y":mouse.y}

	if mouse.button and not lastButton then
		mouseMovement.push [1000] * 20
		bonk.play
		tapSprite.x = mouse.x
		tapSprite.y = mouse.y
	else if not bonk.isPlaying then
		tapSprite.x = -1000
	end if
	lastButton = mouse.button

	neko.update
end while
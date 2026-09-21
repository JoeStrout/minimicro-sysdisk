// Flappy Bat
// a simple-ish Sprite demo.
// Press spacebar to fly.

// Constants used in the flying code
kSpeed = 16
kGravity = 0.5
kFlapStrength = 5
kMaxRise = 10
kMaxFall = -10

// clear the displays
text.clear
gfx.clear "#220022"

// prepare sounds we'll need
flapSnd = file.loadSound("/sys/sounds/swoosh.wav")
hitSnd = file.loadSound("/sys/sounds/hit.wav")

// load our sprites
d = "/sys/pics/animals/"
frames = []
for i in range(1,5)
	frames.push file.loadImage(d + "bat-" + i + ".png")
end for
pipeImg = file.loadImage("/sys/pics/Pipe.png")
pipecapImg = file.loadImage("/sys/pics/PipeCap.png")

display(4).mode = displayMode.sprite
disp = display(4)
disp.clear
disp.scrollX = 0

// Define a Bat class.  Even though we're only going to
// need one Bat in this game, defining a class for it
// is a good habit to get into.
Bat = new Sprite
Bat.dy = 0
Bat.frame = 0
Bat.nextFrameTime = 0
Bat.doFlap = false
Bat.init = function
	self.image = frames[0]
	self.x = 100
	self.y = 320
end function
Bat.update = function
	if time > self.nextFrameTime then
		if self.frame < 4 then
			self.frame = self.frame + 1
		else if self.doFlap then
			self.frame = 0
			self.doFlap = false
			flapSnd.play 1, -0.5, 0.9 + 0.2 * rnd
		end if
		self.image = frames[self.frame]
		self.nextFrameTime = time + 0.05
	end if
	if self.frame == 0 then
		self.dy = self.dy + kFlapStrength
		if self.dy > kMaxRise then self.dy = kMaxRise
	else
		self.dy = self.dy - kGravity
		if self.dy < kMaxFall then self.dy = kMaxFall
	end if
	self.y = self.y + self.dy
	self.x = self.x + kSpeed
end function

// Instantiate our bat, and add it to the sprite display.
bat = new Bat
bat.init
disp.sprites.push bat

// Define a Pipe class.  (We'll need a lot of these.)
Pipe = {}
Pipe.init = function
	self.tube = new Sprite
	self.tube.image = pipeImg
	self.tube.scale = [1, 4] // so it's now 1024 pixels high!
	self.tube.tint = "#CCCCFF"
	disp.sprites.push self.tube
	self.cap = new Sprite
	self.cap.image = pipecapImg
	self.cap.tint = "#CCCCFF"
	disp.sprites.push self.cap
	self.setRandomPos
end function

Pipe.setPos = function(x, height)
	self.tube.x = x
	self.cap.x = x
	if height > 0 then
		self.tube.y = height - 544
		self.cap.y = height
	else
		self.cap.y = 640+height
		self.tube.y = 1182+height
	end if
	self.x = x
	self.height = height
end function

Pipe.setRandomPos = function
	x = round(disp.scrollX + 1000 + 500*rnd)
	h = round(600*(rnd-0.5))
	self.setPos x, h 
end function

Pipe.update = function
	// check for collision with bat
	if self.x > bat.x-60 and self.x < bat.x+60 then
		hit = false
		if self.height > 0 then
			if bat.y < self.height+30 then hit = true
		else
			if bat.y > 640+self.height-50 then hit = true
		end if
		if hit then doGameOver
	end if
	// check for went off screen
	if self.x + 64 - disp.scrollX < 0 then
		self.setRandomPos
	end if
end function

// Prepare some initial pipes.
pipes = []
for i in range(1,3)
	p = new Pipe
	p.init
	p.setPos 1500 + pipes.len*500, p.height
	pipes.push p
end for

// Handle keyboard input
handleKeys = function
	if not key.available then return
	k = key.get
	if k == char(27) or k == "q" then
		exit
	else
		bat.doFlap = true
	end if
end function

// Handle game-over
doGameOver = function
	hitSnd.play
	text.row = 13
	print "GAME OVER!"
	print "Your score: " + disp.scrollX

	// If we are returning to the shell, wait for a keypress
	if env.hasIndex("shell") and env.shell then key.get

	exit
end function

// Main loop
while true
	bat.update
	for p in pipes
		p.update
	end for
	handleKeys
	disp.scrollX = disp.scrollX + kSpeed
	yield
end while

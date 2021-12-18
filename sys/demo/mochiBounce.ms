// Mochi Bounce
// Hold the spacebar to jump, and left/right arrows to control your Mochi.
// How high can you go?

// Load our four platform images
platformImages = []
for i in ["", "2", "3", "4"]
	platformImages.push file.loadImage("/sys/pics/Block" + i + ".png")
end for
tints = ["#CCFFCC", "#B28048", "#C49EBC"]

// Prepare sounds
bounceSnd = new Sound
bounceSnd.init 0.3, [100,1000], [1,0]
landSnd = new Sound
landSnd.init 0.1, 440, [0.1, 0], Sound.noiseWave
fallSnd = new Sound
fallSnd.init 1, [1000, 20], [1, 0.5, 0.1, 0]

// Return the value 'x' moved towards a target value,
// but changing by no more than maxChange.
moveTowards = function(x, target, maxChange)
	diff = target - x
	if diff > -maxChange and diff < maxChange then return target
	return x + maxChange * sign(diff)
end function

// Define the Player class
Player = new Sprite
Player.vx = 0
Player.vy = 0

Player.idleBounce = function
	t = time * 10
	dscale = -(sin(t)+1)^2 * 0.03
	dy = 10 * abs(sin(t/2 - 0.785398))
	sy = 1 + dscale
	self.scale = [1, sy]
	self.y = self.trueY + dy + 42*sy
end function

Player.update = function(dt)
	pan = self.x / gfx.width - 0.5
	if key.pressed("space") and self.vy >= 0 then
		if self.grounded then
			// start a bounce!
			self.vy = 600
			self.grounded = false
			bounceSnd.play 0.6, pan, 0.9 + 0.2 * rnd
		else
			self.vy = self.vy - 400 * dt
		end if
	else
		if not self.grounded then
			self.vy = self.vy - 1600 * dt
		end if
	end if
	if self.grounded then
		self.idleBounce
	else
		if key.pressed("left") then
			self.vx = moveTowards(self.vx, -200, 400*dt)
		else if key.pressed("right") then
			self.vx = moveTowards(self.vx, 200, 400*dt)
		else
			self.vx = moveTowards(self.vx, 0, 200*dt)
		end if
		self.x = self.x + self.vx * dt
		
		self.trueY = self.trueY + self.vy * dt
		if self.vy < 0 then
			hitY = platformHit
			if hitY != null then
				self.trueY = hitY
				self.vy = 0
				self.grounded = true
				landSnd.play 1, pan, 0.9 + 0.2 * rnd
				self.vx = 0
			else if self.trueY - disp.scrollY < -100 then
				print "GAME OVER!"
				fallSnd.play
				exit
			end if
		end if
		self.y = self.trueY + 42
	end if
end function

// Instantiate the player
player = new Player
player.image = file.loadImage("/sys/pics/Mochi.png")
player.x = 960/2
player.y = 100

// Prepare the displays
display(4).mode = displayMode.sprite
disp = display(4)
disp.clear
gfx.clear "#000044"
text.clear
text.row = 25
text.delimiter = char(13)
print "Height: 0"

platforms = []

// Define the Platform class
Platform = new Sprite
Platform.config = function(size, x, y)
	self.image = platformImages[size-1]
	self.x = x
	self.y = y
	self.tint = tints[floor(rnd*tints.len)]
end function

Platform.pointInBounds = function(x, y)
	x = x - self.x
	hw = self.image.width/2
	if x < -hw or x > hw then return false
	y = y - self.y
	hh = self.image.height/2
	if y < -hh or y > hh then return false
	return true
end function

// function to add a new platform
addPlatform = function(size, x, y)
	p = new Platform
	p.config size, x, y
	platforms.push p
	disp.sprites.push p
end function

// Find the platform the player is touching, if any.
platformHit = function
	for p in platforms
		if p.pointInBounds(player.x, player.trueY) then
			return p.y + 28
		end if
	end for
	return null
end function

// Check whether any platform has moved off the bottom
// of the screen, and if so, move it up to a random
// position above the top of the screen.  This creates
// the illusion of an infinite supply of platforms.
loopPlatforms = function
	if platforms[0].y - disp.scrollY < -40 then
		p = platforms.pull
		p.config ceil(rnd * 4), round(100 + 700 * rnd), 680 + disp.scrollY
		platforms.push p
	end if		
end function

// add platforms in order, lowest one first   
addPlatform 4, player.x, player.y - 28
addPlatform 3, 200, 300
addPlatform 2, 750, 500
addPlatform 3, 450, 600

// add player last, so it's drawn on top
disp.sprites.push player
player.trueY = player.y
player.grounded = true

// Update the camera (display scroll position) 
// as the player moves upward
camSpeed = 0
updateCamera = function(dt)
	if player.y - disp.scrollY > 320 then
		globals.camSpeed = moveTowards(camSpeed, 200, 400*dt)
	else
		globals.camSpeed = moveTowards(camSpeed, 0, 400*dt)
	end if
	if camSpeed > 0 then
		disp.scrollY = disp.scrollY + camSpeed * dt
		loopPlatforms
		text.row = 25
		text.print "Height: " + floor(disp.scrollY)
	end if
end function

// Main loop
lastTime = time
while not key.pressed("escape")
	dt = time - lastTime
	lastTime = time
	player.update dt
	updateCamera dt
	yield
end while
key.clear

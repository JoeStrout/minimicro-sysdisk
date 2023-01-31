// Asteroids!  A loving tribute to the 1979 Atari classic.
//
// Use the arrow keys, WASD, or a gamepad/joistick
// to turn and thrust; press spacebar or gamepad
// button to fire.  Shoot the rocks and UFOs.
// Try not to get blown up.

import "listUtil"
import "mathUtil"
import "sounds"
import "chars"

clear
Sound.stopAll
sheet2x = file.loadImage("/sys/pics/Asteroids-2X.png")
images = {}
images.ship = sheet2x.getImage(64*3, 0, 96, 64)
images.shipThrusting = sheet2x.getImage(64*3+96, 0, 96, 64)
images.bullet = sheet2x.getImage(sheet2x.width-64, 0, 32, 32)
images.debris = images.bullet
images.ufoBullet = sheet2x.getImage(sheet2x.width-32, 0, 32, 32)
images.ufo = sheet2x.getImage(sheet2x.width-96, 16*5, 96, 80)
images.rocks = list.init2d(3,3) // index by: [type][size], each 0-2
for type in range(0,2)
	images.rocks[type][0] = sheet2x.getImage(160*type, 96+64, 160,160)
	images.rocks[type][1] = sheet2x.getImage(96*type, 64, 96,96)
	images.rocks[type][2] = sheet2x.getImage(64*type, 0, 64,64)
end for

// Prepare sounds
pew = new Sound
pew.init 0.25, [2000,100], [1,0]
bipBoop = [new Sound, new Sound]
bipBoop[0].init 0.1, noteFreq(42), [0.3,0]
bipBoop[1].init 0.1, noteFreq(44), [0.3,0]
hit = file.loadSound("/sys/sounds/hit.wav")
engineNoise = new Sound
engineNoise.init 3, 1, 1, Sound.noiseWave
engineNoise.loop = true
ufoSound = new Sound
ufoSound.init 2, 
  [noteFreq(80), noteFreq(76), noteFreq(80), noteFreq(80)]*10, 0.25
ufoSound.loop = true
ufoSound.fadeIn = 0; ufoSound.fadeOut = 0

GameSprite = new Sprite
GameSprite.scale = 0.5
GameSprite.v = null  // x and y
GameSprite.destroyed = false
GameSprite.update = function(dt)
	self.x = self.x + self.v.x * dt
	if self.x > 1040 then
		self.x = -80
	else if self.x < -80 then
		self.x = 1040
	end if
	self.y = self.y + self.v.y * dt
	if self.y > 720 then
		self.y = -80
	else if self.y < -80 then
		self.y = 720
	end if
end function
GameSprite.init = function
	self.v = {"x":0, "y":0}
	self.destroyed = false
	display(4).sprites.push self
end function
GameSprite.destroy = function
	self.destroyed = true
	display(4).sprites.removeVal self
end function

zeroZero = {"x":0, "y":0}

ship = new GameSprite
ship.image = images.ship
ship.acceleration = 2000  // pixels/sec/sec
ship.deceleration = 100   // pixels/sec/sec
ship.maxSpeed = 1200 // pixels/sec
ship.turnRate = 720  // degrees/sec
ship.fireWasPressed = false
ship.localBounds = new Bounds
ship.localBounds.width = 64
ship.localBounds.height = 32
ship.tint = color.lime
ship.thrusting = false
ship.reset = function
	self.x = 480
	self.y = 320
	self.rotation = 0
end function
ship.update = function(dt)
	// turn
	turn = key.axis("Horizontal")
	self.rotation = self.rotation - turn * self.turnRate * dt
	
	// alternate turn scheme: face the mouse!
	// Kind of fun, but maybe TOO easy.
	//self.rotation = atan(mouse.y - self.y, mouse.x - self.x) * 180/pi
	
	// thrust
	thrust = key.axis("Vertical") or key.pressed("left shift") or
	  key.pressed("right shift")
	if thrust < 0 then thrust = 0
	radians = self.rotation * pi/180
	self.v.x = self.v.x + cos(radians) * thrust * self.acceleration * dt
	self.v.y = self.v.y + sin(radians) * thrust * self.acceleration * dt
	if thrust > 0 and not self.thrusting then
		self.image = images.shipThrusting
		engineNoise.play 0.1
		self.thrusting = true
	else if self.thrusting and thrust == 0 then
		self.image = images.ship
		engineNoise.stop
		self.thrusting = false
	end if
	
	// fire bullets
	fireIsPressed = key.pressed("space") or
	  key.pressed("joystick button 0") or
	  key.pressed("joystick button 1") or
	  mouse.button
	if fireIsPressed and not self.fireWasPressed then
		b = new Bullet
		b.init
		b.tint = self.tint
		b.x = self.x + cos(radians)*16
		b.y = self.y + sin(radians)*16
		b.v.x = self.v.x + cos(radians)*500
		b.v.y = self.v.y + sin(radians)*500
		pew.play 1, (self.x - 480)/480
	end if
	self.fireWasPressed = fireIsPressed
	
	// apply friction and max speed
	mathUtil.moveTowardsXY self.v, zeroZero, self.deceleration * dt
	speed = sqrt(self.v.x^2 + self.v.y^2)
	if speed > self.maxSpeed then
		f = self.maxSpeed / speed
		self.v.x = self.v.x * f
		self.v.y = self.v.y * f
	end if
	
	super.update dt
end function
ship.destroy = function
	super.destroy
	engineNoise.stop
	hit.play 1, (self.x - 480)/480, 0.3
	makeDebris self
	globals.lives = lives - 1
	globals.respawnTime = time + 3
	drawScore
end function
ship.respawn = function
	if not safeToRespawn then return // not yet!
	self.x = 480
	self.y = 320
	self.rotation = 0
	self.init
	globals.respawnTime = 0
end function
ship.respawnArea = new Bounds
ship.respawnArea.x = 480
ship.respawnArea.y = 320
ship.respawnArea.width = 150
ship.respawnArea.height = 150

respawnTime = 1

TimedSprite = new GameSprite
TimedSprite.despawnTime = 0
TimedSprite.init = function(duration = 0.5)
	super.init
	self.despawnTime = time + duration
end function
TimedSprite.update = function(dt)
	if time > self.despawnTime then
		self.destroy
	else
		super.update dt
	end if
end function

Bullet = new TimedSprite
Bullet.image = images.bullet
Bullet.instances = []
Bullet.init = function(lifetime = 0.6)
	super.init lifetime
	Bullet.instances.push self
end function
Bullet.destroy = function
	super.destroy
	Bullet.instances.removeVal self
end function

Enemy = new GameSprite
Enemy.spin = 0
Enemy.scoreValue = 100
Enemy.update = function(dt)
	self.rotation = self.rotation + self.spin * dt
	if self.overlaps(ship) and not ship.destroyed then
		ship.destroy	// comment out this line for invulnerability!
		self.destroy
	else
		for b in Bullet.instances
			if self.contains(b) then
				addPoints self.scoreValue
				self.destroy
				b.destroy
			end if
		end for	
	end if
	super.update dt	
end function

Rock = new Enemy
Rock.size = 0
Rock.init = function(size=0)
	super.init
	self.size = size
	self.image = images.rocks[rnd*3][self.size]
	self.localBounds = new Bounds
	self.localBounds.width = self.image.width * 0.75
	self.localBounds.height = self.image.height * 0.75	
	self.spin = 360 * (rnd - 0.5)
end function
Rock.scoreValue = function
	return [20, 50, 100][self.size]
end function
Rock.destroy = function
	super.destroy
	hit.play 0.7, (self.x - 480)/480, 0.5 + 0.2*self.size
	makeDebris self
	if self.size < 2 then
		// break into two rocks of the next size down
		Rock.make self.size+1, self
		Rock.make self.size+1, self
	end if
	heartbeat.updateInterval
end function
Rock.make = function(size=0, position=null)
	rock = new Rock
	rock.init size
	if position then
		rock.x = position.x
		rock.y = position.y
	else
		rock.x = 960 * rnd
		rock.y = 640 * rnd
	end if
	rock.v.x = (rnd-0.5) * 300
	rock.v.y = (rnd-0.5) * 300
end function

Ufo = new Enemy
Ufo.image = images.ufo
Ufo.tint = "#FF4444"
Ufo.localBounds = new Bounds
Ufo.localBounds.width = 72
Ufo.localBounds.height = 40
Ufo.scoreValue = 500   // ToDo: 200 vs 1000 for small/large UFO
Ufo.volume = 0
Ufo.nextFireTime = 0
Ufo.spawn = function
	if rnd > 0.5 then
		self.x = 1020
		self.v.x = round(mathUtil.randRange(-150, -50))
	else
		self.x = -60
		self.v.x = round(mathUtil.randRange(50, 150))
	end if
	self.y = round(mathUtil.randRange(100, 540))
	if display(4).sprites.indexOf(self) == null then
		display(4).sprites.push self
	end if
	Ufo.nextSpawnTime = time + mathUtil.randRange(20,45)
	self.volume = 0.01
	ufoSound.stop
	ufoSound.play self.volume, (self.x - 480)/480
	self.nextFireTime = time + mathUtil.randRange(5, 10)
end function
Ufo.despawn = function
	display(4).sprites.removeVal self
	ufoSound.stop
end function
Ufo.update = function(dt)
	super.update dt
	self.volume = mathUtil.moveTowards(self.volume, 0.5, dt)
	ufoSound.adjust self.volume, (self.x - 480)/480
	if self.x < -110 or self.x > 1070 then
		self.despawn
	else if time > self.nextFireTime then
		self.fire
	end if
end function
Ufo.fire = function
	if not ship.destroyed then
		b = new UfoBullet
		b.init 0.8
		radians = atan(ship.y - self.y, ship.x - self.x) + 0.4*(rnd-0.5)
		b.x = self.x + cos(radians)*16
		b.y = self.y + sin(radians)*16
		b.v.x = cos(radians)*500
		b.v.y = sin(radians)*500
		pew.play 1, (self.x - 480)/480, 0.6
	end if
	self.nextFireTime = time + mathUtil.randRange(0.5, 1)
end function
Ufo.destroy = function
	super.destroy
	ufoSound.stop
	hit.play 1, (self.x - 480)/480, 0.4
	makeDebris self
	heartbeat.updateInterval
end function

UfoBullet = new Bullet
UfoBullet.image = images.ufoBullet
UfoBullet.tint = Ufo.tint
UfoBullet.update = function(dt)
	super.update dt
	if ship.contains(self) and not ship.destroyed then
		ship.destroy
		self.destroy
	end if
end function


safeToRespawn = function
	for sp in display(4).sprites
		if sp isa Rock and sp.overlaps(ship.respawnArea) then return false
	end for
	return true
end function

makeDebris = function(source)
	for i in range(10)
		d = new TimedSprite
		d.init
		d.image = images.debris
		d.x = source.x; d.y = source.y; d.tint = source.tint
		d.v.x = (rnd-0.5) * 300
		d.v.y = (rnd-0.5) * 300		
	end for
end function

heartbeat = {}
heartbeat.nextPlayTime = 0
heartbeat.which = 0
heartbeat.interval = 0.75
heartbeat.updateInterval = function
	// count rocks to adjust heartbeat
	count = 0
	for sp in display(4).sprites
		if sp isa Enemy then count = count + 1
	end for
	self.interval = mathUtil.clamp(1.25 - count * 0.1, 0.25, 1.25)
	if count == 0 and not nextLevelTime then
		globals.nextLevelTime = time + 3
	end if
end function
heartbeat.update = function(dt)
	if time > self.nextPlayTime then
		bipBoop[self.which].play
		self.nextPlayTime = time + self.interval
		self.which = not self.which
	end if
end function

drawScore = function
	text.row = 25; text.column = 4
	print ("000000" + score)[-6:] + "   " + 
	chars.figureStanding * lives + "   "
end function

addPoints = function(points)
	globals.score = score + points
	drawScore
end function

startLevel = function
	globals.level = level + 1
	// Board setup
	ship.reset
	for i in range(0,7)
		Rock.make
	end for
	heartbeat.updateInterval
	drawScore
	globals.nextLevelTime = 0
	Ufo.nextSpawnTime = time + mathUtil.randRange(5,15)
end function

autoplay = env.hasIndex("shell") and env.shell and env.autorun
if autoplay then
	// make some dummy inputs for auto-play mode!
	key = {}
	key.axis = function(which)
		if which == "Vertical" then
			return cos(time) + cos(time/2) > 0.8
		end if
		c = cos(time) + cos(time/2) + cos(time * 10)
		if abs(c) < 0.5 then return 0
		return sign(c)
	end function
	key.pressed = function(k)
		if k != "space" then return false
		return rnd < 0.1
	end function
end if

level = 0
score = 0
ship.destroyed = true
lives = 2 + (not autoplay)
startLevel
Ufo.init
Ufo.despawn

// Main loop
lastTime = time
while true
	dt = time - lastTime
	lastTime = time
	for sp in display(4).sprites
		sp.update dt
	end for
	heartbeat.update dt
	if ship.destroyed and respawnTime and time > respawnTime then
		if lives < 0 then break
		ship.respawn
	end if
	if nextLevelTime and time > nextLevelTime then startLevel
	if time > Ufo.nextSpawnTime then Ufo.spawn
	yield
end while

text.row = 14; text.column = 30
print "GAME OVER"
Sound.stopAll
text.row = 1
if autoplay then globals.remove "key"
key.clear

// If we are returning to the shell, wait for a keypress;
// or if we're in auto-run mode, just wait a short time
if env.hasIndex("shell") and env.shell then
	if env.autorun then wait 2 else key.get
end if

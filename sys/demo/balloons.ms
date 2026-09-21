// Balloons!
// A little demo (NOT a full game) mostly demonstrating the
// pathUtil library in /sys/lib.
// Any relation to OTHER balloon-popping games you may know
// is purely coincidental.
// (Just kidding.  We love you, Ninja Kiwi!)

import "mathUtil"
import "pathUtil"
PathPoint = pathUtil.PathPoint

// Here's the balloon path.
// (I created this by importing "pathUtil", then calling
// pathUtil.makePathWithMouse, clicking out the path,
// and then copying it and pasting it here.)
path = [[0, 531], [338, 534], [371, 506], [370, 284], [353, 270],
 [177,269], [159, 255], [154, 85], [181, 54], [522, 59], [564, 94],
 [560,502], [584, 537], [836, 536], [870, 505], [871, 302], 
 [857, 285], [719, 274], [704, 243], [706, -20]]

clear
gfx.clear "#004400"
pathUtil.drawPath gfx, path, "#666622", 30

display(4).mode = displayMode.sprite
disp = display(4)
disp.clear

pop = file.loadSound("/sys/sounds/pop.wav")
burstImg = file.loadImage("/sys/pics/Burst.png")

//==================================================
// Balloon class
//==================================================
Balloon = new Sprite
Balloon.image = file.loadImage("/sys/pics/Balloon.png")
Balloon.speed = 100
Balloon.burstTime = null

Balloon.init = function
	self.pathPoint = PathPoint.make(path)
	type = floor(rnd*4)
	if type == 0 then
		self.tint = color.yellow
		self.scale = 1.1
		self.speed = 200
	else if type == 1 then
		self.tint = color.blue
		self.speed = 150
	else
		self.tint = color.red
		self.scale = 0.9
		self.speed = 100
	end if
	disp.sprites.push self
end function

Balloon.remove = function
	disp.sprites.remove disp.sprites.indexOf(self)
	balloons.remove balloons.indexOf(self)
end function

Balloon.update = function(dt=0.1)
	if self.burstTime then
		if time - self.burstTime > 0.1 then self.remove
		return
	end if
	self.pathPoint.advance self.speed * dt
	self.x = self.pathPoint.position[0]
	self.y = self.pathPoint.position[1]
	if self.pathPoint.isAtEnd then self.remove
end function

Balloon.pop = function
	pop.play
	self.image = burstImg
	self.tint = color.lerp(self.tint, color.white, 0.7)
	self.rotation = 360*rnd
	self.burstTime = time
end function

//==================================================
// Dart class
//==================================================
Dart = new Sprite
Dart.image = file.loadImage("/sys/pics/Dart.png")
Dart.scale = 0.5

Dart.init = function(thrower, speed=500)
	self.rotation = thrower.rotation
	self.dx = speed * cos(self.rotation * pi/180)
	self.dy = speed * sin(self.rotation * pi/180)
	self.x = thrower.x + self.dx * 0.1
	self.y = thrower.y + self.dy * 0.1
	disp.sprites.push self
	darts.push self
end function

Dart.update = function(dt=0.1)
	self.x = self.x + self.dx * dt
	self.y = self.y + self.dy * dt
	if self.x > 960 or self.x < 0 or self.y > 640 or self.y < 0 then
		self.remove
	else
		for b in balloons
			if b.burstTime then continue
			if mathUtil.distance(b, self) < 32 then
				b.pop
				self.remove
				break
			end if
		end for
	end if
end function

Dart.remove = function
	darts.remove darts.indexOf(self)
	disp.sprites.remove disp.sprites.indexOf(self)
end function

//==================================================
// tower
//==================================================

tower = new Sprite
tower.image = file.loadImage("/sys/pics/arrows/circleHat.png")
tower.tint = color.orange
tower.scale = 0.5
tower.x = 300
tower.y = 150
tower.nextFireTime = 0.5
tower.gotTarget = false
disp.sprites.push tower

tower.faceNearest = function
	self.gotTarget = false
	if not balloons then return
	best = null
	for b in balloons
		dist = mathUtil.distance(self, b)
		if best == null or dist < bestDist then
			best = b
			bestDist = dist
		end if
	end for
	self.rotation = 180 / pi * 
	atan(best.y - self.y, best.x - self.x)
	self.gotTarget = (bestDist < 400)
end function

tower.update = function
	self.faceNearest
	if time < self.nextFireTime then return
	// Fire!
	self.nextFireTime = time + 0.5
	if self.gotTarget then
		d = new Dart
		d.init self
	end if
end function

//==================================================
// Main program
//==================================================

handleClick = function(pos)
	// check for a click on a balloon
	for b in balloons
		if mathUtil.distance(b, pos) < 32 then
			b.pop
			return
		end if
	end for
	if pathUtil.distanceToPath(pos, path) > 40 then
		// move the tower
		tower.x = pos.x
		tower.y = pos.y
	end if
end function

balloons = []
darts = []
hadMouseDown = mouse.button
lastTime = time
while not key.pressed("escape")
	dt = time - lastTime
	lastTime = time
	
	// make a new balloon now and then
	if rnd < 0.02 then
		b = new Balloon
		b.init
		balloons.push b
	end if
	
	// handle mouse clicks
	mouseDown = mouse.button
	if mouseDown and not hadMouseDown then handleClick mouse
	hadMouseDown = mouseDown
	
	// update the tower, darts, and balloons
	tower.update
	for d in darts
		d.update dt
	end for
	for b in balloons
		b.update dt
	end for
	
	yield  // (wait till next frame)
end while
key.clear


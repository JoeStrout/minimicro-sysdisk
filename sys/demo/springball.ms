// Ball-and-spring physics demo

// Try experimenting with Ball.damping and Spring.k to see
// what different behavior you get!

import "mathUtil"

gravity = 10

Ball = new Sprite
Ball.image = file.loadImage("/sys/pics/shapes/CircleThick.png")
Ball.scale = 0.25
Ball.vx = 0
Ball.vy = 0
Ball.mass = 10
Ball.forceX = 0
Ball.forceY = 0
Ball.damping = 0.2
Ball.update = function(dt)
	// assume our forces have already been calculated;
	// do simple Newtonian physics (F = ma, so a = F/m)
	self.vx = self.vx + self.forceX / self.mass
	self.vy = self.vy + self.forceY / self.mass
	// also, accelerate due to gravity
	self.vy = self.vy - gravity * dt
	// and slow down due to damping (friction)
	self.vx = self.vx - self.vx * self.damping / self.mass
	self.vy = self.vy - self.vy * self.damping / self.mass
	// update position
	self.x = self.x + self.vx * dt
	self.y = self.y + self.vy * dt
	// then do bounds checking against the walls
	self.x = mathUtil.clamp(self.x, 5, 955)
	self.y = mathUtil.clamp(self.y, 5, 635)	
end function
balls = []

Spring = new Sprite
Spring.image = file.loadImage("/sys/pics/shapes/Square.png")
Spring.ballA = null
Spring.ballB = null
Spring.k = 15  // (spring constant, or "stiffness")
Spring.idealLength = 100
Spring.update = function(dt)
	self.x = (self.ballA.x + self.ballB.x) / 2
	self.y = (self.ballA.y + self.ballB.y) / 2
	self.rotation = atan(self.ballA.y - self.ballB.y,
	self.ballA.x - self.ballB.x) * 180/pi
	length = mathUtil.distance(self.ballA, self.ballB)
	self.scale = [length / self.image.width, 5 / self.image.height ]
	if length < self.idealLength then
		// compressed: tint red
		t = (self.idealLength - length) / (self.idealLength/2)
		self.tint = color.lerp(color.gray, "#FF8080", t)
	else
		// stretched: tint blue
		t = (length - self.idealLength) / self.idealLength
		self.tint = color.lerp(color.gray, "#8080FF", t)
	end if
end function
springs = []

connected = function(bA, bB)
	for spr in springs
		if (spr.ballA == bA and spr.ballB == bB) or
		(spr.ballB == bA and spr.ballA == bB) then return true
	end for
	return false
end function

doOneStep = function(dt = 0.1)
	// Clear all the forces on the balls
	for b in balls; b.forceX = 0; b.forceY = 0; end for
	
	// Apply spring forces for all the springs
	for spr in springs
		bA = spr.ballA
		bB = spr.ballB
		// calculate the amount of pulling force of the spring
		dx = bB.x - bA.x  // (dx,dy points from A towards B)
		dy = bB.y - bA.y
		dist = sqrt(dx*dx + dy*dy)
		f = (dist - spr.idealLength) * spr.k
		// apply this to X and Y of the balls, in the proper
		// direction for each ball
		fX = f * dx / dist
		fY = f * dy / dist
		bA.forceX = bA.forceX + fX; bA.forceY = bA.forceY + fY
		bB.forceX = bB.forceX - fX; bB.forceY = bB.forceY - fY
	end for
	
	// Then, update all balls, then all springs
	for b in balls; b.update dt; end for
	for spr in springs; spr.update dt; end for
end function


clear
display(4).type = displayMode.sprite
disp = display(4)

// create some balls
for ang in range(0, 2*pi, pi/6)
	b = new Ball
	b.x = 480 + 80 * cos(ang)
	b.y = 320 + 80 * sin(ang)
	balls.push b
end for

// connect them with springs
for i in balls.indexes
	for j in range(1, balls.len+4, 5)
		bA = balls[i]
		bB = balls[(i + j) % balls.len]
		if connected(bA, bB) then continue
		spr = new Spring
		spr.ballA = bA
		spr.ballB = bB
		spr.idealLength = mathUtil.distance(bA, bB)
		disp.sprites.push spr
		springs.push spr
		spr.update
	end for
end for
// (draw balls on top of springs)
for b in balls; disp.sprites.push b; end for

// run the simulation, and allow the user to grab any
// ball with the mouse and drag it around.
grabbed = null
lastMouse = {"x":mouse.x, "y":mouse.y}
while true
	yield
	if mouse.button then
		if grabbed == null then
			for b in balls
				if mathUtil.distance(mouse, b) < 10 then grabbed = b
			end for
		else		
			// drag the ball with the mouse directly
			b.x = mouse.x
			b.y = mouse.y
			b.vx = mouse.x - lastMouse.x
			b.vy = mouse.y - lastMouse.y
		end if
	else
		grabbed = null
	end if
	lastMouse.x = mouse.x; lastMouse.y = mouse.y
	doOneStep
end while


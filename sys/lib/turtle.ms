Turtle = {}
Turtle.image = file.loadImage("/sys/pics/animals/turtle.png")
Turtle.scale = 0.2
Turtle.x = 960/2
Turtle.y = 640/2
Turtle.heading = 0
Turtle.displayNum = 4
Turtle.penDown = true
Turtle.penSize = 1
Turtle.color = color.white
Turtle.fillColor = color.white
Turtle._fillPoints = null

Turtle.updateSprite = function
	if not self.hasIndex("sprite") then return
	self.sprite.image = self.image
	self.sprite.scale = self.scale
	self.sprite.x = self.x
	self.sprite.y = self.y
	self.sprite.rotation = self.heading
end function

Turtle.show = function
	self.sprite = new Sprite
	self.updateSprite
	display(self.displayNum).mode = displayMode.sprite
	display(self.displayNum).sprites.push self.sprite
end function

Turtle.hide = function
	splist = display(self.displayNum).sprites
	idx = splist.indexOf(self.sprite)
	if idx >= 0 then splist.remove idx
	self.remove "sprite"
end function

Turtle.clear = function
	gfx.clear
	display(self.displayNum).sprites = []
	self.remove "sprite"
end function

Turtle.plop = function
	if self.penSize <= 1 then
		gfx.setPixel self.x, self.y, self.color
	else
		hs = self.penSize * 0.5
		gfx.fillEllipse self.x-hs, self.y - hs, self.penSize, self.penSize, self.color
	end if
end function

Turtle.goTo = function(x,y)
	if self.penDown then
		if self.penSize > 1 then self.plop
		gfx.line self.x, self.y, x, y, self.color, self.penSize
		if self.penSize > 1 then self.plop
	end if
	self.x = x
	self.y = y
	if self._fillPoints isa list then self._fillPoints.push [x,y]
	self.updateSprite
end function

Turtle.jumpTo = function(x,y)
	self.x = x
	self.y = y
	if self._fillPoints isa list then self._fillPoints.push [x,y]
	self.updateSprite
end function

Turtle.forward = function(dist)
	radians = self.heading * pi/180
	self.goTo self.x + dist * cos(radians), self.y + dist * sin(radians)
end function

Turtle.backward = function(dist)
	self.forward -dist
end function

Turtle.right = function(degrees)
	self.heading = (self.heading - degrees) % 360
	self.updateSprite
end function

Turtle.left = function(degrees)
	self.right -degrees
end function

Turtle.circle = function(radius, extent=360, steps=null)
	circleFrac = abs(extent) / 360
	pathLen = 2*pi*radius * circleFrac
	if steps == null then
		steps = ceil(pathLen / 10)
		steps2 = ceil(36 * circleFrac)
		if steps2 > steps then steps = steps2
	end if
	radians = (self.heading + 90 * sign(extent)) * pi/180
	cx = self.x + radius * cos(radians); cy = self.y + radius * sin(radians)
	baseAng = radians - pi
	dAng = extent / steps * pi/180
	for i in range(1, steps)
		ang = baseAng + i*dAng
		self.goTo cx + radius * cos(ang), cy + radius * sin(ang)
	end for
	self.heading += extent
end function

Turtle.beginFill = function
	self._fillPoints = [[self.x,self.y]]
end function

Turtle.endFill = function
	if self._fillPoints then gfx.fillPoly self._fillPoints, self.fillColor
	self._fillPoints = null
end function

demo = function
	Turtle.jumpTo gfx.width/2, gfx.height/2
	Turtle.color = color.yellow
	Turtle.penSize = 100
	Turtle.plop
	Turtle.penSize = 4
	Turtle.jumpTo Turtle.x + 55, Turtle.y + 22
	Turtle.heading = 60
	Turtle.penDown = true
	for i in range(0,12)
		Turtle.forward 40
		Turtle.left 135
		Turtle.forward 40
		Turtle.right 105
	end for
end function

demo2 = function
	Turtle.jumpTo gfx.width/2, gfx.height/2 - 50
	Turtle.penSize = 2
	for j in range(24)
		for i in range(14)
			Turtle.color = color.hsv(255*i/15, 255*j/25, 255)
			Turtle.right 90
			Turtle.circle 200-j*4, 90
			
			Turtle.left 90
			Turtle.circle 200-j*4, 90
			
			Turtle.right 180
			Turtle.circle 50, 24
		end for
	end for
end function

longDemo = function
	// This demo draws a turtle, using Turtle!
	// Based on a design by Discord user @Intas.
	clear
	Turtle.clear
	Turtle.show
	
	// some helper functions...
	smoothWave = function(valA, valB, step, waveSteps)
		t = cos(step / waveSteps * 2 * pi)*0.5 + 0.5
		return valB + (valA - valB) * t
	end function
	
	drawEllipse = function(length, minWidth, extraWidth)
		Turtle.penDown = true
		for step in range(1,length)
			Turtle.penSize = minWidth + extraWidth * sin(step/length * pi)
			Turtle.forward 1
		end for
	end function
	
	move = function(initialTurn, forwardDist, endTurn=0)
		Turtle.penDown = false
		Turtle.right initialTurn
		Turtle.forward forwardDist
		Turtle.right endTurn
	end function
	
	// Draw legs
	Turtle.color = color.lime
	Turtle.penDown = false
	Turtle.left 45
	for i in range(1,4)
		Turtle.forward 40
		drawEllipse 120, 30, 30
		move 180, 120+40, -90
	end for
	
	// Draw tail
	move 45, 100; drawEllipse 80, 5, 20
	
	// Draw head
	move 180, 360; drawEllipse 40, 80, 20
	
	// Draw eyes
	Turtle.penSize = 10; Turtle.penDown = false
	Turtle.color = color.black
	move 180, 10; move 90, 20; Turtle.plop
	move 180, 40; Turtle.plop
	move 180, 20, -90
	
	// Shell (main color)
	Turtle.forward 130
	Turtle.color = color.green
	drawEllipse 150, 160, 60
	
	// Shell outlines
	move 0, 80
	Turtle.penSize = 15; Turtle.color = color.black; 
	Turtle.left 90; Turtle.penDown = true
	for step in range(1,360)
		Turtle.left 1
		Turtle.forward smoothWave(1, 3.6, step, 180) // trial & error!
	end for
	move -90, 8, 90
	Turtle.penSize = 10
	Turtle.color = "#005300"; Turtle.penDown = true
	for step in range(1,360)
		Turtle.left 1
		Turtle.forward smoothWave(1, 3.4, step, 180) // trial & error!
	end for
	
	// Shell lines
	move -90, 75, 60
	Turtle.penSize = 10; Turtle.color = color.black
	Turtle.penDown = true
	for step in range(0,5)
		Turtle.forward [60,90,60,60,90,60][step]
		lineLen = 50 + 30 * (step==2 or step==5)
		Turtle.right 60;	Turtle.forward lineLen
		Turtle.right 180;	Turtle.forward lineLen
		Turtle.right 60
	end for
	
end function

// Since this module defines only a class, we'll poke that class
// directly into the globals, so you can say `Turtle` instead of `turtle.Turtle`.
globals.Turtle = Turtle

if globals == locals then longDemo


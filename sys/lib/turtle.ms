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
Turtle.updateSprite = function()
	if not self.hasIndex("sprite") then return
	self.sprite.image = self.image
	self.sprite.scale = self.scale
	self.sprite.x = self.x
	self.sprite.y = self.y
	self.sprite.rotation = self.heading
end function
Turtle.show = function()
	self.sprite = new Sprite
	self.updateSprite
	display(self.displayNum).mode = displayMode.sprite
	display(self.displayNum).sprites.push self.sprite
end function
Turtle.hide = function()
	splist = display(self.displayNum).sprites
	idx = splist.indexOf(self.sprite)
	if idx >= 0 then splist.remove idx
	self.remove "sprite"
end function
Turtle.clear = function()
	gfx.clear
	display(self.displayNum).sprites = []
	self.remove "sprite"
end function
Turtle.plop = function()
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
	self.updateSprite
end function
Turtle.jumpTo = function(x,y)
	self.x = x
	self.y = y
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

// Since this module defines only a class, we'll poke that class
// directly into the globals, so you can say `Turtle` instead of `turtle.Turtle`.
globals.Turtle = Turtle

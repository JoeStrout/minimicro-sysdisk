// What is Mini Micro?
//
// A demo of direct manipulation of the text display.

// Load /sys/lib/chars, so we can use chars.printable
import "chars"

// Gather all the characters we're going to use.
characters = []
for i in range(33,127) + range(161,255)
	characters.push char(i)
end for
characters = characters + chars.printable

// Define a Drop class, to represent one dropping 
// column of text.
Drop = {}
Drop.x = 0
Drop.y = 26
Drop.length = 30
Drop.framesPerUpdate = 2
Drop.framesTillNextUpdate = 1

// Initialize a drop with random settings.
Drop.init = function()
	self.x = floor(68 * rnd)
	self.framesPerUpdate = 1 + ceil(3*rnd)
	self.length = round(10 + 10*rnd + 10*rnd)
end function

// Calculate the topmost row in the drop
Drop.top = function()
	return self.y + self.length
end function

// Update a drop.
Drop.update = function()
	self.framesTillNextUpdate = self.framesTillNextUpdate - 1
	if self.framesTillNextUpdate > 0 then return
	self.framesTillNextUpdate = self.framesPerUpdate
	
	self.y = self.y - 1
	if self.y >= 0 then
		text.setCell self.x, self.y, 
		  characters[characters.len * rnd]
		text.setCellColor self.x, self.y, "#88FF00"
	end if
	for y in range(self.top, 0)
		if y <= self.y then break
		if y > 25 then continue
		if y == self.top then
			c = text.backColor
		else
			c = text.cellColor(self.x, y)
			c = "#00" + c[3:]  // (reduce Red to zero)
			c = color.lerp(c, text.backColor, 0.1)
		end if
		text.setCellColor self.x, y, c
	end for
end function

// Keep a list of all the active drops
drops = []

// Main loop
text.clear
while not key.pressed("escape")
	// every now and then, add a new drop
	if rnd < 0.25 then
		noob = new Drop
		noob.init
		for d in drops
			if d.x == noob.x and d.top > 24 then
				// ensure drop tails don't overlap new drops,
				// at least initially
				d.length = 24 - d.y
			end if
		end for
		drops.push noob
	end if
	
	// update all the existing drops
	for drop in drops
		drop.update
	end for
	
	// filter out any drops that are done
	if drops then
		for i in range(drops.len-1)
			if drops[i].top < 0 then drops.remove i
		end for
	end if
	
	yield
end while
key.clear

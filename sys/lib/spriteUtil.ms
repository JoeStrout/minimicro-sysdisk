// --- spriteUtil.ms ---
// Sprite helpers
Sprite.Create = function(img)
	s = new Sprite
	if img isa Image then s.image = img
	if img isa string then s.image = file.loadImage(img)
	return s
end function

Sprite.setImage = function(img)
	self.image = img
	return self
end function

Sprite.setlocalBounds = function(b)
	self.localBounds = b
	return self
end function

Sprite.setBoundsFromImage = function
	if self.image then 
		b = new Bounds
		b.width = self.image.width
		b.height = self.image.height
		self.localBounds = b
	end if
	return self
end function

Sprite.setScale = function(scale)
	if scale isa list then self.scale = scale else self.scale = [scale, scale]
	return self
end function

Sprite.setPos = function(x, y, applyScale = false)
	scaleFactor_x = (1 * (not applyScale)) + (self.scale[0] * applyScale)
	scaleFactor_y = (1 * (not applyScale)) + (self.scale[1] * applyScale)
	self.x = x * scaleFactor_x
	self.y = y * scaleFactor_y
	return self
end function

Sprite.addTo = function(layer)
	if layer isa SpriteDisplay then
		layer.sprites.push self
	else
		if layer isa number then display(layer).sprites.push self
	end if
	return self
end function

Sprite.removeFrom = function(layer)
	if layer isa SpriteDisplay then
		indx = dl.sprites.indexOf(self)
		if indx then dl.sprites.remove(indx)
		return 
	end if
	dl = display(layer)
	if dl isa SpriteDisplay then
		indx = dl.sprites.indexOf(self)
		if indx then dl.sprites.remove(indx)
	end if
end function
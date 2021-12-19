import "matrixUtil"
import "mathUtil"

CardSprite = new Sprite
CardSprite.frontImage = file.loadImage("/sys/pics/cards/cardHeartsK.png")
CardSprite.backImage = file.loadImage("/sys/pics/cards/cardBack_green4.png")
CardSprite.localBounds = new Bounds
CardSprite.localBounds.width = CardSprite.frontImage.width
CardSprite.localBounds.height = CardSprite.frontImage.height
CardSprite.faceUp = 1  // range from 0 (back) to 1 (front)
CardSprite.image = CardSprite.frontImage
CardSprite.x = 480
CardSprite.y = 320
CardSprite.target = {} // may contain any of x, y, scale, and faceUp
CardSprite.speed = {}  // any of xy, scale, and faceUp
CardSprite.speed.xy = 1000 // pixels/sec
CardSprite.speed.scale = 1  // in scale units/sec
CardSprite.speed.faceUp = 2 // in flips/sec
CardSprite._lastFaceUp = -1  // (for internal use)

CardSprite.localToWorld = function(x,y)
	if self.rotation == 0 then
		return [self.x + x * self.scale,
		  self.y + y * self.scale]
	else
		ang = self.rotation * pi / 180
		sinAng = sin(ang); cosAng = cos(ang)
		x = x * self.scale; y = y * self.scale
		return [self.x + x * cosAng - y * sinAng,
		   self.y + y * cosAng + x * sinAng]
	end if
end function

CardSprite.update = function(dt=0.016)
	if self.target.hasIndex("x") and self.target.hasIndex("y") then
		mathUtil.moveTowardsXY self, self.target, self.speed.xy * dt
	end if
	if self.target.hasIndex("scale") then
		self.scale = mathUtil.moveTowards(self.scale,
		  self.target.scale, self.speed.scale * dt)
	end if
	if self.target.hasIndex("faceUp") then
		self.faceUp = mathUtil.moveTowards(self.faceUp,
		  self.target.faceUp, self.speed.faceUp * dt)
	end if
	if self.faceUp !=  self._lastFaceUp then
		f = self.faceUp % 2; if f < 0 then f = f + 2
		if f < 0.5 or f > 1.5 then
			self.image = self.backImage
		else
			self.image = self.frontImage
		end if
		theta = pi * f
		h = self.image.height / 2
		w = self.image.width / 2
		c = []
		if f <= 1 then
			c.push self.localToWorld(-w * cos(theta), -h - sin(theta) * w/2)
			c.push self.localToWorld( w * cos(theta), -h)
			c.push self.localToWorld( w * cos(theta),  h)
			c.push self.localToWorld(-w * cos(theta),  h + sin(theta) * w/2)
		else
			c.push self.localToWorld(-w * cos(theta), -h)
			c.push self.localToWorld( w * cos(theta), -h + sin(theta) * w/2)
			c.push self.localToWorld( w * cos(theta),  h - sin(theta) * w/2)
			c.push self.localToWorld(-w * cos(theta),  h)
		end if
		if f > 0.5 and f < 1.5 then
			// swap left-right, otherwise the image appears backwards
			temp = c[0]; c[0] = c[1]; c[1] = temp
			temp = c[2]; c[2] = c[3]; c[3] = temp			
		end if
		//print c
		self.setCorners c
		self._lastFaceUp = self.faceUp
	end if
end function

demo = function
	clear
	
	card = new CardSprite
	display(4).sprites.push card
	
	card.faceUp = 0
	text.row = 2; text.column = 27; print "Click to flip!"
	origTextColor = text.color
	while true
		card.update
		
		if mouse.button and card.contains(mouse) then
			if true then
				// flip the card (back and forth)
				card.target.faceUp = (card.faceUp < 0.5)
			else
				// flip the card (always the same way)
				card.target.faceUp = floor(card.faceUp) + 1
			end if
			
			text.color = color.gray
			text.row = 1; text.column = 23
			print "card.target.faceUp = " + card.target.faceUp
			text.color = origTextColor
		end if
		if key.available then
			k = key.get.code
			if k == 17 then  // left
				card.rotation = card.rotation + 10
			else if k == 18 then // right
				card.rotation = card.rotation - 10
			else if k == 19 then // up
				card.scale = card.scale / 0.9
			else if k == 20 then // down
				card.scale = card.scale * 0.9
			else if k == 27 then // esc
				return
			end if
		end if
		yield
	end while
end function

if locals == globals then demo

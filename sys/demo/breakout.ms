// BREAKOUT!  Use the paddle to hit the ball into the bricks.
// Break them all and you win!

import "mathUtil"
import "listUtil"

// Set up displays
clear
display(7).color = color.yellow
display(6).mode = displayMode.pixel
bg = display(6)
gfx.clear color.black, 960+10, 640+10
gfx.fillRect 960, 0, 10, 650, color.yellow
spriteDisp = display(4)

// Prepare sprites
ball = new Sprite
ball.image = file.loadImage("/sys/pics/shapes/Circle.png")
ball.scale = 0.2
ball.x = 480
ball.y = 35
ball.vx = 0  // velocity in pixels/frame
ball.vy = 0
ball.targetSpeed = 20  // (vary this with difficulty level)
ball.tail = []
spriteDisp.sprites.push ball

paddle = new Sprite
paddle.image = file.loadImage("/sys/pics/Block4.png")
paddle.scale = [0.5, 0.25]
paddle.x = 480
paddle.y = 20
paddle.poly = []
spriteDisp.sprites.push paddle

//gfx.drawPoly paddle.poly, color.orange

// Prepare arena
bg.clear "#000066"
for y in range(0, 640, 100)
	bg.line 0, y, 960, y, "#000022"
	bg.line 0, y-1, 960, y-1, "#4444AA"
end for
for x in range(0, 960, 100)
	bg.line x, 0, x, 640, "#000022"
	bg.line x+1, 0, x+1, 640, "#4444AA"
end for	

arenaBounds = [[10,-100], [10,620], [20,630],
  [940,630], [950, 620], [950,-100]]
outerPoly = arenaBounds + [[960,0], [960,640], [0,640], [0,0]]
gfx.clear color.clear
gfx.fillPoly outerPoly, color.yellow
obstacles = []
obstacles.push [[10,320-80], [40,320], [10,320+80]]
obstacles.push [[950,320-80], [960-40,320], [950,320+80]]
for ob in obstacles
	gfx.fillPoly ob, color.yellow
end for

// Prepare sounds
boop = new Sound
boop.init 0.1, [19, 220], [1, 0.8, 0.8, 0.8, 0], Sound.triangleWave
boop.fadeIn = 0.01; boop.fadeOut = 0.01

loseSound = new Sound
loseSound.init 1, [220, 16.352], [1, 0.8, 0.8, 0.8, 0], Sound.triangleWave

// ===== Ball behavior =====
ball.update = function
	self.tail.push [self.x, self.y]
	if self.tail.len > 20 then self.tail.pull
	self.drawTail
	self.x += self.vx
	self.y += self.vy
	bounced = false
	boopPitch = 1
	for ob in obstacles
		bounced = bounced or mathUtil.bounceOffPoly(self, ob)
	end for
	bounced = bounced or mathUtil.bounceOffPoly(self, arenaBounds)
	if bounced then
		boopPitch = 2
	else
		bounced = mathUtil.bounceOffPoly(self, paddle.poly, paddle.prevPoly)		
	end if
	
	if bounced then
		self.playBoop boopPitch
		speed = sqrt(ball.vx^2 + ball.vy^2)
		factor = 1 + 0.1 * (speed < self.targetSpeed)
		           - 0.1 * (speed > self.targetSpeed)
		self.vx *= factor
		self.vy *= factor
	end if
end function

ball.playBoop = function(pitch=1)
	boop.play 1, (self.x - 480)/400, pitch
end function

ball.drawTail = function
	x = self.x; y = self.y
	maxi = self.tail.len - 1
	for i in range(maxi, 0, -1)
		c = color.lerp("#00000000", "#AAAAAAFF", i/maxi)
		p = self.tail[i]
		gfx.line x, y, p[0], p[1], c
		x = p[0]; y = p[1]
	end for
end function

// ===== Paddle behavior =====
paddle.calcPoly = function
	x = self.x; y = self.y
	w = self.image.width/2 * self.scale[0]
	h = self.image.height/2 * self.scale[1]
	return [
	[x-w, y-h], [x-w, y+h-3], [x-w+5, y+h],
	[x+w-5, y+h], [x+w, y+h-3], [x+w, y-h]]
end function

paddle.update = function
	self.x = mathUtil.clamp(mouse.x, 74, 960-74)
	self.y = mathUtil.clamp(mouse.y, 0, 200)
	self.prevPoly = self.poly
	self.poly = self.calcPoly
end function

// ===== Particle Behavior =====
Particle = new Sprite
Particle.image = file.loadImage("/sys/pics/Block.png")
Particle.scale = 0.3
Particle.Instances = []
Particle.age = 0

Particle.Make = function(x, y, vx, vy, tint="#FFFFFF")
	p = new Particle
	p.x = x; p.y = y
	p.vx = vx; p.vy = vy
	p.tint = tint[:7] + "CC"
	spriteDisp.sprites.push p
	Particle.Instances.push p
end function	

Particle.update = function
	self.vy -= 1
	self.x += self.vx
	self.y += self.vy
	self.age += 1
	if self.age > 50 then
		spriteDisp.sprites.removeVal self
		Particle.Instances.removeVal self
	end if
end function

Particle.UpdateAll = function
	for i in range(Particle.Instances.len - 1, 0, -1)
		Particle.Instances[i].update
	end for
end function

// ===== Block Behavior =====
Block = new Sprite
Block.image = file.loadImage("/sys/pics/Block3.png")
Block.scale = 0.5
Block.width = Block.image.width * Block.scale
Block.height = Block.image.height * Block.scale
Block.localBounds = new Bounds
Block.localBounds.width = Block.image.width
Block.localBounds.height = Block.image.height
ROWS = 6
COLS = 9

colorPerRow = ["#DD00FFFF", "#8F9DFFFF", "#00D800FF", 
               "#FFFF00FF", "#FF7800FF", "#FF4444FF"]

xPosForCol = function(col)
	return 480 - (COLS/2 - col - 0.5) * Block.width
end function

colForXPos = function(x)
	return round(COLS/2 - 0.5 - (480 - x) / Block.width)
end function

yPosForRow = function(row)
	return 400 + row * Block.height
end function

rowForYPos = function(y)
	return round((y - 400) / Block.height)
end function

setupBlocks = function
	outer.blocks = list.init2d(COLS, ROWS)
	w = Block.image.width * Block.scale
	h = Block.image.height * Block.scale
	for row in range(0, ROWS-1)
		for col in range(0, COLS-1)
			b = new Block
			b.x = xPosForCol(col)
			b.y = yPosForRow(row)
			b.tint = colorPerRow[row]
			blocks[col][row] = b
			spriteDisp.sprites.push b
		end for
	end for	
end function
setupBlocks

checkForHitBlocks = function
	vx = ball.vx
	vy = ball.vy
	if vy > 0 then rows = range(0,ROWS-1) else rows = range(ROWS-1,0)
	if vx > 0 then cols = range(0,COLS-1) else cols = range(COLS-1,0)
	for row in rows
		for col in cols
			b = blocks[col][row]
			if b == null then continue
			if mathUtil.bounceOffPoly(ball, b.worldBounds.corners) then
				spriteDisp.sprites.removeVal b
				blocks[col][row] = null
				ball.playBoop 4
				Particle.Make b.x, b.y, vx-8, vy+8, b.tint
				Particle.Make b.x, b.y, vx+8, vy+8, b.tint
				Particle.Make b.x, b.y, vx-8, vy-8, b.tint
				Particle.Make b.x, b.y, vx+8, vy-8, b.tint
				speed = sqrt(ball.vx^2 + ball.vy^2)
				globals.score += round(10*row + speed)
				globals.bricksBroken += 1
				drawScoreAndLives
				if bricksBroken >= ROWS * COLS then endGame
				break
			end if
		end for
	end for
end function

// ===== Global Functions =====
bricksBroken = 0
score = 0
lives = 3

drawScoreAndLives = function
	text.row = 25
	text.color = "#4444FF"
	text.column = 2; print "BALLS: " + lives, ""
	s = ("000000" + score)[-6:]
	text.column = 54; print "SCORE:" + s
end function

printCenter = function(s)
	text.row = 13
	text.column = 34 - s.len/2
	text.color = "#AAAAFF"
	print s
end function

endBall = function
	loseSound.play
	if ball.y > -10 then ball.y = -10
	ball.vx = 0; ball.vy = 0
	for i in range(60)
		ball.update
		Particle.UpdateAll
		yield
	end for
	ball.tail = []
end function

endGame = function
	printCenter "You Win!"
	ball.vx = 0; ball.vy = 0
	snd = new Sound
	snd.init 0.2, 130.818, [1, 0.8, 0.8, 0.8, 0], Sound.triangleWave
	snd.fadeIn = 0.01
	for note in [60, 64, 67, 72]
		snd.play 1, 0, noteFreq(note) / noteFreq(60)
		for i in range(5)
			ball.update
			Particle.UpdateAll
			yield
		end for
	end for
	text.row = 1
	text.color = color.orange
	exit
end function

startNextBall = function
	globals.lives -= 1
	if lives < 0 then
		printCenter "Game Over!"
		text.row = 1
		text.color = color.orange
		exit
	end if
	drawScoreAndLives
	while mouse.button; yield; end while
	printCenter "Ready!"
	while not mouse.button
		paddle.update
		ball.x = paddle.x; ball.y = paddle.y + 15
		Particle.UpdateAll
		yield
	end  while
	text.clear
	drawScoreAndLives

	ball.vx = rnd * 20 - 10
	ball.vy = 12
end function

// Main loop
startNextBall
while true
	yield
	paddle.update
	ball.update
	checkForHitBlocks
	Particle.UpdateAll
	if ball.y < 0 then
		endBall
		startNextBall
	end if
end while

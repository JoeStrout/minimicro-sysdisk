// A basic tower defense game.
// This builds on and extends the simpler "balloons" demo.

import "listUtil"
import "textUtil"
import "pathUtil"
import "mathUtil"

pop = file.loadSound("/sys/sounds/pop.wav")
burstImg = file.loadImage("/sys/pics/Burst.png")

clear
gfx.clear color.clear

display(6).mode = displayMode.tile
tiles = display(6)
tiles.tileSet = file.loadImage("/sys/pics/TwoCornerTiles.png")
tiles.tileSetTileSize = tiles.tileSet.width/16
tiles.cellSize = 64
tiles.extent = [15, 10]
tiles.clear null
tiles.scrollX = 0; tiles.scrollY = 0
tiles.overlap = 0

display(5).mode = displayMode.tile
pathTiles = display(5)
pathTiles.tileSet = tiles.tileSet
pathTiles.tileSetTileSize = tiles.tileSetTileSize
pathTiles.cellSize = 64
pathTiles.extent = [13, 10]
pathTiles.clear null
pathTiles.scrollX = 0; pathTiles.scrollY = 0
pathTiles.overlap = tiles.overlap

sprites = display(4).sprites

display(7).mode = displayMode.pixel
display(7).fillRect 0, 0, 13*64, 10*64, "#939FFFFF"

levelMap = file.readLines("/usr/data/td-maps.txt")
if levelMap == null then levelMap = file.readLines("/sys/data/td-maps.txt")
if not levelMap[-1] then levelMap.remove -1
levelMap.reverse // (since coordinates are bottom-up)
mapH = levelMap.len; mapW = levelMap[0].len
entrance = {"x":0, "y":0}

inBounds = function(x,y)
	return x >= 0 and x < mapW and y >= 0 and y < mapH
end function

isLand = function(x,y)
	return not inBounds(x,y) or levelMap[y][x] != "w"
end function

isPath = function(x,y)
	if inBounds(x,y) then return levelMap[y][x] == "#"
	if x < 0 then x = 0
	if x >= mapW then x = mapW-1
	if y < 0 then y = 0
	if y >= mapH then y = mapH-1
	return levelMap[y][x] == "#"
end function

isValidTowerPos = function(x,y)
	return inBounds(x,y) and isLand(x,y) and not isPath(x,y)
end function

prepareMap = function
	// Start by finding the entrance
	for y in range(0, mapH-1)
		for x in range(0, mapW-1)
			if levelMap[y][x] == "*" then
				// entrance point!
				entrance.x = x; entrance.y = y
				levelMap[y] = levelMap[y].replace("*", "#")
			end if
		end for
	end for
	if entrance.x == 0 then entrance.x = -1
	if entrance.x == mapW-1 then entrance.x = mapW
	if entrance.y == 0 then entrance.y = -1
	if entrance.y == mapH-1 then entrance.y = mapH
	
	// Then, build the tile display
	for y in range(0, mapH-1)
		for x in range(0, mapW-1)
			idx = 0 +
			 1 * isLand(x+1,y+1) + 2 * isLand(x+1,y) +
			 4 * isLand(x,y) + 8 * isLand(x,y+1)
			tiles.setCell x, y, idx
			tiles.setCellTint x, y, "#338833"
			idx = 16 +
			 1 * isPath(x+1,y+1) + 2 * isPath(x+1,y) +
			 4 * isPath(x,y) + 8 * isPath(x,y+1)
			pathTiles.setCell x, y, idx
			pathTiles.setCellTint x, y, "#D0A700FF"
		end for
		for x in [13,14]
			tiles.setCell x, y, 31
			tiles.setCellTint x, y, color.black
		end for
	end for	
end function

// Build a path, starting at the entrance, and following path
// points in the map (choosing randomly at any branches) until
// we exit the bounds of the map.
getPath = function
	path = []
	x = entrance.x; y = entrance.y
	path.push [x*64, y*64]
	prevx = -1; prevy = -1
	while true
		// find valid path points around the current position
		possible = []
		for n in [[x+1,y], [x-1,y], [x,y+1], [x,y-1]]
			if not inBounds(n[0],n[1]) or not isPath(n[0],n[1]) then continue
			if n[0] == prevx and n[1] == prevy then continue
			
			possible.push n
		end for
		// if none possible, then we must be done
		if not possible then break
		choice = possible.any
		prevx = x; prevy = y
		x = choice[0]; y = choice[1]
		path.push [x*64, y*64]		
	end while
	return path
end function

//==================================================
// Balloon class
//==================================================
Balloon = new Sprite
Balloon.image = file.loadImage("/sys/pics/Balloon.png")
Balloon.speed = 50
Balloon.burstTime = null
Balloon.level = 0

Balloon.init = function(level, path)
	self.pathPoint = pathUtil.PathPoint.make(path)
	self.level = level
	if level == 0 then
		self.tint = color.red
		self.scale = 0.9
		self.speed = 25
	else if level == 1 then
		self.tint = color.blue
		self.speed = 35
	else
		self.tint = color.yellow
		self.scale = 1.1
		self.speed = 70
	end if
	self.x = self.pathPoint.position[0]
	self.y = self.pathPoint.position[1]
	sprites.push self
	balloons.push self
end function

Balloon.remove = function
	sprites.removeVal self
	balloons.removeVal self
end function

Balloon.update = function(dt=0.1)
	if self.burstTime then
		if time - self.burstTime > 0.1 then self.remove
		return
	end if
	self.pathPoint.advance self.speed * dt
	self.x = self.pathPoint.position[0]
	self.y = self.pathPoint.position[1]
	if self.pathPoint.isAtEnd then
		self.remove
		loseLife self.level+1
	end if
end function

Balloon.pop = function
	pop.play
	self.image = burstImg
	self.tint = color.lerp(self.tint, color.white, 0.7)
	self.rotation = 360*rnd
	self.burstTime = time
	addCash cashPerPop
	
	if self.level > 0 then
		noob = new Balloon
		noob.init self.level-1, self.pathPoint.path
		noob.pathPoint = self.pathPoint
	end if
end function

balloons = []

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
	sprites.push self
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
	darts.removeVal self
	sprites.removeVal self
end function

darts = []

//==================================================
// Tower class
//==================================================

Tower = new Sprite
Tower.image = file.loadImage("/sys/pics/arrows/circleHat.png")
Tower.tint = color.orange
Tower.scale = 0.5
Tower.nextFireTime = 0.5
Tower.gotTarget = false

Tower.init = function
	towers.push self
end function

Tower.faceNearest = function
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
	self.gotTarget = (bestDist < 300)
end function

Tower.update = function
	self.faceNearest
	if time < self.nextFireTime then return
	// Fire!
	self.nextFireTime = time + 0.5
	if self.gotTarget then
		d = new Dart
		d.init self
	end if
end function

towers = []

//==================================================
// Buttons (and other stuff on right side of screen)
//==================================================

drawButton = function(caption, row, pressed=false, enabled=true)
	text.row = row; text.column = 60
	if pressed then c = "#8888CC" else c = "#CCCCFF"
	if not enabled then c = "#888888"
	text.color = c
	textUtil.drawButton padCenter(caption, 5)
end function

eraseButton = function(row)
	text.row = row; text.column = 60
	print " "*8
end function

buyButtonRow = 10
startButtonRow = 6
quitButtonRow = 1

drawStartButton = function(pressed=false, enabled=true)
	drawButton "START", startButtonRow, pressed, enabled
end function

hideStartButton = function; eraseButton startButtonRow; end function

drawBuyButton = function(pressed=false, enabled=true)
	drawButton "BUY", buyButtonRow, pressed, enabled
end function

drawQuitButton = function(pressed=false, enabled=true)
	drawButton "QUIT" + char(8594), quitButtonRow, pressed, enabled
end function

trackButton = function(row, drawFunc)
	while mouse.button
		hit = (textUtil.textRow(mouse.y) == row and textUtil.textCol(mouse.x) >= 60)
		drawFunc hit
		yield
	end while
	drawFunc false
	return hit
end function

padCenter = function(s, width=8)
	s = str(s)
	s = " " * floor((width-s.len)/2) + s
	s += " " * (width-s.len)
	return s
end function

drawLabeledValue = function(label, value, row)
	text.color = "#CCCCFF"
	text.row = row; text.column = 60
	print padCenter(label)
	text.row = row-1; text.column = 60
	print padCenter(value)
end function

drawRound = function; drawLabeledValue "ROUND:", roundNum, 24; end function
drawLives = function; drawLabeledValue "LIVES:", lives, 20; end function
drawMoney = function; drawLabeledValue "MONEY:", "$"+money, 16; end function

//==================================================
// Game utility functions
//==================================================

addCash = function(amountToAdd)
	globals.money += amountToAdd
	drawMoney
	drawBuyButton false, money >= towerCost
end function

loseLife = function(livesToLose=1)
	globals.lives -= livesToLose
	if lives < 0 then globals.lives = 0
	drawLives
	if lives <= 0 then quitGame
end function

prepareRound = function
	drawLives
	globals.roundNum += 1
	drawRound
	addCash cashPerRound
	drawStartButton
	globals.roundInProgress = false
	
	// Queue up balloons to come, based on the round number.
	// Here is where you could get creative and bunch them up or whatever.
	// Each entry in this list is a balloon level (1-N) and delay time, in frames.
	globals.waiting = []
	for i in range(1, 4 + 2^roundNum)
		level = floor(rnd * roundNum); if level > 2 then level = 2
		delay = round(120 / roundNum)
		waiting.push [level, delay]
	end for
	globals.framesTillNextBalloon = 60
	for dart in darts
		sprites.removeVal dart
	end for
	globals.darts = []
end function

startRound = function
	hideStartButton
	globals.roundInProgress = true
	for tower in towers
		tower.nextFireTime = time + rnd
	end for
end function

continueRound = function
	if not waiting and not balloons then
		prepareRound
		return
	end if

	for balloon in balloons; balloon.update; end for
	for dart in darts; dart.update; end for
	for tower in towers; tower.update; end for

	if waiting then
		globals.framesTillNextBalloon -= 1
		if framesTillNextBalloon <= 0 then enterBalloon
	end if
end function

enterBalloon = function
	balloonLevel = waiting.pull[0]
	if waiting then globals.framesTillNextBalloon = waiting[0][1]
	noob = new Balloon
	noob.init(balloonLevel, getPath)
end function	

buyTower = function
	addCash -towerCost
	globals.pendingTower = new Tower
	sprites.push pendingTower
end function

quitGame = function
	text.row = 1; text.column = 0
	text.color = color.orange
	print "Thanks for playing!"
	exit
end function

checkButtons = function
	if not mouse.button then return
	if textUtil.textCol(mouse.x) < 60 then return
	row = textUtil.textRow(mouse.y)
	if row == startButtonRow and not roundInProgress then
		if trackButton(startButtonRow, @drawStartButton) then startRound
	else if row == buyButtonRow and money >= towerCost then
		if trackButton(buyButtonRow, @drawBuyButton) then buyTower
	else if row == quitButtonRow then
		if trackButton(quitButtonRow, @drawQuitButton) then quitGame
	end if
end function

placeTower = function
	col = round(mouse.x/64); row = round(mouse.y/64)
	pendingTower.x = col*64; pendingTower.y = row*64
	if isValidTowerPos(col, row) then
		pendingTower.tint = color.orange
		if mouse.button then
			pendingTower.init
			globals.pendingTower = null
		end if
	else
		pendingTower.tint = color.lerp(color.orange, "#88888800")
	end if	
end function

//==================================================
// Main program
//==================================================

prepareMap

roundNum = 0
lives = 100
money = 50
towerCost = 100
cashPerPop = 5
cashPerRound = 50

drawQuitButton
drawLabeledValue "TOWER:", "$"+towerCost, 12
pendingTower = null		// sprite of tower to set, when tower is bought but not yet placed
prepareRound

mainLoop = function
	while true
		if pendingTower then placeTower else checkButtons
		if roundInProgress then continueRound
		yield
	end while
end function

mainLoop

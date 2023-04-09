// Quadris!  Rotate and shift the four-block shapes to make complete
// lines.  Bonus points for completing multiple lines at once, or for
// rushing/dropping a piece down.

import "listUtil"
import "qa"
import "mathUtil"

clear
display(4).mode = displayMode.sprite
spr = display(4)

kBinWidth = 10
kBinHeight = 17

// Game option: if kSkootch is true, we draw some in-between frames when a piece
// moves to produce a smoother motion.  If false, they only move in whole grid
// cell increments.
kSkootch = true

inBounds = function(column, row)
	return column >= 0 and column < kBinWidth and
	  row >= 0 and row < kBinHeight
end function

xForColumn = function(column)
	return 100 + column * Block.image.width
end function

yForRow = function(row)
	return 40 + row * Block.image.height
end function

blockAtlas = file.loadImage("/usr/pics/blockTiles.png")
if not blockAtlas then blockAtlas = file.loadImage("/sys/pics/blockTiles.png")

Block = new Sprite
Block.images = []
for i in range(0,15)
	Block.images.push blockAtlas.getImage(
	 (i%4) * 32, (3-floor(i/4)) * 32, 32, 32)
end for
Block.connN = false  // (connected to neighboring block
Block.connE = false  //  in any direction that's true)
Block.connS = false
Block.connW = false
Block.selectImage = function
	self.image = Block.images[
	  self.connN + self.connE*2 + self.connS*4 + self.connW*8]
end function
Block.image = Block.images[0]
Block.row = -1
Block.column = -1
Block.targetXY = null
Block.targetTint = null
Block.update = function(dt=0)
	if self.targetXY then
		mathUtil.moveTowardsXY(self, self.targetXY, 8)
		if self.x == self.targetXY.x and self.y == self.targetXY.y then
			self.targetXY = null
		end if
	end if
	if self.targetTint then
		self.tint = color.lerp(self.tint, self.targetTint, 0.1)
	end if
end function
Block.setPosition = function(column, row)	
	self.column = column
	self.row = row
	self.x = xForColumn(self.column)
	self.y = yForRow(self.row)	
	self.targetXY = null
end function
Block.setTarget = function(column, row)
	self.column = column
	self.row = row
	self.targetXY = {"x":xForColumn(self.column), "y":yForRow(self.row)	}
end function

softDropKey = false  // true when down-arrow key was pressed
hardDropKey = false

softDropKeyDown = function
	return key.pressed("down") and not softDropKey
end function

hardDropKeyDown = function
	return (key.pressed("up") or key.pressed("space")) and not hardDropKey
end function

bin = list.init2d(kBinWidth, kBinHeight)
updateBin = function
	for col in bin.indexes
		for row in bin[col].indexes
			b = bin[col][row]
			if b then b.update
		end for
	end for
end function

timePerFallStep = function
	return 5 / (5 + level)
end function

Shape = {}
Shape.row = 0
Shape.column = 0
Shape.blocks = null  // list of four Blocks in this shape
Shape.blockPos = null  // list of [dcol, drow] block positions
Shape.tint = color.white
Shape.fallDelay = 0   // how much time until we fall 1 step
Shape.done = false   // block has hit the bottom, or "landed"

Shape.update = function(dt)
	if hardDropKeyDown then
		self.hardDrop
		return
	end if
	self.fallDelay = self.fallDelay - dt
	if self.fallDelay > 0 and not softDropKeyDown then return
	if softDropKeyDown then addToScore 1, 0
	self.fallOneStep
	delayTime = timePerFallStep
	if (softDropKey or softDropKeyDown) and self.softDropOK then
		delayTime = delayTime / 10
	end if
	self.fallDelay = self.fallDelay + delayTime
	if not softDropKey then self.softDropOK = true
end function

Shape.fallOneStep = function
	// try moving down one row
	self.row = self.row - 1
	// check if we hit bottom (or an existing block)
	if self.hitsSomething then
		self.row = self.row + 1
		self.done = true
		if self.fitsInBin then
			self.storeInBin
		else
			// Game over!  (This shape does not fit on the board)
			globals.gameOver = true
			return
		end if
		return
	end if
	newRow = self.row
	if kSkootch then
		self.setPosition self.column, newRow + 0.5
		yield
	end if
	self.setPosition self.column, newRow	
end function

Shape.hardDrop = function
	// move down until we hit something
	f = 0
	while not self.done
		self.fallOneStep
		addToScore 5, 0
		f = not f
		if f then yield
	end while
end function

Shape.hitsSomething = function
	for pos in self.blockPos
		c = self.column + pos[0]
		r = self.row + pos[1]
		// check for hitting bottom
		if r < 0 then return true  // hit bottom
		// check for hitting existing blocks
		if inBounds(c,r) and bin[c][r] then return true
	end for
end function

Shape.fitsInBin = function
	for i in self.blocks.indexes
		b = self.blocks[i]
		if b.row >= kBinHeight then return false
	end for
	return true
end function

Shape.storeInBin = function
	for i in self.blocks.indexes
		b = self.blocks[i]
		bin[b.column][b.row] = b
	end for
	validate
end function

Shape.shift = function(colStep)
	for pos in self.blockPos
		newCol = self.column + colStep + pos[0]
		if newCol < 0 then colStep = colStep - newCol
		if newCol >= kBinWidth then
			colStep = colStep - (newCol - kBinWidth + 1)
		end if
	end for
	self.column = self.column + colStep
	if self.hitsSomething then
		self.column = self.column - colStep
	else
		newCol = self.column
		if kSkootch then
			self.setPosition newCol - colStep/2, self.row
			yield
		end if		
		self.setPosition newCol, self.row		
	end if
end function

Shape.rotate = function(dir=1)
	if not dir then return
	for i in range(0,3)
		offset = self.blockPos[i]
		if dir > 0 then
			self.blockPos[i] = [-offset[1], offset[0]]
		else
			self.blockPos[i] = [offset[1], -offset[0]]
		end if
	end for
	if self.hitsSomething then
		self.rotate -dir
		return
	end if
	if kSkootch then
		self.tilt -45 * dir
		yield
		self.tilt 0
	end if
	self.shift 0
	self.fixConnections
	self.setPosition self.column, self.row
end function

Shape.hasBlockAtPos = function(dcol, drow)
	for pos in self.blockPos
		if pos[0] == dcol and pos[1] == drow then return true
	end for
	return false
end function

// Set connN, connE, etc. for each of our blocks.
Shape.fixConnections = function
	for i in range(0,3)
		p = self.blockPos[i]
		b = self.blocks[i]
		b.connN = self.hasBlockAtPos(p[0], p[1]+1)
		b.connS = self.hasBlockAtPos(p[0], p[1]-1)
		b.connE = self.hasBlockAtPos(p[0]+1, p[1])
		b.connW = self.hasBlockAtPos(p[0]-1, p[1])
		b.selectImage
	end for
end function

Shape.setPosition = function(column, row)
	self.column = column
	self.row = row
	x = xForColumn(self.column)
	y = yForRow(self.row)
	for i in range(0,3)
		offset = self.blockPos[i]
		self.blocks[i].setPosition column + offset[0], row + offset[1]
	end for
end function

Shape.tilt = function(degrees)
	radians = degrees * pi/180
	for i in range(0,3)
		offset = self.blockPos[i]
		b = self.blocks[i]
		r = sqrt(offset[0]^2 + offset[1]^2) * Block.image.width
		ang = atan(offset[1], offset[0]) + radians		
		b.x = xForColumn(self.column) + r * cos(ang)
		b.y = yForRow(self.row) + r * sin(ang)
		b.rotation = degrees
	end for
end function

Shape.init = function
	self.blocks = []
	for i in range(0,3)
		b = new Block
		b.tint = self.tint
		self.blocks.push b
		spr.sprites.push b
	end for
	self.setPosition round(kBinWidth/2), kBinHeight
	self.softDropOK = not softDropKey
	self.fixConnections
	return self
end function

Shape.remove = function
	for i in range(0,3)
		spr.sprites.removeVal self.blocks[i]
	end for
end function

ShapeLine = new Shape
ShapeLine.blockPos = [[0,-1], [0,0], [0,1], [0,2]]
ShapeLine.tint = color.red

ShapeT = new Shape
ShapeT.blockPos = [[-1,0], [0,0], [1,0], [0,-1]]
ShapeT.tint = color.lime

Shape5 = new Shape
Shape5.blockPos = [[0,0], [1,0], [1,1], [0,-1]]
Shape5.tint = color.orange

ShapeS = new Shape
ShapeS.blockPos = [[1,0], [0,0], [0,1], [1,-1]]
ShapeS.tint = "#CCCCFF"

ShapeSquare = new Shape
ShapeSquare.blockPos = [[0,0], [0,1], [1,0], [1,1]]
ShapeSquare.tint = color.blue

ShapeL = new Shape
ShapeL.blockPos = [[0,0], [0,1], [0,-1], [1,-1]]
ShapeL.tint = "#FFBBDD"

ShapeInvL = new Shape
ShapeInvL.blockPos = [[0,0], [0,1], [0,-1], [-1,-1]]
ShapeInvL.tint = color.yellow

allShapes = [ShapeLine, ShapeT, Shape5, ShapeS, ShapeSquare,
ShapeL, ShapeInvL]

isCompleteLine = function(row)
	for col in range(0, kBinWidth-1)
		if not bin[col][row] then return false
	end for
	return true
end function

validate = function
	for col in range(0, kBinWidth-1)
		for row in range(0, kBinHeight-1)
			b = bin[col][row]
			if not b then continue
			qa.assert b.column == col and b.row == row
			qa.assert spr.sprites.indexOf(b) != null
			// qa.assert b.x == xForColumn(col)
			// qa.assert b.y == yForRow(row)
		end for
	end for
end function

vanishingBlocks = []
updateVanishingBlocks = function
	for i in range(vanishingBlocks.len-1)
		b = vanishingBlocks[i]
		t = time - b.startTime
		if t < 0 then continue
		if t < 0.3 then
			b.tint = color.lerp(b.startTint, color.white, t*3)
		else
			b.tint = color.lerp(color.white, b.startTint[:7]+"00", (t-0.3)*3)
			if t > 0.6 then
				spr.sprites.removeVal b
				vanishingBlocks.remove i
			end if
		end if
	end for
	return vanishingBlocks.len > 0
end function

clearLine = function(row)
	validate
	// iterate over all columns in the game...
	for col in range(0, kBinWidth-1)
		b = bin[col][row]
		if not b then continue
		// start this block vanishing
		vanishingBlocks.push b
		b.startTint = b.tint
		b.startTime = time + 0.1 * abs(col - kBinWidth/2)
		// remove it from the bin data structure
		bin[col].remove row
		bin[col].push null
		// make sure all the blocks above move to their new location
		for r in range(row, kBinHeight-1)
			b = bin[col][r]
			if b then b.setTarget b.column, r
		end for
		// disconnect any blocks above or below from the deleted block
		if row < kBinHeight-1 then
			b = bin[col][row]
			if b then
				b.connS = false; b.selectImage
			end if
		end if
		if row > 0 then
			b = bin[col][row-1]
			if b then
				b.connN = false; b.selectImage				
			end if
		end if
	end for
	validate
end function

clearCompleteLines = function
	clearCount = 0
	for row in range(kBinHeight-1, 0)
		if isCompleteLine(row) then
			clearLine row
			clearCount = clearCount + 1
		end if
	end for
	if not clearCount then return
	while updateVanishingBlocks; end while
	pointValues = [0, 40, 100, 300, 1200]
	addToScore pointValues[clearCount], clearCount
	for i in range(4 * clearCount)
		updateBin
		yield
	end for
end function

// Draw the bin
// left side
gfx.line xForColumn(0)-24, yForRow(0)-24,
xForColumn(0)-24, yForRow(kBinHeight-1), color.silver, 16
// right side
gfx.line xForColumn(kBinWidth-1)+24, yForRow(0)-24,
xForColumn(kBinWidth-1)+24, yForRow(kBinHeight-1), color.silver, 16
// bottom
gfx.line xForColumn(0)-16, yForRow(0)-24,
xForColumn(kBinWidth-1)+16, yForRow(0)-24, color.silver, 16

drawScore = function
	s = ("00000" + score)[-6:]
	text.row = 25; text.column = 54
	text.color = color.gray; print "SCORE: ", ""
	text.color = color.white; print s
	text.column = 54; text.color = color.gray; print "LINES: ", ""
	text.color = color.white; print lines
	text.column = 54; text.color = color.gray; print "LEVEL: ", ""
	text.color = color.white; print level
end function

drawHelp = function
	text.row = 15; text.color = color.gray
	text.column = 54; print "CONTROLS:"
	print
	text.column = 50; print "Left/Right: Move"
	text.column = 50; print "Shift/Alt: Rotate"
	text.column = 50; print "Down: Rush"
	text.column = 50; print "Spacebar: Drop"
	print
	text.column = 50; print "Try gamepad too!"
end function

addToScore = function(points, lines)
	globals.score = score + points
	globals.lines = globals.lines + lines
	globals.level = ceil(globals.lines/10)
	drawScore
end function

nextShapeOnScreen = null
drawNextShape = function(shape)
	if nextShapeOnScreen then nextShapeOnScreen.remove
	globals.nextShapeOnScreen = shape	
	shape.init
	shape.setPosition 15, 8
end function
gfx.print "NEXT", xForColumn(15)-18, yForRow(8)+80, color.silver, "small"

pickNextShape = function
	nextShapeClass = shapesBag.pop
	globals.currentShape = new nextShapeClass
	currentShape.init
	if not shapesBag then
		globals.shapesBag = allShapes[:]
		shapesBag.shuffle
	end if
	drawNextShape shapesBag[-1]
end function

// Main Loop
prevTime = time
prevHorInp = 0
prevRotInp = 0
gameOver = false
drawHelp
score = 0
lines = 0
level = 1
drawScore
shapesBag = allShapes[:]; shapesBag.shuffle
pickNextShape

while not gameOver
	now = time
	dt = now - prevTime
	prevTime = now
	key.clear
	
	// check inputs
	horInp = round(key.axis("Horizontal"))
	if horInp != prevHorInp then
		currentShape.shift horInp
		prevHorInp = horInp
	end if
	rotInp = key.pressed("left shift") + key.pressed("right shift") -
			 key.pressed("left alt") - key.pressed("right alt")
	if rotInp != prevRotInp then
		currentShape.rotate rotInp
		prevRotInp = rotInp
	end if
	// update the shape
	currentShape.update dt
	if currentShape.done then
		clearCompleteLines
		pickNextShape
		prevTime = time
	end if
	// update keys
	softDropKey = key.pressed("down")	
	hardDropKey = key.pressed("up") or key.pressed("space")	
	
	yield
end while

text.row = 12; text.column = 30
print "GAME OVER"
wait
key.clear
text.row = 1


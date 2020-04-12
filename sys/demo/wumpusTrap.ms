// Trap the wumpus!
// Inspired by:
//   https://www.gamedesign.jp/flash/chatnoir/chatnoir.html
//
// Demonstrates use of TileDisplay.
//
// Click light-colored hexes to darken them.
// Surround the wumpus with dark hexes before it gets away!

clear

// Prepare the hex grid
tiles = file.loadImage("/sys/pics/TileShapes.png")
display(7).mode = displayMode.solidColor
display(7).color = "#000044"
gfx.clear color.clear
display(6).mode = displayMode.tile
grid = display(6)
grid.tileSet = tiles
grid.tileSetTileSize = 64
grid.cellSize = 64
grid.oddColOffset = 0
grid.oddRowOffset = 0.5  // makes a hex grid by rows!
grid.overlap = [0, 10]
grid.extent = [11,11]
grid.scrollX = -100
grid.scrollY = -32
spacing = [grid.cellSize - grid.overlap[0], 
   grid.cellSize - grid.overlap[1]]

freeCell = 33
blockedCell = 36

grid.clear
grid.setCell range(0,10), range(0,10), freeCell

// Make a couple of functions to convert between hex cell
// coordinates, and pixel coordinates.
xForCell = function(col, row)
	x = grid.cellSize*0.5 + col * spacing[0] - grid.scrollX
	x = x + (row%2) * grid.oddRowOffset * spacing[0]
	return x
end function

yForCell = function(col, row)
	y = grid.cellSize*0.5 + row * spacing[1] - grid.scrollY
	return y
end function

colForXY = function(x, y)
	row = rowForXY(x, y)
	col = (x + grid.scrollX - grid.cellSize*0.5 - 
	(row%2)*grid.oddRowOffset*spacing[0]) / spacing[0]
	return round(col)
end function

rowForXY = function(x, y)
	row = (y + grid.scrollY - grid.cellSize*0.5) / spacing[1]
	return round(row)
end function

// Handy dandy function to return a value closer to
// a target value, but by only so much.
moveTowards = function(x, target, amount)
	diff = abs(x - target)
	if diff < amount then return target
	return x + amount * sign(target - x)
end function

// Prepare the wumpus.
wumpus = new Sprite
wumpus.image = file.loadImage("/sys/pics/Wumpus.png")
wumpus.scale = 0.75
display(4).mode = displayMode.sprite
display(4).clear
display(4).sprites.push wumpus
wumpus.col = 5
wumpus.row = 5
wumpus.x = xForCell(wumpus.col, wumpus.row)
wumpus.y = yForCell(wumpus.col, wumpus.row) + 20
wumpus.moving = false
wumpus.update = function()
	targetX = xForCell(self.col, self.row)
	targetY = yForCell(self.col, self.row) + 10
	self.x = moveTowards(self.x, targetX, 3.895)
	self.y = moveTowards(self.y, targetY, 3)
	self.moving = (self.x != targetX or self.y != targetY)
end function

// Randomly darken a set of cells (not including
// where the wumpus is).
for i in range(0, 6 + 11 * rnd)
	row = floor(rnd*11)
	col = floor(rnd*11)
	if row == wumpus.row and col == wumpus.col then continue
	grid.setCell col, row, blockedCell
end for

// Get the neighbors of any given hex cell.
// Slightly tricky since it depends on which row you're on.
neighbors = function(col, row)
	result = [[col-1,row], [col+1,row]]
	if row%2 then
		result = result + [[col,row-1], [col+1,row-1]]
		result = result + [[col,row+1], [col+1,row+1]]
	else
		result = result + [[col-1,row-1], [col,row-1]]
		result = result + [[col-1,row+1], [col,row+1]]
	end if
	// Remove any neighbors which are blocked.
	for i in range(result.len-1, 0)
		if grid.cell(result[i][0], result[i][1]) == blockedCell then
			result.remove i
		end if
	end for
	return result
end function

// Function to calculate the distance from every cell
// to the nearest edge.
distMap = {}
updateDistMap = function()
	//gfx.clear color.clear
	//gfx.color = color.red
	toDo = []
	// initialize distances to 0 out of bounds, 999 everywhere else;
	// set our initial to-do list to all the out-of-bounds positions
	for row in range(-1,11)
		for col in range(-1,11)
			pos = [col, row]
			if row < 0 or row > 10 or col < 0 or col > 10 then
				distMap[pos] = 0
				toDo.push pos
			else
				distMap[pos] = 999
			end if
		end for
	end for
	// for each pos on the to-do list, for any free neighbor
	// whose distance is currently set too big, set it properly
	// and add it to the to-do list; repeat until no more changes.
	while toDo
		pos = toDo.pull
		dist = distMap[pos] + 1
		for n in neighbors(pos[0], pos[1])
			if grid.cell(n[0], n[1]) != freeCell then continue
			if distMap[n] > dist then
				distMap[n] = dist
				toDo.push n
			end if
		end for
	end while
end function

// Move the wumpus towards the edge.
moveWumpus = function()
	bestDist = 99
	bestNeighbor = null
	for n in neighbors(wumpus.col, wumpus.row)
		if distMap[n] < bestDist then
			bestDist = distMap[n]
			bestNeighbor = n
		end if
	end for
	if bestNeighbor == null then
		printStatus "You caught the wumpus!  Great job!"
		globals.done = true
		return
	end if
	wumpus.col = bestNeighbor[0]
	wumpus.row = bestNeighbor[1]
	if wumpus.col < 0 or wumpus.col > 10 or 
	   wumpus.row < 0 or wumpus.row > 10 then
		printStatus "The wumpus got away!"
		globals.done = true
	end if
end function

// Function to block a cell when the user clicks on it.
blockCell = function(col, row)
	grid.setCell col, row, blockedCell
end function

// Handle mouse input.    
checkMouse = function()
	col = colForXY(mouse.x, mouse.y)
	row = rowForXY(mouse.x, mouse.y)
	if not mouse.button then return
	if grid.cell(col,row) == freeCell and 
	      (col != wumpus.col or row != wumpus.row) then
		blockCell col, row
		updateDistMap
		moveWumpus
	end if
end function

// Function to print a line centered at the bottom of the screen.
printStatus = function(s)
	for i in range(0,67)
		text.setCell i,0, " "
	end for
	text.delimiter = ""
	text.row = 0
	text.column = 34 - s.len/2
	print s
	text.row = 5
	text.delimiter = char(13)
end function
printStatus "Click hexes around the wumpus to trap it.  " +
   "Don't let it get away!"

// Main loop.
done = false
while not done
	if key.pressed("q") or key.pressed("escape") then break
	checkMouse
	wumpus.update
	yield
end while

// After exiting the main loop, let the wumpus finish his last
// movement before exiting.
while wumpus.moving
	wumpus.update
	yield
end while
key.clear
text.row = 25

// SpeedConquest
//  A turn-based strategy game with AI.

import "listUtil"

// Set up the display.
text.inverse = false
clear
bgColor = "#000044FF"
display(7).mode = displayMode.solidColor
display(7).color = bgColor

hurry = false

// Define a Player class to keep track of all the data
// about one player (whether AI or human)
Player = {}
newPlayer = function(name, human=true, color=null)
	noob = new Player
	noob.name = name
	noob.human = human
	noob.territories = 0
	noob.soldiers = 0
	noob.eliminated = false
	if color == null then
		noob.color = globals.color[name.lower]
	else
		noob.color = color
	end if
	return noob
end function

// Prepare the teams and their colors.  (Note that
// if color is not specified, the team name is looked
// up as a standard color.)
// Adjust this for more or fewer players, or to change
// which of the players are human (second argument == true).
teams = []
teams.push newPlayer("Blue", true, "#4444FF")
teams.push newPlayer("Purple", false)
teams.push newPlayer("Red", false)
teams.push newPlayer("Orange", false)
teams.push newPlayer("Green", false)
teams.push newPlayer("Brown", false)

// Prepare sound effects
conquerSnd = new Sound
conquerSnd.init 0.5, 50, [1,0], Sound.noiseWave
failSnd = new Sound
failSnd.init 0.1, 400, [0,1,0], Sound.noiseWave
reinforceSnd = new Sound
reinforceSnd.init 0.05, 10, [1,1,1,0], Sound.noiseWave

// Prepare our soldier and flag images
d = "/sys/pics/gamePieces/"
soldierPic = file.loadImage(d + "pieceWhite_border02.png")
flagPic = file.loadImage(d + "pieceWhite_border18.png")

//----------------------------------------------------------------------
// Functions to draw the soldiers
//----------------------------------------------------------------------
drawSoldierAt = function(disp, x, y)
	disp.drawImage soldierPic, x - 8, y - 8, 16, 16
end function

drawSoldiers = function(disp, x, y, count, withFlag=false)
	disp.fillEllipse x-24, y-24, 48, 48, color.clear
	if withFlag then disp.drawImage flagPic, x - 8, y - 8, 16, 16
	if count < 1 then return
	pos = []
	// This method is longer than you might expect just
	// because we have a different set of positions to
	// draw depending on how many soldiers there are,
	// and whether we also have a flag.  Long, but simple.
	if withFlag then
		if count == 1 then
			pos = [[-10,0]]
		else if count == 2 then
			pos = [[-10,0], [10,0]]
		else if count == 3 then
			pos = [[-10,-8], [10,-8], [0,12]]
		else if count == 4 then
			pos = [[-10,-10], [10,-10], [-10,10], [10,10]]
		else if count == 5 then
			pos = [[-15,-8], [0,-15], [15,-8], [-8,12], [8,12]]
		else if count == 6 then
			pos = [[-8,-12], [8,-12], [-15,0], [15,0], [-8,12], [8,12]]
		end if
	else
		if count == 1 then
			pos = [[0,0]]
		else if count == 2 then
			pos = [[-8,0], [8,0]]
		else if count == 3 then
			pos = [[-10,-8], [10,-8], [0,8]]
		else if count == 4 then
			pos = [[-8,-10], [8,-10], [-8,10], [8,10]]
		else if count == 5 then
			pos = [[-15,-10], [0,-10], [15,-10], 
			       [-8,10], [8,10]]
		else if count == 6 then
			pos = [[-15,-10], [0,-10], [15,-10], 
			       [-15,10], [0,10], [15,10]]
		end if
	end if
	for p in pos
		drawSoldierAt disp, x + p[0], y + p[1]
	end for
end function

//----------------------------------------------------------------------
// Prepare the hex grid
//----------------------------------------------------------------------
columns = 15
rows = 12
tiles = file.loadImage("/sys/pics/TileShapes.png")
gfx.clear color.clear
display(6).mode = displayMode.tile
grid = display(6)
grid.tileSet = tiles
grid.tileSetTileSize = 64
grid.cellSize = 64
grid.oddColOffset = 0
grid.oddRowOffset = 0.5  // makes a hex grid by rows!
grid.overlap = [7,15]
grid.extent = [columns, rows]
grid.scrollX = -32
grid.scrollY = -32
spacing = [grid.cellSize - grid.overlap[0], grid.cellSize - grid.overlap[1]]

colRange = range(0, columns-1)
rowRange = range(0, rows-1)

//----------------------------------------------------------------------
// CellInfo class: represents data about one cell (hex) on the map
//----------------------------------------------------------------------
CellInfo = {}
CellInfo.isWater = false
CellInfo.owner = -1
CellInfo.selected = false
CellInfo.soldiers = 0
CellInfo.hasFlag = false
CellInfo.make = function(col, row)
	noob = new CellInfo
	noob.col = col
	noob.row = row
	return noob
end function
CellInfo.desc = function
	n = "Unclaimed"
	if self.owner >= 0 then n = teams[self.owner].name
	return n + " cell at " + self.col + "," + self.row + 
	    " with " + self.soldiers + " soldiers"
end function
CellInfo.show = function
	if self.isWater then
		tint = bgColor
	else if self.owner >= 0 then
		tint = teams[self.owner].color
	else
		tint = "#444444"
	end if
	if self.selected then tint = color.lerp(tint, color.white)
	grid.setCellTint self.col, self.row, tint
end function
CellInfo.setWater = function(isWater=true)
	self.isWater = isWater
	self.show
end function
CellInfo.setOwner = function(owner)
	self.owner = owner
	self.show
end function
CellInfo.setSelected =  function(select=true)
	self.selected = select
	self.show
end function
CellInfo.setSoldiers = function(count)
	if count < 0 then count = 0
	self.soldiers = count
	drawSoldiers gfx, xForCell(self.col, self.row), 
	   yForCell(self.col, self.row), count, self.hasFlag
end function
CellInfo.setFlag = function(hasFlag)
	self.hasFlag = hasFlag
	self.setSoldiers self.soldiers // (forces a redraw)
end function

//----------------------------------------------------------------------
// Set up 2D array of info about each cell, accessed as cellInfo[col][row]
//----------------------------------------------------------------------
cellInfo = []
for c in colRange
	cellInfo.push []
	for r in rowRange
		cellInfo[c].push CellInfo.make(c, r)
	end for
end for

grid.clear
grid.setCell colRange, rowRange, 32 // solid white hex

//----------------------------------------------------------------------
// Make a couple of functions to convert between hex cell
// coordinates, and pixel coordinates.
//----------------------------------------------------------------------
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

inBounds = function(col, row)
	return col >= 0 and col < columns and row >= 0 and row < rows
end function

cellAt = function(xy)
	c = colForXY(xy.x, xy.y)
	r = rowForXY(xy.x, xy.y)
	if not inBounds(c, r) then return null
	return cellInfo[c][r]
end function

//----------------------------------------------------------------------
// Get the neighbors of any given hex cell.
// Slightly tricky since it depends on which row you're on.
//----------------------------------------------------------------------
neighbors = function(col, row, allowWater = false)
	result = [[col-1,row], [col+1,row]]
	if row%2 then
		result = result + [[col,row-1], [col+1,row-1]]
		result = result + [[col,row+1], [col+1,row+1]]
	else
		result = result + [[col-1,row-1], [col,row-1]]
		result = result + [[col-1,row+1], [col,row+1]]
	end if
	// Remove any neighbors which are out of bounds or (optionally) water.
	for i in range(result.len-1, 0)
		c = result[i][0]
		r = result[i][1]
		if not inBounds(c,r) or (not allowWater and cellInfo[c][r].isWater) then
			result.remove i
		end if
	end for
	return result
end function

isNeighboring = function(cell1, cell2)
	return neighbors(cell1.col, cell1.row).indexOf([cell2.col, cell2.row]) != null
end function

//----------------------------------------------------------------------
// Count up the territories and soldiers for the given player
//----------------------------------------------------------------------
countTeamStats = function(playerNum)
	team = teams[playerNum]
	team.territories = 0
	team.soldiers = 0
	for c in colRange
		for r in rowRange
			ci = cellInfo[c][r]
			if ci.owner != playerNum or ci.isWater then continue
			team.territories = team.territories + 1
			team.soldiers = team.soldiers + ci.soldiers + 1  
			// (+1 to include implicit defender)
		end for
	end for
	team.eliminated = (team.territories == 0)
end function

//----------------------------------------------------------------------
// Detect when the game is over
//----------------------------------------------------------------------
isGameOver = function
	count = 0
	for team in teams
		if not team.eliminated then count = count + 1
	end for
	return count < 2
end function

//----------------------------------------------------------------------
// findGroups: find all sets of connected cells of the given player.
// Return them as a list of sets (maps) of CellInfo objects.
//----------------------------------------------------------------------
findGroups = function(playerNum)
	result = []
	for c in colRange
		for r in rowRange
			// find a cell that belongs to this player
			ci = cellInfo[c][r]
			if ci.owner != playerNum or ci.isWater then continue
			// make sure it's not part of an existing group
			alreadyFound = false
			for set in result
				if set.hasIndex(ci) then
					alreadyFound = true
					break
				end if
			end for
			if alreadyFound then continue
			// start a group, then add all connected cells
			grp = {}
			grp.push ci
			toDo = neighbors(ci.col, ci.row)
			while toDo
				p = toDo.pop
				n = cellInfo[p[0]][p[1]]
				if n.owner != playerNum or grp.hasIndex(n) then continue
				grp.push n
				toDo = toDo + neighbors(n.col, n.row)
			end while
			result.push grp
		end for
	end for
	return result
end function

//----------------------------------------------------------------------
// Find the largest set among a list of sets.
//----------------------------------------------------------------------
largestSet = function(sets)
	best = sets[0]
	if sets.len > 1 then
		for i in range(1, sets.len-1)
			if sets[i].len > best.len then best = sets[i]
		end for
	end if
	return best
end function

//----------------------------------------------------------------------
// Figure out what cells are reinforcible (i.e., are
// next to an enemy hex if bordersOnly is true).
//----------------------------------------------------------------------
reinforcibleCells = function(cells, bordersOnly=true)
	result = []
	for cell in cells
		if cell.soldiers > 5 then continue	// already full
		if bordersOnly then
			ok = false
			for pos in neighbors(cell.col, cell.row)
				if cellInfo[pos[0]][pos[1]].owner != cell.owner then
					ok = true
					break
				end if
			end for
			if not ok then continue	// not a border
		end if
		result.push cell
	end for
	result.shuffle
	return result
end function

//----------------------------------------------------------------------
// Management of the flag.  (The flag counts as 1 extra soldier.)
//----------------------------------------------------------------------
findFlag = function(playerNum)
	for c in colRange
		for r in rowRange
			ci = cellInfo[c][r]
			if ci.hasFlag and ci.owner == playerNum then return ci
		end for
	end for
end function

plantFlag = function(hexes)
	oldFlagCell = findFlag(curPlayer)
	if not hexes.hasIndex(oldFlagCell) then
		if oldFlagCell != null then oldFlagCell.setFlag false
		hexes.indexes.any.setFlag true
	end if
end function

//----------------------------------------------------------------------
// Map generation code
//----------------------------------------------------------------------

// helper function for map generation: adds a new hex of the given color,
// but if it touches some other color, then changes all of that other color
// to this color.
addLandHex = function(col, row, newColor="#888888")
	cellInfo[col][row].setWater false
	grid.setCellTint col, row, newColor
	converts = 0
	for n in neighbors(col, row)
		prevColor = grid.cellTint(n[0], n[1])
		if prevColor != c then		
			// Recolor all hexes of prevColor to new color.
			for r in rowRange
				for c in colRange
					if grid.cellTint(c,r) == prevColor then 
						grid.setCellTint c,r, newColor
					end if
				end for
			end for
		end if
	end for
end function

// Generate a random map.
genMap = function
	randRow = function
		return round(rnd * rows/2 + rnd * rows/2)
	end function
	randCol = function
		return round(rnd * colums/2 + rnd * columns/2)
	end function
	
	// land high points:
	landPoints = []
	for i in range(1 + ceil(rnd*3))
		landPoints.push {"row":randRow, "col":randRow, 
		    "dist":3 + rnd*3, "lake": rnd*2.5}
		//print landPoints[-1]
	end for
	
	for c in colRange
		for r in rowRange
			cellInfo[c][r].setSoldiers 0
			// check if we're within range of any land high point
			isWater = true
			for lp in landPoints
				dsqr = (r - lp.row)^2 + (c - lp.col)^2
				if dsqr < lp.dist^2 then isWater = false
				if dsqr < lp.lake^2 then isWater = true
			end for
			cellInfo[c][r].setWater isWater
			if not isWater then cellInfo[c][r].setOwner floor(rnd * teams.len) 
		end for
	end for
end function

// Assign random starting positions.
genStart = function
	for teamNum in teams.indexes
		// gather all the hexes that belong to this team
		hexes = []
		for ciList in cellInfo
			for ci in ciList
				if not ci.isWater and ci.owner == teamNum then hexes.push ci
			end for
		end for
		// Now, distribute soldiers among those hexes
		soldiersLeft = 25 + 5 * teams[teamNum].human
		while soldiersLeft > 0
			hex = hexes[rnd * hexes.len]
			if hex.soldiers >= 6 then continue
			hex.setSoldiers hex.soldiers + 1
			soldiersLeft = soldiersLeft - 1
		end while
	end for
end function

//----------------------------------------------------------------------
// functions related to the prompt & "Done" button at bottom of screen
//----------------------------------------------------------------------
drawStatus = function(s)
	s = s + " " * (60 - s.len)
	text.delimiter = ""
	text.row = 0; text.column = 0
	print s
	text.delimiter = char(13)
end function

drawPrompt = function
	text.color = teams[curPlayer].color
	prompt = teams[curPlayer].name + "'s turn.  "
	if state == kStateSelectingAttacker then
		prompt = prompt + "Select attacking territory."
	else if state == kStateSelectingTarget then
		prompt = prompt + "Select target."
	else if state == kStateDoingBattle then
		prompt = teams[curPlayer].name + " attacks " + 
		   teams[defendingCell.owner].name + "!"
	else
		prompt = ""
	end if
	drawStatus prompt
end function

drawDoneButton = function(drawIt=true)
	s = char(57856) + "DONE" + char(57857)
	foreColor = text.backColor
	backColor = text.color
	if not drawIt then
		s = " " * s.len
		foreColor = text.color
		backColor = text.backColor
	end if
	for i in s.indexes
		x = 68 - s.len + i
		text.setCell x, 0, s[i]
		text.setCellColor x, 0, foreColor
		text.setCellBackColor x, 0, backColor
	end for
end function

doneButtonClicked = function
	if mouse.x > 875 and mouse.y < 30 then	// "DONE" button
		// ToDo: we really should do proper button tracking here.
		// But for now we'll just react to the mouse-down.
		return true
	end if
	return false
end function

//----------------------------------------------------------------------
// roll some number of 6-sided dice and return the sum
//----------------------------------------------------------------------
roll = function(dice, sides=6)
	sum = 0
	for i in range(1, dice)
		sum = sum + floor(rnd * sides) + 1
	end for
	return sum
end function

//----------------------------------------------------------------------
// doBattle: resolve one hex attacking another
//----------------------------------------------------------------------
doBattle = function
	drawDoneButton false
	text.row = 0; text.column = 0; text.delimiter = ""
	print " " * 66
	
	attack = roll(attackingCell.soldiers + 1)
	defense = roll(defendingCell.soldiers + 1)
	
	s = "Attack: " + (attackingCell.soldiers + 1) +
	    "d6 = " + attack + "   "
	if attack > defense then s = s + ">" else s = s + "<="
	s = s + "   Defense: " + (defendingCell.soldiers + 1) +
	    "d6 = " + defense
	text.column = 34 - s.len/2; print s
	text.delimiter = char(13)
	
	if attack > defense then
		// attacker won
		conquerSnd.freq = 40 + 20 * rnd
		conquerSnd.play
		defender = defendingCell.owner
		defendingCell.setOwner curPlayer
		lost = round((attackingCell.soldiers + 1) * defense/attack)
		survivors = attackingCell.soldiers + 1 - lost
		if survivors < 2 then survivors = 2
		if defendingCell.hasFlag then defendingCell.setFlag false
		defendingCell.setSoldiers survivors - 2
		attackingCell.setSoldiers 0
		countTeamStats defender
		if teams[defender].eliminated then
			drawStatus teams[defender].name + " is eliminated!"
			wait 1
		end if
	else
		// defender won
		failSnd.play
		lost = round((defendingCell.soldiers + 1) * attack/defense)
		survivors = defendingCell.soldiers + 1 - lost
		attackingCell.setSoldiers 0
		defendingCell.setSoldiers survivors - 1
	end if
	enterState kStateDidBattle
end function

//----------------------------------------------------------------------
// doReinforcements: add new armies for the current player
//----------------------------------------------------------------------
doReinforcements = function
	drawDoneButton false
	groups = findGroups(curPlayer)
	if groups then
		best = largestSet(groups)
		// OK, we've found the best group, and its size.
		// Make sure it contains the flag.
		plantFlag best
		// Distribute reinforcements!
		reinforcements = best.len
		drawStatus teams[curPlayer].name + " gets " + reinforcements +
		" reinforcement" + "s" * (reinforcements != 1)
		delay = 0.4
		options = reinforcibleCells(best.indexes)
		for i in range(1, best.len)
			if not options then
				options = reinforcibleCells(best.indexes, false)
				if not options then break
			end if
			choice = options[i % options.len]
			choice.setSoldiers choice.soldiers + 1
			if choice.soldiers > 5 then options.remove options.indexOf(choice)
			reinforceSnd.freq = 9 + 2 * rnd
			reinforceSnd.play
			if key.available and key.get == char(10) then globals.hurry = true
			if not hurry then wait delay
			delay = delay * 0.9
		end for
	else
		// eliminated!
	end if
end function

//----------------------------------------------------------------------
// endTurn: do all the stuff we do at the end of one player's turn
//----------------------------------------------------------------------
endTurn = function
	if attackingCell != null then
		attackingCell.setSelected false
		globals.attackingCell = null
	end if
	
	doReinforcements
	
	while true
		globals.curPlayer = (curPlayer + 1) % teams.len
		if not teams[curPlayer].eliminated then break
	end while
	enterState kStateSelectingAttacker
end function

//----------------------------------------------------------------------
// AI
//----------------------------------------------------------------------
ai = {}
ai.selectAttacker = function
	//drawStatus teams[curPlayer].name + " is thinking..."
	if not hurry then wait
	
	// Find our largest group -- this is the one we mostly want to expand.
	myGroups = findGroups(curPlayer)
	
	if not myGroups then return null
	mainGrp = largestSet(myGroups)
	
	// Find all the enemy territories adjacent to this one.
	// These are potential targets.
	targets = []
	for c in colRange
		for r in rowRange
			ci = cellInfo[c][r]
			if ci.isWater or ci.owner == curPlayer then continue
			for n in neighbors(ci.col, ci.row)
				if mainGrp.hasIndex(cellInfo[n[0]][n[1]]) then
					//drawStatus teams[curPlayer].name + " considers " + ci.desc
					targets.push ci
					break
				end if
			end for
		end for
	end for
	
	while targets
		// select a potential target
		t = targets.pop
		// make sure we will be able to attack it
		for n in neighbors(t.col, t.row)
			nc = cellInfo[n[0]][n[1]]
			if nc.owner == curPlayer and nc.soldiers > 0 then
				// yep, this is a valid target; return the attacker
				outer.target = t
				return nc
			end if
		end for
		// nope, try again
	end while
	
	return null
end function

ai.selectTarget = function	
	// target was actually set in selectAttacker.
	return target
end function

//----------------------------------------------------------------------
// Game state machine
//----------------------------------------------------------------------
kStateSelectingAttacker = "Selecting Attacker"
kStateSelectingTarget = "Selecting Target"
kStateDoingBattle = "Doing Battle"
kStateDidBattle = "Did Battle"
kStateGameOver = "Game Over"

enterState = function(state)
	globals.state = state
	text.color = teams[curPlayer].color
	
	if state == kStateSelectingAttacker then
		globals.hurry = false
		if attackingCell != null then
			attackingCell.setSelected false
			globals.attackingCell = null
		end if
		if defendingCell != null then
			defendingCell.setSelected false
			globals.defendingCell = null
		end if
		if teams[curPlayer].human then drawDoneButton
		drawPrompt
	else if state == kStateSelectingTarget then
		if defendingCell != null then
			defendingCell.setSelected false
			globals.defendingCell = null
		end if
		if teams[curPlayer].human then drawDoneButton
		drawPrompt
	else if state == kStateDoingBattle then
		drawDoneButton false
		drawPrompt
	else if state == kStateDidBattle then
		if attackingCell != null then
			attackingCell.setSelected false
			globals.attackingCell = null
		end if
		if defendingCell != null then
			defendingCell.setSelected false
			globals.defendingCell = null
		end if
		if teams[curPlayer].human then drawDoneButton
		if isGameOver then enterState kStateGameOver
	else if state == kStateGameOver then
		drawDoneButton false
		drawStatus "GAME OVER!"
		while mouse.button; end while
		while not mouse.button; end while
		run
	end if
	
end function

lastMouseButton = mouse.button
attackingCell = null
defendingCell = null
update = function
	mouseDown = mouse.button and not lastMouseButton
	if mouseDown then clicked = cellAt(mouse) else clicked = null
	globals.lastMouseButton = mouse.button
	
	if state == kStateSelectingAttacker or state == kStateDidBattle then
		if not teams[curPlayer].human then
			globals.attackingCell = ai.selectAttacker
			if attackingCell == null then
				endTurn
			else
				attackingCell.setSelected
				enterState kStateSelectingTarget
			end if
			return
		end if
		if mouseDown and doneButtonClicked then endTurn
		if clicked != null and clicked.owner == curPlayer and
		         clicked.soldiers > 0 then
			clicked.setSelected
			globals.attackingCell = clicked
			enterState kStateSelectingTarget
		end if
	else if state == kStateSelectingTarget then
		if not teams[curPlayer].human then
			globals.defendingCell = ai.selectTarget
			defendingCell.setSelected
			if not hurry then wait 0.3
			enterState kStateDoingBattle
			return
		end if
		if mouseDown and doneButtonClicked then endTurn
		if clicked == null then return
		if clicked == attackingCell then
			// clicked the original selection again; undo it
			enterState kStateSelectingAttacker
		else if clicked.owner == curPlayer then
			if clicked.soldiers > 0 then
				// clicked a different cell of the current player;
				// select that instead
				attackingCell.setSelected false
				clicked.setSelected
				globals.attackingCell = clicked
			end if
		else if isNeighboring(attackingCell, clicked) then
			// attack!
			globals.defendingCell = clicked
			clicked.setSelected
			enterState kStateDoingBattle
		end if
	else if state == kStateDoingBattle then
		doBattle
	end if
end function

//----------------------------------------------------------------------
// Game Menu
//----------------------------------------------------------------------
text.color = color.gray
text.delimiter = ""
while true
	genMap
	genStart
	
	text.inverse = true
	text.row = 0
	text.column = 20
	print char(57856) + "PLAY" + char(57857)
	text.column = 40
	print char(57856) + "NEW MAP" + char(57857)
	text.inverse = false
	
	while mouse.button; end while
	while not mouse.button; end while
	if mouse.x < gfx.width/2 then break
end while
text.delimiter = char(13)

//----------------------------------------------------------------------
// Main loop
//----------------------------------------------------------------------
state = null
curPlayer = 0
enterState kStateSelectingAttacker

while not key.pressed("escape")
	update
	if key.available and key.get == char(10) then globals.hurry = true
	yield
end while
key.clear

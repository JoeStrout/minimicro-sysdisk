// Drum Machine demo

clear
text.row = 25
text.column = 29
print "DRUM MACHINE"
text.row = 1
print " "*12 + "Click cells above to lay down a sick beat!"
text.delimiter = ""
print " "*15 + "Each row is a different instrument."
text.delimiter = char(13)

// Load sounds
sounds = []
// First four are instrument sounds, adjusted in pitch.
instrument = file.loadSound("/sys/sounds/elecGuitarC4.wav")
instrumentFreq = noteFreq(60)
notes = [[60, 64, 67, 72],  // major C chord
		 [60, 65, 68, 72],  // major F chord
		 [62, 67, 71, 74],	// major G chord
		 [60, 64, 67, 72]]  // major C chord
sounds.push instrument
sounds.push instrument
sounds.push instrument
sounds.push instrument

// The other rows are simple sounds, played exactly as they are.
sounds.push file.loadSound("/sys/sounds/hit.wav")
sounds.push file.loadSound("/sys/sounds/hihat.wav")
sounds.push file.loadSound("/sys/sounds/hihat2.wav")
sounds.push file.loadSound("/sys/sounds/snare.wav")
sounds.push file.loadSound("/sys/sounds/snare2.wav")
sounds.push file.loadSound("/sys/sounds/bongo.wav")
sounds.push file.loadSound("/sys/sounds/aminPluck.wav")
sounds.push file.loadSound("/sys/sounds/woodblock.wav")

// Prepare the tile maps.
// 'tile' is our grid of actual buttons;
// 'bgtile' is the background, used to light up the current column

display(5).mode = displayMode.tile
tile = display(5)
tile.tileSet = file.loadImage("/sys/pics/TileShapes.png")
tile.tileSetTileSize = 64
tile.cellSize = [48, 40]
tile.overlap = [-8, -6]
tile.oddRowOffset = 0
tile.oddColOffset = 0
darkcell1 = 9
darkcell2 = 12
litcell = 14
rows = 12  // i.e., how many instruments we have
columns = 16
tile.extent = [columns, rows]
tile.scrollX = -50
tile.scrollY = -60

display(6).mode = displayMode.tile
bgtile = display(6)
bgtile.extent = tile.extent
bgtile.tileSet = tile.tileSet
bgtile.tileSetTileSize = tile.tileSetTileSize
bgtile.cellSize = [48+8, 40+6]
bgtile.overlap = 0
bgtile.scrollX = tile.scrollX - tile.overlap[0]/2
bgtile.scrollY = tile.scrollY - tile.overlap[1]/2

// function to set or clear a cell (indicating whether
// we should play a sound at that point)
setLit = function(x, y, lit)
	if lit then
		tile.setCell x, y, litcell
	else
		measure = floor(x / 4)
		if measure % 2 then
			tile.setCell x, y, darkcell2
		else
			tile.setCell x, y, darkcell1
		end if
	end if
end function

// function to tell us whether a given cell is lit
isLit = function(x, y)
	return tile.cell(x,y) == litcell
end function

// function to light up a particular column (in bgtile)
lightColumn = function(col)
	bgtile.clear
	for row in range(0, rows-1)
		bgtile.setCell col, row, 3
	end for
	globals.litCol = col
end function

// functions to find the grid row and column hit by the mouse
mouseRow = function
	return floor((mouse.y + tile.scrollY) / (tile.cellSize[1] - tile.overlap[1]))
end function
mouseCol = function
	return floor((mouse.x + tile.scrollX) / (tile.cellSize[0] - tile.overlap[0]))
end function

// clear the board
for c in range(0, columns-1)
	for r in range(0, rows-1)
		setLit c, r, false
	end for
end for
lightColumn 0

// function to play the appropriate sound for a row and column
playSound = function(row, column)
	if row > 3 then
		// above row 3, it's all just simple digitized sounds
		sounds[row].play
	else
		// but for rows 0-3, we calculate a pitch based on a chord progression
		speed = noteFreq(notes[column/4][row]) / instrumentFreq
		sounds[row].play 1, 0, speed
	end if
end function		

// handle mouse clicks
wasPressed = false
checkMouse = function
	if mouse.button and not wasPressed then
		x = mouseCol
		y = mouseRow
		if x >= 0 and y >= 0 and x < columns and y < rows then
			setLit x, y, not isLit(x,y)
		end if
	end if
	globals.wasPressed = mouse.button
end function

// update the lit column and play selected sounds
bpm = 90
next16th = time
updateMusic = function
	if time < next16th then return
	lightColumn (litCol + 1) % columns
	for row in range(0, rows-1)
		if isLit(litCol, row) then playSound(row, litCol)
	end for
	globals.next16th = next16th + 15 / bpm
end function

// main loop
while not key.pressed("escape")
	checkMouse
	updateMusic
	yield
end while
text.clear
key.clear

// Maze demo, using a Wang 2-Corner tile set.
// See http://www.cr31.co.uk/stagecast/wang/2corn.html

import "listUtil"

clear
gfx.clear color.clear

baseIndex = 16  // (select the thin, squarish tileset)

display(6).mode = displayMode.tile
tiles = display(6)
tiles.tileSet = file.loadImage("/sys/pics/TwoCornerTiles.png")
tiles.tileSetTileSize = tiles.tileSet.width/16
tiles.cellSize = tiles.tileSetTileSize/2
tiles.extent = [960/tiles.cellSize, 640/tiles.cellSize]
tiles.clear null
tiles.scrollX = 0
tiles.scrollY = 0
tiles.overlap = 0

// Wang tiles are selected by solid/empty CORNERS, not cells.
// So, we need someplace else to store the state of each corner.
// We'll just make a 2D array for that.
corners = list.init2d(tiles.extent[0], tiles.extent[1], 0)

// For generating a maze, we will also have a concept of "rooms".
// A room is one position in the maze, surrounded by 0-4 walls.
// But since rooms are arranged in a rectangular grid, we only
// need to worry about two walls per room: the north and east walls.
// For every room we also keep track of what "set" the room is in;
// all connected rooms are in the same set.  Initially, each room
// is in a set all by itself.
// While we're at it, make a big list of all the walls, so we can
// shuffle that and consider walls in random order.
Room = {}
Room.cols = floor(tiles.extent[0]/2)
Room.rows = floor(tiles.extent[1]/2)
rooms = list.init2d(Room.cols, Room.rows)
walls = []
for col in range(0, Room.cols-1)
	for row in range(0, Room.rows-1)
		r = new Room
		r.col = col; r.row = row
		r.north = true   // wall to the north
		r.east = true  // wall to the east
		r.set = [r]  // in a set by itself
		rooms[col][row] = r
		walls.push [r, "north"]
		walls.push [r, "east"]
	end for
end for
walls.shuffle

// Set corners from the rooms.  There's a solid corner
// on either end of any solid wall.
setCornersFromRooms = function()
	for x in range(0, tiles.extent[0]-1)
		for y in range(0, tiles.extent[1]-1)
			corners[x][y] = (x == tiles.extent[0]-1 or y == tiles.extent[1]-1)
		end for
	end for
	
	for col in range(0, Room.cols-1)
		for row in range(0, Room.rows-1)
			r = rooms[col][row]
			if r.north then corners[col*2][row*2+1] = 1
			if r.east then corners[col*2+1][row*2] = 1
			corners[col*2+1][row*2+1] = 1
		end for
	end for
end function

// Function to pick the appropriate tile in our tile set for any
// cell in the display, based on our corners map.
pickTile = function(col, row)
	n = 1 * corners[col][row] +
	2 * corners[col][row-1] +
	4 * corners[col-1][row-1] +
	8 * corners[col-1][row]
	return n + baseIndex
end function

// Update all the tiles in our display from the corners map.
updateTiles = function()
	for col in range(0, tiles.extent[0]-1)
		for row in range(0, tiles.extent[1]-1)
			tiles.setCell col, row, pickTile(col, row)
		end for
	end for
end function
updateTiles

removeWall = function(room, whichWall)
	room[whichWall] = false
	//setCornersFromRooms
	//updateTiles
end function

doOneStep = function()
	w = walls.pop
	room = w[0]
	whichWall = w[1]
	// Find the neighboring room
	if whichWall == "north" then
		if room.row+1 == Room.rows then return
		neighbor = rooms[room.col][room.row+1]
	else
		if room.col+1 == Room.cols then return
		neighbor = rooms[room.col+1][room.row]
	end if
	// If it's already in the same set as this one, then 
	// don't remove this wall.
	if room.set == neighbor.set then return
	// Otherwise, remove the wall, and combine the sets.
	removeWall room, whichWall
	for r in neighbor.set
		room.set.push r
		r.set = room.set
	end for
end function

// Generate a maze!
while walls
	doOneStep
end while
setCornersFromRooms
updateTiles


// That's it for maze generation!
// Everything below is for manually drawing with the mouse.

// Print instructions.
gfx.fillRect 0, 0, 960, 60, "#00000088"
c = color.yellow
gfx.print "Click and drag to draw/erase.", 20, 30, c, "small"
gfx.print "1-3: thin/normal/thick", 400, 40, c, "small"
gfx.print "4-9: select color", 400, 25, c, "small"
gfx.print "  G: toggle grid", 400, 10, c, "small"
gfx.print "ESC: quit",780, 30, c, "small"

applyColor = function(colorIdx)
	colors = [color.white, color.pink, color.fuchsia,
	   color.aqua, color.lime, color.yellow, color.orange]
	c = colors[colorIdx % colors.len]
	for x in range(tiles.extent[0]-1)
		for y in range(tiles.extent[1]-1)
			tiles.setCellTint x, y, c
		end for
	end for
end function

toggleGrid = function()
	if tiles.overlap then tiles.overlap = 0 else tiles.overlap = -1
	tiles.cellSize = tiles.tileSetTileSize/2 + tiles.overlap
end function

// Find the corner closest to the mouse cursor.
cornerAtMouse = function()
	d = {}
	spacing = tiles.cellSize - tiles.overlap
	d.col = floor(mouse.x/spacing - 0.5)
	d.row = floor(mouse.y/spacing - 0.5)
	return d
end function

while true
	yield
	if key.available then
		k = key.get
		if k == "1" then baseIndex = 16
		if k == "2" then baseIndex = 0
		if k == "3" then baseIndex = 32
		if k.lower == "g" then toggleGrid
		if k >= "4" and k <= "9" then applyColor val(k)-4
		if k == "q" or k == char(27) then exit
		updateTiles
	end if
	if not mouse.button then continue
	cs = tiles.cellSize
	m = cornerAtMouse
	setEm = not corners[m.col][m.row]
	while mouse.button
		m = cornerAtMouse
		corners[m.col][m.row] = setEm
		updateTiles
		yield
	end while
end while

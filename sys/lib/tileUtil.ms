// Utilities related to TileDisplay.
// Includes some code to save and load a tile layout in a text file.

// Helper method to convert a string that could be either a number
// or a list of numbers into a proper MiniScript value.
parse = function(valstr)
	while valstr[0] == " "; valstr = valstr[1:]; end while
	if not valstr then return null
	if valstr[0] == "[" then
		result = []
		for item in valstr[1:-1].split(",")
			result.push parse(item)
		end for
		return result
	else
		return val(valstr)
	end if
end function

// Helper function to take a size which may be either a number
// or a 2-element list, and return it as a map with "x" and "y".
// (These sorts of sizes are used for tile display cellSize, etc.)
sizeToXY = function(size)
	result = {}
	if size isa number then
		result.x = size
		result.y = size
	else
		result.x = size[0]
		result.y = size[1]
	end if
	return result
end function

// Save a tile map to a file.
// Returns null on success, or an error string in case of an error.
saveToFile = function(path, tiles)
	data = []
	data.push "tileSetPath:" + tileSetPath
	data.push "tileSetTileSize:" + tiles.tileSetTileSize
	data.push "cellSize:" + tiles.cellSize
	data.push "overlap:" + tiles.overlap
	data.push "extent:" + tiles.extent
	data.push "--"
	extent = sizeToXY(tiles.extent)
	for row in range(extent.y - 1, 0) // (backwards to match visually)
		line = []
		for col in range(0, extent.x - 1)
			if tiles.cell(col, row) == null then 
				line.push "."
			else
				line.push tiles.cell(col, row)
			end if
		end for
		data.push line.join
	end for
	return file.writeLines(layoutFilePath, data)
end function


// Load a tile map from a file. 
// Returns true (1) on success, false (0) on failure.
// Also sets globals.tileSetPath (in case you need that).
loadFromFile = function(path, tiles)
	if file.info(path) == null then return false
	extent = {"x":0, "y":0}
	row = -1
	gotTileSet = false
	for line in file.readLines(path)
		if line == "--" then
			row = extent.y - 1
		else if row >= 0 then
			col = 0
			for item in line.split
				if item != "." then tiles.setCell col, row, val(item)
				col = col + 1
			end for
			row = row - 1
		else
			kv = line.split(":", 2)
			if kv[0] == "tileSetPath" then
				globals.tileSetPath = kv[1]  // (just FYI)
				tiles.tileSet = file.loadImage(kv[1])
				if tiles.tileSet != null then gotTileSet = true
			else if kv[0] == "tileSetTileSize" then
				tiles.tileSetTileSize = parse(kv[1])
			else if kv[0] == "cellSize" then
				tiles.cellSize = parse(kv[1])
			else if kv[0] == "overlap" then
				tiles.overlap = parse(kv[1])
			else if kv[0] == "extent" then
				tiles.extent = parse(kv[1])
				extent = sizeToXY(tiles.extent)
			end if
		end if
	end for
	return gotTileSet
end function

// This module has no built-in demo/test function; but
// see /sys/demo/levelEditor for a demo (and useful utility).


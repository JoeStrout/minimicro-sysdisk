// Utilities related to TileDisplay.
// Includes some code to save and load a tile layout in a text file.

//======================================================================
// Methods to assist with a tile set (i.e., a bunch of little images
// arranged into one big image, so they can be used with a TileDisplay).

// toImages: split a tile set up into a list of separate images.
//	tileSet: big image containing a bunch of tiles
//	tileSize: square size (e.g. 64) or [width,height] of each tile
//	border: extra space between the tiles
//	borderOnLeft: whether border applies on leftmost side of tileSet
//	borderOnTop: whether border applies on topmost side of tileSet
toImages = function(tileSet, tileSize, border=0, borderOnLeft=false, borderOnTop=false)
	result = []
	if tileSize isa list then
		tw = tileSize[0]
		th = tileSize[1]
	else
		tw = tileSize
		th = tileSize
	end if
	y = tileSet.height - border * borderOnTop
	while y > 0
		x = border * borderOnLeft
		while x < tileSet.width
			result.push tileSet.getImage(x, y-th, tw, th)
			x += tw + border
		end while
		y -= th + border
	end while
	return result
end function

// toTileSet: combine a bunch of separate images (all the same size)
// into a tileSet.  If images are NOT all the same size, they will
// all be padded (with transparent color) to match the largest.
//	images: list of individual tile images
//	columns: how many columns ot have in the tile set; if null,
//		a number of columns will be auto-chosen for you
//	border: how many pixels of extra space to leave between tiles
//	borderColor: what color to use for this extra space
toTileSet = function(images, columns=null, border=0, borderColor="#FF00FF")
	// Start by finding the maximum width and height of any tile image
	tw = 0; th = 0
	for img in images
		if img.width > tw then tw = img.width
		if img.height > th then th = img.height
	end for
	// And find out how many rows and columns we need
	if columns == null then
		columns = 2^(ceil(log(sqrt(images.len))/log(2)))
		if columns < 8 then columns = 8
	end if
	rows = ceil(images.len / columns)
	g = new PixelDisplay
	g.clear color.clear, tw*columns + border*(columns-1), th*rows + border*(rows-1)
	y = g.height - th
	x = 0
	for img in images
		if x + tw > g.width then
			if border then g.fillRect 0, y-border, g.width, border, borderColor
			y -= th + border
			x = 0
		end if
		g.drawImage img, x, y
		x += tw + border
		if border then g.fillRect x-border, 0, border, g.height, borderColor
	end for
	return g.getImage(0, 0, g.width, g.height)
end function

// saveImages: save a whole list of images to disk, by appending a number
// to the given base path.
//	basePath: base file name or path, e.g. "tile-"
//	imageList: list of images (for example, little tile images)
//	digits: how many digits to use in sequential number
//	verbose: if true, print out info on each file saved
saveImages = function(basePath, imageList, digits=3, verbose=true)
	for i in imageList.indexes
		istr = str(i)
		istr = "0" * (digits-istr.len) + istr
		path = basePath + istr + ".png"
		file.saveImage path, imageList[i]
		if verbose then print "Saved " + imageList[i].width + "x" +
		  imageList[i].height + " image to " + path
	end for
end function

// loadImages: given a path to a directory or a partial file name/path,
// load all matching images into a list.
//	basePath: base file name/path or directory path
//	verbose: if true, print out info on each file loaded
loadImages = function(basePath, verbose=true)
	basePathInfo = file.info(basePath)
	if basePathInfo and basePathInfo.isDirectory then
		dir = basePath
		files = file.children(dir)
	else
		dir = file.parent(basePath)
		files = file.children(dir)
		baseName = file.name(basePath)
		for i in range(files.len-1, 0, -1)
			if files[i][:baseName.len] != baseName then files.remove i
		end for
	end if
	result = []
	for f in files
		img = file.loadImage(file.child(dir, f))
		if img == null then continue
		result.push img
		if verbose then print "Loaded " + img.width + "x" + img.height +
		  " image from " + f + " as [" + (result.len-1) + "]"
	end for
	return result
end function

//======================================================================
// Methods to assist with saving and loading a tile map, i.e., some
// configuration of a TileDisplay.

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
saveToFile = function(path, tileDisplay)
	data = []
	data.push "tileSetPath:" + tileSetPath
	data.push "tileSetTileSize:" + tileDisplay.tileSetTileSize
	data.push "cellSize:" + tileDisplay.cellSize
	data.push "overlap:" + tileDisplay.overlap
	data.push "extent:" + tileDisplay.extent
	data.push "--"
	extent = sizeToXY(tileDisplay.extent)
	for row in range(extent.y - 1, 0) // (backwards to match visually)
		line = []
		for col in range(0, extent.x - 1)
			if tileDisplay.cell(col, row) == null then 
				line.push "."
			else
				line.push tileDisplay.cell(col, row)
			end if
		end for
		data.push line.join
	end for
	return file.writeLines(layoutFilePath, data)
end function


// Load a tile map from a file. 
// Returns true (1) on success, false (0) on failure.
// Also sets globals.tileSetPath (in case you need that).
loadFromFile = function(path, tileDisplay)
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
				if item != "." then tileDisplay.setCell col, row, val(item)
				col = col + 1
			end for
			row = row - 1
		else
			kv = line.split(":", 2)
			if kv[0] == "tileSetPath" then
				globals.tileSetPath = kv[1]  // (just FYI)
				tileDisplay.tileSet = file.loadImage(kv[1])
				if tileDisplay.tileSet != null then gotTileSet = true
			else if kv[0] == "tileSetTileSize" then
				tileDisplay.tileSetTileSize = parse(kv[1])
			else if kv[0] == "cellSize" then
				tileDisplay.cellSize = parse(kv[1])
			else if kv[0] == "overlap" then
				tileDisplay.overlap = parse(kv[1])
			else if kv[0] == "extent" then
				tileDisplay.extent = parse(kv[1])
				extent = sizeToXY(tileDisplay.extent)
			end if
		end if
	end for
	return gotTileSet
end function

// This module has no built-in demo/test function; but
// see /sys/demo/levelEditor for a demo (and useful utility).


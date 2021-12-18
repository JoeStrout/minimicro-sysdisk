clear
print "TILE MAP LEVEL EDITOR"
print
print "This program allows you to create, edit, and save an arrangement of tiles."
print

import "tileUtil"
sizeToXY = @tileUtil.sizeToXY

EOL = char(13)

min = function(a,b)
	if a < b then return a else return b
end function

getOption = function(optionList)
	text.inverse = true
	print " "
	text.inverse = false
	text.column = text.column - 1
	optionKeys = []
	for opt in optionList
		optionKeys.push opt[0]
	end for
	while true
		k = key.get.upper
		idx = optionKeys.indexOf(k)
		if idx >= 0 then
			print optionList[idx] + EOL
			return optionList[idx]
		end if
	end while
end function


inputNumber = function(prompt, default, help="")
	text.column = 0
	if help then
		print char(13)*2
		r = text.row + 2
		c = text.color
		text.color = color.gray
		print help
		text.row = r
		text.column = 0
		text.color = c
	end if
	print prompt + " [" + default + "]: "
	c = text.column
	s = input
	if help then
		text.row = r - 2
		print " " * 67
		text.row = r - 1
		text.column = 0
	end if
	if s == "" then
		text.row = text.row + 1
		text.column = c
		print default + char(13)
		return default
	end if
	return val(s)
end function

editMapParams = function
	d = sizeToXY(tiles.tileSetTileSize)
	d.x = inputNumber("Tile set tile width ", d.x, "Width of one tile in the tile set image, in pixels.")
	d.y = inputNumber("Tile set tile height", d.y, "Height of one tile in the tile set image, in pixels.")
	tiles.tileSetTileSize = [d.x, d.y]
	
	d = sizeToXY(tiles.extent)
	d.x = inputNumber("Tile map columns ", d.x, "Extent (in X) of your level layout, in tiles.")
	d.y = inputNumber("Tile map rows    ", d.y, "Extent (in Y) of your level layout, in tiles.")
	tiles.extent = [d.x, d.y]
	
	d = sizeToXY(tiles.cellSize)
	d.x = inputNumber("Tile map tile width ", d.x, "Size (width) of a tile on screen, in pixels.")
	d.y = inputNumber("Tile map tile height", d.y, "Size (height) of a tile on screen, in pixels.")
	tiles.cellSize = [d.x, d.y]
	
	d = sizeToXY(tiles.overlap)
	d.x = inputNumber("Tile map tile overlap (x)", d.x, "How much (in pixels) tiles should overlap horizontally on screen.")
	d.y = inputNumber("Tile map tile overlap (y)", d.y, "How much (in pixels) tiles should overlap vertically on screen.")
	tiles.overlap = [d.x, d.y]
	
	tiles.oddRowOffset = inputNumber("Tile map odd row offset", tiles.oddRowOffset, "Normally 0, but set to 0.5 for row-aligned hex map.")
	tiles.oddColOffset = inputNumber("Tile map odd col offset", tiles.oddColOffset, "Normally 0, but set to 0.5 for column-aligned hex map.")
end function	
	
createNew = function
	while true
		globals.tileSetPath = input("Tile set path? ") - ".png" + ".png"
		tiles.tileSet = file.loadImage(tileSetPath)
		if tiles.tileSet != null then break
		print "Unable to load image at " + tileSetPath + EOL
	end while
	tiles.tileSetTileSize = 64
	tiles.cellSize = 64
	tiles.extent = [gfx.width / tiles.cellSize, gfx.height / tiles.cellSize]
	tiles.clear
	editMapParams
	tiles.clear
	globals.layoutFilePath = ""
end function

loadExisting = function
	while true
		path = input("Layout path? ")
		if not path then continue
		info = file.info(path)
		if not info then
			print "Invalid path." + EOL
			continue
		end if
		if info.isDirectory then
			print "Invalid path (that's a directory, not a file)." + EOL
			continue
		end if		
		globals.layoutFilePath = path
		break
	end while
	tileUtil.loadFromFile layoutFilePath, tiles
end function

saveToFile = function
	text.column = 0
	if layoutFilePath == "" then
		globals.layoutFilePath = input("Save layout to path: ")
		if layoutFilePath == "" then return
	end if
	tileUtil.saveToFile layoutFilePath, tiles
	print "Saved data to " + layoutFilePath + EOL
	print "(Press any key to continue.)"
	key.get
	text.clear
end function

selectBrush = function(index)
	count = tileSetRows * tileSetCols
	if index < 0 then index = index + count
	if index >= count then index = index - count
	globals.brush = index
end function

pickBrushDialog = function
	img = tiles.tileSet
	scale = min(512/img.width, 512/img.height)
	destw = img.width * scale
	desth = img.height * scale
	left = 480 - destw/2
	right = 480 + destw/2
	bottom = 320 - desth/2
	top = 320 + desth/2
	gfx.fillRect left-10, bottom-10, destw+20, desth+40, color.gray
	gfx.drawImage img, left, bottom, destw, desth
	cellSize = sizeToXY(tiles.tileSetTileSize)
	for x in range(left, right+1, cellSize.x * scale)
		gfx.line x, top, x, bottom, color.white
	end for
	for y in range(bottom, top+1, cellSize.y * scale)
		gfx.line left, y, right, y, color.white
	end for
	gfx.print "SELECT BRUSH TILE", 400, top + 6, color.black, "small"
	while true
		if not mouse.button or mouse.x < left or mouse.x > right or 
		   mouse.y < bottom or mouse.y > top then continue
		col = floor((mouse.x - left) / (cellSize.x * scale))
		row = floor((top - mouse.y) / (cellSize.y * scale))
		columns = floor(img.width / cellSize.x)
		globals.brush = row * columns + col
		break
	end while
	gfx.fillRect left-10, bottom-10, destw+20, desth+40, color.clear
	while mouse.button; end while
end function

showCursorInfo = function(col, row)
	text.row = 0
	text.column = 0
	print "Pixel: " + mouse.x + ", " + mouse.y + "    "
	text.column = 19
	print "Tile: " + col + ", " + row + "    "
	text.column = 33
	val = tiles.cell(col, row)
	if val == null then val = "null"
	print "Cell value: " + val + "    "
	text.column = 52
	print "Brush: " + brush
	for i in range(text.column, 67)
		text.setCell i, 0, " "
	end for
end function

checkKeys = function
	if not key.available then return
	k = key.get.upper
	if k == char(17) then  // left arrow
		selectBrush brush - 1
	else if k == char(18) then  // right arrow
		selectBrush brush + 1
	else if k == char(19) then  // up arrow
		selectBrush brush - tileSetCols
	else if k == char(20) then  // down arrow
		selectBrush brush + tileSetCols
	else if k == "S" then   // Save
		gfx.fillRect 0, 32, gfx.width, gfx.height-32, "#000000DD"
		text.row = 20
		saveToFile
		gfx.fillRect 0, 32, gfx.width, gfx.height-32, color.clear	
	else if k == "E" then   // Edit Parameters
		gfx.fillRect 0, 32, gfx.width, gfx.height-32, "#000000DD"
		text.row = 20
		editMapParams
		text.clear
		gfx.fillRect 0, 32, gfx.width, gfx.height-32, color.clear	
	end if
end function

scroll = function(dx, dy)
	tiles.scrollX = tiles.scrollX + 10 * dx
	if tiles.scrollX < 0 then tiles.scrollX = 0
	tiles.scrollY = tiles.scrollY + 10 * dy
	if tiles.scrollY < 0 then tiles.scrollY = 0
end function

mouseScroll = function
	if mouse.x < 1 then scroll -1, 0
	if mouse.x > gfx.width-2 then scroll 1, 0
	if mouse.y < 1 then scroll 0, -1
	if mouse.y > gfx.height-2 then scroll 0, 1
end function

brush = 0

handleClickInBottomBar = function
	while mouse.button; end while
	pickBrushDialog
end function

// Main edit loop: paint the map with the mouse!
editLoop = function
	cellSize = sizeToXY(tiles.cellSize)
	overlap = sizeToXY(tiles.overlap)
	grid = {"x":cellSize.x + overlap.x, "y":cellSize.y + overlap.y}
	mouseWasDown = false
	while not key.pressed("escape")
		checkKeys
		row = floor((mouse.y + tiles.scrollY) / grid.y)
		col = floor((mouse.x + tiles.scrollX) / grid.x)
		if mouse.button then
			if not mouseWasDown then
				if mouse.y < 32 then
					handleClickInBottomBar
					continue
				end if
				erasing = (tiles.cell(col,row) == brush)
			end if
			if erasing then
				tiles.setCell col, row, null
			else
				tiles.setCell col, row, brush
			end if
			mouseWasDown = true
		else
			mouseWasDown = false
			if mouse.button(1) then
				// right-click: set brush to current tile
				selectBrush tiles.cell(col, row)
			end if
		end if
		showCursorInfo col, row
		mouseScroll
		yield
	end while
end function

display(6).mode = displayMode.tile
tiles = display(6)
tiles.clear
tiles.scrollX = 0
tiles.scrollY = 0

display(5).mode = displayMode.pixel
gfx = display(5)
gfx.clear color.clear
gfx.fillRect 0, 0, gfx.width, 32, "#00000088"

text.delimiter = ""
_printMark "`N`ew layout, or `L`oad existing layout? "
if getOption(["New", "Load"]) == "New" then
	createNew
else
	loadExisting
end if
tileSetTileSize = sizeToXY(tiles.tileSetTileSize)
tileSetRows = floor(tiles.tileSet.height / tileSetTileSize.y)
tileSetCols = floor(tiles.tileSet.width / tileSetTileSize.x)

text.clear

editLoop

key.clear
text.delimiter = EOL

// Maze demo, using a Wang 2-Corner tile set.
// See http://www.cr31.co.uk/stagecast/wang/2corn.html

import "listUtil"

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

display(7).mode = displayMode.pixel
display(7).fillRect 0, 0, 13*64, 10*64, "#939FFFFF"

map = file.readLines("/usr/data/td-maps.txt")
if map == null then map = file.readLines("/sys/data/td-maps.txt")
if not map[-1] then map.remove -1
map.reverse // (since coordinates are bottom-up)
mapH = map.len; mapW = map[0].len

inBounds = function(x,y)
	return x >= 0 and x < mapW and y >= 0 and y < mapH
end function

isLand = function(x,y)
	return not inBounds(x,y) or map[y][x] != "w"
end function

isPath = function(x,y)
	if inBounds(x,y) then return map[y][x] == "#"
	if x < 0 then x = 0
	if x >= mapW then x = mapW-1
	if y < 0 then y = 0
	if y >= mapH then y = mapH-1
	return map[y][x] == "#"
end function

prepareMap = function
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

prepareMap

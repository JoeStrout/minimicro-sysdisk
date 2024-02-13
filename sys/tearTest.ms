// Graphics Tearing Test
clear
display(5).mode = displayMode.tile
td = display(5)
td.tileSet = Image.create(2, 1, color.black)
td.tileSet.setPixel 0, 0, color.silver
td.tileSetTileSize = 1
td.cellSize = 64
td.extent = [17,12]
for x in range(0, 16)
	for y in range(0, 11)
		td.setCell x, y, (x+y)%2
	end for
end for



spr = new Sprite
spr.image = file.loadImage("/sys/pics/shapes/Square.png")
spr.scale = 4
spr.tint = color.red
spr.x = 480; spr.y = 360
spr.dx = 5; spr.dy = -3
display(4).sprites.push spr

while true
	td.scrollX = (td.scrollX + 2) % (td.cellSize*2)
	td.scrollY = (td.scrollY + 1) % (td.cellSize*2)
	spr.x += spr.dx
	if spr.x > 900 and spr.dx > 0 then spr.dx = -spr.dx
	if spr.x < 60 and spr.dx < 0 then spr.dx = -spr.dx
	spr.y += spr.dy
	if spr.y > 580 and spr.dy > 0 then spr.dy = -spr.dy
	if spr.y < 60 and spr.dy < 0 then spr.dy = -spr.dy
	wait 0.01
end while




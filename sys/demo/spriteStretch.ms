import "mathUtil"
clear
print "Grab any corner and drag with the mouse."

stretch = file.loadSound("/sys/sounds/stretch.wav")
stretch.loop = true

spr = new Sprite
spr.image = file.loadImage("/sys/pics/textures/BricksRed.png")
spr.x = 480
spr.y = 320
display(4).sprites.push spr
corners = spr.corners

dragCorner = function(index)
	text.row = 1; print "Dragging corner " + index
	stretch.play
	volume = 0.5
	prevPos = [mouse.x, mouse.y]
	while mouse.button
		yield
		newPos = [mouse.x, mouse.y]
		d = mathUtil.distance(newPos, prevPos)
		volume = mathUtil.moveTowards(volume, d/10, 0.05)
		stretch.adjust volume
		if d == 0 then continue
		corners[index] = newPos
		spr.setCorners corners
		prevPos = newPos
	end while
	stretch.stop
	text.row = 1; print " " * 60
end function

while true
	if mouse.button then
		bestIndex = null
		bestDist = 200
		for i in corners.indexes
			d = mathUtil.distance(mouse, corners[i])
			if d < bestDist then
				bestDist = d
				bestIndex = i
			end if
		end for
		if bestIndex != null then dragCorner bestIndex
	end if
	
	yield
	if key.pressed("escape") then exit
end while



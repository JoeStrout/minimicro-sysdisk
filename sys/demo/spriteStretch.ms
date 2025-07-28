import "mathUtil"
import "textUtil"
printAt = @textUtil.printAt

clear
printAt 6, 25, "Grab any corner below and"
printAt 6, 24, "drag with the mouse."

printAt 40,25, "Or, drag a UV (texture)"
printAt 40,24, "handle to change what part"
printAt 40,23, "of the image is used."

stretch = file.loadSound("/sys/sounds/stretch.wav")
stretch.loop = true

spr = new Sprite
spr.image = file.loadImage("/sys/pics/textures/BricksRed.png")
spr.x = 240
spr.y = 320
display(4).sprites.push spr
corners = spr.corners

display(6).mode = displayMode.pixel
bgfx = display(6)
bgfx.clear
uvX = 720 - spr.image.width/2
uvY = 320 - spr.image.height/2
bgfx.drawImage spr.image, uvX, uvY

uvHandles = []
drawUVs = function
	gfx.clear
	gfx.color = color.yellow
	uvs = spr.uvs
	if not uvs then return
	lastpt = null
	outer.uvHandles = [null] * 4
	for i in [0,1,2,3,0]
		uv = uvs[i]
		pt = [uvX + uv[0] * spr.image.width,
		  uvY + uv[1] * spr.image.height]  
		if lastpt != null then
			gfx.line lastpt[0], lastpt[1], pt[0], pt[1]
		end if
		gfx.fillEllipse pt[0]-4, pt[1]-4, 9, 9
		lastpt = pt
		uvHandles[i] = pt
	end for
end function

drawUVs

dragCorner = function(index)
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
		text.row = 1; print "Dragging corner " + index +
		  " to: " + newPos + " " * 20	
	end while
	stretch.stop
	text.row = 1; print " " * 60
end function

dragUV = function(index)
	stretch.play
	volume = 0.5
	prevPos = [mouse.x, mouse.y]
	uvs = spr.uvs
	while mouse.button
		yield
		newPos = [mouse.x, mouse.y]
		d = mathUtil.distance(newPos, prevPos)
		volume = mathUtil.moveTowards(volume, d/10, 0.05)
		stretch.adjust volume
		if d == 0 then continue
		uvHandles[index] = newPos
		uvs[index][0] = (newPos[0] - uvX) / spr.image.width
		uvs[index][1] = (newPos[1] - uvY) / spr.image.height
		spr.setUVs uvs
		prevPos = newPos
		drawUVs
		text.row = 1
		print "Dragging uv " + index + " to: " + 
		  uvs[index] + " " * 10
	end while
	stretch.stop
	text.row = 1; print " " * 60
end function

while true
	yield
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
		if bestIndex != null then
			dragCorner bestIndex
			continue
		end if
		for i in uvHandles.indexes
			d = mathUtil.distance(mouse, uvHandles[i])
			if d < bestDist then
				bestDist = d
				bestIndex = i
			end if
		end for
		if bestIndex != null then dragUV bestIndex		
	end if
	
	yield
	if key.pressed("escape") then exit
end while



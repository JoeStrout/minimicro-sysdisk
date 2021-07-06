// Angles and Rotations
//
// A little educational demo to help you understand angles,
// rotations, and the functions that work with them.
clear

// layout constants
circCX = 700
circCY = 400
circR = 120

// color constants
bgColor = "#00000D"
degreeColor = "#CC00CC"
radianColor = "#00CC00"

// program state
curAng = 90  // currently displayed angle, in degrees

// setup
sprite = new Sprite
sprite.image = file.loadImage("/sys/pics/Wumpus.png")
sprite.x = circCX
sprite.y = circCY
display(4).sprites.push sprite

pointOnCircle = function(ang=null, radius=null)
	if ang == null then ang = curAng
	if radius == null then radius = circR
	return [
	  circCX + radius * cos(ang*pi/180), 
	  circCY + radius * sin(ang*pi/180) ]
end function

printCentered = function(s, x, y, textColor)
	gfx.print s, x - s.len*9/2, y, textColor, "small"
end function

drawCircleDisplay = function()
	gfx.fillRect circCX-circR-150, circCY-circR-150,
	circR*2+300, circR*2+200, bgColor
	sprite.rotation = curAng
	
	gfx.color = color.gray
	gfx.drawEllipse circCX-circR, circCY-circR,
	circR*2, circR*2
	gfx.line circCX-circR-20, circCY, circCX+circR+20, circCY
	gfx.line circCX, circCY-circR-20, circCX, circCY+circR+20
	
	gfx.color = color.yellow
	if curAng != 0 then
		outer.poly = []
		for ang in range(0, curAng, 3 * sign(curAng))
			poly.push pointOnCircle(ang, circR-4)
		end for
		poly.push pointOnCircle(curAng)
		for ang in range(curAng, 0, -3 * sign(curAng))
			poly.push pointOnCircle(ang, circR+4)
		end for
		poly.push pointOnCircle(0, circR+4)
		gfx.fillPoly poly
	end if
	pA = pointOnCircle(curAng, circR-4)
	pB = pointOnCircle(curAng, circR+15)
	gfx.line pA[0], pA[1], pB[0], pB[1]
	
	radians = round(curAng * pi/180, 2)
	textPos = pointOnCircle(curAng, circR+30)
	x = textPos[0] + cos(radians) * 50
	y = textPos[1] + 2
	printCentered curAng + " degrees", x, y, degreeColor
	printCentered radians + " radians", x, y-16, radianColor	
	
	degStr = str(curAng)
	radStr = str(radians)
	x = circCX - (degStr.len + 6)*9
	y = circCY - circR - 60
	gfx.print degStr, x, y, degreeColor, "small"
	printCentered "* pi/180 =", circCX, y, color.silver
	x = circCX + 6*9
	gfx.print radStr, x, y, radianColor, "small"
	
	x = circCX - (radStr.len + 6)*9
	y = circCY - circR - 76
	gfx.print radStr, x, y, radianColor, "small"
	printCentered "* 180/pi =", circCX, y, color.silver
	x = circCX + 6*9
	gfx.print degStr, x, y, degreeColor, "small"
	
end function

handleClick = function()
	radians = atan(mouse.y - circCY, mouse.x - circCX)
	newAng = round(radians * 180/pi)
	if newAng != curAng then
		globals.curAng = newAng
		drawCircleDisplay
	end if
end function

drawCircleDisplay

while true
	yield
	if mouse.button then handleClick
end while

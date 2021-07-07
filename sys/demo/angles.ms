// Angles and Rotations
//
// A little educational demo to help you understand angles,
// rotations, and the functions that work with them.
import "chars"
clear

// layout constants
circCX = 700
circCY = 470
circR = 120
triX = 700
triY = 160
triR = 80

// color constants
bgColor = "#00000D"
degreeColor = "#CC00CC"
radianColor = "#00CC00"

// program state
curAng = 60  // currently displayed angle, in degrees
negativeAngles = true  // whether to show negative angles

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

rectify = function(angle)
	if angle > 180 and negativeAngles then
		return angle - 360
	else if angle < 0 and not negativeAngles then
		return angle + 360
	end if
	return angle	
end function

printCentered = function(s, x, y, textColor)
	s = str(s)
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
		poly.push pointOnCircle(curAng, circR-4)
		poly.push pointOnCircle(curAng, circR+4)
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

drawTriDisplay = function()
	gfx.fillRect triX-triR-80, triY-triR-100,
	triR*2+200, triR*2+100, bgColor
	
	radians = curAng * pi/180
	x = triX + triR * cos(radians)
	y = triY + triR * sin(radians)
	gfx.color = color.silver
	gfx.line triX, triY, x, y, color.white
	gfx.line triX, triY, x, triY
	gfx.line x, y, x, triY
	xstr = str(round(cos(radians), 2)) + "*d"
	ystr = str(round(sin(radians), 2)) + "*d"
	if sin(radians) >= 0 then
		printCentered xstr, (triX + x)/2, triY-20, color.white
	else
		printCentered xstr, (triX + x)/2, triY+2, color.white	
	end if
	if cos(radians) >= 0 then
		gfx.print ystr, x + 2, (triY + y)/2 - 8, color.white, "small"
		gfx.print "d", (triX+x)/2-11, (triY+y)/2-10*(sin(radians)<0), color.white, "small"
	else
		gfx.print ystr, x - 2 - ystr.len*9, (triY + y)/2 - 8, color.white, "small"		
		gfx.print "d", (triX+x)/2+2, (triY+y)/2-10*(sin(radians)<0), color.white, "small"
	end if
	
	rstr = str(round(radians, 2))
	xstr = xstr[:-2]
	ystr = ystr[:-2]
	y = 16*3
	x = triX - 70
	gfx.print "cos(", x, y, color.white, "small"
	gfx.print rstr, x+4*9, y, radianColor, "small"
	gfx.print ") = " + xstr, x+(4+rstr.len)*9, y, color.white, "small"
	y = y - 16
	gfx.print "sin(", x, y, color.white, "small"
	gfx.print rstr, x+4*9, y, radianColor, "small"
	gfx.print ") = " + ystr, x+(4+rstr.len)*9, y, color.white, "small"
	y = y - 16
	s = "atan(" + ystr + ", " + xstr + ") = "
	gfx.print s, x, y, color.white, "small"
	gfx.print rstr, x+s.len*9, y, radianColor, "small"
	
end function

trackMouse = function(centerX, centerY)
	while mouse.button
		yield
		radians = atan(mouse.y - centerY, mouse.x - centerX)
		newAng = rectify(round(radians * 180/pi))
		if newAng != curAng then
			globals.curAng = newAng
			drawCircleDisplay
			drawTriDisplay
		end if
	end while
end function

string.indexOfFirst = function(options, after=-1)
	result = null
	for opt in options
		i = self.indexOf(opt, after)
		if i != null and (result == null or i < result) then
			result = i
		end if
	end for
	return result
end function

printMarkup = function(s)
	text.delimiter = ""
	while s
		endPos = s.indexOfFirst(["<D>", "<R>", "</>"])
		if endPos == null then
			print s
			break
		else if endPos > 0 then
			print s[:endPos]
			s = s[endPos:]
			continue
		end if
		tag = s[:3]
		if tag == "<D>" then text.color = degreeColor
		if tag == "<R>" then text.color = radianColor
		if tag == "</>" then text.color = color.white
		s = s[3:]
	end while
	text.delimiter = char(13)
	print
end function

printInfo = function()
	text.row = 25
	text.color = color.white
	printMarkup "Angles can be measured in two"
	printMarkup "different ways: <D>degrees</> or <R>radians</>."
	print
	printMarkup "<D>Degrees</> run from <D>0</> to <D>360</> (or"
	printMarkup "<D>-180</> to <D>180</>).  <R>Radians</> run from"
	printMarkup "<R>0</> to <R>2*pi</> (or <R>-pi</> to <R>pi</>)."
	printMarkup "They're just two ways of "
	printMarkup "expressing the same idea: how"
	printMarkup "far to go around a circle."
	print
	printMarkup "You can assign an angle in <D>degrees</>"
	printMarkup "to the <D>.rotation</> of a sprite to"
	printMarkup "set the angle of that sprite."
	print
	printMarkup "You can treat an angle in <R>radians</>"
	printMarkup "like a direction, and use the <R>cos</>"
	printMarkup "and <R>sin</> functions (times a distance"
	printMarkup "d) to find the X and Y step in that"
	printMarkup "direction.  Or, if you have X and Y,"
	printMarkup "you can use <R>atan</> to find the direction."
	print
	printMarkup "Click and drag at right to explore"
	printMarkup "different angles!"
	text.delimiter = ""; text.row = 0; text.color = color.silver
	print chars.checkedBox + " Use negative angles"
	text.row = 25; text.delimiter = char(13)
end function

toggleNegativeAngles = function()
	globals.negativeAngles = not negativeAngles
	if negativeAngles then b = chars.checkedBox else b = chars.emptyBox
	text.setCell 0, 0, b
	
	globals.curAng = rectify(curAng)
	drawCircleDisplay
	drawTriDisplay
	
	while mouse.button; yield; end while // wait for mouse-up	
end function	

printInfo
drawCircleDisplay
drawTriDisplay

while true
	yield
	if mouse.button then
		if mouse.x < 480 then
			if mouse.y < 30 then toggleNegativeAngles
		else if mouse.y > triY + 120 then
			trackMouse circCX, circCY
		else
			trackMouse triX, triY
		end if
	else if key.available then
		k = key.get
		if k == char(27) or k == "q" then break
	end if
end while

text.row = 0
print; print
text.color = color.orange

// This demo draws a 3D rotating sphere on a SpriteDisplay.
// This works by dividing the sphere into a bunch of little
// square-ish faces, making a sprite for each one from the
// corresponding part of our Earth map, and then using some
// trigonometry (sin and cos) to adjust the position of
// the corners of each face over time.

bigMapImg = file.loadImage("/sys/pics/earth_day.jpg")

clear
sprites = display(4).sprites

sections = 12  // how many longitudinal sections (east/west)
secW = bigMapImg.width / sections
rings = 8      // how many latitudinal sections (north/south)
ringH = bigMapImg.height / rings
R = 200  // globe radius on screen

// build a sprite for each little rectangular portion of the map
for i in range(0, sections-1)
	for j in range(0, rings-1)
		sp = new Sprite
		sp.image = bigMapImg.getImage(i*secW, j*ringH, secW, ringH)
		yangBot = (10 + 160/rings * j) * pi/180
		yangTop = (10 + 160/rings * (j+1)) * pi/180
		sp.yBot = 320 - R * cos(yangBot)
		sp.yTop = 320 - R * cos(yangTop)
		sp.rBot = R * sin(yangBot) // radius at bottom
		sp.rTop = R * sin(yangTop) // radius at top
		sp.x = 480; sp.y = (sp.yBot + sp.yTop)/2
		sp.angLeft = i * 2*pi/sections
		sp.angRight = (i+1) * 2*pi/sections
		sprites.push sp
	end for	
end for

// position all the sprites where they should be on screen
// for the given rotation
positionSprites = function(rotDegrees)
	dang = rotDegrees * pi/180
	for sp in sprites
		corners = []
		corners.push [480+sp.rBot*cos(sp.angLeft+dang), sp.yBot]
		corners.push [480+sp.rBot*cos(sp.angRight+dang), sp.yBot]
		corners.push [480+sp.rTop*cos(sp.angRight+dang), sp.yTop]
		corners.push [480+sp.rTop*cos(sp.angLeft+dang), sp.yTop]
		sp.setCorners  corners
		if corners[1][0] > corners[0][0] then
			sp.tint = color.white
		else
			sp.tint = color.clear
		end if
	end for	
end function

// Main program: animate the globe!
rot = 0
startTime = time
while not key.pressed("escape") and not key.pressed("q")
	yield
	positionSprites rot
	rot = rot + 1
	if env.hasIndex("shell") and env.shell and env.autorun then
		// in auto-run mode, exit after 20 seconds
		if time - startTime > 20 then exit
	end if
end while
key.clear


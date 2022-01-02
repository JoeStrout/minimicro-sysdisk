// Road demo.  This program illustrates how to make a 
// pseudo-3D effect, like the classic arcade game "Outrun",
// by stretching each road-section sprite so that it appears
// to lay flat, and they recede into the distance.

import "listUtil"

clear
sd = display(4)

RoadSprite = new Sprite
RoadSprite.image = file.loadImage("/sys/pics/textures/Road.png")
RoadSprite.turn = 0
RoadSprite.slope = 0

// Prepare a list of road sections.  We'll move these down
// and adjust them on each frame to make an infinite road.
roadSprites = []
for i in range(15)
	roadSprites.push new RoadSprite
	if i % 2 == 0 then roadSprites[-1].tint = color.silver
end for
sd.sprites = roadSprites

// Perspective factor: how much things should appear smaller
// as they get further away (z).
perspectiveFactor = function(z)
	return 300 / (300 + z)
end function

// Update all the road sprites, with the first one
// having its bottom at the given z.
updateSprites = function(z=0)	
	midx = 480
	angle = 0
	elevation = 0
	
	p = perspectiveFactor(z)
	y = 320 - 320 * p
	sectionHeight = 60 * p
	rhw = 300 * p
	
	for spr in roadSprites
		// section bottom (near side)
		spr.x = midx
		sectionHeight = 320-320*perspectiveFactor(z+200) - y
		spr.y = y + sectionHeight/2
		corners = [[midx-rhw, y], [midx+rhw, y]]
		
		if y >= 0 then
			angle = angle + spr.turn
			elevation = elevation + spr.slope
		else
			// apply just some fraction of the angle,
			// based on how much of this section is visible
			f = (sectionHeight+y)/sectionHeight
			angle = angle + spr.turn * f
			elevation = elevation + spr.slope * f
		end if
		
		// section top (far side)
		z = z + 200
		p = perspectiveFactor(z)
		y = 320 + (3*elevation - 320) * p
		rhw = 300 * p
		midx = midx + 100 * angle/500
		corners.push [midx+rhw, y]
		corners.push [midx-rhw, y]
		spr.setCorners corners
	end for
end function

// Track sections: each road section will get two numbers:
// [turn, slope].
straight = [[0,0]] * 15
rightTurn = [[1,0], [5,0], [10,0]] + [[20,0]]*10 + [[10,0], [5,0], [1,0]]
leftTurn = [[-1,0], [-5,0], [-10,0]] + [[-20,0]]*10 + [[-10,0], [-5,0], [-1,0]]
leftRight = leftTurn + rightTurn
rightLeft = rightTurn + leftTurn
slopeUp = []; slopeDown = []
for i in range(1,20)
	slopeUp.push [0, i]; slopeDown.push [0, -i]
end for
for i in range(20, 1)
	slopeUp.push [0, i]; slopeDown.push [0, -i]
end for

// Define our track by combining track sections.
track = straight + leftTurn + slopeUp + slopeDown + rightTurn + 
 straight + slopeDown + leftTurn + slopeUp + straight +
 leftRight + straight + rightLeft + rightLeft + straight

text.row = 25
prevColor = text.color
text.color = "#444444"
print "Press Esc to quit, any other key to pause/step,"
print "and Return to unpause."
text.color = prevColor

// Main loop.
trackIdx = 0
z = 0
paused = false
while true
	updateSprites z
	z = z - 20
	if z < -200 then
		newSection = roadSprites.pull
		newSection.turn = track[trackIdx][0]
		newSection.slope = track[trackIdx][1]
		trackIdx = (trackIdx + 1) % track.len
		roadSprites.push newSection
		sd.sprites = roadSprites[:]
		sd.sprites.reverse	
		z = z + 200
	end if
	yield
	if paused then
		if key.get == char(10) then paused = false
	else 		if key.available then
		paused = true
	end if
	if key.pressed("escape") then exit
end while


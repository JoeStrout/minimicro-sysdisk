// A simple (but fun!) desktop environment for Mini Micro.

import "events"
import "listUtil"

// ToDo: update this path when we have updated the sys disk!
gfxSource = file.loadImage("/usr/data/desktop/desktopGfx.png")

//----------------------------------------------------------------------
// Image9Slice class: an image wrapper with margins that are not stretched,
// and a middle that is stretched when drawn to any size.
//----------------------------------------------------------------------

Image9Slice = {}
Image9Slice.image = null		// (an Image instance)
Image9Slice.leftMargin = 0
Image9Slice.bottomMargin = 0
Image9Slice.rightMargin = 0
Image9Slice.topMargin = 0

Image9Slice.make = function(image, left=12, bottom=12, right=12, top=12)
	noob = new Image9Slice
	noob.image = image
	noob.leftMargin = left
	noob.bottomMargin = bottom
	noob.rightMargin = right
	noob.topMargin = top
	return noob
end function

Image9Slice.draw = function(g, left, bottom, width, height)
	midH = height - self.bottomMargin - self.topMargin
	srcH = self.image.height - self.bottomMargin - self.topMargin
	nearTop = bottom + height - self.topMargin
	srcNearTop = self.image.height - self.topMargin
	midW = width - self.leftMargin - self.rightMargin
	srcW = self.image.width - self.leftMargin - self.rightMargin
	nearRight = left + width - self.rightMargin
	srcNearRight = self.image.width - self.rightMargin
	
	// left side (bottom, middle, top)
	g.drawImage self.image, 
		left, bottom, self.leftMargin, self.bottomMargin,
		0, 0, self.leftMargin, self.bottomMargin
	g.drawImage self.image, 
		left, bottom + self.bottomMargin, self.leftMargin, midH,
		0, self.bottomMargin, self.leftMargin, srcH
	g.drawImage self.image, 
		left, nearTop, self.leftMargin, self.topMargin,
		0, srcNearTop, self.leftMargin, self.topMargin
	
	// center section (bottom, middle, top)
	g.drawImage self.image, 
		left + self.leftMargin, bottom, midW, self.bottomMargin,
		self.leftMargin, 0, srcW, self.bottomMargin
	g.drawImage self.image, 
		left + self.leftMargin, bottom + self.bottomMargin, midW, midH,
		self.leftMargin, self.bottomMargin, srcW, srcH
	g.drawImage self.image, 
		left + self.leftMargin, nearTop, midW, self.topMargin,
		self.leftMargin, srcNearTop, srcW, self.topMargin
	
	// right section (bottom, middle, top)
	g.drawImage self.image, 
		nearRight, bottom, self.rightMargin, self.bottomMargin,
		srcNearRight, 0, self.rightMargin, self.bottomMargin
	g.drawImage self.image, 
		nearRight, bottom + self.bottomMargin, self.rightMargin, midH,
		srcNearRight, self.bottomMargin, self.rightMargin, srcH
	g.drawImage self.image, 
		nearRight, nearTop, self.rightMargin, self.topMargin,
		srcNearRight, srcNearTop, self.rightMargin, self.topMargin	
end function

//----------------------------------------------------------------------
// Load/define the images from our resources sheet
//----------------------------------------------------------------------

images = {}
images.menuBar = gfxSource.getImage(0, 488, 24, 24)
images.windowBox = Image9Slice.make(gfxSource.getImage(0, 0, 48, 48))
images.titleBar = Image9Slice.make(gfxSource.getImage(96, 0, 64, 36), 12, 0, 12, 0)
images.shadow = Image9Slice.make(gfxSource.getImage(0, 48, 80, 80), 32, 32, 32, 32)
images.titleShadow = Image9Slice.make(gfxSource.getImage(80, 64, 96, 48), 32, 0, 32, 32)
clear; print

display(6).mode = displayMode.solidColor
backgroundDisp = display(6)
backgroundDisp.color = "#7EBDC5FF"

if globals.hasIndex("DEBUG") and DEBUG then
	display(5).mode = displayMode.pixel
	scratchDisp = display(5)
else
	display(5).mode = displayMode.off
	display(7).mode = displayMode.pixel
	scratchDisp = display(7)
end if	
scratchDisp.clear color.clear

display(4).mode = displayMode.sprite
spriteDisp = display(4)
spriteDisp.clear
events.spriteDisplay = spriteDisp

display(2).mode = displayMode.pixel
menuDisp = display(2)
menuDisp.clear color.clear, 960+16, 640+16
menuDisp.scrollX = 8; menuDisp.scrollY = 7

//----------------------------------------------------------------------
// General drawing functions
//----------------------------------------------------------------------

drawMenuBar = function
	menuDisp.drawImage images.menuBar, 0, 624, 960+16, 24
end function

//----------------------------------------------------------------------
// Constants
//----------------------------------------------------------------------
for k in ("kDragMove kDragResizeR kDragResizeBR kDragResizeB kDragResizeBL" +
" kDragResizeL kDragResizeTL kDragResizeT kDragResizeTR").split
	globals[k] = k		// just defines a unique global constant
end for


//----------------------------------------------------------------------
// Window class and related methods
//----------------------------------------------------------------------

// Make an image for the window sprite, given the content size and title bar parameters.
makeWindowImage = function(width, height, titleLeft=0, titleWidth=150, title="Untitled")
	scratchDisp.clear color.clear
	images.windowBox.draw scratchDisp, 0, 0, width+16, height+16
	images.titleBar.draw scratchDisp, titleLeft, height+12, titleWidth, 36
	scratchDisp.print title, titleLeft+16, height+24, "#444444", "small"
	return scratchDisp.getImage(0, 0, width+16, height+48)
end function

// Make a shadow image to go under the window sprite.
makeWindowShadow = function(width, height, titleLeft=0, titleWidth=150)
	scratchDisp.clear color.clear
	images.shadow.draw scratchDisp, 0, 0, width+48, height+48
	images.titleShadow.draw scratchDisp, titleLeft, height+20, titleWidth+32, 64
	return scratchDisp.getImage(0, 0, width+48, height+88)
end function

Window = new events.EventSprite
Window.dragMode = null
Window.dragOffset = [0,0]  // (position of window relative to mouse)

Window.make = function(width=300, height=200, titleLeft=0, titleWidth=150, title="Untitled")
	w = new Window
	w.image = makeWindowImage(width, height, titleLeft, titleWidth, title)
	w.localBounds = new Bounds
	w.localBounds.width = width + 16
	w.localBounds.height = height + 16
	w.localBounds.y = -16  // (accounting for title bar)
	
	w.shadow = new Sprite
	w.shadow.image = makeWindowShadow(width, height, titleLeft, titleWidth)
	
	spriteDisp.sprites.push w.shadow
	spriteDisp.sprites.push w
	return w
end function

Window.goTo = function(x, y)
	self.x = x
	self.y = y
	extra = 2 * (self.dragMode == kDragMove)
	self.shadow.x = x + 4 + extra
	self.shadow.y = y - 4 - extra
end function

Window.moveToFront = function
	spriteDisp.sprites.removeVal self
	spriteDisp.sprites.removeVal self.shadow
	spriteDisp.sprites.push self.shadow
	spriteDisp.sprites.push self
end function

Window.onClick = function
	self.dragMode = kDragMove
	self.moveToFront
	self.goTo self.x-2, self.y+2
	self.dragOffset = [self.x - mouse.x, self.y - mouse.y]
end function

Window.onDrag = function
	if self.dragMode == kDragMove then
		self.goTo mouse.x + self.dragOffset[0], mouse.y + self.dragOffset[1]
	end if
end function

Window.onDragEnd = function
	self.dragMode = null
	self.goTo self.x+2, self.y-2
end function



drawMenuBar
window1 = Window.make(300, 200, 0, 150, "Window One")
window1.goTo 600, 300
window2 = Window.make(400, 250, 125, 150, "Window Two")
window2.goTo 300, 400

events.eventLoop.run
// This module provides classes and utilities for making GUI
// (Graphical User Interface) apps, like the desktop demo.

import "importUtil"
ensureImport "events"
ensureImport "bmfFonts"
ensureImport "mathUtil"

//----------------------------------------------------------------------
// Constants (and a few options)
//----------------------------------------------------------------------
// Values for Window.dragMode:
kDragMove = "kDragMove"			// moving the window
kDragResize = "kDragResize"		// stretching the window
kDragSelect = "kDragSelect"		// selecting stuff within the window
// Values returtned by Window.partHit:
kPartTitle = "kPartTitle"		// the window title bar
kPartFrame = "kPartFrame"		// the window frame
kPartResize = "kPartResize"		// the window resize box
kPartContent = "kPartContent"	// the window content area
// Things that may become options some day
selectionColor = "#CCCCFF"
scrollWheelSpeed = 50



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

Image9Slice.draw = function(g, left, bottom, width, height, tint="#FFFFFF")
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
	0, 0, self.leftMargin, self.bottomMargin, tint
	g.drawImage self.image, 
	left, bottom + self.bottomMargin, self.leftMargin, midH,
	0, self.bottomMargin, self.leftMargin, srcH, tint
	g.drawImage self.image, 
	left, nearTop, self.leftMargin, self.topMargin,
	0, srcNearTop, self.leftMargin, self.topMargin, tint
	
	// center section (bottom, middle, top)
	g.drawImage self.image, 
	left + self.leftMargin, bottom, midW, self.bottomMargin,
	self.leftMargin, 0, srcW, self.bottomMargin, tint
	g.drawImage self.image, 
	left + self.leftMargin, bottom + self.bottomMargin, midW, midH,
	self.leftMargin, self.bottomMargin, srcW, srcH, tint
	g.drawImage self.image, 
	left + self.leftMargin, nearTop, midW, self.topMargin,
	self.leftMargin, srcNearTop, srcW, self.topMargin, tint
	
	// right section (bottom, middle, top)
	g.drawImage self.image, 
	nearRight, bottom, self.rightMargin, self.bottomMargin,
	srcNearRight, 0, self.rightMargin, self.bottomMargin, tint
	g.drawImage self.image, 
	nearRight, bottom + self.bottomMargin, self.rightMargin, midH,
	srcNearRight, self.bottomMargin, self.rightMargin, srcH, tint
	g.drawImage self.image, 
	nearRight, nearTop, self.rightMargin, self.topMargin,
	srcNearRight, srcNearTop, self.rightMargin, self.topMargin, tint
end function

//----------------------------------------------------------------------
// Load resources
//----------------------------------------------------------------------

gfxSource = file.loadImage("/usr/data/desktop/desktopGfx.png")
if gfxSource == null then
	gfxSource = file.loadImage("/sys/data/desktop/desktopGfx.png")
end if

smallFont = bmfFonts.Font.load("/usr/fonts/minimicro-pro-12.bmf")
if smallFont == null then
	smallFont = bmfFonts.Font.load("/sys/fonts/minimicro-pro-12.bmf")
end if
medFont = bmfFonts.Font.load("/usr/fonts/minimicro-pro-16.bmf")
if medFont == null then
	medFont = bmfFonts.Font.load("/sys/fonts/minimicro-pro-16.bmf")
end if
largeFont = bmfFonts.Font.load("/usr/fonts/minimicro-pro-20.bmf")
if largeFont == null then
	largeFont = bmfFonts.Font.load("/sys/fonts/minimicro-pro-20.bmf")
end if

images = {}
images.menuBar = gfxSource.getImage(0, 488, 24, 24)
images.windowBox = Image9Slice.make(gfxSource.getImage(0, 0, 48, 48))
images.titleBar = Image9Slice.make(gfxSource.getImage(96, 0, 64, 36), 12, 0, 12, 0)
images.shadow = Image9Slice.make(gfxSource.getImage(0, 48, 80, 80), 32, 32, 32, 32)
images.titleShadow = Image9Slice.make(gfxSource.getImage(80, 64, 96, 48), 32, 0, 32, 32)
images.iconHighlight = gfxSource.getImage(192, 0, 80, 80)
images.rounded4 = Image9Slice.make(gfxSource.getImage(280, 0, 32, 32), 8, 8, 8, 8)

// scrollbar parts (H = Horizontal, V = Vertical)
images.sbTrackH = Image9Slice.make(gfxSource.getImage(32, 176, 32, 16), 8, 0, 8, 0)
images.sbThumbH = Image9Slice.make(gfxSource.getImage(0, 176, 32, 16), 8, 0, 8, 0)
images.sbNubsH = gfxSource.getImage(0, 160, 16, 16)
images.sbTrackV = Image9Slice.make(gfxSource.getImage(16, 192, 16, 32), 0, 8, 0, 8)
images.sbThumbV = Image9Slice.make(gfxSource.getImage(0, 192, 16, 32), 0, 8, 0, 8)
images.sbNubsV = gfxSource.getImage(16, 160, 16, 16)


//----------------------------------------------------------------------
// General drawing functions
//----------------------------------------------------------------------

// Clear our off-screen "scratch" display, used for drawing or 
// compositing things to create an image or sprite).
clearScratch = function(width=256, height=256, color="#FFFFFF")
	if width > scratchDisp.width or height > scratchDisp.height then
		scratchDisp.clear color, width, height
	else
		scratchDisp.clear color, scratchDisp.width, scratchDisp.height
	end if
end function

// Draw a menu bar.
drawMenuBar = function
	globals.gfx = menuDisp
	y = 624
	menuDisp.drawImage images.menuBar, 0, y, 960+16, 24
	x = 40
	for title in ["File", "Edit", "Window", "Help"]
		medFont.print title, x, y + 5, 1, color.black
		x = x + medFont.width(title) + 20
	end for
end function

//----------------------------------------------------------------------
// Scrollbar class and related methods and CONSTANTS
//----------------------------------------------------------------------
SB_THICKNESS = 16 //default thickness for any scrollbar

Scrollbar = {}
Scrollbar.left = 0
Scrollbar.bottom = 0
Scrollbar.width = SB_THICKNESS
Scrollbar.height = SB_THICKNESS
Scrollbar.minValue = 0
Scrollbar.maxValue = 100
Scrollbar.value = 0
Scrollbar.pageSize = 30
Scrollbar.thumbSprite = null
Scrollbar.onValueChanged = null
Scrollbar.right = function; return self.left + self.width; end function
Scrollbar.top = function; return self.bottom + self.height; end function

// Static method: draw a scrollbar track, without an instance.
// Note: both width and height must be >= 16, and one of them
// should be exactly 16, or behavior is undefined.
Scrollbar.drawTrack = function(g, x, y, width, height)
	if width > height then img = images.sbTrackH else img = images.sbTrackV
	img.draw g, x, y, width, height
end function

// Instance method: draw the background for this scrollbar
Scrollbar.drawBackground = function(g)
	Scrollbar.drawTrack g, self.left, self.bottom, self.width, self.height
end function

Scrollbar.createThumb = function
	sp = new events.EventSprite
	sp.localBounds = new Bounds
	// We need to receive clicks in the entire scrollbar area, not just
	// in the thumb.  So, we're going to set the bounds wide enough to
	// cover that whole area, and we'll just have to adjust its position
	// (in updateThumb) as it moves to keep it in the right place.
	sp.localBounds.width = self.width
	sp.localBounds.height = self.height
	sp.start
	sp.scrollbar = self
	sp.onClick = function; self.scrollbar.onClick; end function
	sp.onDrag = function; self.scrollbar.onDrag; end function
	sp.onDragEnd = function; self.scrollbar.onDragEnd; end function
	sp.tint = "#EEEEFF"
	self.thumbSprite = sp
end function

Scrollbar.onDragEnd = function
	self.thumbSprite.tint = "#EEEEFF"
end function


// ---------- Horizontal Scrollbar ----------
ScrollbarH = new Scrollbar
ScrollbarH.width = 100

// Draw a horizontal scrollbar thumb to the given pixel display.
ScrollbarH.drawThumb = function(g, x, y, width, tint="#FFFFFF")
	if width < 16 then width = 16
	images.sbThumbH.draw g, x, y, width, SB_THICKNESS, tint
	if width > 19 then
		g.drawImage images.sbNubsH, x + ceil(width/2-8), y, -1, -1,
		  0, 0, -1, -1, tint
	else
		// no room for full nubs -- draw only 10 pixels' worth
		g.drawImage images.sbNubsH, x + ceil(width/2-5), y, 10, 16,
		  0, 0, 10, 16, tint
	end if
end function

ScrollbarH.onClick = function
	// determine if we hit the thumb, or the track (and if track, which side)
	self.mouseOffset = null
	thumbSize = self.thumbSprite.image.width
	if mouse.x < self.thumbSprite.x - thumbSize/2 then
		// page left
		self.value = mathUtil.clamp(self.value - self.pageSize, self.minValue, self.maxValue)
		self.updateThumb
	else if mouse.x > self.thumbSprite.x + thumbSize/2 then
		// page right
		self.value = mathUtil.clamp(self.value + self.pageSize, self.minValue, self.maxValue)
		self.updateThumb
	else
		// click on thumb -- start a drag
		self.thumbSprite.tint = "#CCCCEE"
		self.mouseOffset = self.thumbSprite.x - mouse.x
	end if
end function

ScrollbarH.onDrag = function
	if self.mouseOffset == null then return
	newX = mouse.x + self.mouseOffset
	// Invert the math in updateThumb to calculate the value from the sprite position.
	valueRange = self.maxValue - self.minValue
	size = self.thumbSprite.image.width
	thumbLeft = newX - size/2
	frac = (thumbLeft - self.left) / (self.width - size)
	self.value = mathUtil.clamp(self.minValue + valueRange * frac, self.minValue, self.maxValue)
	self.updateThumb 
end function

ScrollbarH.updateThumb = function
	if self.thumbSprite == null then self.createThumb
	// Here are the somewhat tricky calculations for thumb size and position.
	// First, the thumb size.  This reflects how much the pageSize is out
	// of the total value range PLUS the pageSize.
	valueRange = self.maxValue - self.minValue
	size = round(self.width * (self.pageSize / (valueRange + self.pageSize)))
	// Then, the position.  The leftmost end of the thumb reflects the 
	// position of the current value within the range, as a fraction
	// of our total width MINUS the thumb size.
	frac = (self.value - self.minValue) / valueRange
	thumbLeft = self.left + (self.width - size) * frac
	// Now we can prepare the actual sprite
	if self.thumbSprite.image == null or self.thumbSprite.image.width != size then
		clearScratch size, SB_THICKNESS, color.clear
		self.drawThumb scratchDisp, 0, 0, size
		self.thumbSprite.image = scratchDisp.getImage(0, 0, size, SB_THICKNESS)
	end if
	self.thumbSprite.x = thumbLeft + size/2
	self.thumbSprite.y = self.bottom + SB_THICKNESS/2
	self.thumbSprite.localBounds.x = self.left + self.width/2 - self.thumbSprite.x
	self.onValueChanged
end function

// ---------- Vertical Scrollbar ----------
ScrollbarV = new Scrollbar
ScrollbarV.height = 100
ScrollbarV.topDown = true

// Draw a vertical scrollbar thumb to the given pixel display.
ScrollbarV.drawThumb = function(g, x, y, height, tint="#FFFFFF")
	if height < 16 then height = 16
	images.sbThumbV.draw g, x, y, SB_THICKNESS, height, tint
	if height > 19 then
		g.drawImage images.sbNubsV, x, y + ceil(height/2-8), -1, -1,
		  0, 0, -1, -1, tint
	else
		// no room for full nubs -- draw only 10 pixels' worth
		g.drawImage images.sbNubsV, x, y + ceil(height/2-5), 16, 10,
		  0, 0, 16, 10, tint
	end if
end function

ScrollbarV.onClick = function
	// determine if we hit the thumb, or the track (and if track, which side)
	self.mouseOffset = null
	thumbSize = self.thumbSprite.image.height
	downSign = -1 + 2 * self.topDown
	if mouse.y < self.thumbSprite.y - thumbSize/2 then
		// thumb down
		self.value = mathUtil.clamp(self.value + downSign*self.pageSize, self.minValue, self.maxValue)
		self.updateThumb
	else if mouse.y > self.thumbSprite.y + thumbSize/2 then
		// thumb up
		self.value = mathUtil.clamp(self.value - downSign*pageSize, self.minValue, self.maxValue)
		self.updateThumb
	else
		// click on thumb -- start a drag
		self.thumbSprite.tint = "#CCCCEE"
		self.mouseOffset = self.thumbSprite.y - mouse.y
	end if
end function

ScrollbarV.onDrag = function
	if self.mouseOffset == null then return
	newY = mouse.y + self.mouseOffset
	// Invert the math in updateThumb to calculate the value from the sprite position.
	valueRange = self.maxValue - self.minValue
	size = self.thumbSprite.image.height
	if self.topDown then
		frac = (self.top - (newY + size/2)) / (self.height - size)
	else
		frac = (newY - size/2 - self.bottom) / (self.height - size)
	end if
	self.value = mathUtil.clamp(self.minValue + valueRange * frac, self.minValue, self.maxValue)
	self.updateThumb 
end function

ScrollbarV.updateThumb = function
	if self.thumbSprite == null then self.createThumb
	// Here are the somewhat tricky calculations for thumb size and position.
	// First, the thumb size.  This reflects how much the pageSize is out
	// of the total value range PLUS the pageSize.
	valueRange = self.maxValue - self.minValue
	size = round(self.height * (self.pageSize / (valueRange + self.pageSize)))
	// Then, the position.  The bottom end of the thumb reflects the 
	// position of the current value within the range, as a fraction
	// of our total height MINUS the thumb size.
	frac = (self.value - self.minValue) / valueRange
	if self.topDown then
		newx = self.top - (self.height - size) * frac - size/2	
	else
		newx = self.bottom + (self.height - size) * frac + size/2
	end if
	// Now we can prepare the actual sprite
	if self.thumbSprite.image == null or self.thumbSprite.image.height != size then
		clearScratch size, SB_THICKNESS, color.clear
		self.drawThumb scratchDisp, 0, 0, size
		self.thumbSprite.image = scratchDisp.getImage(0, 0, SB_THICKNESS, size)
	end if
	self.thumbSprite.x = self.left + SB_THICKNESS/2
	self.thumbSprite.y = newx
	self.thumbSprite.localBounds.y = self.bottom + self.height/2 - self.thumbSprite.y
	self.onValueChanged
end function


//----------------------------------------------------------------------
// Window class and related methods
//----------------------------------------------------------------------
Window = new events.EventSprite
Window.dragMode = null
Window.dragOffset = [0,0]  // (position of window relative to mouse)
Window.contentImage = null
Window.scrollX = 0; Window.scrollY = 0

// Make an image for the window sprite.
// Uses self: width, height, titleLeft, titleWidth, title, and contentImage
Window.makeImage = function
	clearScratch self.width+16, self.height+48, color.clear
	images.windowBox.draw scratchDisp, 0, 0, self.width+16, self.height+16
	images.titleBar.draw scratchDisp, self.titleLeft, self.height+12, self.titleWidth, 36
	scratchDisp.print self.title, self.titleLeft+16, self.height+24, "#444444", "small"
	if self.contentImage != null then
		w = min(self.width, self.contentImage.width)
		h = min(self.height, self.contentImage.height)
		scratchDisp.drawImage self.contentImage, 8, 8+self.height-h, w, h,
		   self.scrollX, self.contentImage.height - h - self.scrollY, w, h
	end if
	self.image = scratchDisp.getImage(0, 0, self.width+16, self.height+48)
end function

// Make a shadow image to go under the window sprite.
Window.makeShadow = function
	clearScratch self.width+48, self.height+88, color.clear
	images.shadow.draw scratchDisp, 0, 0, self.width+48, self.height+48
	images.titleShadow.draw scratchDisp, self.titleLeft, self.height+20, self.titleWidth+32, 64
	return scratchDisp.getImage(0, 0, self.width+48, self.height+88)
end function

Window.init = function(width, height, titleLeft, titleWidth, title)
	self.width = width
	self.height = height
	self.title = title
	self.titleWidth = titleWidth
	self.titleLeft = titleLeft
	self.makeImage
	
	self.localBounds = new Bounds
	self.localBounds.width = width + 16
	self.localBounds.height = height + 16
	self.localBounds.x = 0
	self.localBounds.y = -16
	
	self.titleBounds = new Bounds
	self.titleBounds.width = titleWidth
	self.titleBounds.height = 32
	
	self.shadow = new Sprite
	self.shadow.image = self.makeShadow
	
	spriteDisp.sprites.push self.shadow
	spriteDisp.sprites.push self
	
	self.moveToFront // a new window should always be frontmost
end function

Window.make = function(width=300, height=200, titleLeft=0, titleWidth=150, title="Untitled")
	w = new Window
	w.init width, height, titleLeft, titleWidth, title
	w.goTo 480, 320
	
	return w
end function

Window.close = function
	spriteDisp.sprites.removeVal self.shadow
	spriteDisp.sprites.removeVal self
end function

Window.contains = function(x, y)
	return self.worldBounds.contains(x,y) or self.titleBounds.contains(x,y)
end function

Window.left = function; return self.x - self.width/2; end function
Window.top = function; return self.y - 16 + self.height/2; end function
Window.right = function; return self.x + self.width/2; end function
Window.bottom = function; return self.y - 16 - self.height/2; end function

Window.partHit = function(xy)
	midX = self.x
	midY = self.y - 16  // (accounting for title bar)
	x = xy.x; y = xy.y
	if y > midY + self.height/2 + 8 then return kPartTitle
	if x > midX + self.width/2-8 and y < midY - self.height/2+6 then
		return kPartResize
	end if
	if x > midX - self.width/2 and x < midX + self.width/2 and
	   y > midY - self.height/2 and y < midY + self.height/2 then
		return kPartContent
	end if
	return kPartFrame
end function

Window.goTo = function(x, y)
	self.x = x
	self.y = y
	extra = 6 * (self.dragMode == kDragMove)
	self.shadow.x = x + 4 + extra
	self.shadow.y = y - 4 - extra
	self.titleBounds.x = self.x - self.width/2 + self.titleLeft + self.titleWidth/2 - 8
	self.titleBounds.y = self.y + self.height/2 + 8
end function

Window.resize = function(newWidth, newHeight)
	if newWidth == self.width and newHeight == self.height then return
	left = self.x - self.width/2; top = self.y + self.height/2
	self.x = left + newWidth/2; self.y = top - newHeight/2
	self.width = newWidth
	self.height = newHeight
	self.makeImage
	self.shadow.image = self.makeShadow
	self.shadow.x = self.x + 4
	self.shadow.y = self.y - 4
	self.localBounds.width = newWidth + 16
	self.localBounds.height = newHeight + 16
end function

Window.scroll = function(dx, dy)
	self.scrollX = mathUtil.clamp(self.scrollX + dx, 0, self.contentImage.width - self.width)
	self.scrollY = mathUtil.clamp(self.scrollY + dy, 0, self.contentImage.height - self.height)
	self.updateContent
end function

Window.debugDrawBounds = function
	menuDisp.drawPoly self.worldBounds.corners, color.orange
	menuDisp.drawPoly self.titleBounds.corners, color.orange
end function

Window.moveToFront = function
	spriteDisp.sprites.removeVal self
	spriteDisp.sprites.removeVal self.shadow
	spriteDisp.sprites.push self.shadow
	spriteDisp.sprites.push self
	// dim out all windows...
	for i in spriteDisp.sprites.indexes
		spriteDisp.sprites[i].tint="#DDDDEE"
	end for
	//... and undim the frontmost one
	spriteDisp.sprites[-1].tint="#FFFFFF"
end function

Window.isFrontmost = function
	return spriteDisp.sprites[-1] == self
end function

Window.onClick = function
	self.moveToFront
	hit = self.partHit(mouse)
	if hit == kPartTitle or hit == kPartFrame then
		self.dragMode = kDragMove
		self.goTo self.x-2, self.y+2
		self.dragOffset = [self.x - mouse.x, self.y - mouse.y]
	else if hit == kPartResize then
		self.dragMode = kDragResize
		self.dragOffset = [self.width - mouse.x, mouse.y + self.height]
	end if
end function

Window.onDrag = function
	if self.dragMode == kDragMove then
		self.goTo mouse.x + self.dragOffset[0], mouse.y + self.dragOffset[1]
	else if self.dragMode == kDragResize then
		self.resize mouse.x + self.dragOffset[0], self.dragOffset[1] - mouse.y
	end if
end function

Window.onDragEnd = function
	self.dragMode = null
	self.goTo self.x+2, self.y-2
end function

frontmostWindow = function
	if not spriteDisp.sprites then return null
	for i in range(spriteDisp.sprites.len-1)
		if spriteDisp.sprites[i] isa Window then return spriteDisp.sprites[i]
	end for
	return null
end function

windowUnderMouse = function
	if not spriteDisp.sprites then return null
	for i in range(spriteDisp.sprites.len-1)
		if spriteDisp.sprites[i] isa Window and spriteDisp.sprites[i].contains(mouse) then
			return spriteDisp.sprites[i]
		end if
	end for
	return null
end function


//----------------------------------------------------------------------
// Setup functions
//----------------------------------------------------------------------

setupDisplays = function
	clear; print
	
	display(6).mode = displayMode.solidColor
	outer.backgroundDisp = display(6)
	backgroundDisp.color = "#7EBDC5FF"
	
	if globals.hasIndex("DEBUG") and DEBUG then
		display(5).mode = displayMode.pixel
		outer.scratchDisp = display(5)
	else
		display(5).mode = displayMode.off
		display(7).mode = displayMode.pixel
		outer.scratchDisp = display(7)
	end if	
	scratchDisp.clear color.clear
	
	display(4).mode = displayMode.sprite
	outer.spriteDisp = display(4)
	spriteDisp.clear
	events.spriteDisplay = spriteDisp
	
	display(2).mode = displayMode.pixel
	outer.menuDisp = display(2)
	menuDisp.clear color.clear, 960+16, 640+16
	menuDisp.scrollX = 8; menuDisp.scrollY = 7
end function


//----------------------------------------------------------------------
// Test/Debug functions
//----------------------------------------------------------------------

testWindows = function
	setupDisplays
	
	globals.window1 = Window.make(600,400, 25, 150, "window1")
	window1.goTo 480, 320
	
	globals.window2 = Window.make(100,100, 8, 100, "window2")
	window2.goTo 750, 500
	
	globals.window3 = Window.make(200,200, 25, 150, "window3")
	window3.goTo 150, 200
	
	events.eventLoop.onUpdate = function
		wind = windowUnderMouse
		s = "Window under mouse: "
		if wind then
			s = s + wind.title + " (" + wind.partHit(mouse) + ")"
		else
			s = s + "(null)"
		end if
		text.row = 25; print s + " " * 30
	end function
	
	events.eventLoop.run
end function

testDrawScrollbars = function
	clear
	y = 620
	for w in range(16, 100, 3)
    	ScrollbarH.drawThumb gfx, 650, y, w
    	y = y - 20
	end for

	x = 50
	for h in range(16, 100, 3)
    	ScrollbarV.drawThumb gfx, x, 50, h
    	x = x + 20
	end for	
end function

testScrollbars = function
// common to H or V
	setupDisplays
	display(5).mode = displayMode.pixel
	gfx = display(5)
	gfx.clear color.clear
	text.color=color.blue

	// instantiate a HSB
	globals.sbH = new ScrollbarH //
	sbH.left = 100 // x coordinate where the HSB starts
	sbH.bottom = 100 // y coordinate
	sbH.width = 600 // width of the HSB in pixels
	sbH.pageSize = 50
	sbH.drawBackground gfx
	sbH.onValueChanged = function
		text.row = 2; print "H Value: " + sbH.value + " " * 5
	end function
	sbH.updateThumb

	// instantiate a VSB
	globals.sbV = new ScrollbarV //
	sbV.left = 700 // x coordinate where the VSB starts
	sbV.bottom = 116 // y coordinate
	sbV.height = 500 // height of the VSB in pixels
	sbV.pageSize = 50
	sbV.drawBackground gfx
	sbV.onValueChanged = function
		text.row = 22; text.column = 52; print "V Value: "+ round (sbV.value,2) + " " * 5
	end function
	sbV.updateThumb

	// poll for SB events
	events.eventLoop.run
end function


if locals == globals then
//	testWindows
// testDrawScrollbars
	testScrollbars
end if

// This module provides classes and utilities for making GUI
// (Graphical User Interface) apps, like the desktop demo.

import "importUtil"
ensureImport "events"
ensureImport "bmfFonts"
ensureImport "mathUtil"
ensureImport "listUtil"

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
// Drawing constants
kScrollbarSize = 16				// default thickness for any scrollbar
kMenuBarHeight = 24				// height of the menu bar at top of screen
kMenuItemHeight = 20			// height of one item in a menu
// Things that may become options some day
selectionColor = "#CCCCFF"
scrollWheelSpeed = 50



//----------------------------------------------------------------------
// Image9Slice class: an image wrapper with margins that are not stretched,
// and a middle that is stretched when drawn to any size.
//----------------------------------------------------------------------

Image9Slice = {}
Image9Slice._name = "Image9Slice"
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

images.menuItem = Image9Slice.make(gfxSource.getImage(4, 251, 42, 12), 8, 0, 8, 0)
images.menuSeparator = Image9Slice.make(gfxSource.getImage(52, 257-10, 42, 20), 8, 0, 8, 0)
images.menuTop = Image9Slice.make(gfxSource.getImage(4, 263, 42, 4), 8, 0, 8, 0)
images.menuBottom = Image9Slice.make(gfxSource.getImage(4, 240, 42, 10), 8, 0, 8, 0)

// scrollbar parts (H = Horizontal, V = Vertical)
images.sbTrackH = Image9Slice.make(gfxSource.getImage(32, 176, 32, 16), 8, 0, 8, 0)
images.sbThumbH = Image9Slice.make(gfxSource.getImage(0, 176, 32, 16), 8, 0, 8, 0)
images.sbNubsH = gfxSource.getImage(0, 160, 16, 16)
images.sbTrackV = Image9Slice.make(gfxSource.getImage(16, 192, 16, 32), 0, 8, 0, 8)
images.sbThumbV = Image9Slice.make(gfxSource.getImage(0, 192, 16, 32), 0, 8, 0, 8)
images.sbNubsV = gfxSource.getImage(16, 160, 16, 16)


//----------------------------------------------------------------------
// General drawing and utility functions
//----------------------------------------------------------------------

max = function(a,b); if a >= b then return a else return b; end function
min = function(a,b); if a <= b then return a else return b; end function

// Clear our off-screen "scratch" display, used for drawing or 
// compositing things to create an image or sprite).
clearScratch = function(width=256, height=256, color="#FFFFFF")
	if width > scratchDisp.width or height > scratchDisp.height then
		scratchDisp.clear color, width, height
	else
		scratchDisp.clear color, scratchDisp.width, scratchDisp.height
	end if
end function

// Draw a single menu item.
// Usually this is a helper method for some bigger menu-handling routine.
// Note that this does NOT draw a top or bottom; those have to be drawn
// separately.  That's so you can have a whole series of these, and they
// will join smoothly together.
drawMenuItem = function(g, menuText, left, bottom, width=100, highlighted=false, disabled=false)
	// Shift X by 4 pixels, and increase width by 10, to account for shadow.
	if menuText == "-" then img = images.menuSeparator else img = images.menuItem
	img.draw g, left-4, bottom, width+10, kMenuItemHeight
	drawMenuItemText g, menuText, left, bottom, width, kMenuItemHeight, highlighted, disabled
end function

drawMenuItemText = function(g, menuText, left, bottom, width, height, highlighted=false, disabled=false)
	if menuText == "-" then return
	globals.gfx = g
	if disabled then
		textColor = "#AAAAAA"
	else if highlighted then
		g.fillRect left+1, bottom, width-2, height, "#2222AA"
		textColor = color.white
	else
		textColor = color.black
	end if
	y = bottom + 2 + round((height-16)/2)
	if menuText != "-" then medFont.print menuText, left+6, y, 1, textColor
end function

calcMenuItemWidth = function(menuText)
	return medFont.width(menuText) + 18
end function

// Draw the bottom of the menu.  Note that the third parameter is the bottom
// of the bottommost menu item; we actually draw below that (border and shadow).
drawMenuBottom = function(g, left, menuBottom, width=100)
	h = images.menuBottom.image.height
	images.menuBottom.draw g, left-4, menuBottom-h, width+10, h
end function

//----------------------------------------------------------------------
// Scrollbar class and related methods and CONSTANTS
//----------------------------------------------------------------------
Scrollbar = {}
Scrollbar._name = "Scrollbar"
Scrollbar.left = 0
Scrollbar.bottom = 0
Scrollbar.width = kScrollbarSize
Scrollbar.height = kScrollbarSize
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
	images.sbThumbH.draw g, x, y, width, kScrollbarSize, tint
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
	if self.value < self.minValue then self.value = self.minValue
	if self.value > self.maxValue then self.value = self.maxValue
	valueRange = self.maxValue - self.minValue
	if valueRange <= 0 then
		// special case: scrollbar can't move at all; peg thumb at full size
		size = self.width
		thumbLeft = self.left
	else
		size = round(self.width * (self.pageSize / (valueRange + self.pageSize)))
		if size < 16 then size = 16
		// Then, the position.  The leftmost end of the thumb reflects the 
		// position of the current value within the range, as a fraction
		// of our total width MINUS the thumb size.
		frac = (self.value - self.minValue) / valueRange
		thumbLeft = self.left + (self.width - size) * frac
	end if
	// Now we can prepare the actual sprite
	if self.thumbSprite.image == null or self.thumbSprite.image.width != size then
		clearScratch size, kScrollbarSize, color.clear
		self.drawThumb scratchDisp, 0, 0, size
		self.thumbSprite.image = scratchDisp.getImage(0, 0, size, kScrollbarSize)
	end if
	self.thumbSprite.x = thumbLeft + size/2
	self.thumbSprite.y = self.bottom + kScrollbarSize/2
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
	images.sbThumbV.draw g, x, y, kScrollbarSize, height, tint
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
		self.value = mathUtil.clamp(self.value - downSign*self.pageSize, self.minValue, self.maxValue)
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
	if self.value < self.minValue then self.value = self.minValue
	if self.value > self.maxValue then self.value = self.maxValue
	valueRange = self.maxValue - self.minValue
	if valueRange <= 0 then
		// special case: scrollbar can't move at all; peg thumb at full size
		size = self.height
		newx = self.bottom + self.height/2
	else
		size = round(self.height * (self.pageSize / (valueRange + self.pageSize)))
		if size < 16 then size = 16
		// Then, the position.  The bottom end of the thumb reflects the 
		// position of the current value within the range, as a fraction
		// of our total height MINUS the thumb size.
		frac = (self.value - self.minValue) / valueRange
		if self.topDown then
			newx = self.top - (self.height - size) * frac - size/2	
		else
			newx = self.bottom + (self.height - size) * frac + size/2
		end if
	end if
	// Now we can prepare the actual sprite
	if self.thumbSprite.image == null or self.thumbSprite.image.height != size then
		clearScratch size, kScrollbarSize, color.clear
		self.drawThumb scratchDisp, 0, 0, size
		self.thumbSprite.image = scratchDisp.getImage(0, 0, kScrollbarSize, size)
	end if
	self.thumbSprite.x = self.left + kScrollbarSize/2
	self.thumbSprite.y = newx
	self.thumbSprite.localBounds.y = self.bottom + self.height/2 - self.thumbSprite.y
	self.onValueChanged
end function


//----------------------------------------------------------------------
// Window class and related methods
//----------------------------------------------------------------------
Window = new events.EventSprite
Window._name = "Window"
Window.dragMode = null
Window.dragOffset = [0,0]  // (position of window relative to mouse)
Window.contentImage = null
Window.scrollX = 0	// amount content is shifted left
Window.scrollY = 0	// amount content is shifted DOWN from TOP
Window.controls = null		// list of Sprites which are "children" of this window
Window.contentSprite = null	// sprite representing window content
Window.scrollbarH = null
Window.scrollbarV = null

Window.minSize = function		// minimum window size (feel free to override!)
	return [self.titleLeft + self.titleWidth + 20, 100]
end function

// Make an image for the window sprite.
// Uses self: width, height, titleLeft, titleWidth, title
Window.makeImage = function
	clearScratch self.width+16, self.height+48, color.clear
	images.windowBox.draw scratchDisp, 0, 0, self.width+16, self.height+16
	images.titleBar.draw scratchDisp, self.titleLeft, self.height+12, self.titleWidth, 36
	scratchDisp.print self.title, self.titleLeft+16, self.height+24, "#444444", "small"
//	if self.contentImage != null then
//		w = min(self.width, self.contentImage.width)
//		h = min(self.height, self.contentImage.height)
//		scratchDisp.drawImage self.contentImage, 8, 8+self.height-h, w, h,
//		   self.scrollX, self.contentImage.height - h - self.scrollY, w, h
//	end if

	if self.scrollbarH then
		Scrollbar.drawTrack scratchDisp, 8, 8, self.scrollbarH.width, kScrollbarSize
	end if
	if self.scrollbarV then
		Scrollbar.drawTrack scratchDisp, 8 + self.width - kScrollbarSize, 8 + kScrollbarSize, 
				kScrollbarSize, self.scrollbarV.height
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

Window.updateContent = function
	if self.contentSprite == null then
		self.contentSprite = new Sprite
		spriteDisp.sprites.push self.contentSprite
	end if	
	if self.contentImage then
		w = self.width  - kScrollbarSize * (self.scrollbarV != null)
		h = self.height - kScrollbarSize * (self.scrollbarH != null)
		self.contentSprite.image = self.contentImage.getImage(
				self.scrollX, 
				self.contentImage.height - h - self.scrollY, 
				w, h)
		self._positionContent
	end if
end function

Window.init = function(width, height, titleLeft, titleWidth, title)
	self.width = width
	self.height = height
	self.title = title
	self.titleWidth = titleWidth
	self.titleLeft = titleLeft
	self.controls = []
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
	
	if self.contentImage then
		if self.contentImage.width > width or self.contentImage.height > height then
			self.addScrollbars
		else
		self.updateContent
		end if
	end if

	self.moveToFront // a new window should always be frontmost
end function

Window.make = function(width=300, height=200, titleLeft=0, titleWidth=150, title="Untitled")
	w = new Window
	w.init width, height, titleLeft, titleWidth, title
	w.goTo 480, 320
	return w
end function

Window.addScrollbars = function
	self.scrollbarH = new ScrollbarH
	window = self	// (just so it can be bound/accessible in the functions below)
	self.scrollbarH.onValueChanged = function
		window.scrollX = self.value
		window.updateContent
	end function
	self.scrollbarV = new ScrollbarV
	self.scrollbarV.onValueChanged = function
		window.scrollY = self.value
		window.updateContent
	end function
	self.updateScrollbars
	self.scrollbarV.value = 0//self.scrollbarV.maxValue
	self.controls.push self.scrollbarH.thumbSprite
	self.controls.push self.scrollbarV.thumbSprite
	self.makeImage
	self.updateContent
end function

Window.updateScrollbars = function
	if not self.scrollbarH then return	// (for now if you have one, you must have both)

	contentWidth = self.contentImage.width
	contentHeight = self.contentImage.height
	visibleWidth = self.width - kScrollbarSize
	visibleHeight = self.height - kScrollbarSize

	self.scrollbarH.left = self.left
	self.scrollbarH.bottom = self.bottom
	self.scrollbarH.width = self.width - kScrollbarSize
	self.scrollbarH.height = kScrollbarSize
	self.scrollbarH.maxValue = max(0, contentWidth - visibleWidth)
	self.scrollbarH.pageSize = visibleWidth
	self.scrollbarH.updateThumb
	
	self.scrollbarV.left = self.right - kScrollbarSize
	self.scrollbarV.bottom = self.bottom + kScrollbarSize
	self.scrollbarV.width = kScrollbarSize
	self.scrollbarV.height = self.height - kScrollbarSize
	self.scrollbarV.maxValue = max(0, contentHeight - visibleHeight)
	self.scrollbarV.pageSize = visibleHeight
	self.scrollbarV.updateThumb
end function

Window.setContent = function(image, scrollIfNeeded=true)
	self.contentImage = image
	self.updateContent
	if scrollIfNeeded and not self.scrollbarH then self.addScrollbars
end function

Window.close = function
	for ctl in self.controls
		spriteDisp.sprites.removeVal ctl
	end for
	if self.contentSprite then spriteDisp.sprites.removeVal self.contentSprite
	spriteDisp.sprites.removeVal self.shadow
	spriteDisp.sprites.removeVal self
	w = frontmostWindow
	if w != null then w.moveToFront(true)
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

Window._positionContent = function
	if not self.contentSprite then return
	w = self.contentSprite.image.width
	if self.scrollbarH then
		self.contentSprite.x = min(self.x - 16 + kScrollbarSize/2, self.left + w/2)
	else
		self.contentSprite.x = self.left + w/2
	end if
	h = self.contentSprite.image.height
	if self.scrollbarV then
		self.contentSprite.y = max(self.y - 16 + kScrollbarSize/2, self.top - h/2)
	else
		self.contentSprite.y = self.top - h/2
	end if
end function

Window.goTo = function(x, y, keepOnScreen=true)
	self.x = x
	self.y = y
	if keepOnScreen then
		if self.left > 960 then self.x -= self.left - 960
		if self.right < 0 then self.x += 0 - self.right
		if self.bottom > 640 - kMenuBarHeight then self.y -= self.bottom - (640-kMenuBarHeight)
		if self.top < -16 then self.y += -16 - self.top // (because title bar)
	end if
	extra = 6 * (self.dragMode == kDragMove)
	self.shadow.x = self.x + 4 + extra
	self.shadow.y = self.y - 4 - extra
	self._positionContent
	self.titleBounds.x = self.x - self.width/2 + self.titleLeft + self.titleWidth/2 - 8
	self.titleBounds.y = self.y + self.height/2 + 8
	self.updateScrollbars
end function

Window.resize = function(newWidth, newHeight)
	if newWidth < self.minSize[0] then newWidth = self.minSize[0]
	if newHeight < self.minSize[1] then newHeight = self.minSize[1]
	if newWidth == self.width and newHeight == self.height then return
	yield	// (to try to sync to display, though that's a bit hopeless now)
	left = self.x - self.width/2; top = self.y + self.height/2
	self.x = left + newWidth/2; self.y = top - newHeight/2
	self.width = newWidth
	self.height = newHeight
	self.updateScrollbars
	self.makeImage
	self.shadow.image = self.makeShadow
	self.shadow.x = self.x + 4
	self.shadow.y = self.y - 4
	self.localBounds.width = newWidth + 16
	self.localBounds.height = newHeight + 16
	self.updateContent
end function

Window.scroll = function(dx, dy)
	self.scrollX = mathUtil.clamp(self.scrollX + dx, 0, self.contentImage.width - self.width)
	self.scrollY = mathUtil.clamp(self.scrollY + dy, 0, self.contentImage.height - self.height)
	if self.scrollbarH then
		self.scrollbarH.value = self.scrollX
		self.scrollbarV.value = self.scrollY
		self.updateScrollbars
	else	
		self.updateContent
	end if
end function

Window.debugDrawBounds = function
	menuDisp.drawPoly self.worldBounds.corners, color.orange
	menuDisp.drawPoly self.titleBounds.corners, color.orange
end function

Window.moveToFront = function(tintOnly=false)
	if not tintOnly then
		spriteDisp.sprites.removeVal self
		spriteDisp.sprites.removeVal self.shadow
		spriteDisp.sprites.push self.shadow
		spriteDisp.sprites.push self
		if self.contentSprite then
			spriteDisp.sprites.removeVal self.contentSprite
			spriteDisp.sprites.push self.contentSprite
		end if
		for ctl in self.controls
			spriteDisp.sprites.removeVal ctl
			spriteDisp.sprites.push ctl
		end for
	end if
		
	// dim out all windows and controls...
	for i in spriteDisp.sprites.indexes
		spriteDisp.sprites[i].tint="#DDDDEE"
	end for
	//... and undim this (frontmost) one
	self.tint="#FFFFFF"
	if self.contentSprite then self.contentSprite.tint="#FFFFFF"
	for ctl in self.controls
		ctl.tint = "#FFFFFF"
	end for
end function

Window.isFrontmost = function
	return self == frontmostWindow
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
// Menu and MenuItem classes, and related methods
//----------------------------------------------------------------------

MenuItem = {}
MenuItem._name = "gui.MenuItem"
MenuItem.text = ""
MenuItem.selected = false
MenuItem.disabled = false
MenuItem.submenu = null
MenuItem.action = null	// function invoked for this menu item

MenuItem.make = function(text)
	item = new MenuItem
	item.text = text
	if text == "-" then item.disabled = true
	return item
end function

MenuItem.draw = function(left, top, width)
	drawMenuItem menuDisp, self.text, left, top - kMenuItemHeight, width, self.selected, self.disabled
end function

MenuItem.openSubmenu = function(asTopLevelMenu = false)
	if self.submenu == null then return false
	if asTopLevelMenu then
		self.submenu.left = self.left
	else
		self.submenu.left = self.left + self.width
	end if
	for item in self.submenu.items; item.selected = false; end for
	self.submenu.draw
end function

Menu = {}
Menu._name = "gui.Menu"
Menu.items = null		// list of MenuItem
Menu.top = 0
Menu.left = 0
Menu.width = 200
Menu.selectedItem = null	// (currently open submenu, if any)
Menu.selectedMenu = function
	if self.selectedItem == null then return null
	return self.selectedItem.submenu
end function

Menu.make = function(items, width=null)
	menu = new Menu
	menu.items = items
	maxWidth = 0
	for i in menu.items.indexes
		if menu.items[i] isa string then
			menu.items[i] = MenuItem.make(menu.items[i])
		end if
		maxWidth = max(maxWidth, calcMenuItemWidth(menu.items[i].text))
	end for
	menu.top = 641 + menuDisp.scrollY - kMenuBarHeight
	if width == null then width = maxWidth
	menu.width = width
	return menu
end function

Menu.draw = function
	y = self.top
	for item in self.items
		item.draw self.left, y, self.width
		y -= kMenuItemHeight
	end for
	drawMenuBottom menuDisp, self.left, y, self.width
end function

Menu.selectItem = function(item)
	if item == self.selectedItem then return
	if self.selectedItem then
		self.selectedItem.selected = false
		self.redrawItem self.items.indexOf(self.selectedItem)
	end if
	if item and item.disabled then
		self.selectedItem = null
		return
	end if
	if item then
		item.selected = true
		self.redrawItem self.items.indexOf(item)
	end if
	self.selectedItem = item
end function

Menu.redrawItem = function(itemIndex)
	yield
	y = self.top - kMenuItemHeight * (itemIndex + 1)
	menuDisp.fillRect self.left-4, y, self.width+10, kMenuItemHeight, color.clear
	self.items[itemIndex].draw self.left, y + kMenuItemHeight, self.width
end function

Menu.flashItem = function(itemIndex, flashes=3)
	for i in range(1, flashes*2)
		self.items[itemIndex].selected = not self.items[itemIndex].selected
		self.redrawItem itemIndex
		wait 0.05
	end for
end function

Menu.invokeSelectedItem = function
	if not self.selectedItem then return
	self.flashItem self.items.indexOf(self.selectedItem)
	if @self.selectedItem.action == null then
		print
		print "No action defined for: " + self.selectedItem.text
	else
		self.selectedItem.action
	end if
end function


Menu.itemAtPoint = function(point)
	if point.x < self.left or point.x > self.left + self.width then return null
	y = self.top - menuDisp.scrollY
	if point.y > y then return null
	for item in self.items
		y -= kMenuItemHeight
		if point.y > y then return item
	end for
	return null
end function

Menubar = new Menu
Menubar._name = "gui.Menubar"
Menubar.draw = function
	x = 40; y = 624
	menuDisp.drawImage images.menuBar, 0, y, 960+16, kMenuBarHeight
	for item in self.items
		itemWidth = medFont.width(item.text) + 20
		drawMenuItemText menuDisp, item.text, x, y, itemWidth, kMenuBarHeight, item.selected, item.disabled
		item.left = x
		item.width = itemWidth
		x = x + itemWidth
	end for
end function

Menubar.make = function(items)
	bar = new Menubar
	bar.width = 960
	bar.top = 640
	bar.items = items
	for i in bar.items.indexes
		if bar.items[i] isa string then
			bar.items[i] = MenuItem.make(bar.items[i])
		end if
	end for
	return bar
end function

Menubar.itemAtPoint = function(point)
	if point.y < 640 - kMenuBarHeight then return
	for item in self.items
		if point.x >= item.left and point.x < item.left + item.width then return item
	end for
end function

Menubar.trackMouse = function
	if mouse.y > 640-kMenuBarHeight then
		// track mouse over the menu bar
		newMenu = self.itemAtPoint(mouse)
		if newMenu == self.selectedItem or (newMenu == null and not mouse.button) then return
		self.openMenu newMenu
	else if self.selectedItem then
		// track mouse below the menu bar, maybe in the open menu
		menu = self.selectedMenu
		if menu == null then return
		menu.selectItem menu.itemAtPoint(mouse)
	end if
end function

Menubar.openMenu = function(menu)
	if self.selectedItem then 
		self.selectedItem.selected = false
		menuDisp.fillRect 0, 0, 640-kMenuBarHeight, 960, color.clear
	end if
	self.selectedItem = menu
	if menu then
		menu.selected = true
		menu.openSubmenu true
	end if
	self.draw
end function
		
Menubar.handleMouseUp = function
	if self.selectedItem then
		menu = self.selectedMenu
		if menu and menu.selectedItem then
			menu.invokeSelectedItem
		end if
		self.openMenu null
	end if
end function

Menubar.handleClick = function
	menu = self.itemAtPoint(mouse)
	if menu == null then return
	self.openMenu menu
	// Start tracking the mouse.  Take action on a mouse-up that occurs
	// after some brief threshold amount of time after the *initial*
	// mouse-down.
	mouseDownTime = time
	mouseWasDown = true
	while true
		yield
		self.trackMouse
		if mouseWasDown and not mouse.button then
			// ignore a mouse-up if it comes too quickly after initial mouse-down;
			// otherwise, act on it
			if time - mouseDownTime > 0.5 then
				self.handleMouseUp
				return
			end if
			mouseWasDown = false
		else if mouse.button then
			mouseWasDown = true
		end if
	end while
end function

Menubar.installHandlers = function
	mb = self
	events.eventLoop.onClick = function; mb.handleClick; end function
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
	
	display(3).mode = displayMode.text
	text = display(3)
	text.color = color.blue

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
	scratchDisp.clear color.pink, 800,500
	scratchDisp.line 0, 0, scratchDisp.width, scratchDisp.height, color.blue
	scratchDisp.line 0, scratchDisp.height, scratchDisp.width, 0, color.blue
	window1.setContent scratchDisp.getImage
	window1.goTo 480, 320
	
	globals.window2 = Window.make(100,100, 8, 100, "window2")
	window2.goTo 750, 500

	globals.window3 = Window.make(200,200, 25, 150, "window3")
	window3.goTo 150, 200
	
	window1.moveToFront
	
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
	globals.sbV = new ScrollbarV
	sbV.topDown = false
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

testMenus = function
	setupDisplays
	globals.menubar = Menubar.make(["File", "Edit", "Window", "Help"])
	menubar.draw

	menu = Menu.make(["New Window", "Close Window", "-", "Exit to Shell"])
	menu.items[1].disabled = true
	menu.items[-1].action = function; menubar.openMenu null; exit; end function
	menubar.items[0].submenu = menu
	
	menu = Menu.make(["Item One", "Second Item jg", "Item the Third", "-", "Disabled Item", "Last Item"])
	menu.items[-2].disabled = true
	menubar.items[1].submenu = menu
	
	menu = Menu.make(["Help You", "Help Me", "Self Help"])
	menubar.items[-1].submenu = menu
		
	menubar.installHandlers
	events.eventLoop.run
	
	text.row = 4
end function


// Temp method, for debugging
listSprites = function
	for i in spriteDisp.sprites.indexes
		sp = spriteDisp.sprites[i]
		print i + ". " + mapName(sp.__isa), ""
		if sp isa Window then print " (" + sp.title + ")" else print
	end for
end function

if locals == globals then
//	testWindows
//	testScrollbars
	testMenus
end if

// A simple (but fun!) desktop environment for Mini Micro.

import "events"
import "listUtil"
import "stringUtil"
import "mathUtil"

//----------------------------------------------------------------------
// General utility functions
//----------------------------------------------------------------------

min = function(a,b)
	if a < b then return a else return b
end function

//----------------------------------------------------------------------
// Load resources
//----------------------------------------------------------------------

gfxSource = file.loadImage("/usr/data/desktop/desktopGfx.png")
if gfxSource == null then
	gfxSource = file.loadImage("/sys/data/desktop/desktopGfx.png")
end if
fileIcons = {}	// key: file name (without .png); value: Image
for iconFolder in ["/sys/data/desktop/icons", "/usr/data/desktop/icons"]
	for f in file.children(iconFolder)
		if not f.endsWith(".png") then continue
		img = file.loadImage(iconFolder + "/" + f)
		if img != null then fileIcons[f - ".png"] = img
	end for
end for

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

clearScratch = function(width=256, height=256, color="#FFFFFF")
	if width > scratchDisp.width or height > scratchDisp.height then
		scratchDisp.clear color, width, height
	else
		scratchDisp.clear color, scratchDisp.width, scratchDisp.height
	end if
end function

drawMenuBar = function
	menuDisp.drawImage images.menuBar, 0, 624, 960+16, 24
end function

//----------------------------------------------------------------------
// Constants
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

//----------------------------------------------------------------------
// File icons and related methods
//----------------------------------------------------------------------

iconCache = {}	// key: file path; value: icon (Image)

getFreshIconForFile = function(path)
	if iconCache.hasIndex(path) then return iconCache(path)
	info = file.info(path)
	if path[-1] == "/" or (info != null and info.isDirectory) then
		if path[-1] != "/" then path = path + "/"
		if path == "/usr/" or path == "/usr2/" then return fileIcons.disk
		if path == "/sys/" then return fileIcons.hardDrive
		if path.endsWith("/lib/") then return fileIcons.folderLib
		return fileIcons.folder
	end if
	ext = path[-4:]
	if ext == ".ms" then return fileIcons.miniscript
	if ext == ".wav" or ext == ".ogg" then return fileIcons.sound
	if ext == ".png" or ext == ".jpg" or path[-5:] == ".jpeg" then
		p = file.loadImage(path)
		if p == null then return fileIcons.picture
		clearScratch 128, 128, color.white
		scratchDisp.drawImage fileIcons["picture-2x"]
		scaleFactor = min(96/p.width, 96/p.height)
		dw = p.width * scaleFactor; dh = p.height * scaleFactor
		scratchDisp.drawImage p, 64-dw/2, 64-dh/2, dw, dh
		return scratchDisp.getImage(0, 0, 128, 128)
	end if
	return fileIcons.document
end function

getIconForFile = function(path)
	if iconCache.hasIndex(path) then return iconCache[path]
	result = getFreshIconForFile(path)
	iconCache[path] = result
	return result
end function

drawFile = function(g, path, left, bottom, width, height)
	icon = getIconForFile(path)
	g.drawImage icon, left+width/2 - 32, bottom+height/2 - 24, 64, 64
	name = path.split("/")[-1]
	w = name.len * 8
	g.print name, left+width/2 - w/2, bottom+height/2 - 40, color.black, "small"
end function

//----------------------------------------------------------------------
// Window class and related methods
//----------------------------------------------------------------------
Window = new events.EventSprite
Window.dragMode = null
Window.dragOffset = [0,0]  // (position of window relative to mouse)
Window.contentImage = null

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
		   0, self.contentImage.height - h, w, h
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
end function

Window.make = function(width=300, height=200, titleLeft=0, titleWidth=150, title="Untitled")
	w = new Window
	w.init width, height, titleLeft, titleWidth, title
	return w
end function

Window.contains = function(x, y)
	return self.worldBounds.contains(x,y) or self.titleBounds.contains(x,y)
end function

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

//Window.update = function
//	if self.isFrontmost then
//		text.row = 2; text.col = 0; print self.contains(mouse) + " " + self.partHit(mouse) + "      "
//	end if
//end function

Window.goTo = function(x, y)
	self.x = x
	self.y = y
	extra = 2 * (self.dragMode == kDragMove)
	self.shadow.x = x + 4 + extra
	self.shadow.y = y - 4 - extra
	self.titleBounds.x = self.x - self.width/2 + self.titleLeft + self.titleWidth/2
	self.titleBounds.y = self.y + self.height/2 + 14
end function

Window.resize = function(newWidth, newHeight)
	if newWidth == self.width and newHeight == self.height then return
	left = self.x - self.width/2; top = self.y + self.height/2
	self.width = newWidth
	self.height = newHeight
	self.makeImage
	self.localBounds.width = newWidth + 16
	self.localBounds.height = newHeight + 16
	self.x = left + newWidth/2
	self.y = top - newHeight/2
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
	if self.dragMode == kDragMove then self.goTo self.x+2, self.y-2
	self.dragMode = null
end function

//----------------------------------------------------------------------
// FileWindow (subclass of Window)
//----------------------------------------------------------------------

FileWindow = new Window
FileWindow.make = function(path, width=300, height=200, titleLeft=0, titleWidth=150)
	w = new FileWindow
	w.width = width; w.height = height
	w.path = path
	w.contentImage = w.makeContentImage
	w.init width, height, titleLeft, titleWidth, path
	return w
end function

FileWindow.makeContentImage = function
	spacing = 128
	files = file.children(self.path)

	base = self.path
	if base[-1] != "/" then base = base + "/"
	if base == "/" then base = ""  // (special case; may be a flaw in Mini Micro)
	
	// prefetch the icons first, in case they need to use the scratch space
	for f in files
		getIconForFile base + f
	end for
	
	// then, draw the content
	columns = floor(self.width / spacing)
	rows = ceil(files.len / columns)
	contentHeight = rows * spacing
	col = 0
	row = 0
	clearScratch columns*spacing, contentHeight, color.white	
	for f in files
		x = col * spacing
		y = contentHeight - spacing - row * spacing
		drawFile scratchDisp, base + f, x, y, spacing, spacing
		col = col + 1
		if col >= columns then
			col = 0
			row = row + 1
		end if
	end for
	return scratchDisp.getImage(0, 0, columns*spacing, contentHeight)
end function

//----------------------------------------------------------------------
// Main program
//----------------------------------------------------------------------

drawMenuBar
window1 = FileWindow.make("/", 384, 128, 0, 80)
window1.goTo 200, 450
window2 = FileWindow.make("/sys/pics", 512, 350, 125, 150)
window2.goTo 600, 400
//window3 = Window.make(200,200, 25, 150, "Accessory")
//window3.goTo 750, 500

events.eventLoop.run
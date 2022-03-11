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

pathJoin = function(base, filename)
	if filename[0] == "/" then filename = filename[1:]
	if base[-1] == "/" then return base + filename
	return base + "/" + filename
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
// Load/define the images from our resources sheet
//----------------------------------------------------------------------

images = {}
images.menuBar = gfxSource.getImage(0, 488, 24, 24)
images.windowBox = Image9Slice.make(gfxSource.getImage(0, 0, 48, 48))
images.titleBar = Image9Slice.make(gfxSource.getImage(96, 0, 64, 36), 12, 0, 12, 0)
images.shadow = Image9Slice.make(gfxSource.getImage(0, 48, 80, 80), 32, 32, 32, 32)
images.titleShadow = Image9Slice.make(gfxSource.getImage(80, 64, 96, 48), 32, 0, 32, 32)
images.iconHighlight = gfxSource.getImage(192, 0, 80, 80)
images.rounded4 = Image9Slice.make(gfxSource.getImage(280, 0, 32, 32), 8, 8, 8, 8)

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
// Things that may become options some day
selectionColor = "#CCCCFF"

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
	ext2 = path[-3:]
	ext3 = path[-4:]
	ext4 = path[-5:]
	if ext2 == ".ms" then return fileIcons.miniscript
	if ext3 == ".wav" or ext3 == ".ogg" then return fileIcons.sound
	if ext3 == ".png" or ext3 == ".jpg" or ext4 == ".jpeg" then
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

// Draw the icon and name for a file, centered in the given area.
drawFile = function(g, nameOrPath, left, bottom, width, height, isSelected=false)
	name = nameOrPath.split("/")[-1]
	nameWidth = name.len * 8
	midx = left + width/2
	midy = bottom + height/2 + 8
	if isSelected then
		w = images.iconHighlight.width
		h = images.iconHighlight.height
		g.drawImage images.iconHighlight, midx - w/2, midy - h/2, w, h,
		  0, 0, w, h, selectionColor
		images.rounded4.draw g, midx - nameWidth/2 - 4, midy - 50, nameWidth + 8, 16, selectionColor
	end if
	icon = getIconForFile(nameOrPath)
	if icon.width > 64 or icon.height > 64 then
		f = min(64/icon.width, 64/icon.height)
		g.drawImage icon, midx - icon.width*f/2, midy - icon.height*f/2, icon.width*f, icon.height*f
	else
		g.drawImage icon, midx - icon.width/2, midy - icon.height/2
	end if
	g.print name, midx - nameWidth/2, midy - 48, color.black, "small"
end function

// Return whether the given mouse position is over the actual drawn image
// of the file (including name), as drawn by drawFile above.
isOverFile = function(xyMap, nameOrPath, left, bottom, width, height)
	midx = left + width/2
	midy = bottom + height/2 + 8
	// check if over the icon itself (with a little extra slop allowed)
	if abs(xyMap.x - midx) < 40 and abs(xyMap.y - midy) < 40 then return true
	// check if over the name
	name = nameOrPath.split("/")[-1]
	nameWidth = name.len * 8
	nameMidY = midy - 42
	if abs(xyMap.x - midx) < nameWidth/2+8 and abs(xyMap.y - nameMidY) < 12 then return true
	return false
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

Window.close = function
	print "Closing " + self.title
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
FileWindow.selectedFiles = null	// list of selected file names
FileWindow.spacing = 128
FileWindow.lastClickTime = 0
FileWindow.isDoubleClick = false
FileWindow.make = function(path, width=300, height=200, titleLeft=0, titleWidth=150)
	w = new FileWindow
	w.width = width; w.height = height
	w.path = path
	w.selectedFiles = []
	w.selectedFiles.push file.children(path)[0]  // HACK!
	w.contentImage = w.makeContentImage
	w.init width, height, titleLeft, titleWidth, path
	return w
end function

FileWindow.update = function
	if not self.isFrontmost then return
	text.row = 2; text.col = 0; print self.fileAtXY(mouse) + " " * 30
end function

FileWindow.updateContent = function
	self.contentImage = self.makeContentImage
	self.makeImage
end function

FileWindow.onClick = function
	self.moveToFront
	if self.partHit(mouse) != kPartContent then return super.onClick
	fileHit = self.fileAtXY(mouse)
	anyChange = false
	if not fileHit then
		// clear selection
		if self.selectedFiles then
			self.selectedFiles = []
			anyChange = true
		end if
		self.isDoubleClick = false
	else if self.selectedFiles.len != 1 or self.selectedFiles[0] != fileHit then
		// replace selection with new file
		self.selectedFiles = [fileHit]
		anyChange = true
		self.isDoubleClick = false
	else
		// clicked previously-selected file (maybe a double-click?)
		self.isDoubleClick = (time - self.lastClickTime < 0.5)
	end if
	if anyChange then self.updateContent
	self.lastClickTime = time
end function

FileWindow.onDragEnd = function
	if self.dragMode then super.onDragEnd
	if self.selectedFiles.len == 1 and self.isDoubleClick then
		// Open the selected file!
		openFile pathJoin(self.path, self.selectedFiles[0]), self
	end if
end function

// Figure out what file, if any, the mouse is over.
FileWindow.fileAtXY = function(screenPos)
	if self.partHit(screenPos) != kPartContent then return null
	left = self.x - self.width/2
	top = self.y - 16 + self.height/2  // (accounting for title bar)
	col = floor((mouse.x - left) / self.spacing)
	row = floor((top - mouse.y) / self.spacing)
	if col < self.columns and row < self.rows then
		if isOverFile(mouse, self.files[col][row],
		  left + col * self.spacing, top - (row+1) * self.spacing, 
		  self.spacing, self.spacing) then
			// Found it: we are over the file icon/name at col, row.
			return self.files[col][row]
		end if
	end if
	return null
end function

FileWindow.makeContentImage = function
	files = file.children(self.path)

	base = self.path
	if base[-1] != "/" then base = base + "/"
	if base == "/" then base = ""  // (special case; may be a flaw in Mini Micro)
	
	// prefetch the icons first, in case they need to use the scratch space
	for f in files
		getIconForFile base + f
	end for
	
	// then, draw the content
	self.columns = floor(self.width / self.spacing)
	self.rows = ceil(files.len / self.columns)
	self.files = list.init2d(self.columns, self.rows)
	contentHeight = self.rows * self.spacing
	col = 0
	row = 0
	clearScratch self.columns*self.spacing, contentHeight, color.white	
	for f in files
		self.files[col][row] = f
		x = col * self.spacing
		y = contentHeight - self.spacing - row * self.spacing
		isSelected = self.selectedFiles.contains(f)
		drawFile scratchDisp, base + f, x, y, self.spacing, self.spacing, isSelected
		col = col + 1
		if col >= self.columns then
			col = 0
			row = row + 1
		end if
	end for
	return scratchDisp.getImage(0, 0, self.columns*self.spacing, contentHeight)
end function

//----------------------------------------------------------------------
// Desktop global methods (open file, etc.) and event handlers
//----------------------------------------------------------------------

frontmostWindow = function
	if not spriteDisp.sprites then return null
	for i in range(spriteDisp.sprites.len-1)
		if spriteDisp.sprites[i] isa Window then return spriteDisp.sprites[i]
	end for
	return null
end function

openFile = function(filePath, fromWindow=null)
	info = file.info(filePath)
	if ["/sys", "/usr", "/usr2"].contains(filePath) then info = {"isDirectory":1}
	if info == null then
		print "Can't open path: " + filePath
		return
	else if info.isDirectory then
		w = FileWindow.make(filePath, 512, 350, 50, 40 + filePath.len*8)
		if fromWindow then
			w.goTo fromWindow.left + w.width/2 + 20, fromWindow.top - w.height/2 - 20
		else
			w.goTo 20 + w.width/2, 50 - w.height/2
		end if
	else if filePath.endsWith(".png") or
			filePath.endsWith(".jpg") or
			filePath.endsWith(".jpeg") then
		view filePath
	else if filePath.endsWith(".txt") or
			filePath.endsWith(".csv") or
			filePath.endsWith(".grfon") or
			filePath.endsWith(".json") then
		display(4).mode = displayMode.solidColor
		display(4).color = color.black
		text.color = color.silver
		view filePath
		text.color = color.gray; print "(Press any key.)"; key.get
		text.clear
		display(4).mode = displayMode.sprite
	else if filePath.endsWith(".ms") then
		text.color = color.orange
		clear; reset; load filePath; run
		exit
	else
		// can't launch other files yet, but maybe:
		view filePath
		text.clear
	end if
end function

handleShortcutKey = function(key)
	if key == "/" then
		if rootWindow == null then
			globals.rootWindow = FileWindow.make("/", 384, 128, 0, 80)
			rootWindow.goTo 200, 450
		else
			rootWindow.moveToFront
		end if
	else if key == "w" then
		w = frontmostWindow
		if w then w.close
	end if
end function

events.eventLoop.onGotKey = function(key)
	if key.code < 27 then
		handleShortcutKey char(key.code + 26)
	else
		// for now, treat unmodified keys as shortcut keys
		handleShortcutKey key
	end if
end function

//----------------------------------------------------------------------
// Main program
//----------------------------------------------------------------------

drawMenuBar
rootWindow = FileWindow.make("/", 384, 128, 0, 80)
rootWindow.goTo 200, 450
//window2 = FileWindow.make("/sys/pics", 512, 350, 125, 150)
//window2.goTo 600, 400
//window3 = Window.make(200,200, 25, 150, "Accessory")
//window3.goTo 750, 500

events.eventLoop.run
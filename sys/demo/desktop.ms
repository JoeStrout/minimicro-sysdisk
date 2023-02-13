// A simple (but fun!) desktop environment for Mini Micro.

import "events"
import "listUtil"
import "stringUtil"
import "mathUtil"
import "bmfFonts"
import "gui"

gui.setupDisplays

// import certain gui identifiers into our own global space
for ident in "scratchDisp spriteDisp menuDisp smallFont clearScratch".split
	globals[ident] = @gui[ident]
end for

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
// File icons and related methods
//----------------------------------------------------------------------

fileIcons = {}	// key: file name (without .png); value: Image
for iconFolder in ["/sys/data/desktop/icons", "/usr/data/desktop/icons"]
	for f in file.children(iconFolder)
		if not f.endsWith(".png") then continue
		img = file.loadImage(iconFolder + "/" + f)
		if img != null then fileIcons[f - ".png"] = img
	end for
end for

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
	if ext3 == ".bmf" then return fileIcons.font
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
		w = gui.images.iconHighlight.width
		h = gui.images.iconHighlight.height
		g.drawImage gui.images.iconHighlight, midx - w/2, midy - h/2, w, h,
		  0, 0, w, h, gui.selectionColor
		gui.images.rounded4.draw g, midx - nameWidth/2 - 4, midy - 50, nameWidth + 8, 16, gui.selectionColor
	end if
	icon = getIconForFile(nameOrPath)
	if icon.width > 64 or icon.height > 64 then
		f = min(64/icon.width, 64/icon.height)
		g.drawImage icon, midx - icon.width*f/2, midy - icon.height*f/2, icon.width*f, icon.height*f
	else
		g.drawImage icon, midx - icon.width/2, midy - icon.height/2
	end if
	globals.gfx = g
	smallFont.print name, midx - nameWidth/2, midy - 46, 1, color.black
end function

// Return whether the given mouse position is over the actual drawn image
// of the file (including name), as drawn by drawFile above.
isOverFile = function(xyMap, nameOrPath, left, bottom, width, height)
	if not nameOrPath then return false
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
// FileWindow (subclass of Window)
//----------------------------------------------------------------------

FileWindow = new gui.Window
FileWindow.selectedFiles = null	// list of selected file names
FileWindow.spacing = 128
FileWindow.lastClickTime = 0
FileWindow.isDoubleClick = false
FileWindow.make = function(path, width=300, height=200, titleLeft=0, titleWidth=150)
	w = new FileWindow
	w.width = width; w.height = height
	w.path = path
	w.selectedFiles = []
	w.contentImage = w.makeContentImage
	w.init width, height, titleLeft, titleWidth, path
	return w
end function

FileWindow.update = function
	if not self.isFrontmost then return
end function

FileWindow.onClick = function
	self.moveToFront
	if self.partHit(mouse) != gui.kPartContent then return super.onClick
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
	if self.partHit(screenPos) != gui.kPartContent then return null
	left = self.x - self.width/2 + self.scrollX
	top = self.y - 16 + self.height/2 + self.scrollY // (accounting for title bar)
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
	gui.clearScratch self.columns*self.spacing, contentHeight, color.white	
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
		w = gui.frontmostWindow
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

events.eventLoop.onUpdate = function
	scroll = key.axis("Mouse ScrollWheel")
	if scroll != 0 then
		wind = gui.windowUnderMouse
		if wind then wind.scroll 0, -scroll * gui.scrollWheelSpeed
	end if
end function

//----------------------------------------------------------------------
// Main program
//----------------------------------------------------------------------

gui.drawMenuBar
rootWindow = FileWindow.make("/", 384, 128, 0, 80)
rootWindow.goTo 200, 450

window2 = FileWindow.make("/sys/pics", 512, 350, 125, 150)
window2.goTo 600, 400

//window3 = Window.make(200,200, 25, 150, "Accessory")
//window3.goTo 750, 500

events.eventLoop.run
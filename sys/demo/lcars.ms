// This demo makes a GUI interface based on the famous LCARS UI,
// complete with a working file manager and other tools.
//
// It's mostly a matter of laying out panels with buttons and other
// widgets.

import "importUtil"
ensureImport "listUtil"
ensureImport "mathUtil"
ensureImport "stringUtil"
ensureImport "events"
ensureImport "bmfFonts"
ensureImport "dateTime"
ensureImport "gui"
ensureImport "styledText"

clear
spriteDisp = display(4)
display(7).mode = displayMode.pixel
scratch = display(7)
gfx.clear color.black

smallFont = bmfFonts.Font.load("/sys/fonts/minimicro-pro-12.bmf")
mediumFont = bmfFonts.Font.load("/usr/fonts/minimicro-pro-16.bmf")	// ToDo: get this on /sys!
largeFont = bmfFonts.Font.load("/sys/fonts/minimicro-pro-20.bmf")

resourcePic = file.loadImage("/usr/data/desktop/desktopGfx.png")	// ToDo: get from /sys
swoopImages = []
w = 163; h = 73
for i in range(0,3)
	swoopImages.push resourcePic.getImage(512-w*2+(i%2)*w, 512-h-h*floor(i/2), w, h)
end for
oval48 = gui.Image9Slice.make(resourcePic.getImage(464, 0, 48, 48), 24,24,24,24)
oval32 = gui.Image9Slice.make(resourcePic.getImage(424, 0, 32, 32), 16,16,16,16)
oval24 = gui.Image9Slice.make(resourcePic.getImage(392, 0, 24, 24), 12,12,12,12)
leftCap24 = gui.Image9Slice.make(resourcePic.getImage(392, 0, 12, 24), 11,12,1,12)
rightCap24 = gui.Image9Slice.make(resourcePic.getImage(404, 0, 12, 24), 1,12,11,12)

// Let's add a couple special characters to our fonts.
downInChar = char(8627)
upOutChar = char(11025)
smallFont.addChar downInChar, resourcePic.getImage(0,458,13,10), 0, 1, null
smallFont.addChar upOutChar, resourcePic.getImage(0,468,13,13), 0, -1, null
mediumFont.addChar downInChar, resourcePic.getImage(16,454,15,12), 0, 2, null
mediumFont.addChar upOutChar, resourcePic.getImage(16,466,15,14), 0, 0, null

//----------------------------------------------------------------------
Style = {}
Style._name = "Style"
Style.spacing = 2
Style.buttonHeight = 32
Style.buttonWidth = 120
Style.topBarHeight = function; return self.buttonHeight; end function
Style.bottomBarHeight = function; return self.topBarHeight; end function
Style.leftBarWidth = 120
Style.rightBarWidth = function; return self.leftBarWidth; end function
Style.swoopExtra = [64,48]

// colors reference: https://www.thelcars.com/colors.php
Style.color = "#FFEBDE"			// fallback color
Style.blockColor = function; return self.color; end function
Style.infoBlockColor = function; return self.blockColor; end function
Style.buttonColor = "#FFAA00"
Style.swoopColor = function; return self.infoBlockColor; end function
Style.textColor = function; return self.infoBlockColor; end function

//----------------------------------------------------------------------
// Modifier keys that affect various clicks.
modKey = {}
modKey.doAll = function
	return key.pressed("left alt") or key.pressed("right alt")
end function

//----------------------------------------------------------------------
Panel = {}
Panel._name = "Panel"
Panel.parent = null		// reference to parent
Panel.children = null	// list of children
Panel.left = 0
Panel.bottom = 0
Panel.width = 0
Panel.height = 0
Panel.style = Style
Panel.area = function; return self.width * self.height; end function
Panel.right = function; return self.left + self.width; end function
Panel.top = function; return self.bottom + self.height; end function
Panel.midX = function; return self.left + self.width/2; end function
Panel.midY = function; return self.bottom + self.height/2; end function
Panel.onUpdate = null

Panel.make = function(parent, left, bottom, width, height)
	p = new Panel
	if parent != null then
		parent.addChild p
		if left == null then left = parent.left
		if bottom == null then bottom = parent.bottom
		if width == null then width = parent.right - left
		if height == null then height = parent.top - bottom
		p.style = new parent.style
	end if
	p.left = left
	p.bottom = bottom
	p.width = width
	p.height = height
	p.children = []
	return p
end function

Panel.unparent = function
	if self.parent then self.parent.children.removeVal self
	self.parent = null
end function

Panel.addChild = function(child)
	child.unparent
	child.parent = self
	self.children.push child
end function

Panel.offset = function(dx, dy)
	return Panel.make(self.left + dx, self.bottom + dy, self.width, self.height)
end function

Panel.grow = function(dwidth, dheight)
	return Panel.make(self.left, self.bottom, self.width + dwidth, self.height + dheight)
end function

Panel.setTop = function(newTop, shiftBottom=true)
	if shiftBottom then self.bottom = newTop - self.height else self.height = newTop - self.bottom
end function

Panel.setRight = function(newRight, shiftLeft=true)
	if shiftLeft then self.left = newRight - self.width else self.width = newRight - self.left
end function

Panel.contains = function(pt)
	return pt.x >= self.left and pt.x < self.left + self.width and
	  pt.y >= self.bottom and pt.y < self.bottom + self.height
end function

Panel.debugDraw = function(g)
	if g == null then g = gfx
	g.drawRect self.left, self.bottom, self.width, self.height
	s = mapName(self.__isa)
	g.print s, self.left+3, self.bottom+3, g.color, "small"
	for child in self.children
		child.debugDraw g
	end for
end function

Panel.present = function
	for child in self.children
		child.present
	end for
end function

Panel.dismiss = function
	gfx.fillRect self.left, self.bottom, self.width, self.height, color.black
	for child in self.children
		child.dismiss
	end for
end function

Panel.destroy = function
	for child in self.children
		child.destroy
		child.parent = null
	end for
	children = null
	p = self.parent
	if p then
		self.parent = null
		p.children.removeVal self
	end if
end function

//----------------------------------------------------------------------
// Block: a panel that just draws a solid color
Block = new Panel
Block._name = "Block"
Block.make = function(parent, left, bottom, width, height)
	p = super.make(parent, left, bottom, width, height)
	p.__isa = self
	return p
end function

Block.present = function
	gfx.fillRect self.left, self.bottom, self.width, self.height, self.style.blockColor
	super.present
end function


//----------------------------------------------------------------------
// Gap: a special panel that represents a flexible gap in a layout of subpanels.
Gap = new Block
Gap._name = "Gap"
Gap.make = function(parent)
	p = super.make(parent)
	p.__isa = self
	return p
end function
	
Panel.layout = function
	gapCount = 0
	lastGap = null
	if self.width > self.height then
		// lay out children horizontally
		remainder = self.width - self.style.spacing * (self.children.len - 1)
		for child in self.children
			child.bottom = self.bottom; child.height = self.height
			child.left = 0
			if child.width == null then child.width = self.style.buttonWidth
			if child isa Gap then
				gapCount += 1
				lastGap = child
			else
				remainder -= child.width
			end if
		end for
		perGapWidth = floor(remainder / gapCount)
		gapsLeft = gapCount
		x = self.left
		for child in self.children
			if child isa Gap then
				if gapsLeft == 1 then child.width = remainder else child.width = perGapWidth
				remainder -= perGapWidth
				gapsLeft -= 1
			end if
			child.left = x
			x += child.width + self.style.spacing
		end for		
	else
		// lay out children vertically
		remainder = self.height - self.style.spacing * (self.children.len - 1)
		for child in self.children
			child.left = self.left; child.width = self.width
			child.bottom = 0
			if child.height == null then child.height = self.style.buttonHeight
			if child isa Gap then
				gapCount += 1
				lastGap = child
			else
				remainder -= child.height
			end if
		end for
		perGapHeight = floor(remainder / gapCount)
		gapsLeft = gapCount
		y = self.top
		for child in self.children
			if child isa Gap then
				if gapsLeft == 1 then child.height = remainder else child.height = perGapHeight
				remainder -= perGapHeight
				gapsLeft -= 1
			end if
			child.setTop y
			y -= child.height + self.style.spacing
		end for
	end if
end function

//----------------------------------------------------------------------
// Button: a panel that's clickable.
Button = new Panel
Button._name = "Button"
Button.caption = ""
Button.captionFont = mediumFont
Button.sprite = null
Button.action = null
Button.key = ""			// shortcut key, or list of keys
Button.keyButton = {}
Button.make = function(caption, parent, left, bottom, width, height)
	p = super.make(parent, left, bottom, width, height)
	p.__isa = self
	p.caption = caption
	if caption.len == 1 then p.key = caption
	return p
end function

Button.checkKey = function(k)
	if not Button.keyButton.hasIndex(k) then return false
	btn = Button.keyButton[k]
	btn.sprite.tint = btn.pressedColor
	wait 0.2
	btn.sprite.tint = btn.color
	btn.action
end function

Button.drawToScratch = function
	scratch.fillRect 0, 0, self.width, self.height, color.white
	globals.gfx = scratch
	self.captionFont.printRight self.caption, self.width-4, 4, 1, color.black
	globals.gfx = display(5)
end function

Button.makeSprite = function
	self.drawToScratch
	if self.sprite == null then self.sprite = new events.EventSprite
	self.sprite.image = scratch.getImage(0, 0, self.width, self.height)
	self.sprite.tint = self.color
	self.sprite.x = self.midX
	self.sprite.y = self.midY
	self.sprite.button = self
	self.sprite.onClick = function; self.button.onClick; end function
	self.sprite.onDrag = function; self.button.onDrag; end function
	self.sprite.onDragEnd = function; self.button.onDragEnd; end function
end function
Button.redrawSprite = function
	if not self.sprite then return
	self.drawToScratch
	self.sprite.image = scratch.getImage(0, 0, self.width, self.height)
end function

Button.present = function
	if self.sprite == null then self.makeSprite
	if not spriteDisp.sprites.contains(self.sprite) then self.sprite.start
	if self.key isa list then
		for k in self.key
			Button.keyButton[k] = self
		end for
	else
		Button.keyButton[self.key] = self
	end if
	super.present
end function

Button.move = function(dx, dy)
	self.left += dx; self.bottom += dy
	if self.sprite then
		self.sprite.x += dx; self.sprite.y += dy
	end if
end function

Button.dismiss = function
	if self.sprite != null then self.sprite.stop
	if self.key isa list then
		for k in self.key
			Button.keyButton.remove k
		end for
	else
		Button.keyButton.remove self.key
	end if
	if self.key then Button.keyButton.remove self.key
	super.dismiss
end function

Button.color = function; return self.style.buttonColor; end function
Button.pressedColor = function
	return color.lerp(self.color, color.black, 0.1)
end function

Button.onClick = function
	self.sprite.tint = self.pressedColor
end function

Button.onDrag = function
	if self.contains(mouse) then
		self.sprite.tint = self.pressedColor
	else
		self.sprite.tint = self.color
	end if
end function

Button.onDragEnd = function
	self.sprite.tint = self.color
	if self.contains(mouse) then self.action
end function

//----------------------------------------------------------------------
// RoundButton: a button with round endcaps.
// Height should be 24, 32, or 48 for best roundness.
RoundButton = new Button
RoundButton.make = function(caption, parent, left, bottom, width, height)
	p = super.make(caption, parent, left, bottom, width, height)
	p.__isa = self
	return p
end function

RoundButton.drawToScratch = function
	globals.gfx = scratch
	gfx.fillRect 0, 0, self.width, self.height, color.black
	pic = oval24
	if self.height >= 32 then pic = oval32
	if self.height >= 48 then pic = oval48
	pic.draw gfx, 0, 0, self.width, self.height
	self.captionFont.printRight self.caption, self.width-self.height/2, 4, 1, color.black
	globals.gfx = display(5)
end function

//----------------------------------------------------------------------
// InfoBlock: a block that shows some text
InfoBlock = new Panel
InfoBlock.font = mediumFont
InfoBlock.inverted = false	// if true, draw colored text on black background
InfoBlock.make = function(text, parent, left, bottom, width, height)
	p = super.make(parent, left, bottom, width, height)
	p.__isa = self
	p.text = text
	return p
end function

InfoBlock.present = function
	gfx.color = self.style.infoBlockColor * (not self.inverted) + color.black * self.inverted
	gfx.fillRect self.left, self.bottom, self.width, self.height
	textColor = self.style.infoBlockColor * self.inverted + color.black * (not self.inverted)
	self.font.printCentered self.text, self.midX, self.midY - self.font.lineHeight/2, 1, textColor
end function

//----------------------------------------------------------------------
// Swoop: swoopy corner piece for a Frame (below).
Swoop = new Panel
Swoop.which = 0		// 0=top left, 1=top right, 2=bot left, 3=bot right
Swoop.make = function(which, parent, left, bottom, width, height)
	if width == null then width = swoopImages[0].width + 12
	if height == null then height = swoopImages[0].height + 12
	p = super.make(parent, left, bottom, width, height)
	p.__isa = self
	p.which = which
	return p
end function

Swoop.present = function
	gfx.color = self.style.swoopColor
	w = swoopImages[0].width	// (it's OK, they're all the same size)
	h = swoopImages[0].height
	vertWidth = 120
	horzHeight = 32
	if self.which == 0 then			// top left
		gfx.drawImage swoopImages[0], self.left, self.top - h, -1, -1,
			0, 0, -1, -1, gfx.color
		gfx.fillRect self.left, self.bottom, vertWidth, self.height - h
		gfx.fillRect self.left + w, self.top - horzHeight, self.width - w, horzHeight
	else if self.which == 1 then	// top right
		// ToDo
	else if self.which == 2 then	// bottom left
		gfx.drawImage swoopImages[2], self.left, self.bottom, -1, -1,
			0, 0, -1, -1, gfx.color
		gfx.fillRect self.left, self.bottom + h, vertWidth, self.height - h
		gfx.fillRect self.left + w, self.bottom, self.width - w, horzHeight
	else if self.which == 3 then	// bottom right
		// ToDo
	end if		
end function

//----------------------------------------------------------------------
// Frame: Contains content with swoopy corner(s) and side/top/bottom bars.
// Currently, this always uses a medium-thickness top/bottom (if any),
// a wide left side, and no right.  We can generalize it more later.
Frame = new Panel
Frame.topPanel = null
Frame.leftPanel = null
Frame.bottomPanel = null
Frame.rightPanel = null
Frame.make = function(parent, left, bottom, width, height)
	p = super.make(parent, left, bottom, width, height)
	p.__isa = self
	return p
end function
Frame.configure = function(hasTop, hasBottom, hasLeft=true, hasRight=false)
	if hasTop then
		left = self.left
		if hasLeft then left += self.style.leftBarWidth + self.style.swoopExtra[0]
		right = self.right
		if hasRight then right -= self.style.rightBarWidth + self.style.swoopExtra[0]
		bottom = self.top - self.style.topBarHeight
		self.topPanel = Panel.make(self, left, bottom, right-left, self.style.topBarHeight)
	end if
	if hasBottom then
		left = self.left
		if hasLeft then left += self.style.leftBarWidth + self.style.swoopExtra[0]
		right = self.right
		if hasRight then right -= self.style.rightBarWidth + self.style.swoopExtra[0]
		self.bottomPanel = Panel.make(self, left, self.bottom, right-left, self.style.topBarHeight)
	end if
	if hasLeft then
		top = self.top
		if hasTop then top -= self.style.topBarHeight + self.style.swoopExtra[1]
		bottom = self.bottom
		if hasBottom then bottom += self.style.bottomBarHeight + self.style.swoopExtra[1]
		self.leftPanel = Panel.make(self, self.left, bottom, self.style.leftBarWidth, top-bottom)
	end if
	if hasRight then
		top = self.top
		if hasTop then top -= self.style.topBarHeight + self.style.swoopExtra[1]
		bottom = self.bottom
		if hasBottom then bottom += self.style.bottomBarHeight + self.style.swoopExtra[1]
		left = self.right - self.style.rightBarWidth
		self.rightPanel = Panel.make(self, left, bottom, self.style.rightBarWidth, top-bottom)
	end if
	gap = self.style.spacing
	if hasTop and hasLeft then
		Swoop.make 0, self, self.left, self.leftPanel.top + gap,
			self.topPanel.left - gap - self.left, self.top - self.leftPanel.top - gap
	end if
	if hasBottom and hasLeft then
		Swoop.make 2, self, self.left, self.bottom,
			self.bottomPanel.left - gap - self.left, self.leftPanel.bottom - gap - self.bottom
	end if
end function


// End of general classes.  Time for...

//======================================================================
// LCARS Application

// Root: the base of our entire display
root = Panel.make(null, 0, 0, 960, 640)

//----------------------------------------------------------------------
// File Manager panel
FileRow = new Button
FileRow.selected = false
FileRow.file = null  // a file.info map
FileRow.make = function(parent, left, bottom, width, height)
	p = super.make("", parent, left, bottom, width, height)
	p.__isa = self
	return p
end function
FileRow.setPath = function(path)
	if path.startsWith("//") then path = path[1:]
	self.file = file.info(path)
	if self.sprite then self.sprite.stop
	self.sprite = null
	if self.children then
		self.children[0].dismiss; self.children[0].destroy
		self.children = []
	end if
end function
FileRow.drawToScratch = function
	f = self.file
	gap = self.style.spacing
	y = 6
	globals.gfx = scratch
	gfx.fillRect 0, 0, self.width, self.height, color.black
	if self.selected then gfx.fillEllipse 0, 6, 16, 12, color.white
	x0 = 20
	leftCap24.draw gfx, x0, 0, 16, 24
	x0 += 16 + gap
	x1 = self.width
	if self.selected then gfx.fillEllipse x1-16, 6, 16, 12, color.white
	x1 -= 20
	rightCap24.draw gfx, x1-16, 0, 16, 24; x1 -= 16 + gap

	w = 48
	gfx.fillRect x1-w, 0, w, 24, color.white
	if f == null then
		smallFont.printCentered self.file, (x0+x1)/2, y, 1, color.red
		return
		
	end if
	
	smallFont.printCentered f.date[-8:-3], x1-w/2, y, 1, color.black; x1 -= w + gap

	w = 88
	gfx.fillRect x1-w, 0, w, 24, color.white
	smallFont.printCentered f.date[:10], x1-w/2, y, 1, color.black; x1 -= w + gap

	name = file.name(f.path)
	if f.isDirectory then
		w = 72 + 72
		if not self.children then
			b = RoundButton.make(downInChar + " Directory", self, self.left + x1 - w, self.bottom, w, 24)
			b.captionFont = smallFont
			b.action = function
				globals.wtf = self
				fb = self.parent.parent
				fb.load self.parent.file.path
				fb.present
			end function
			self.children = [b]
		end if
		x1 -= w + gap
	else
		w = 72
		smallFont.printCentered f.size, x1-w/2, y, 1, color.white; x1 -= w + gap

		extLen = name.reverse.indexOf(".")
		if extLen == null or extLen >= name.len - 1 then
			ext = ""
		else
			ext = name[-extLen-1:]
			name = name[:-extLen-1]
		end if
		w = 72
		gfx.fillRect x1-w, 0, w, 24, color.white
		smallFont.print ext, x1-w+2, y, 1, color.black; x1 -= w + gap
	end if
	
	w = x1 - x0
	gfx.fillRect x0, 0, w, 24, color.white
	smallFont.print name, x0+4, y, 1, color.black; x1 -= w + gap
	
	globals.gfx = display(5)
end function
FileRow.select = function(selectIt)
	if self.selected == selectIt then return
	self.selected = selectIt
	self.redrawSprite
end function

fileManager = Panel.make(root, 168, 0, 960-168, 640)
fileManager.style.color = "#7788ff"
fileManager.style.buttonColor = "#88CCFF"
fileManager.header = Frame.make(fileManager, null, fileManager.top - 108)
fileManager.header.configure false, true, true, false
Block.make fileManager.header.leftPanel
Block.make fileManager.header.bottomPanel
title = InfoBlock.make("FILE MANAGER", fileManager.header,
	fileManager.header.right - 200, fileManager.top - 30, 200, 30)
title.font = largeFont
title.inverted = true
fileManager.infoPanel = Panel.make(fileManager.header, 
	fileManager.header.bottomPanel.left,
	fileManager.header.bottomPanel.top + 8)
fileManager.infoPanel.setTop 632, false
fileManager.infoPanel.setRight title.left - 8, false
fileManager.infoPanel.present = function
	gfx.fillRect self.left, self.bottom, self.width, self.height, color.black
	sel = fileManager.fileBox.selection
	y = self.top - 20
	smallFont.print "Files selected: " + sel.len, self.left, y, 1, self.style.textColor
	if sel.len == 0 then return
	y -= 16
	totalSize = 0
	for f in sel; totalSize += f.file.size; end for
	smallFont.print "Total bytes: " + totalSize, self.left, y, 1, self.style.textColor
end function

fileManager.fileBox = Frame.make(fileManager, null, 0, null, fileManager.height - 118)
fileManager.fileBox.configure true, true, true, false
fileManager.fileBox.fileRows = []
fileManager.fileBox.setup = function
	w = 60
	Button.make "/usr", self.topPanel, null, null, w
	Button.make "/usr2", self.topPanel, null, null, w
	Button.make "/sys", self.topPanel, null, null, w
	b = Button.make(upOutChar + " UP", self.topPanel, null, null, w)
	b.action = function
		fb = self.parent.parent
		if fb.path == "/" then return
		fb.load file.parent(fb.path)
		fb.present
	end function
	self.pathInfo = InfoBlock.make("/usr", self.topPanel, null, null, self.topPanel.width - self.style.buttonWidth)
	self.topPanel.layout
	
	Button.make "Name", self.leftPanel, null, null, null, self.style.buttonHeight
	Button.make "Size", self.leftPanel, null, null, null, self.style.buttonHeight
	Button.make "Date", self.leftPanel, null, null, null, self.style.buttonHeight
	Button.make "Selected", self.leftPanel, null, null, null, self.style.buttonHeight
	Gap.make self.leftPanel
	Button.make("Select All", self.leftPanel, null, null, null, self.style.buttonHeight).action = function
		self.parent.parent.selectAll true
	end function
	Button.make("Select None", self.leftPanel, null, null, null, self.style.buttonHeight).action = function
		self.parent.parent.selectAll false
	end function
	Gap.make self.leftPanel
	Button.make "Move/Copy", self.leftPanel, null, null, null, self.style.buttonHeight
	self.leftPanel.layout
	
	Button.make "Rename", self.bottomPanel, null, null, self.style.buttonWidth
	delBtn = Button.make("Delete", self.bottomPanel, null, null, self.style.buttonWidth)
	delBtn.color = "#DD4444"
	Gap.make self.bottomPanel
	Button.make "Preview", self.bottomPanel, null, null, self.style.buttonWidth
	launchBtn = Button.make("Launch", self.bottomPanel, null, null, self.style.buttonWidth)
	launchBtn.color = "#33CC99"
	self.bottomPanel.layout
end function

fileManager.fileBox.load = function(path)
	self.path = path
	children = file.children(path)
	for i in range(0,13)
		if i >= children.len then break
		if i >= self.fileRows.len then
			fr = FileRow.make(self, 
			  self.topPanel.left-20, self.topPanel.bottom - 36 - 32*i, 
			  self.right - self.topPanel.left - 10, 24)
			fr.action = function
				if modKey.doAll then
					self.parent.selectAll not self.selected
				else
					self.select not self.selected
					fileManager.infoPanel.present
				end if
			end function
			self.fileRows.push fr
		end if
		self.fileRows[i].setPath file.child(self.path, children[i])
	end for	
	while self.fileRows.len > i
		self.fileRows[-1].dismiss; self.fileRows[-1].destroy
		self.fileRows.remove -1
	end while
	self.pathInfo.text = path
end function

fileManager.fileBox.selectAll = function(selectEm=true)
	for fr in self.fileRows
		fr.select selectEm
	end for
	fileManager.infoPanel.present
end function

fileManager.fileBox.selection = function
	return self.fileRows.filtered("selected")
end function

fileManager.fileBox.setup
fileManager.fileBox.load("/usr/")


//----------------------------------------------------------------------
// Clock panel
clock = Panel.make(root, 168, 0, 960-168, 640)
clock.header = Frame.make(clock, null, clock.top - 200)
clock.header.configure false, true, true, false
Block.make clock.header.leftPanel
Block.make clock.header.bottomPanel
title = InfoBlock.make("CLOCK", clock.header,
	clock.header.right - 200, clock.top - 30, 200, 30)
title.font = largeFont
title.inverted = true

clock.topDisplay = Panel.make(clock, clock.left + 160, clock.header.bottom + 50, 400, clock.header.height - 50)
clock.topDisplay.present = function
	gfx.fillRect self.left, self.bottom, self.width, self.height, color.black
	now = dateTime.val
	y = self.top - largeFont.lineHeight * 3
	x = self.left + 20
	largeFont.print dateTime.str(now, "dddd"), x, y, 2, self.style.textColor
	y = y - largeFont.lineHeight * 2
	largeFont.print dateTime.str(now, "MMMM d, yyyy"), x, y, 1, self.style.textColor
end function

clock.main = Panel.make(clock, clock.left, 0, clock.width, clock.header.bottom)
clock.main.present = function
	gfx.fillRect self.left, self.bottom, self.width, self.height, color.black
	s = dateTime.now.split[1]
	largeFont.printCentered s, self.midX, self.midY - 50, 6, self.style.textColor
	self.curTimeShown = s
end function

clock.onUpdate = function
	s = dateTime.now.split[1]
	if s != self.main.curTimeShown then self.main.present
end function

//----------------------------------------------------------------------
// Calculator panel
calc = Panel.make(root, 168, 0, 960-168, 640)
calc.style.displayColor = "#88CCFF"
calc.header = Frame.make(calc, null, calc.top - 108)
calc.header.configure false, true, true, false
calc.displayStr = "0"
calc.clearOnInput = false
Block.make calc.header.leftPanel
Block.make calc.header.bottomPanel
title = InfoBlock.make("CALCULATOR", calc.header,
	calc.header.right - 200, calc.top - 30, 200, 30)
title.font = largeFont
title.inverted = true

calc.display = Panel.make(calc, calc.left+160, calc.top-64, 420, 48)
calc.display.present = function
	gfx.fillRect self.left, self.bottom, self.width, self.height, "#666688"
	largeFont.printRight calc.displayStr, self.right - 4, self.bottom + 8, 2, self.style.displayColor
end function

calc.doAction = function(s)
	if s >= "0" and s <= "9" then
		if self.displayStr == "0" or self.clearOnInput then self.displayStr = ""
		self.displayStr += s
		self.clearOnInput = false
	else if s == "Backspace" and self.displayStr then
		self.displayStr = calc.displayStr[:-1]
		if not self.displayStr then self.displayStr = "0"
	else if s == "Clear" then
		self.displayStr = "0"
		self.opA.text = ""
		self.operator.text = ""
		self.opA.present
		self.operator.present
	else if s == "=" then
		op = self.operator.text
		if not op then return
		valA = val(self.opA.text)
		valB = val(self.displayStr)
		result = valB
		if op == "+" then result = valA + valB
		if op == "-" then result = valA - valB
		if op == "*" then result = valA * valB
		if op == "/" then result = valA / valB
		if op == "^" then result = valA ^ valB
		if op == "%" then result = valA % valB
		if op == "and" then result = valA and valB
		if op == "or" then result = valA or valB
		if op == "not" then result = valA not valB
		self.displayStr = str(result)
		self.main.log.add valA + " " + op + " " + valB, self.displayStr
		self.clearOnInput = true
	else
		self.opA.text = self.displayStr
		self.operator.text = s
		self.displayStr = "0"
		self.opA.present
		self.operator.present
	end if
	self.display.present
end function

calc.main = Frame.make(calc, null, 0, null, calc.height - 118)
calc.main.configure true, false, true, false

Gap.make calc.main.topPanel
calc.main.logHeader = InfoBlock.make("Calculation Log", calc.main.topPanel, null, null, 320)
calc.main.topPanel.layout

b = Button.make("Backspace", calc.main.leftPanel, null, null, null, calc.style.buttonHeight)
b.action = function; calc.doAction self.caption; end function
b.key = char(8)

b = Button.make("Clear", calc.main.leftPanel, null, null, null, calc.style.buttonHeight)
b.action = function; calc.doAction self.caption; end function
b.key = char(1)	// (Home button, at least on Macs)

InfoBlock.make "", calc.main.leftPanel, null, null, null, calc.style.buttonHeight*2

b = Button.make("=", calc.main.leftPanel, null, null, null, calc.style.buttonHeight*3)
b.action = function; calc.doAction self.caption; end function
b.key = ["=", char(10), char(13), char(3)]

Gap.make calc.main.leftPanel

calc.opA = InfoBlock.make("", calc.main.leftPanel, null, null, null, calc.style.buttonHeight)
calc.operator = InfoBlock.make("", calc.main.leftPanel, null, null, null, calc.style.buttonHeight)
Gap.make calc.main.leftPanel
calc.main.leftPanel.layout

calc.main.setup = function
	y = self.topPanel.bottom - 72
	btns = ["789", "456", "123", " 0.", "+-*", "/^%", ["and","or","not"]]
	for row in btns.indexes
		for col in btns[row].indexes
			x = self.topPanel.left + 96*col
			if btns[row][col] == " " then continue
			if btns[row][col] == "0" then
				x = self.topPanel.left
				b = RoundButton.make(btns[row][col], calc, x, y, 84+96, 48)
			else
				b = RoundButton.make(btns[row][col], calc, x, y, 84, 48)
			end if
			b.action = function; calc.doAction self.caption; end function
		end for
		y = y - 60 - 24 * (row == 3)
	end for
end function
calc.main.setup

calc.main.log = Panel.make(calc.main, calc.main.logHeader.left, 16, calc.main.logHeader.width, calc.main.topPanel.bottom - 40)
calc.main.log.add = function(expression, result)
	h = self.style.topBarHeight
	gap = 8
	y = self.top - h - self.children.len * (h+gap)
	while y < self.bottom
		self.children[0].dismiss; self.children[0].destroy
		for b in self.children; b.move 0, h+gap; end for
		y += h+gap
	end while
	b = Button.make(expression + " = " + result, self, self.left, y, self.width, h)
	b.action = function
		calc.displayStr = result
		calc.display.present
	end function
	b.present
end function

//----------------------------------------------------------------------
// News panel
news = Panel.make(root, 168, 0, 960-168, 640)
news.style.displayColor = "#88CCFF"
news.header = Frame.make(news, null, news.top - 108)
news.header.configure false, true, true, false
news.clearOnInput = false
Block.make news.header.leftPanel
Block.make news.header.bottomPanel
title = InfoBlock.make("NEWS", news.header,
	news.header.right - 200, news.top - 30, 200, 30)
title.font = largeFont
title.inverted = true

news.main = Frame.make(news, null, 0, null, news.height - 118)
news.main.configure true, false, true, false

Gap.make news.main.topPanel
news.date = InfoBlock.make("2000-01-01", news.main.topPanel, null, null, 160)
news.posCount = InfoBlock.make("0 / 0", news.main.topPanel, null, null, 160)
news.main.topPanel.layout

Gap.make news.main.leftPanel

b = Button.make("Previous", news.main.leftPanel, null, null, null, news.style.buttonHeight)
b.action = function; news.nextStory -1; end function
b.key = char(17)

b = Button.make("Next", news.main.leftPanel, null, null, null, news.style.buttonHeight)
b.action = function; news.nextStory 1; end function
b.key = char(18)

Gap.make news.main.leftPanel
news.main.leftPanel.layout

news.data = null; news.curItemIdx = 0
news.nextStory = function(delta=1)
	if not self.data then return
	self.curItemIdx = (self.curItemIdx + self.data.len + delta) % self.data.len
	self.content.present
end function

news.content = Panel.make(news.main, news.main.topPanel.left, 0, 
			940 - news.main.topPanel.left, news.main.topPanel.bottom - 16)
news.presenting = false	// or a map of context data
news.content.present = function
	if news.data == null then
		lines = http.get("https://miniscript.org/news/news.dat").splitLines
		news.data = []
		curItem = {}
		for line in lines
			if line == "" then
				if curItem then news.data.push curItem
				curItem = {}
				continue
			end if
			parts = line.split(": ", 2)
			if parts.len < 2 then continue
			curItem[parts[0]] = parts[1]
		end for
		if curItem then news.data.push curItem
	end if
	story = news.data[news.curItemIdx]
	news.date.text = story.date; news.date.present
	news.posCount.text = news.curItemIdx + " / " + news.data.len; news.posCount.present

	gfx.fillRect self.left, self.bottom, self.width, self.height, color.black

	printer = new styledText.BmfPrinter
	printer.x = self.left
	printer.wrapTo = self.left
	printer.wrapAt = self.right
	printer.y = self.top - 20
	printer.font = mediumFont
	gfx.color = color.yellow
	printer.printHTML story.title, self.left
	gfx.color = self.style.textColor; printer.y -= 20
	printer.printHTML story.shortText, self.left; printer.y -= 20
	if story.hasIndex("moreText") then
		printer.printHTML story.moreText, self.left
	end if
end function


//----------------------------------------------------------------------
// Main Menu: a simple panel of buttons (and gaps) on the left side of the screen.
// Color of each button corresponds to the primary color of the UI it shows.
mainMenu = Panel.make(root, 0, 0, 144, 640)
mainMenu.style = new root.style
mainMenu.style.buttonHeight = 36
mainMenu.style.infoBlockColor = "#D0B0A0"
mainMenu.curMode = null

mainMenu.switchTo = function(modePanel)
	if self.curMode == modePanel then return
	if self.curMode then self.curMode.dismiss
	self.curMode = modePanel
	self.curMode.present
end function

// Mini-clock at the top
miniClock = InfoBlock.make(dateTime.now[-8:-3], mainMenu, null, null, null, 40)
// Settings button
Button.make "Settings", mainMenu, null, null, null, mainMenu.style.buttonHeight
// ...gap...
Gap.make mainMenu
// Main buttons, one for each mode
b = Button.make("File Manager", mainMenu, null, null, null, mainMenu.style.buttonHeight)
b.style.buttonColor = fileManager.style.buttonColor
b.action = function; mainMenu.switchTo fileManager; end function

Button.make("Clock", mainMenu, null, null, null, mainMenu.style.buttonHeight).action = function
	mainMenu.switchTo clock
end function
Button.make("Calculator", mainMenu, null, null, null, mainMenu.style.buttonHeight).action = function
	mainMenu.switchTo calc
end function
Button.make("News", mainMenu, null, null, null, mainMenu.style.buttonHeight).action = function
	mainMenu.switchTo news
end function
// ...gap...
Gap.make mainMenu
// Exit button at bottom
exitBtn = Button.make("Exit", mainMenu, null, null, null, mainMenu.style.buttonHeight)
exitBtn.action = function
	root.dismiss; root.destroy
	exit
end function
exitBtn.key = char(27)

events.eventLoop.onGotKey = function(k)
	Button.checkKey k
end function
events.eventLoop.onUpdate = function
	mainMenu.curMode.onUpdate
	time = dateTime.now[-8:-3]
	if time != miniClock.text then
		miniClock.text = time
		miniClock.present
	end if
end function

mainMenu.layout
mainMenu.present
mainMenu.switchTo fileManager

events.eventLoop.run

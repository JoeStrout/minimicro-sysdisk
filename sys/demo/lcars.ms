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

file.loadSound("/sys/sounds/blip-thinking.wav").play

clear
spriteDisp = display(4)
display(7).mode = displayMode.pixel
scratch = display(7)
gfx.clear color.black

loadFontName = function(fontName)
	for basePath in ["/usr/fonts/", "/sys/fonts/", "./"]
		fullPath = basePath + fontName + ".bmf"
		if file.exists(fullPath) then return bmfFonts.Font.load(fullPath)
	end for
	print "Font not found: " + fontName
	exit
end function
smallFont = loadFontName("Lcars-24")
mediumFont = loadFontName("Lcars-32")
largeFont = loadFontName("Lcars-48")

resourcePic = file.loadImage("/sys/data/desktop/desktopGfx.png")
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
pageUpChar = char(8670)
pageDownChar = char(8671)
lineUpChar = char(8613)
lineDownChar = char(8615)
mediumFont.addChar lineUpChar, resourcePic.getImage(16, 439, 15, 14), 0, 0, null
mediumFont.addChar pageUpChar, resourcePic.getImage(16, 424, 15, 14), 0, 0, null
mediumFont.addChar pageDownChar, resourcePic.getImage(16, 409, 15, 14), 0, 0, null
mediumFont.addChar lineDownChar, resourcePic.getImage(16, 394, 15, 14), 0, 0, null

// And prepare some sounds
sounds = {}
sounds.blip = file.loadSound("/sys/sounds/blipA4.wav")
sounds.alert = file.loadSound("/sys/sounds/blip-alert.wav")
sounds.ok = file.loadSound("/sys/sounds/blip-ok.wav")
sounds.err = file.loadSound("/sys/sounds/blip-what.wav")

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
Button.key = ""			// shortcut key (character), or list of keys
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
	self.font.printCentered self.text, self.midX, self.midY - self.font.lineHeight/2 + 2, 1, textColor
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

// Load an app module from mods/lcars, call its init, and return its panel.
loadApp = function(name)
	oldPaths = env.importPaths
	env.importPaths = ["/usr/mods/lcars", "/sys/mods/lcars"] + oldPaths
	import name
	env.importPaths = oldPaths
	mod = locals[name]
	mod.init
	return mod.panel
end function

// Load all the modules found in /sys/mods/lcars and /usr/mods/lcars
// (allowing the latter to override the former)
appModules = []
loadAllApps = function
	names = {}
	for name in file.children("/usr/mods/lcars")
		if name.endsWith(".ms") then names.push name - ".ms"
	end for
	for name in file.children("/sys/mods/lcars")
		if name.endsWith(".ms") then names.push name - ".ms"
	end for
	for name in names.indexes
		appModules.push loadApp(name)
	end for	
end function

loadAllApps

//----------------------------------------------------------------------
// Main Menu: a simple panel of buttons (and gaps) on the left side of the screen.
// Color of each button corresponds to the primary color of the UI it shows.
mainMenu = Panel.make(root, 0, 0, 144, 640)
mainMenu.style = new root.style
mainMenu.style.buttonHeight = 36
mainMenu.style.buttonColor = "#ffaa90"
mainMenu.style.infoBlockColor = "#D0B0A0"
mainMenu.curMode = null

mainMenu.switchTo = function(modePanel)
	if self.curMode == modePanel then return
	if self.curMode then self.curMode.dismiss
	sounds.alert.play
	self.curMode = modePanel
	self.curMode.present
end function

// Mini-clock at the top
miniClock = InfoBlock.make(dateTime.now[-8:-3], mainMenu, null, null, null, 40)
// Settings button
Button.make("Settings", mainMenu, null, null, null, mainMenu.style.buttonHeight).action = function
	// We don't have any settings yet.
	// Maybe someday!
	sounds.err.play
end function

// ...gap...
Gap.make mainMenu

// Main buttons, one for each mode
appModules.sort "modeLabel"
for mod in appModules
	b = Button.make(mod.modeLabel, mainMenu, null, null, null, mainMenu.style.buttonHeight)
	b.style.buttonColor = mod.style.color
	b.mod = mod
	b.action = function; mainMenu.switchTo self.mod; end function
end for

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
	if key.pressed("page down") then
		Button.checkKey char(4)  // ctrl-D
		while key.pressed("page down"); yield; end while
	else if	key.pressed("page up") then
		Button.checkKey char(21)  // ctrl-U
		while key.pressed("page up"); yield; end while
	end if
	time = dateTime.now[-8:-3]
	if time != miniClock.text then
		miniClock.text = time
		miniClock.present
	end if
end function

mainMenu.layout
mainMenu.present
mainMenu.switchTo appModules[0]

events.eventLoop.run

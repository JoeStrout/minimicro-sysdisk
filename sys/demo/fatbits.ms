// Pixel Painting program.  Handy for making sprites
// without ever leaving Mini Micro!

import "listUtil"
import "textUtil"
import "mathUtil"
import "qa"

// Constants and global state variables
kModeDraw = "DRAW"
kModeErase = "ERASE"
kModeSelect = "SELECT"
kModeMove = "MOVE"
kModeFill = "FILL"
kModeEyedrop = "EYEDROP"
kModePaint = "PAINT"
kModeLighten = "LIGHTEN"
kModeDarken = "DARKEN"
kModeBlur = "BLUR"
kModeDrawRect = "DRAWRECT"
kModeFillRect = "FILLRECT"
kModeDrawEllipse = "DRAWELLIPSE"
kModeFillEllipse = "FILLELLIPSE"
kModeLine = "DRAWLINE"
kModeReplace = "REPLACE"
kModePasting = "PASTING"

foreColor = "#000000FF"
backColor = "#00000000"
spriteBoundsColor = color.silver
ps = 9	// "pixel size" (forgive the short name, but we use this a lot)
picW = 64
picH = 64
resourceDir = "/sys/data/fatbits/"

// Prepare displays
// text: display 1
clear
display(1).mode = displayMode.text
text = display(1)
text.backColor = color.clear
text.clear
// spriteDisp: used for UI buttons, etc.
display(2).mode = displayMode.sprite
spriteDisp = display(2)
spriteDisp.clear
// gfx: static overlay (drawing area grid, etc.)
display(3).mode = displayMode.pixel
gfx = display(3)
gfx.clear
// bkgnd: background color; masks off everything except paint area
display(4).mode = displayMode.pixel
bkgnd = display(4)
bkgnd.clear "#929292", 970, 650
bkgnd.scrollX = 5
bkgnd.scrollY = 5
// fatbits: scaled-up (fat) display of picture we're drawing
display(5).mode = displayMode.pixel
fatbits = display(5)
fatbits.clear color.clear, picW, picH
fatbits.scale = ps
// backdrop: area that appears behind the fat-bits drawing (and preview area)
display(6).mode = displayMode.pixel
backdrop = display(6)
backdrop.color = "#444444"
// scratch: hidden drawing area
display(7).mode = displayMode.pixel
scratch = display(7)

// load brush sprites
brushImages = [null]
for i in range(1, 12)
	brushImages.push file.loadImage(resourceDir + "Brush-" + i + ".png")
end for
brushSprite = new Sprite
brushSprite.image = brushImages[5]
brushSprite.tint = "#00FFFF88"
spriteDisp.sprites.push brushSprite

brushRowWidths = [null, [1], [2,2], [3,3,3], [2,4,4,2], [3,5,5,5,3], [4,6,6,6,6,4],
  [3,5,7,7,7,5,3], [4,6,8,8,8,8,6,4], [5,7,9,9,9,9,9,7,5], [4,8,8,10,10,10,10,8,8,4],
  [5,7,9,11,11,11,11,11,9,7,5], [4,8,10,10,12,12,12,12,10,10,8,4]]


// Helper methods we probably should have in a utils module somewhere
Sprite.addBounds = function(inset=0)
	qa.assert self.image != null, "Sprite image is null"
	self.localBounds = new Bounds
	self.localBounds.width = self.image.width - inset*2
	self.localBounds.height = self.image.height - inset*2
end function


updatePaintScroll = function
	hsz = 32 * previewArea.scale  // (half scrollbox size)
	fatbits.scrollX = (previewArea.scrollbox.x-hsz - previewArea.left) / 
		previewArea.scale * fatbits.scale - paintArea.left
	fatbits.scrollY = (previewArea.scrollbox.y-hsz - previewArea.bottom) /
		previewArea.scale * fatbits.scale - paintArea.bottom
end function

//---------------------------------------------------------------------
// Make a handy Rect class
Rect = {}
Rect.left = 0
Rect.bottom = 0
Rect.width = 0
Rect.height = 0
Rect.area = function; return self.width * self.height; end function
Rect.right = function; return self.left + self.width; end function
Rect.top = function; return self.bottom + self.height; end function
Rect.midX = function; return self.left + self.width/2; end function
Rect.midY = function; return self.bottom + self.height/2; end function
Rect.make = function(left, bottom, width, height)
	r = new Rect
	r.left = left
	r.bottom = bottom
	r.width = width
	r.height = height
	return r
end function
Rect.fromPoints = function(p0, p1)
	r = new Rect
	if p0.x < p1.x then
		r.left = p0.x
		r.width = p1.x - p0.x
	else
		r.left = p1.x
		r.width = p0.x - p1.x
	end if
	if p0.y < p1.y then
		r.bottom = p0.y
		r.height = p1.y - p0.y
	else
		r.bottom = p1.y
		r.height = p0.y - p1.y
	end if
	return r
end function
Rect.offset = function(dx, dy)
	return Rect.make(self.left + dx, self.bottom + dy, self.width, self.height)
end function
Rect.grow = function(dwidth, dheight)
	return Rect.make(self.left, self.bottom, self.width + dwidth, self.height + dheight)
end function
Rect.contains = function(pt)
	return pt.x >= self.left and pt.x < self.left + self.width and
	  pt.y >= self.bottom and pt.y < self.bottom + self.height
end function
Rect.fill = function(gfx, color=null)
	gfx.fillRect self.left, self.bottom, self.width, self.height, color
end function
Rect.fillEllipse = function(gfx, color=null)
	gfx.fillEllipse self.left, self.bottom, self.width, self.height, color
end function
Rect.drawImage = function(gfx, image)
	gfx.drawImage image, self.left, self.bottom, self.width, self.height
end function
Rect.frame = function(gfx, color=null, lineWidth=1, inset=0)
	gfx.drawRect self.left+inset, self.bottom+inset,
	   self.width-inset*2, self.height-inset*2,
	   color, lineWidth
end function
Rect.frameEllipse = function(gfx, color=null, lineWidth=1, inset=0)
	gfx.drawEllipse self.left+inset, self.bottom+inset,
	   self.width-inset*2, self.height-inset*2,
	   color, lineWidth
end function

//---------------------------------------------------------------------
// Buttons
Button = {}
Button.btnDownImg = file.loadImage(resourceDir + "toolButtonDown.png")
Button.btnUpImg = file.loadImage(resourceDir + "toolButtonUp.png")
Button.instances = []
Button.toggles = false
Button.isDown = false	// (for toggle buttons, which can be up or down)
Button.init = function(imageName, left, top)
	self.bgSprite = new Sprite
	self.bgSprite.image = Tool.btnUpImg
	self.bgSprite.x = left + Tool.btnUpImg.width/2
	self.bgSprite.y = 640 - top - Tool.btnUpImg.height/2
	spriteDisp.sprites.push self.bgSprite
	
	self.iconSprite = new Sprite
	self.iconSprite.image = file.loadImage(resourceDir + imageName + ".png")
	self.iconSprite.x = self.bgSprite.x
	self.iconSprite.y = self.bgSprite.y
	spriteDisp.sprites.push self.iconSprite
	
	self.bgSprite.addBounds
	
	Button.instances.push self
end function

Button.update = function(pressed=false)
	if pressed then
		self.bgSprite.image = Tool.btnDownImg
		self.bgSprite.tint = "#666666"
		self.iconSprite.tint = color.white
	else if self.isDown then
		self.bgSprite.image = Tool.btnDownImg
		self.bgSprite.tint = color.white
		self.iconSprite.tint = color.white
	else
		self.bgSprite.image = Tool.btnUpImg
		self.bgSprite.tint = color.white
		self.iconSprite.tint = "#CCCCCCCC"
	end if
end function

Button.make = function(imageName, left, top, toggles=false)
	btn = new Button
	btn.init imageName, left, top
	btn.toggles = toggles
	return btn
end function

Button.handleClick = function
	if self.toggles then
		self.isDown = not self.isDown
	end if
end function

Button.checkEvents = function
	if mouse.button and self.bgSprite.contains(mouse) then
		// track mouse until released
		while mouse.button
			self.update self.bgSprite.contains(mouse)
			yield
		end while
		if self.bgSprite.contains(mouse) then self.handleClick
		self.update
	end if
end function

//---------------------------------------------------------------------
// Sliders etc.
Slider = {}
Slider.instances = []
Slider.init = function(imgName, left, bottom)
	self.bgSprite = new Sprite
	path = resourceDir + imgName + ".png"
	self.bgSprite.image = file.loadImage(path)
	qa.assert self.bgSprite.image != null, "unable to locate " + path
	self.bgSprite.addBounds
	self.bgSprite.x = left + self.bgSprite.image.width/2
	self.bgSprite.y = bottom + self.bgSprite.image.height/2
	spriteDisp.sprites.push self.bgSprite
	
	self.knob = new Sprite
	self.knob.image = file.loadImage(resourceDir + "diamondKnob.png")
	self.knob.x = self.bgSprite.x
	self.knob.y = self.bgSprite.y
	spriteDisp.sprites.push self.knob
	
	Slider.instances.push self
end function

Slider.make = function(imgName, left, bottom)
	noob = new Slider
	noob.init imgName, left, bottom
	return noob
end function

Slider.set = function(value)
	w = self.bgSprite.image.width
	self.knob.x = self.bgSprite.x - w/2 + w * value
end function

Slider.value = function
	w = self.bgSprite.image.width
	return (self.knob.x - self.bgSprite.x + w/2) / w
end function

Slider.snap = null

Slider.checkEvents = function
	if mouse.button and not mouseWasDown and self.bgSprite.contains(mouse) then
		w = self.bgSprite.image.width
		while mouse.button
			rx = mouse.x - self.bgSprite.x  // get mouse position relative to slider center
			value = rx / w + 0.5
			if value < 0 then value = 0
			if value > 1 then value = 1
			self.set value
			self.snap
			if @self.applyValue != null then self.applyValue value
			yield
		end while
	end if
end function

Slider.applyValue = null

Slider.toggleHidden = function
	self.bgSprite.x = -self.bgSprite.x
	self.knob.x = -self.knob.x
end function

Slider.isHidden = function
	return self.bgSprite.x < 0
end function

Slider.hide = function
	if not self.isHidden then self.toggleHidden
end function

Slider.show = function
	if self.isHidden then self.toggleHidden
end function

lightnessSlider = Slider.make("lightnessSlider", 8, 24)
lightnessSlider.applyValue = function(value)
	colorWheel.updateColor
end function

alphaSlider = Slider.make("alphaSlider", 8, 8)
alphaSlider.applyValue = function(value)
	colorWheel.updateColor
end function

scaleSlider = Slider.make("scaleSlider", 804, 360)
scaleSlider.value = function
	// Our scale slider has 11 divisions (bracketing sizes from 1 to 12), 10 pixels apart.
	leftx = self.bgSprite.x - 64
	dx = self.knob.x - leftx
	value = round(dx / 10)
	if value < 1 then return 1
	if value > 12 then return 12
	return value
end function
scaleSlider.snap = function
	v = self.value
	self.knob.x = self.bgSprite.x - 64 + v*10
end function
scaleSlider.applyValue = function(value)
	// ignore the passed-in value; get our computed value instead
	globals.brushSize = self.value
	if brushSize < brushImages.len then brushSprite.image = brushImages[brushSize]
	// ToDo: draw a representation of the brush (which should maybe even
	// be clickable to switch between round and square!)
end function
scaleSlider.snap
scaleSlider.applyValue
	
//---------------------------------------------------------------------
// Tools
Tool = new Button
Tool.mode = null
Tool.instances = []
Tool.init = function(name, left, top, mode)
	super.init "tool" + name, left, top	
	self.mode = mode
	Tool.instances.push self
end function

Tool.make = function(name, left, top, mode)
	tool = new Tool
	tool.init name, left, top, mode
	return tool
end function

Tool.isDown = function
	return mode == self.mode
end function

// if option key is pressed, switch temporarily to eyedrop mode,
// and use this to remember what to switch back to:
Tool.optKeySwitchedFrom = null

Tool.checkEvents = function
	optKeyIsDown = key.pressed("left alt") or key.pressed("right alt")
	if optKeyIsDown then
		if self.mode == kModeEyedrop and mode != self.mode then
			Tool.optKeySwitchedFrom = mode
			setMode self.mode
		end if
	else if Tool.optKeySwitchedFrom == self.mode then
		Tool.optKeySwitchedFrom = null
		setMode self.mode
	end if
	
	super.checkEvents
end function

Tool.handleClick = function
	setMode self.mode
end function

modesWithSize = [kModeErase, kModePaint, kModeLighten, kModeDarken, kModeBlur,
  kModeDrawRect, kModeDrawEllipse, kModeLine]
setMode = function(newMode)
	globals.mode = newMode
	globals.drawErases = false
	deselect
	for tool in Tool.instances
		tool.update
	end for
	if modesWithSize.contains(newMode) then scaleSlider.show else scaleSlider.hide
end function

//---------------------------------------------------------------------
// screen layout
paintArea = Rect.make(180, 10, 64*ps, 64*ps)
prepareScreen = function
	paintArea.offset(5,5).fill bkgnd, color.clear
	paintArea.grow(1,1).frame gfx, color.black, 4, -4
	backdrop.clear color.black
	drawGrid
	previewArea.draw
	gfx.print "press ? for help", 955 - 16*9, 640-18, color.silver, "small"
end function
drawGrid = function
	// Select current image
	img = selectedTab.image
	// Calculate backdrop rectangle
	if img.width >= 64 then maxWidth = 64 else maxWidth = img.width
	if img.height >= 64 then maxHeight = 64 else maxHeight = img.height
	backdropRect = Rect.make(
	    paintArea.midX - (maxWidth / 2)*ps,
	    paintArea.midY - (maxHeight / 2)*ps,
	    maxWidth * ps,
	    maxHeight * ps)
	// Fill backdrop area
	backdropRect.fill(backdrop, backdrop.color)
	// Draw lines for individual "fat" pixels
	gfx.color = "#88888866"
	for i in range(1, 63)
		if i % 8 == 0 then continue
		x = paintArea.left + i*ps
		gfx.line x, paintArea.top, x, paintArea.bottom
		y = paintArea.bottom + i*ps
		gfx.line paintArea.left, y, paintArea.right, y
	end for
	// Draw 8x8 cell separators
	gfx.color = "#777777AA"
	for i in range(0, 64, 8)
		x = paintArea.left + i*ps
		gfx.line x, paintArea.top, x, paintArea.bottom
		y = paintArea.bottom + i*ps
		gfx.line paintArea.left, y, paintArea.right, y
	end for
	// Draw bounding box of fatbits area
	backdropRect.frame(gfx, spriteBoundsColor)
end  function

makeTools = function
	tools = [
	["Pencil", kModeDraw], ["Erase", kModeErase], ["Move", kModeMove], ["Select", kModeSelect],
	["Brush", kModePaint], ["Fill", kModeFill], ["ReplaceColor", kModeReplace],  ["Blur", kModeBlur],
	["Line", kModeLine], ["DrawRect", kModeDrawRect], ["DrawEllipse", kModeDrawEllipse], ["Lighten", kModeLighten],
	["Eyedropper", kModeEyedrop], ["FillRect", kModeFillRect], ["FillEllipse", kModeFillEllipse], ["Darken", kModeDarken]]
	for i in tools.indexes
		t = tools[i]
		if t[0] == null then continue
		Tool.make t[0], 788 + 40*(i%4), 56 + 40*floor(i/4), t[1]
	end for
end function
makeTools

vSymmetry = Button.make("modeSymmetry", 818, 304, true)
hSymmetry = Button.make("modeSymmetry", 880, 304, true)
hSymmetry.iconSprite.rotation = 90

// Find the painting location at the given screen location.
paintPixelAtXY = function(pos)
	result = {}
	result.x = floor((pos.x + fatbits.scrollX) / ps)
	result.y = floor((pos.y + fatbits.scrollY) / ps)
	return result
end function

// Find the X and Y screen locations for a given painting location.
// (Inverse of paintPixelAtXY, above.)  This returns the CENTER of
// the given fat pixel.
xAtPaintPixel = function(pp); return (pp.x + 0.5) * ps - fatbits.scrollX; end function
yAtPaintPixel = function(pp); return (pp.y + 0.5) * ps - fatbits.scrollY; end function

// Set one pixel in our painting to a specific color.
setPaintPixel = function(pos, c="#000000")
	fatbits.setPixel pos.x, pos.y, c
end function

// Get all symmetry versions of the given paint position, as a list.
symmetries = function(pp)
	result = [pp]
	// Careful: some tools need an extra offset in the reflected quadrants, while
	// others (depending on the brush size) do not.
	xtra = 1
	if modesWithSize.contains(mode) and brushSize%2 == 0 then xtra = 0
	if vSymmetry.isDown then result.push {"x":picW - pp.x - xtra, "y":pp.y}
	if hSymmetry.isDown then result.push {"x":pp.x, "y":picH - pp.y - xtra}
	if vSymmetry.isDown and hSymmetry.isDown then result.push {"x":picW-pp.x-xtra, "y":picH-pp.y-xtra}
	return result
end function

// Get all the pixels affected by a brush (of brushSize) at the given position.
affectedPixels = function(pp)
	if brushSize == 1 then return [pp]
	widths = brushRowWidths[brushSize]
	result = []
	for i in widths.indexes
		w = widths[i]
		y = pp.y - floor(brushSize/2) + i
		for x in range(pp.x - floor(w/2), pp.x + floor(w/2) - 1 + brushSize%2)
			result.push {"x":x, "y":y}
		end for
	end for
	return result
end function

//--------------------------------------------------------------------------------
// CLIPBOARD HELPER FUNCTIONS
selection = null

drawSelection = function
	if selection == null then
		drawGrid
	else
		if time % 1 > 0.9 then gfx.color = color.black else gfx.color = "#FF00FF"
		left = xAtPaintPixel({"x":selection.left}) - floor(ps/2)
		botm = yAtPaintPixel({"y":selection.bottom}) - floor(ps/2)
		gfx.drawRect left, botm, selection.width * ps + 1, selection.height * ps + 1
	end if
end function

deselect = function
	if selection == null then return
	globals.selection = null
	drawGrid
end function

copy = function
	if selection == null then return
	globals.clip = fatbits.getImage(selection.left, selection.bottom, selection.width, selection.height)
	drawGrid
end function

deleteSelection = function
	if mode == kModePasting then
		fatbits.fillRect 0, 0, picW+1, picH+1, color.clear
		fatbits.drawImage picAtStart, 0, 0
		setMode kModeSelect
	else if selection != null then
		selection.fill fatbits, backColor
		deselect
	end if
end function

paste = function
	if not globals.hasIndex("clip") or clip == null then
		print char(7) // Beep!
		return
	end if
	globals.picAtStart = fatbits.getImage(0, 0, picW, picH)
	globals.mode = kModePasting
end function

updatePaste = function(pp)
	fatbits.fillRect 0, 0, picW+1, picH+1, color.clear
	fatbits.drawImage picAtStart, 0, 0
	fatbits.drawImage clip, pp.x - floor(clip.width/2), pp.y - floor(clip.height/2)
end function

//--------------------------------------------------------------------------------
// TOOL FUNCTIONS

toolFuncs = {}

toolFuncs[kModeMove] = function(pp, justDown)
	if justDown then
		globals.startPaintPos = pp
		globals.startPaintImg = fatbits.getImage(0, 0, picW, picH)
		return
	end if
	// Shift the data within the picture.
	dx = pp.x - startPaintPos.x
	dy = pp.y - startPaintPos.y
	fatbits.fillRect 0, 0, picW+1, picH+1, color.clear
	fatbits.drawImage startPaintImg.getImage(-dx * (dx<0), -dy * (dy<0), 
		picW-abs(dx), picH-abs(dy)), dx * (dx>0), dy * (dy>0)
end function

toolFuncs[kModeDraw] = function(pp, justDown)
	if justDown then
		// On the initial mouse-down, pick erase mode if we're clicking
		// a pixel that's already the fore color; otherwise, draw mode.
		pcolor = fatbits.pixel(pp.x, pp.y)
		globals.drawErases = (pcolor == foreColor)
	end if
	if drawErases then c = backColor else c = foreColor
	for pos in symmetries(pp)
		setPaintPixel pos, c
	end for
end function

toolFuncs[kModePaint] = function(pp, justDown)
	for pos in symmetries(pp)
		if brushSize == 1 then
			fatbits.setPixel pos.x, pos.y, foreColor
		else
			x = ceil(pos.x - brushSize/2)
			y = ceil(pos.y - brushSize/2)
			fatbits.fillEllipse x, y, brushSize, brushSize, foreColor
		end if
	end for
end function

toolFuncs[kModeErase] = function(pp, justDown)
	for pos in symmetries(pp)
		if brushSize == 1 then
			fatbits.setPixel pos.x, pos.y, backColor
		else
			fatbits.fillEllipse pos.x - brushSize/2, pos.y - brushSize/2, brushSize, brushSize, backColor
		end if
	end for
end function

toolFuncs[kModeBlur] = function(pp, justDown)
	if not justDown and pp == lastPos then return
	globals.lastPos = pp
	blurList = []
	factor = 1 / 51
	for pos in symmetries(pp)
		for p in affectedPixels(pp)
			c = color.toList(fatbits.pixel(p.x, p.y))  // (extra weight for center pixel)
			c.multiplyBy 42
			for j in range(p.x-1, p.x+1)
				for k in range(p.y-1, p.y+1)
					c.add color.toList(fatbits.pixel(j,k))
				end for
			end for
			c.multiplyBy factor
			blurList.push [p.x, p.y, color.fromList(c)]
		end for
	end for
	for point in blurList
		fatbits.setPixel point[0], point[1], point[2]
	end for
end function

toolFuncs[kModeFill] = function(pp, justDown)
	if not justDown then return
	for pos in symmetries(pp)
		toDo = [pos]
		matchColor = fatbits.pixel(pp.x, pp.y)
		if matchColor == foreColor then return
		while toDo
			pos = toDo.pop
			if pos.x < 0 or pos.x >= picW or pos.y < 0 or pos.y >= picH then continue
			if fatbits.pixel(pos.x, pos.y) != matchColor then continue		
			setPaintPixel pos, foreColor
			toDo.push {"x":pos.x-1, "y":pos.y}
			toDo.push {"x":pos.x+1, "y":pos.y}
			toDo.push {"x":pos.x, "y":pos.y-1}
			toDo.push {"x":pos.x, "y":pos.y+1}		
		end while
	end for
end function

toolFuncs[kModeReplace] = function(pp, justDown)
	if not justDown then return
	fromColor = fatbits.pixel(pp.x, pp.y)
	for y in range(0, picH)
		for x in range(0, picW)
			if fatbits.pixel(x, y) == fromColor then fatbits.setPixel x,y, foreColor
		end for
	end for
end function

toolFuncs[kModeEyedrop] = function(pp, justDown)
	c = fatbits.pixel(pp.x, pp.y)
	curSwatch.setColor c
	colorWheel.updateFromColor c
	PalButton.selectMatchingColor c
end function

toolFuncs[kModeLine] = function(pp, justDown)
	if justDown then
		globals.picAtStart = fatbits.getImage(0, 0, picW, picH)
		globals.posAtStart = pp
		return
	end if
	fatbits.fillRect 0, 0, picW+1, picH+1, color.clear
	fatbits.drawImage picAtStart
	startPos = symmetries(posAtStart)
	curPos = symmetries(pp)
	for i in curPos.indexes
		fatbits.line startPos[i].x, startPos[i].y, curPos[i].x, curPos[i].y, foreColor, brushSize
	end for
end function

toolFuncs[kModeDrawRect] = function(pp, justDown)
	if justDown then
		globals.picAtStart = fatbits.getImage(0, 0, picW, picH)
		globals.posAtStart = pp
		return
	end if
	fatbits.fillRect 0, 0, picW+1, picH+1, color.clear
	fatbits.drawImage picAtStart
	startPos = symmetries(posAtStart)
	curPos = symmetries(pp)
	for i in curPos.indexes
		Rect.fromPoints(startPos[i], curPos[i]).frame fatbits, foreColor, brushSize
	end for
end function

toolFuncs[kModeFillRect] = function(pp, justDown)
	if justDown then
		globals.picAtStart = fatbits.getImage(0, 0, picW, picH)
		globals.posAtStart = pp
		return
	end if
	fatbits.fillRect 0, 0, picW+1, picH+1, color.clear
	fatbits.drawImage picAtStart
	startPos = symmetries(posAtStart)
	curPos = symmetries(pp)
	for i in curPos.indexes
		Rect.fromPoints(startPos[i], curPos[i]).fill fatbits, foreColor
	end for
end function

toolFuncs[kModeDrawEllipse] = function(pp, justDown)
	if justDown then
		globals.picAtStart = fatbits.getImage(0, 0, picW, picH)
		globals.posAtStart = pp
		return
	end if
	fatbits.fillRect 0, 0, picW+1, picH+1, color.clear
	fatbits.drawImage picAtStart
	startPos = symmetries(posAtStart)
	curPos = symmetries(pp)
	for i in curPos.indexes
		Rect.fromPoints(startPos[i], curPos[i]).frameEllipse fatbits, foreColor, brushSize
	end for
end function

toolFuncs[kModeFillEllipse] = function(pp, justDown)
	if justDown then
		globals.picAtStart = fatbits.getImage(0, 0, picW, picH)
		globals.posAtStart = pp
		return
	end if
	fatbits.fillRect 0, 0, picW+1, picH+1, color.clear
	fatbits.drawImage picAtStart
	startPos = symmetries(posAtStart)
	curPos = symmetries(pp)
	for i in curPos.indexes
		Rect.fromPoints(startPos[i], curPos[i]).fillEllipse fatbits, foreColor
	end for
end function

toolFuncs[kModeLighten] = function(pp, justDown)
	if justDown then
		globals.picAtStart = fatbits.getImage(0, 0, picW, picH)
		scratch.fillRect 0, 0, picW, picH, color.clear
		return
	end if
	for pos in symmetries(pp)
		scratch.fillEllipse pos.x - brushSize/2, pos.y - brushSize/2, brushSize, brushSize, "#FFFFFF22"
	end for
	fatbits.fillRect 0, 0, picW+1, picH+1, color.clear
	fatbits.drawImage picAtStart
	fatbits.drawImage scratch.getImage(0, 0, picW, picH)
end function

toolFuncs[kModeDarken] = function(pp, justDown)
	if justDown then
		globals.picAtStart = fatbits.getImage(0, 0, picW, picH)
		scratch.fillRect 0, 0, picW, picH, color.clear
		return
	end if
	for pos in symmetries(pp)
		scratch.fillEllipse pos.x - brushSize/2, pos.y - brushSize/2, brushSize, brushSize, "#00000022"
	end for
	fatbits.fillRect 0, 0, picW+1, picH+1, color.clear
	fatbits.drawImage picAtStart
	fatbits.drawImage scratch.getImage(0, 0, picW, picH)
end function

toolFuncs[kModeSelect] = function(pp, justDown)
	if justDown then globals.selectionAnchor = pp
	if pp == selectionAnchor then
		deselect
	else
		newSel = Rect.fromPoints(selectionAnchor, pp)
		if newSel.width == 0 then newSel.width = 1
		if newSel.height == 0 then newSel.height = 1
		if newSel == selection then return
		globals.selection = newSel
		drawGrid
		drawSelection
	end if
end function

toolFuncs[kModePasting] = function(pp, justDown)
	if justDown then
		globals.mode = kModeSelect
		globals.selectionAnchor = pp
	end if
end function

//--------------------------------------------------------------------------------
// COLOR WHEEL
colorWheel = new Sprite
colorWheel.image = file.loadImage("/sys/pics/ColorWheel.png")
colorWheel.scale = 0.55
colorWheel.x = 75
colorWheel.y = 109
colorWheel.addBounds
spriteDisp.sprites.push colorWheel

colorWheel.knob = new Sprite
colorWheel.knob.image = file.loadImage(resourceDir + "diamondKnob.png")
colorWheel.knob.x = colorWheel.x
colorWheel.knob.y = colorWheel.y
spriteDisp.sprites.push colorWheel.knob

colorWheel.checkEvents = function
	if mouse.button and not mouseWasDown and self.contains(mouse) then
		while mouse.button
			rx = mouse.x - self.x  // get mouse position relative to circle center
			ry = mouse.y - self.y
			dist = sqrt(rx^2 + ry^2)
			maxr = self.image.width * self.scale / 2
			if dist > maxr then  // limit the knob to the circular area with radius maxr
				rx = rx * maxr / dist
				ry = ry * maxr / dist
			end if
			self.knob.x = self.x + rx
			self.knob.y = self.y + ry
			self.updateColor
		end while
	end if
end function

colorWheel.updateColor = function
	rx = self.knob.x - self.x
	ry = self.knob.y - self.y
	c = color.toList(self.image.pixel(rx / self.scale + self.image.width/2, 
		ry / self.scale + self.image.height/2 ))
	lv = lightnessSlider.value
	newColor = color.fromList([c[0] * lv, c[1] * lv, c[2] * lv, alphaSlider.value * 255])
	curSwatch.setColor newColor
	PalButton.selectMatchingColor newColor
end function

colorWheel.updateFromColor = function(c)
	if c == null then
		if curSwatch == foregroundSwatch then c = foreColor else c = backColor
	end if
	hsv = color.toListHSV(c)
	r = self.image.width * self.scale / 2 * hsv[1] / 255
	self.knob.x = self.x + r * cos(hsv[0]/255 * 2*pi)
	self.knob.y = self.y + r * sin(hsv[0]/255 * 2*pi)
	lightnessSlider.set hsv[2] / 255
	alphaSlider.set hsv[3] / 255
end function

//--------------------------------------------------------------------------------
// "NEW TAB" Text-Based UI
setupUI = {}
kStart = "START"		// waiting for user to choose New or Load
kNewFile = "NEWFILE"	// user specifying new file to create
kLoadFile = "LOADFILE"	// user specifying file to load
kPickArea = "PICKAREA"	// user specifying sub-region to edit
kDone = "DONE"
setupUI.state = kStart
setupUI.buttons = []

setupUI.drawButtons = function
	text.color = "#8888FF"
	for b in self.buttons; b.draw; end for
	text.color = "#333333"
end function

setupUI.doEvents = function
	if self.buttons and mouse.button and mouse.y < 640-26 then
		for btn in self.buttons
			if not btn.contains(mouse) then continue
			if btn.trackHit then
				self.state = btn.nextState
				self.draw
			end if
		end for
	end if
end function

setupUI.inputAt = function(column, row, prompt)
	text.color = "#333333"
	textUtil.printAt column, row, prompt
	textUtil.clearToEOL
	text.color = "#000088";	result = input; text.color = "#333333"
	return result
end function

setupUI.draw = function
	text.color = "#333333"
	text.backColor = "#929292"
	text.delimiter = ""
	text.column = 0
	text.clear
	text.setCellBackColor range(0,67),25, color.clear
	gfx.fillRect 0, 0, 960, 640-26, text.backColor
	spriteDisp.scrollX = 9999
	self.buttons = []
	if self.state == kStart then
		textUtil.printCenteredAt 34, 21, "Create or Load Image"
		newBtn = new textUtil.DialogButton
		newBtn.caption = "NEW IMAGE"
		newBtn.x = 34-4-newBtn.width; newBtn.y = 18
		newBtn.nextState = kNewFile
		self.buttons.push newBtn
		loadBtn = new textUtil.DialogButton
		loadBtn.caption = "LOAD IMAGE"
		loadBtn.x = 34+4; loadBtn.y = 18
		loadBtn.nextState = kLoadFile
		self.buttons.push loadBtn
	else if self.state == kNewFile then
		textUtil.printCenteredAt 34, 21, "Create New Image"
		textUtil.printAt 10, 18, "Current Directory: " + pwd
		self.path = self.inputAt(10, 16, "New file path: ")
		self.width = 0
		while not self.width
			self.width = self.inputAt(10, 14, "New image width:  ").val
		end while
		self.height = 0
		while not self.height
			self.height = self.inputAt(10, 13, "New image height: ").val
		end while
		self.img = Image.create(self.width, self.height, color.clear)
		if self.path[-4:] != ".png" then self.path = self.path + ".png"
		err = file.saveImage(self.path, self.img)
		if err then
			textUtil.Dialog.make("Unable to Save File", err).show
			self.state = kStart
			self.draw
		else
			addTabForImage self.img, self.path
			self.state = kDone
		end if
	else if self.state == kLoadFile then
		textUtil.printCenteredAt 34, 21, "Load Image"
		textUtil.printAt 10, 18, "Current Directory: " + pwd
		self.path = self.inputAt(10, 16, "Image file path: ")
		if self.path[-4:] != ".png" then self.path = self.path + ".png"
		self.img = file.loadImage(self.path)
		if self.img == null then
			textUtil.Dialog.make("Unable to Open File", "Invalid path:" + char(13) + self.path).show
			self.state = kStart
			self.draw
		else
			addTabForImage self.img, self.path
			self.state = kDone
		end if
	end if
	self.drawButtons
	text.delimiter = char(13)
end function

setupUI.clear = function
	text.backColor = color.clear
	text.clear
	gfx.fillRect 0, 0, 960, 640-26, color.clear
	spriteDisp.scrollX = 0
end function

//--------------------------------------------------------------------------------
// TABS & FILE MANAGEMENT
closeBtnClean = file.loadImage(resourceDir + "closeBtnWeak.png")
closeBtnDirty = file.loadImage(resourceDir + "closeBtnStrong.png")
CloseButton = new Sprite
CloseButton.image = closeBtnClean
CloseButton.y = 640 - 12
CloseButton.x = 20
CloseButton.update = function(dirty, curTab, pressed)
	if self.localBounds == null then self.addBounds; yield
	if dirty then
		self.image = closeBtnDirty
		if curTab then tint = "FF" else tint = "AA"
	else
		self.image = closeBtnClean
		if curTab then tint = "AA" else tint = "66"
	end if
	if pressed then
		if self.contains(mouse) then tint = "88" else tint = "EE"
	else if self.contains(mouse) then
		tint = "EE"
	end if
	self.tint = "#" + tint + tint + tint
end function

drawTab = function(x, width, title="", isSelected=false)
	h = 25  // tab height
	y = 640 - h - 1  // tab bottom
	poly = [[x,y], [x+12,y+h], [x+width-24,y+h], [x+width-12,y+h], [x+width,y]]
	// fill
	if isSelected then c = "#666666" else c = "#444444"
	gfx.fillPoly poly, c
	// highlight at the top
	if isSelected then c = "#888888" else c = "#666666"
	gfx.line x+12, y+h-1, x+width-12, y+h-1, c
	// frame
	gfx.drawPoly poly, color.black, 2
	// title
	if title == "+" then
		gfx.print "+", x + width/2 - 7, y + h/2 - 10, "#AAAAAA"
	else
		if isSelected then c = "#AAAAAA" else c = "#888888"
		titleWidth = title.len * 9
		gfx.print title, x + width/2 - titleWidth/2 + 8, y + h/2 - 5, c, "small"
	end if
end function
OpenFile = {}
OpenFile.path = ""
OpenFile.tabX = null
OpenFile.targetX = null
OpenFile.tabWidth = 0
OpenFile.tabTitle = ""
OpenFile.srcRect = null
OpenFile.closeBtn = null
OpenFile.saveFromEditArea = function
	self.image = fatbits.getImage(0, 0, self.image.width, self.image.height)
end function
OpenFile.loadToEditArea = function
	globals.picW = self.image.width; globals.picH = self.image.height
	fatbits.clear color.clear, picW, picH
	fatbits.scale = ps
	fatbits.drawImage self.image
	updatePaintScroll
end function
OpenFile.saveToDisk = function
	if self == selectedTab then self.saveFromEditArea
	err = file.saveImage(self.path, self.image)
	if not err then
		dlog = textUtil.Dialog.make("Saved """ + file.name(self.path) + """",
		   self.path + char(13) + self.image.width + " x " + self.image.height + " pixels")
		dlog.okBtn.visible = false
		dlog.show 2
	else
		dlog = textUtil.Dialog.make("Unable to Save File", err)
		dlog.show
	end if
end function
OpenFile.close = function
	tabIdx = tabs.indexOf(self)
	// Choose the tab before it, or the first one if none left
	if tabIdx == 0 then newIdx = 0 else newIdx = tabIdx - 1
	// Remove the close button of the removed tab
	sprIdx = spriteDisp.sprites.indexOf(self.closeBtn)
	spriteDisp.sprites.remove sprIdx
	// Remove the tab object
	tabs.remove tabIdx
	// Point to new tab
	newTab = tabs[newIdx]
	globals.selectedTab = newTab
	// Repaint UI and switch
	layoutTabs; drawTabs
	switchToTab newTab
end function
OpenFile.confirmAndClose = function
	dlog = textUtil.Dialog.make("Save changes to " + self.tabTitle + "?",
	  "If you do not save, your changes will be lost.")
	dlog.okBtn.caption = "Save"
	dlog.cancelBtn.visible = true
	dlog.altBtn.caption = "Don't Save"
	dlog.altBtn.visible = true
	choice = dlog.show
	if choice == dlog.cancelBtn then return
	if choice == dlog.okBtn then self.saveToDisk
	self.close
end function

tabs = []
specialNewTabTab = {"tabWidth":40, "tabTitle":"+", "tabX":null, "closeBtn":null}
specialNewTabTab.saveFromEditArea = null
specialNewTabTab.loadToEditArea = null
tabs.push specialNewTabTab
layoutTabs = function
	x = 0
	for t in tabs
		t.targetX = x
		t.tabX = t.targetX
		if not t.tabWidth then t.tabWidth = t.tabTitle.len * 9 + 50
		if t.tabTitle != "+" then
			if t.closeBtn == null then
				t.closeBtn = new CloseButton
				spriteDisp.sprites.push t.closeBtn
			end if
			t.closeBtn.update
			t.closeBtn.x = x + 20	
		end if		
		x = x + t.tabWidth - 12
	end for
end function
selectedTab = tabs[0]

drawTabs = function
	h = 26
	gfx.fillRect 0, 640-h, 960, h, "#929292"
	gfx.line 0, 640-h, 960, 640-h, color.black, 2
	for t in tabs
		if t == selectedTab then break
		drawTab t.tabX, t.tabWidth, t.tabTitle, false
	end for
	for i in range(tabs.len-1)
		t = tabs[i]
		drawTab t.tabX, t.tabWidth, t.tabTitle, t == selectedTab
		if t == selectedTab then break
	end for
end function

updateTabs = function
	for t in tabs
		if t.closeBtn == null then continue
		t.closeBtn.update false, t == selectedTab, false
	end for
end function

handleTabClick = function
	// first handle clicks on a close button
	for t in tabs
		if t.closeBtn == null or not t.closeBtn.contains(mouse) then continue
		while mouse.button
			t.closeBtn.update false, t == selectedTab, true
		end while
		if t.closeBtn.contains(mouse) then
			if t == selectedTab then t.saveFromEditArea
			t.confirmAndClose
		end if
		return
	end for
	// then, handle click on a tab
	for t in tabs
		if mouse.x > t.tabX + t.tabWidth then continue
		selectedTab.saveFromEditArea
		globals.selectedTab = t
		drawTabs
		while mouse.button; end while
		switchToTab t
		return
	end for
end function

switchToTab = function(tab)
	if tab == specialNewTabTab then
		setupUI.state = kStart
		setupUI.draw
	else
		setupUI.clear
		previewArea.prepare tab.image
		prepareScreen
		tab.loadToEditArea
	end if
end function

addTabForImage = function(img, path)
	tab = new OpenFile
	tab.tabTitle = file.name(path) - ".png"
	tab.path = path
	tab.image = img
	tabs.insert -2, tab
	globals.selectedTab = tab
	layoutTabs; drawTabs
	switchToTab tab
end function

//--------------------------------------------------------------------------------
// PREVIEW/SCROLL AREA

// Here's how this works:
// 1. Preview area is the full size of the source image, unless that is bigger
// than 194x220, in which case it caps at that, and shrinks the image down to fit.
// 2. If the image is bigger than 64x64, then we draw a representation (as a sprite?
// of the current 64x64 editing area, scaled in the same way as the image.
// 3. Clicking in the preview moves this editing area around, scrolling fatbits.

previewArea = new Rect
previewArea.scrollbox = null

previewArea.prepare = function(img)
	// limit preview area size to at most 194 x 220:
	self.scale = mathUtil.clamp([194/img.width, 220/img.height].min)
	self.width = img.width * self.scale
	self.left = 851 - self.width/2
	self.height = img.height * self.scale
	self.bottom = 162 - self.height/2
	// update scrollbox (indicating currently viewable part of the image)
	spriteDisp.sprites.removeVal self.scrollbox
	self.scrollbox = new Sprite
	if img.width > 64 or img.height > 64 then
		sz = 64 * self.scale
		scratch.fillRect 0, 0, sz + 2, sz + 2, color.clear
		scratch.drawRect 0, 0, sz + 2, sz + 2, color.yellow
		scratch.drawRect 1, 1, sz, sz, color.black
		self.scrollbox.image = scratch.getImage(0, 0, sz+2, sz+2)
		spriteDisp.sprites.push self.scrollbox
		self.scrollbox.x = self.left + sz/2
		self.scrollbox.y = self.bottom + sz/2
	end if
	if img.width <= 64 then self.scrollbox.x = self.midX
	if img.height <= 64 then self.scrollbox.y = self.midY
end function

previewArea.draw = function
	if not self.hasIndex("scale") then; print "WTF?"; exit; end if
	previewArea.fill gfx, backdrop.color
	previewArea.frame gfx, color.black
	img = selectedTab.image
	gfx.drawImage img, previewArea.midX - img.width*self.scale/2, 
		previewArea.midY - img.height*self.scale/2,
		img.width * self.scale, img.height * self.scale//, 0, 0, img.width, img.height
end function

previewArea.handleClick = function
	hsz = 32 * self.scale  // (half the size of our scrollbox)
	img = selectedTab.image
	while mouse.button
		x = mathUtil.clamp(mouse.x - previewArea.left, hsz, self.width-hsz)
		y = mathUtil.clamp(mouse.y - previewArea.bottom, hsz, self.height-hsz)
		if img.width > 64 then self.scrollbox.x = self.left + x
		if img.height > 64 then self.scrollbox.y = self.bottom + y
		updatePaintScroll
	end while
end function

//--------------------------------------------------------------------------------
// COLOR SWATCHES (foreground/background)

Swatch = {}
Swatch.instances = []
Swatch.init = function(x, y, labelYOffset, selected=false)
	self.bkgnd = new Sprite
	self.bkgnd.image = file.loadImage(resourceDir + "colorSwatchBkgnd.png")
	self.bkgnd.x = x; self.bkgnd.y = y
	spriteDisp.sprites.push self.bkgnd
	
	self.swatch = new Sprite
	self.swatch.image = file.loadImage(resourceDir + "colorSwatch.png")
	self.swatch.x = x; self.swatch.y = y
	spriteDisp.sprites.push self.swatch
	
	self.frame = new Sprite
	self.frame.image = file.loadImage(resourceDir + "colorSwatchFrame.png")
	self.frame.x = x; self.frame.y = y
	spriteDisp.sprites.push self.frame
	
	self.frame.addBounds
	
	self.labelX = 0
	self.labelY = labelYOffset
	
	self.select selected
	if Swatch.instances.indexOf(self) == null then Swatch.instances.push self
end function

Swatch.make = function(x, y, c=color.white, selected=false)
	noob = new Swatch
	noob.init x, y, c, selected
	return noob
end function

Swatch.contains = function(pos)
	return self.frame.contains(pos)
end function

Swatch.checkEvents = function
	if mouse.button and not mouseWasDown and self.contains(mouse) then
		// track the mouse until it goes up!
		while mouse.button
			self.select (curSwatch == self or self.contains(mouse))
			yield
		end while
		if self.contains(mouse) then selectSwatch self
	end if
end function

Swatch.color = function
	return self.swatch.tint
end function

Swatch.setColor = function(c)
	self.swatch.tint = c
	if self == foregroundSwatch then globals.foreColor = c
	if self == backgroundSwatch then globals.backColor = c
	x = self.bkgnd.x + self.labelX - 40
	y = self.bkgnd.y + self.labelY
	gfx.fillRect x, y, 84, 12, color.clear
	gfx.print "#", x, y, color.black, "small"
	gfx.print " " + c[1:3], x, y, "#CC0000", "small"
	gfx.print " "*3 + c[3:5], x, y, "#00BB00", "small"
	gfx.print " "*5 + c[5:7], x, y, "#0000EE", "small"
	gfx.print " "*7 + c[7:], x, y, color.black, "small"	
end function

Swatch.select = function(selectIt)
	if selectIt then self.frame.tint = color.white else self.frame.tint = color.clear
end function

backgroundSwatch = Swatch.make(104, 200, -26, false)
foregroundSwatch = Swatch.make(48, 212, 14, true)
foregroundSwatch.setColor foreColor
backgroundSwatch.setColor backColor
curSwatch = foregroundSwatch

selectSwatch = function(swatch)
	globals.curSwatch = swatch
	for s in Swatch.instances
		s.select curSwatch == s
	end for
	// ToDo: update color wheel and sliders to reflect selected swatch color
end function

//--------------------------------------------------------------------------------
// COLOR PALETTE
palSelectionRing = new Sprite
palSelectionRing.image = Image.create(18, 11, color.white)
spriteDisp.sprites.push palSelectionRing

PalButton = new Sprite
PalButton.image = Image.create(16, 9, color.white)
PalButton.instances = []
PalButton.make = function(c)
	noob = new PalButton
	if c.len < 9 then c = c + "FF"
	noob.tint = c
	noob.index = PalButton.instances.len
	PalButton.instances.push noob
	spriteDisp.sprites.push noob
	noob.x = 16 + 17 * (noob.index % 8)
	noob.y = 585.5 - 10 * floor(noob.index / 8)
	noob.addBounds
	if noob.index == 0 then
		palSelectionRing.x = noob.x
		palSelectionRing.y = noob.y
	end if
end function

PalButton.checkEventsForAll = function
	if mouse.x > 260 or mouse.y < 255 or not mouse.button then return
	for btn in PalButton.instances
		if not btn.contains(mouse) then continue
		palSelectionRing.x = btn.x
		palSelectionRing.y = btn.y
		curSwatch.setColor btn.tint
		colorWheel.updateFromColor btn.tint
		break
	end for
end function

PalButton.selectMatchingColor = function(c)
	if c.len < 9 then c = c + "FF"
	for btn in PalButton.instances
		if btn.tint == c then
			palSelectionRing.x = btn.x
			palSelectionRing.y = btn.y
			return
		end if
	end for
	palSelectionRing.x = -999
end function

makeDefaultPalette = function
	for r in range(0,5)
		for g in range(0,6)
			for b in range(0,5)
				PalButton.make color.rgb(round(255*r/5), round(255*g/6), round(255*b/5))
			end for
		end for
	end for
	for i in range(1,4)
		rgb = round(42*i)
		PalButton.make color.rgb(rgb, rgb, rgb)
	end for
end function
makeDefaultPalette

//--------------------------------------------------------------------------------
// MAIN PROGRAM

startPaintPos = null
startPaintImg = null
lightnessSlider.set 1
alphaSlider.set 1
colorWheel.updateColor
brushSize = 6
setMode kModeDraw
layoutTabs
drawTabs

setupUI.draw

handleClick = function(justDown)
	if mouse.y > 640-26 then
		handleTabClick
		return
	end if
	if previewArea.contains(mouse) then return previewArea.handleClick
	if not paintArea.contains(mouse) then return
	pp = paintPixelAtXY(mouse)
	tf = toolFuncs[mode]
	tf pp, justDown
	selectedTab.saveFromEditArea
	previewArea.draw
end function

showHelp = function
	lines = []
	lines.push "Alt - Color Picker      "
	lines.push "X - Cut                 "
	lines.push "C - Copy                "
	lines.push "V - Paste               "
	lines.push "Backspace/Delete - Clear"
	lines.push "S - Save                "
	lines.push "Q - Quit                "
	d = textUtil.Dialog.make("Keyboard Shortcuts", lines.join(char(13)))
	d.show
end function

handleKeys = function
	if not key.available then return
	k = key.get.lower
	if k == "c" then copy
	if k == "v" then paste
	if k.code == 8 or k.code == 127 then deleteSelection
	if k == "x" then
		copy
		deleteSelection
	end if
	if k == "s" and selectedTab isa OpenFile then selectedTab.saveToDisk
	if k == "?" or k == "/" then showHelp
	if k == "q" then
		d = textUtil.Dialog.make("Quit fatbits?", "Are you sure you want to quit?")
		d.okBtn.caption = "Quit"
		d.cancelBtn.visible = true
		if d.show.caption == "Quit" then
			clear
			exit
		end if
	end if
end function

mouseWasDown = mouse.button
while true
	yield
	updateTabs
	if selectedTab == specialNewTabTab then
		setupUI.doEvents
		if mouse.button and mouse.y > 640-26 then handleTabClick
		continue
	end if
	
	pp = paintPixelAtXY(mouse)
	gfx.fillRect 860, 0, 100, 20, color.clear
	brushSprite.x = -9999
	if pp.x >= 0 and pp.y >= 0 and pp.x < picW and pp.y < picH then
		gfx.print pp.x + "," + pp.y, 860, 3, color.silver, "small"
		if modesWithSize.contains(mode) then
			brushSprite.x = xAtPaintPixel(pp) - (not brushSize%2)*ps/2
			brushSprite.y = yAtPaintPixel(pp) - (not brushSize%2)*ps/2
		end if
	end if
	if mode == kModePasting then updatePaste pp
	
	// check UI elements
	for btn in Button.instances; btn.checkEvents; end for
	for s in Swatch.instances; s.checkEvents; end for
	for s in Slider.instances; s.checkEvents; end for
	PalButton.checkEventsForAll
	colorWheel.checkEvents
	
	// then, update usage of tools (e.g. painting)
	mouseIsDown = mouse.button
	if mouseIsDown then handleClick not mouseWasDown
	mouseWasDown = mouseIsDown
	if key.available then handleKeys
	if selection != null then drawSelection
end while

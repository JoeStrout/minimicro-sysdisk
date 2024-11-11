// A visual editor for creating synthesized sounds.
//
// Click in the numeric fields, and type to change the value.
// In the curve editors, drag nodes up and down.  Click the
// '+' button to add a new node; press Backspace or Delete to
// delete the selected node.
//
// Click Play (or the keyboard at bottom) to play the current
// sound; click Code to see the code, which you can copy into
// your own programs.
//
// Press Esc to exit SoundLab.

import "gui"
import "textUtil"

textColor = "#CCCCCC"
pianoSound = file.loadSound("/sys/sounds/pianoLongC4.wav")
desktopPic = file.loadImage("/sys/data/desktop/desktopGfx.png")
tempG = new PixelDisplay

// Class to represent any rectangular area on the screen
RectControl = {}
RectControl.left = 0
RectControl.bottom = 0
RectControl.width = 16
RectControl.height = 80
RectControl.margin = 0		// extra margin for hit-testing
RectControl.contains = function(xy)
	m = self.margin
	return xy.x > self.left-m and xy.x < self.left + self.width+m and
	  xy.y > self.bottom-m and xy.y < self.bottom + self.height+m
end function
RectControl.right = function; return self.left + self.width; end function
RectControl.top = function; return self.bottom + self.height; end function

PushButton = new RectControl
PushButton.Instances = []
PushButton.image = desktopPic.getImage(248,106, 20,20)
PushButton.icon = null
PushButton.selected = false
PushButton.action = function(btn); end function
PushButton.enabled = true

PushButton.Make = function(left, bottom, image=null, icon=null)
	noob = new self
	noob.left = left
	noob.bottom = bottom
	noob.icon = icon
	if image then noob.image = image
	noob.width = noob.image.width
	noob.height = noob.image.height
	PushButton.Instances.push noob
	return noob
end function

PushButton.draw = function(pressed=false)
	if pressed then
		btnColor = "#888888"
		iconColor = "#AAAAFF"
	else if self.selected then
		btnColor = "#AAAAAA"
		iconColor = "#CCCCFF"
	else
		btnColor = "#CCCCCC"
		iconColor = "#4444CC"
	end if
	if not self.enabled then
		btnColor = color.lerp(btnColor, color.clear)
		iconColor = color.lerp(iconColor, color.clear)
		gfx.fillRect self.left, self.bottom, self.width, self.height, color.clear
	end if
	gfx.drawImage self.image, self.left, self.bottom, -1, -1, 
	   0, 0, -1, -1, btnColor
	if self.icon != null then
		gfx.drawImage self.icon, self.left, self.bottom, -1, -1,
		   0, 0, -1, -1, iconColor
	end if
end function

PushButton.handleMouse = function
	if not self.enabled or not self.contains(mouse) then return false
	self.draw true
	wasIn = true
	while mouse.button
		yield
		isIn = self.contains(mouse)
		if isIn != wasIn then
			self.draw isIn
			wasIn = isIn
		end if
	end while
	if wasIn then
		self.draw false
		self.action self
	end if
	return true
end function

PushButton.HandleMouseAll = function
	for btn in PushButton.Instances
		if btn.handleMouse then return true
	end for
	return false
end function

// Class to represent a key on one of the musical keyboards.
PianoKey = new RectControl
PianoKey.note = 0
PianoKey.left = 0
PianoKey.bottom = 0
PianoKey.width = 16
PianoKey.height = 80
PianoKey.Instances = []
PianoKey.action = function(keyHit); end function

PianoKey.Make = function(left, top, note, action)
	noob = new self
	noob.left = left
	noob.bottom = top - self.height
	noob.note = note
	if @action != null then noob.action = @action
	PianoKey.Instances.push noob
	noob.draw
	return noob
end function

PianoKey.draw = function(pressed=false)
	if pressed then c = "#AAAAFF" else c = "#EAEAEA"
	gfx2.fillRect self.left, self.bottom, self.width, self.height, c
	gfx2.drawRect self.left, self.bottom, self.width, self.height, "#444444"
end function

PianoKey.press = function
	self.draw true
	self.action self
end function

PianoKey.release = function
	Sound.stopAll
	self.draw false
end function

BlackKey = new PianoKey
BlackKey.width = 10
BlackKey.height = 50
BlackKey.draw = function(pressed=false)
	if pressed then c = "#6666EE" else c = "#222222"
	left = self.left;     bottom = self.bottom
	width = self.width;	  height = self.height
	right = left + width; top = bottom + height
	gfx.fillRect left, bottom, width, height, c
	gfx.line left+2, bottom+2, left+2, top-2, "#555555"
	gfx.line left+2, bottom+2, left+8, top-48, "#555555"	
end function

keyUnderMouse = function
	// first check black keys, then white ones
	for key in PianoKey.Instances
		if key isa BlackKey and key.contains(mouse) then return key
	end for
	for key in PianoKey.Instances
		if not key isa BlackKey and key.contains(mouse) then return key
	end for
	return false
end function

buildKeyboard = function(top, keyAction=null, sound=null)
	x = 24
	note = 12
	while x < 936
		PianoKey.Make x, top, note, @keyAction
		noteInOctave = note % 12		
		if noteInOctave == 2 or noteInOctave == 7 then
			BlackKey.Make x - 7, top, note-1, @keyAction
		else if noteInOctave == 9 then
			BlackKey.Make x - 5, top, note-1, @keyAction
		else if noteInOctave == 4 or noteInOctave == 11 then
			BlackKey.Make x - 3, top, note-1, @keyAction
		end if
		note += 1 + (noteInOctave != 4 and noteInOctave != 11)
		x += 16
	end while
end function

CurveEditor = new RectControl
CurveEditor.left = 24
CurveEditor.width = 440
CurveEditor.height = 88
CurveEditor.margin = 5
CurveEditor.waveMode = false  // (if true, waveform rather than envelope editor)
CurveEditor.editable = true
CurveEditor.nodeValues = null // (list of values)
CurveEditor.selIdx = null
CurveEditor.SelEd = null
CurveEditor.Instances = []

CurveEditor.fillBelow = function; return not self.waveMode; end function

tempG.clear color.clear, 20, 20
tempG.print "+", 3, -1, color.white
CurveEditor.PlusIcon = tempG.getImage

CurveEditor.Make = function(left, top, waveMode=false)
	noob = new self
	noob.left = left
	noob.bottom = top - noob.height
	noob.init waveMode
	CurveEditor.Instances.push noob
	return noob
end function

CurveEditor.init = function(waveMode=false)
	self.waveMode = waveMode
	if waveMode then self.editable = false
	if not self.nodeValues then self.nodeValues = [1, 0.8, 0.8, 0.8, 0]
	bottom = self.bottom; left = self.left
	width = self.width;   height = self.height
	top = bottom + self.height
	right = left + width
	gfx2.fillRect left, bottom, width, height, "#444444"
	gfx2.line left+1, bottom+1, right-2, bottom+1, "#777777", 2
	gfx2.line right-2, bottom+1, right-2, top-1, "#777777", 2
	gfx2.line left+2, bottom+1, left+2, top-1, "#111111", 2
	gfx2.line left+2, top-3, right-1, top-3, "#111111", 2
	gfx2.drawRect left, bottom, width, height, "#AAAAAA"
	
	self.addButton = PushButton.Make(right-20, bottom-20,
			null, CurveEditor.PlusIcon)
	self.addButton.owner = function
		for ed in CurveEditor.Instances
			if refEquals(ed.addButton, self) then return ed
		end for
	end function
	self.addButton.action = function(btn)
		editor = btn.owner
		editor.nodeValues.push editor.nodeValues[-1]
		editor.selIdx = editor.nodeValues.len - 1
		editor.redraw
	end function
	self.redraw
end function

CurveEditor.setNodes = function(nodes, editable=false)
	self.nodeValues = nodes
	self.editable = editable
	self.redraw
end function

CurveEditor.deselect = function
	if CurveEditor.SelEd == self then CurveEditor.SelEd = null
	if self.selIdx != null then
		self.selIdx = null
		self.redraw
	end if
end function

CurveEditor.redraw = function
	gfx.fillRect self.left-6, self.bottom-6, self.width+12, self.height+12, color.clear
	qty = self.nodeValues.len
	pts = []
	if self.waveMode then
		pts.push [self.left, self.valueToY(self.nodeValues[-1])]
	end if
	for i in self.nodeValues.indexes
		pts.push [
		   self.left + self.width / (qty - 1 + (qty<2)) * i,
		   self.valueToY(self.nodeValues[i]) ]
	end for
	if qty == 1 then pts.push [self.left + self.width, pts[0][1]]
	if self.waveMode then
		pts.push [self.left + self.width, self.valueToY(self.nodeValues[0])]
		midY = self.bottom + self.height/2
		gfx.line self.left, midY, self.left + self.width, midY, "#888888"
	else if self.fillBelow then
		polyPts = pts + [
		   [self.left+self.width-1, self.bottom+1], 
		   [self.left+1, self.bottom+1]]
		gfx.fillPoly polyPts, "#44AAAA"
	end if
	for i in range(0, pts.len-2)
		gfx.line pts[i][0], pts[i][1], pts[i+1][0], pts[i+1][1], "#88FFFF", 2
	end for
	
	self.addButton.enabled = self.editable
	self.addButton.draw
	if not self.editable then return
		
	if self.waveMode then pts = pts[1:-1]
	self.nodePos = [null] * qty
	for i in range(0, qty-1)
		x = pts[i][0]; y = pts[i][1]
		gfx.fillRect x-5, y-5, 11, 11, "#8888FF" //"#FFFF88"
		gfx.drawRect x-5, y-5, 11, 11, "#88BBFF"
		if i == self.selIdx then
			if CurveEditor.SelEd == self then c = "#FFFFFF" else c = "#88FFFF"
			gfx.fillEllipse x-3, y-3, 7, 7, c
		end if
		self.nodePos[i] = {"x":x, "y":y}
	end for
end function

CurveEditor.handleMouse = function
	if not self.editable or not self.contains(mouse) then return false
	for i in self.nodePos.indexes
		if mathUtil.distance(mouse, self.nodePos[i]) < 7 then
			self.selectNode i
			while mouse.button
				self.nodeValues[i] = self.yToValue(mouse.y)
				self.redraw
				yield
			end while
			return true
		end if
	end for
	while mouse.button; yield; end while
	return true
end function

CurveEditor.selectNode = function(index)
	if CurveEditor.SelEd != null and CurveEditor.SelEd != self then
		CurveEditor.SelEd.deselect
	end if
	self.selIdx = index
	CurveEditor.SelEd = self
end function
	
CurveEditor.deleteNode = function
	if self.nodeValues.len < 2 or self.selIdx == null then return
	self.nodeValues.remove self.selIdx
	self.selIdx = mathUtil.clamp(self.selIdx, 0, self.nodeValues.len - 1)
	self.redraw
end function

CurveEditor.valueToY = function(value)
	if self.waveMode then
		halfHeight = self.height/2
		return self.bottom + halfHeight + halfHeight * value
	else
		return self.bottom + self.height * value
	end if
end function

CurveEditor.yToValue = function(y)
	y = mathUtil.clamp(y, self.bottom, self.bottom + self.height)
	if self.waveMode then
		halfHeight = self.height/2
		return (y - (self.bottom + halfHeight)) / halfHeight
	else
		return (y - self.bottom) / self.height
	end if
end function

// FreqCurveEditor: uses a logarithmic instead of linear scale!
FreqCurveEditor = new CurveEditor
FreqCurveEditor.fillBelow = false

FreqCurveEditor.init = function(waveModeIgnored)
	self.nodeValues = [880]
	self.selIdx = 0
	super.init
end function

LOGSCALE = log(1.1)
FreqCurveEditor.valueToY = function(value)
	y = log(value) / LOGSCALE
	return self.bottom + mathUtil.clamp(y, 0, self.height)
end function

FreqCurveEditor.yToValue = function(y)
	return 10 ^ ((y - self.bottom) * LOGSCALE)
end function

FreqCurveEditor.selectNode = function(index)
	super.selectNode index
	freqFld.set str(round(self.nodeValues[index], 1))
end function

FreqCurveEditor.deselect = function
	CurveEditor.SelEd = null
	self.redraw
end function

WaveButton = new PushButton
WaveButton.Images = []
// stretch the default mode buttons (35 pixels wide) to 64 pixels wide:
for i in range(0, 2)
	p = desktopPic.getImage(128 + 35*i, 128, 35, 32)
	tempG.clear color.clear, 64, 32
	tempG.drawImage p
	tempG.drawImage p.getImage(16, 0, 2, 32), 16, 0, 32, 32
	tempG.drawImage p.getImage(p.width-16, 0, 16, 32), 48, 0
	WaveButton.Images.push tempG.getImage
end for
WaveButton.bottom = 0
WaveButton.left = 0
WaveButton.image = WaveButton.Images[1]
WaveButton.width = WaveButton.image.width
WaveButton.height = WaveButton.image.height
WaveButton.Icons = []
for i in range(0, 5)
	x = 320 + 64 * (i % 3)
	y = 320 - 32 * (i > 2)
	WaveButton.Icons.push desktopPic.getImage(x, y, 64, 32)
end for
WaveButton.icon = null
WaveButton.selected = false

WaveButton.Make = function(left, bottom, imageIdx=1, iconIdx=0)
	return super.Make(left, bottom, WaveButton.Images[imageIdx], WaveButton.Icons[iconIdx])
end function

WaveButton.select = function(selectIt=true)
	self.selected = selectIt
	self.draw false
	if selectIt then
		for btn in WaveButton.Instances
			if btn.selected and btn != self then btn.select false
		end for
	end if
end function

makeWaveButtons = function(bottom)
	waves = [Sound.squareWave, Sound.triangleWave, Sound.sawtoothWave,
	         Sound.sineWave, Sound.noiseWave, "Custom"]
	x = 48
	for i in waves.indexes
		btn = WaveButton.Make(x, bottom, (i>0) + (i==waves.len-1), i)
		if waves[i] == "Custom" then
			btn.curve = [0, 1, 0, -1, 0]
			btn.action = function(b)
				self.select
				waveEd.setNodes b.curve, true
			end function
		else
			btn.curve = waves[i]
			btn.action = function(b)
				self.select
				waveEd.setNodes b.curve, false
			end function
		end if
		btn.draw
		x += btn.image.width
		if i == 0 then btn.action btn
	end for
end function

Slider = new RectControl
Slider.thumbImage = desktopPic.getImage(368, 152, 16, 32)
Slider.trackImage = desktopPic.getImage(368, 136, 128, 16)
Slider.width = Slider.trackImage.width
Slider.height = Slider.thumbImage.height
Slider.minVal = 0
Slider.maxVal = 1
Slider.value = 0.5
Slider.action = null

Slider.Make = function(left, bottom, value=0.5, minVal=0, maxVal=1)
	noob = new self
	noob.left = left
	noob.bottom = bottom
	noob.value = value
	noob.minVal = minVal
	noob.maxVal = maxVal
	noob.draw
	return noob
end function

Slider.draw = function
	hw = self.thumbImage.width / 2
	gfx.fillRect self.left - hw, self.bottom, self.width + hw*2, self.height, color.clear
	gfx.drawImage self.trackImage, self.left, 
	  self.bottom + self.height/2 - self.trackImage.height/2
	valSpan = self.maxVal - self.minVal
	if self.minVal < 0 then
		x = self.left + self.width * (0 - self.minVal) / valSpan
		gfx.line x, self.bottom + 4, x, self.bottom + self.height - 8, "#555555"
	end if
	x = self.left + self.width * (self.value - self.minVal) / valSpan
	gfx.drawImage self.thumbImage, x - self.thumbImage.width/2, self.bottom
end function

Slider.handleMouse = function
	if not self.contains(mouse) then return false
	while mouse.button
		yield
		t = mathUtil.clamp((mouse.x - self.left) / self.width)
		newVal = self.minVal + (self.maxVal - self.minVal) * t
		if self.minVal < 0 and abs(newVal) < 0.05 then newVal = 0
		if newVal != self.value then
			self.value = newVal
			self.draw
			self.action
		end if
	end while
	return true
end function
	

addField = function(left, bottom, label, defaultValue="0", units="", width=64)
	fld = gui.InputField.make(left, bottom-2, width, 28, defaultValue)
	fld.draw
	proFont.printRight label + ":", left - 12, bottom + 7, 1, textColor
	proFont.print units, left + width + 12, bottom + 7, 1, textColor
	return fld
end function

setup = function
	text.backColor = color.clear
	clear
	display(7).mode = displayMode.pixel
	display(7).drawImage file.loadImage("/sys/data/soundLab/soundLabBG.png")
	display(6).mode = displayMode.pixel
	outer.gfx2 = display(6)
	gfx2.clear
	gfx.clear color.clear
	PianoKey.Instances = []
	
	globals.durationFld = addField(160, 588, "Duration", "1", "sec")

	y = 600
	proFont.print "Frequency:", 496, y + 7, 1, textColor
	globals.freqEd = FreqCurveEditor.Make(496, y - 6)
	y = 492
	globals.freqFld = addField(328, y, "Frequency at Selected Node", "440", "Hz", 80)
	y -= 16
	buildKeyboard y, function(keyHit)
		freq = noteFreq(keyHit.note)
		freqFld.set str(round(freq, 1))
		pianoSound.play 0.5, 0, freq / noteFreq(60)
		if freqEd.selIdx != null then
			freqEd.nodeValues[freqEd.selIdx] = freq
			freqEd.redraw
		end if
	end function

	y = 340
	proFont.print "Waveform:", 24, y + 7, 1, textColor	
	globals.waveEd = CurveEditor.Make(24, y - 40, true)
	makeWaveButtons y - 30

	proFont.print "Envelope:", 496, y + 7, 1, textColor
	globals.envelopeEd = CurveEditor.Make(496, y - 6)
	y -= 140
	globals.fadeInFld = addField(600, y, "Fade-In", "0.1", "sec")
	globals.fadeOutFld = addField(792, y, "Out", "0.1", "sec")
	
	y = 124
	proFont.print "Volume:", 24, y + 7, 1, textColor
	globals.volSlider = Slider.Make(126, y - 3, 1)
	globals.speedFld = addField(390, y, "Speed", "1")
	proFont.print "Pan: L", 512, y + 7, 1, textColor
	proFont.print "R", 512 + 216, y + 7, 1, textColor
	globals.panSlider = Slider.Make(588, y - 3, 0, -1, 1)
	
	btn9 = gui.Image9Slice.make(PushButton.image, 6, 6, 6, 6)
	playBtn = PushButton.Make(780, y, btn9.getImage(72, 24))
	tempG.clear color.clear, playBtn.width, playBtn.height
	tempG.print "PLAY", playBtn.width/2 - 4*7, 0, color.white
	playBtn.icon = tempG.getImage
	playBtn.draw
	playBtn.action = @playNote

	codeBtn = PushButton.Make(playBtn.right + 12, y, playBtn.image)
	tempG.clear color.clear, playBtn.width, playBtn.height
	tempG.print "CODE", playBtn.width/2 - 4*7, 0, color.white
	codeBtn.icon = tempG.getImage
	codeBtn.draw
	codeBtn.action = @showCode
	
	y -= 8
	buildKeyboard y, function(keyHit)
		speed = noteFreq(keyHit.note) / noteFreq(60)
		speedFld.set str(round(speed, 2 + (speed < 10)))
		playNote
	end function
	

	x = 480; y = 30
	gfx.line x-6, y-6, x, y, "#AAAAAA"
	gfx.line x+6, y-6, x, y, "#AAAAAA"
	
end function

playNote = function(_)
	snd = new Sound
	snd.init durationFld.value, freqEd.nodeValues, envelopeEd.nodeValues,
	   waveEd.nodeValues
	snd.fadeIn = fadeInFld.value
	snd.fadeOut = fadeOutFld.value
	snd.play volSlider.value, panSlider.value, speedFld.value
end function

getCodeLines = function
	lines = ["snd = new Sound"]
	numOrList = function(values, decimalPlaces=3)
		if values.len == 1 then return str(round(values[0], decimalPlaces))
		s = []
		for v in values
			s.push str(round(v, decimalPlaces))
		end for
		return "[" + s.join(", ") + "]"
	end function
	lines.push "freq = " + numOrList(freqEd.nodeValues)
	lines.push "envelope = " + numOrList(envelopeEd.nodeValues)
	wave = "Custom"
	w = waveEd.nodeValues
	for wname in "squareWave triangleWave sawtoothWave sineWave noiseWave".split
		wvals = Sound[wname]
		if waveEd.nodeValues == wvals then
			wave = "Sound." + wname
		end if
	end for
	if wave == "Custom" then
		lines.push "waveform = " + numOrList(waveEd.nodeValues)
		wave = "waveform"
	end if
	lines.push "snd.init " + str(durationFld.value) + ", freq, envelope, " + wave

	if fadeInFld.value != 0.1 then lines.push "snd.fadeIn = " + fadeInFld.value
	if fadeOutFld.value != 0.1 then lines.push "snd.fadeOut = " + fadeOutFld.value

	s = ""
	if speedFld.value != 1 then s = ", " + speedFld.value
	if panSlider.value != 0 or s then s = ", " + panSlider.value + s
	if volSlider.value != 1 or s then s = volSlider.value + s
	lines.push "snd.play " + s
	return lines
end function

showCode = function(_)
	lines =  getCodeLines	
	state = textUtil.getState
	text.color = color.orange
	text.backColor = color.black
	textUtil.clearRect 0, 5, 68, lines.len + 2
	text.row = 6 + lines.len
	for line in lines; print line; end for
	print
	text.color = color.gray
	input "(Press Return.)"
	textUtil.setState state
end function

main = function
	setup
	curKeyDown = null
	while true
		k = keyUnderMouse
		if curKeyDown and (k != curKeyDown or not mouse.button) then
			curKeyDown.release
			curKeyDown = null			
		end if
		if mouse.button and k != curKeyDown then
			if k then k.press
			curKeyDown = k		
		end if
		
		if mouse.button then
			PushButton.HandleMouseAll
			if gui.InputField.handleClickAll and CurveEditor.SelEd then
				CurveEditor.SelEd.deselect
			end if
			for item in [freqEd, envelopeEd, waveEd, volSlider, panSlider]
				if item.handleMouse and gui.InputField.focusedField then
					gui.InputField.focusedField.deselect
				end if
			end for
		end if
		if key.available then
			k = key.get
			if not gui.InputField.handleKeyAll(k) then
				if CurveEditor.SelEd and (k == char(8) or k == char(127)) then
					CurveEditor.SelEd.deleteNode
				end if
				if k == char(27) then break
			end if
		end if
		
		yield
	end while
	clear
	pageThrough getCodeLines
end function
 
main

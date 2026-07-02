// LCARS Calculator application module.
// Interface: call init to build the UI; panel is then the root panel.

import "importUtil"

panel = null

init = function
	p = Panel.make(root, 168, 0, 960-168, 640)
	p.modeLabel = "Calculator"
	p.style.color = "#33cc99"
	p.style.buttonColor = "#99dd66"
	p.style.displayColor = "#88CCFF"
	p.header = Frame.make(p, null, p.top - 108)
	p.header.configure false, true, true, false
	p.displayStr = "0"
	p.clearOnInput = false
	Block.make p.header.leftPanel
	Block.make p.header.bottomPanel
	title = InfoBlock.make("CALCULATOR", p.header,
		p.header.right - 200, p.top - 30, 200, 30)
	title.font = largeFont
	title.inverted = true

	p.display = Panel.make(p, p.left+160, p.top-64, 420, 48)
	p.display.present = function
		gfx.fillRect self.left, self.bottom, self.width, self.height, "#666688"
		largeFont.printRight p.displayStr, self.right - 4, self.bottom + 8, 1, self.style.displayColor
	end function

	p.doAction = function(s)
		if s >= "0" and s <= "9" then
			if self.displayStr == "0" or self.clearOnInput then self.displayStr = ""
			self.displayStr += s
			self.clearOnInput = false
			sounds.blip.play 0.5, 0, noteFreq(67)/440
		else if s == "Backspace" and self.displayStr then
			self.displayStr = self.displayStr[:-1]
			if not self.displayStr then self.displayStr = "0"
			sounds.blip.play 0.5, 0, noteFreq(71)/440
			wait 0.05; sounds.blip.play 0.5, 0, noteFreq(72)/440
		else if s == "Clear" then
			self.displayStr = "0"
			self.opA.text = ""
			self.operator.text = ""
			self.opA.present
			self.operator.present
			sounds.blip.play 0.5, 0, noteFreq(64)/440
			wait 0.1; sounds.blip.play 0.5, 0, noteFreq(67)/440
			wait 0.1; sounds.blip.play 0.5, 0, noteFreq(72)/440
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
			sounds.blip.play 0.5, 0, noteFreq(60)/440
			self.main.log.add valA + " " + op + " " + valB, self.displayStr
			self.opA.text = ""; self.opA.present
			self.operator.text = ""; self.operator.present
			self.clearOnInput = true
			wait 0.1
		else
			if self.operator and not self.clearOnInput then self.doAction "="
			self.opA.text = self.displayStr; self.opA.present
			self.operator.text = s; self.operator.present
			self.clearOnInput = true
			sounds.blip.play 0.5, 0, noteFreq(64)/440
		end if
		self.display.present
	end function

	p.main = Frame.make(p, null, 0, null, p.height - 118)
	p.main.configure true, false, true, false

	Gap.make p.main.topPanel
	p.main.logHeader = InfoBlock.make("Calculation Log", p.main.topPanel, null, null, 320)
	p.main.topPanel.layout

	b = Button.make("Backspace", p.main.leftPanel, null, null, null, p.style.buttonHeight)
	b.action = function; p.doAction self.caption; end function
	b.key = char(8)

	b = Button.make("Clear", p.main.leftPanel, null, null, null, p.style.buttonHeight)
	b.action = function; p.doAction self.caption; end function
	b.key = char(1)	// (Home button, at least on Macs)

	InfoBlock.make "", p.main.leftPanel, null, null, null, p.style.buttonHeight*2

	b = Button.make("=", p.main.leftPanel, null, null, null, p.style.buttonHeight*3)
	b.action = function; p.doAction self.caption; end function
	b.key = ["=", char(10), char(13), char(3)]

	Gap.make p.main.leftPanel

	p.opA = InfoBlock.make("", p.main.leftPanel, null, null, null, p.style.buttonHeight)
	p.operator = InfoBlock.make("", p.main.leftPanel, null, null, null, p.style.buttonHeight)
	Gap.make p.main.leftPanel
	p.main.leftPanel.layout

	y = p.main.topPanel.bottom - 72
	btns = ["789", "456", "123", " 0.", "+-*", "/^%", ["and","or","not"]]
	for row in btns.indexes
		for col in btns[row].indexes
			x = p.main.topPanel.left + 96*col
			if btns[row][col] == " " then continue
			if btns[row][col] == "0" then
				x = p.main.topPanel.left
				b = RoundButton.make(btns[row][col], p, x, y, 84+96, 48)
			else
				b = RoundButton.make(btns[row][col], p, x, y, 84, 48)
			end if
			b.action = function; p.doAction self.caption; end function
		end for
		y = y - 60 - 24 * (row == 3)
	end for

	p.main.log = Panel.make(p.main, p.main.logHeader.left, 16, p.main.logHeader.width, p.main.topPanel.bottom - 40)
	p.main.log.calc = p  // back-reference so b.action can reach the calculator panel
	p.main.log.add = function(expression, result)
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
			self.parent.calc.displayStr = result
			self.parent.calc.display.present
			sounds.blip.play 0.5, 0, noteFreq(65)/440
			wait 0.05; sounds.blip.play 0.5, 0, noteFreq(67)/440
		end function
		b.present
	end function

	outer.panel = p
end function

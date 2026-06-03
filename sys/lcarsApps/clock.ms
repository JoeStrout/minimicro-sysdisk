// LCARS Clock application module.
// Interface: call init to build the UI; panel is then the root panel.

import "importUtil"
ensureImport "dateTime"

panel = null

init = function
	p = Panel.make(root, 168, 0, 960-168, 640)
	p.modeLabel = "Clock"
	p.style.color = "#cc4499"
	p.style.textColor = "#cc88ff"

	p.header = Frame.make(p, null, p.top - 200)
	p.header.configure false, true, true, false
	Block.make p.header.leftPanel
	Block.make p.header.bottomPanel
	title = InfoBlock.make("CLOCK", p.header,
		p.header.right - 200, p.top - 30, 200, 30)
	title.font = largeFont
	title.inverted = true

	p.topDisplay = Panel.make(p, p.left + 160, p.header.bottom + 50, 400, p.header.height - 50)
	p.topDisplay.present = function
		gfx.fillRect self.left, self.bottom, self.width, self.height, color.black
		now = dateTime.val
		y = self.top - largeFont.lineHeight * 3
		x = self.left + 20
		largeFont.print dateTime.str(now, "dddd"), x, y, 2, self.style.textColor
		y = y - largeFont.lineHeight * 2
		largeFont.print dateTime.str(now, "MMMM d, yyyy"), x, y, 1, self.style.textColor
	end function

	p.main = Panel.make(p, p.left, 0, p.width, p.header.bottom)
	p.main.present = function
		gfx.fillRect self.left, self.bottom, self.width, self.height, color.black
		s = dateTime.now.split[1]
		largeFont.printCentered s, self.midX, self.midY - 50, 6, self.style.textColor
		self.curTimeShown = s
	end function

	p.onUpdate = function
		s = dateTime.now.split[1]
		if s != self.main.curTimeShown then self.main.present
	end function

	outer.panel = p
end function

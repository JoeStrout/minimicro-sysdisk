// LCARS News application module.
// Interface: call init to build the UI; panel is then the root panel.

import "importUtil"
ensureImport "styledText"

panel = null

init = function
	p = Panel.make(root, 168, 0, 960-168, 640)
	p.modeLabel = "News"
	p.style.color = "#ffaa44"
	p.style.buttonColor = "#ff7700"
	p.style.textColor = "#ffeecc"
	p.header = Frame.make(p, null, p.top - 108)
	p.header.configure false, true, true, false
	Block.make p.header.leftPanel
	Block.make p.header.bottomPanel
	title = InfoBlock.make("NEWS", p.header,
		p.header.right - 200, p.top - 30, 200, 30)
	title.font = largeFont
	title.inverted = true

	p.main = Frame.make(p, null, 0, null, p.height - 118)
	p.main.configure true, false, true, false

	Gap.make p.main.topPanel
	p.date = InfoBlock.make("2000-01-01", p.main.topPanel, null, null, 160)
	p.posCount = InfoBlock.make("0 / 0", p.main.topPanel, null, null, 160)
	p.main.topPanel.layout

	Gap.make p.main.leftPanel

	b = Button.make("Previous", p.main.leftPanel, null, null, null, p.style.buttonHeight)
	b.action = function; p.nextStory -1; end function
	b.key = char(17)

	b = Button.make("Next", p.main.leftPanel, null, null, null, p.style.buttonHeight)
	b.action = function; p.nextStory 1; end function
	b.key = char(18)

	Gap.make p.main.leftPanel
	p.main.leftPanel.layout

	p.data = null; p.curItemIdx = 0
	p.nextStory = function(delta=1)
		if not self.data then return
		self.curItemIdx = (self.curItemIdx + self.data.len + delta) % self.data.len
		self.content.present
	end function

	p.content = Panel.make(p.main, p.main.topPanel.left, 0,
				940 - p.main.topPanel.left, p.main.topPanel.bottom - 16)
	p.content.present = function
		if p.data == null then
			lines = http.get("https://miniscript.org/news/news.dat").splitLines
			p.data = []
			curItem = {}
			for line in lines
				if line == "" then
					if curItem then p.data.push curItem
					curItem = {}
					continue
				end if
				parts = line.split(": ", 2)
				if parts.len < 2 then continue
				curItem[parts[0]] = parts[1]
			end for
			if curItem then p.data.push curItem
		end if
		story = p.data[p.curItemIdx]
		p.date.text = story.date; p.date.present
		p.posCount.text = p.curItemIdx + " / " + p.data.len; p.posCount.present

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

	outer.panel = p
end function

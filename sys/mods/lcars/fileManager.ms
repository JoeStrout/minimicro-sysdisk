// LCARS File Manager application module.
// Interface: call init(env) to build the UI; panel is then the root panel.

import "importUtil"
ensureImport "mathUtil"

panel = null

init = function
	// FileRow: a Button subclass representing one file/directory entry.
	FileRow = new Button
	FileRow._name = "FileRow"
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
		self.selected = false
	end function
	FileRow.drawToScratch = function
		f = self.file
		gap = self.style.spacing
		y = 3
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
					sounds.blip.play 0.5, 0, noteFreq(69)/440
					wait 0.05; sounds.blip.play 0.5, 0, noteFreq(65)/440
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
		sounds.blip.play 1, 0, noteFreq(60 + 7*selectIt)/440
		self.redrawSprite
	end function

	// Root panel for this app
	p = Panel.make(root, 168, 0, 960-168, 640)
	p.modeLabel = "File Manager"
	p.style.color = "#7788ff"
	p.style.buttonColor = "#88CCFF"
	p.header = Frame.make(p, null, p.top - 108)
	p.header.configure false, true, true, false
	Block.make p.header.leftPanel
	Block.make p.header.bottomPanel
	title = InfoBlock.make("FILE MANAGER", p.header,
		p.header.right - 200, p.top - 30, 200, 30)
	title.font = largeFont
	title.inverted = true
	p.infoPanel = Panel.make(p.header,
		p.header.bottomPanel.left,
		p.header.bottomPanel.top + 8)
	p.infoPanel.setTop 632, false
	p.infoPanel.setRight title.left - 8, false
	p.infoPanel.present = function
		gfx.fillRect self.left, self.bottom, self.width, self.height, color.black
		sel = p.fileBox.selection
		y = self.top - 20
		smallFont.print "Files selected: " + sel.len, self.left, y, 1, self.style.textColor
		if sel.len == 0 then return
		y -= 16
		totalSize = 0
		for f in sel; totalSize += f.file.size; end for
		smallFont.print "Total bytes: " + totalSize, self.left, y, 1, self.style.textColor
	end function

	p.fileBox = Frame.make(p, null, 0, null, p.height - 118)
	p.fileBox.configure true, true, true, false
	p.fileBox.fileRows = []

	// Inline setup (was fileBox.setup method; self = p.fileBox throughout)
	fb = p.fileBox
	w = 60
	quickLoad = function
		sounds.ok.play
		fb = self.parent.parent
		fb.load self.caption
		fb.present
	end function
	Button.make("/usr", fb.topPanel, null, null, w).action = @quickLoad
	Button.make("/usr2", fb.topPanel, null, null, w).action = @quickLoad
	Button.make("/sys", fb.topPanel, null, null, w).action = @quickLoad
	b = Button.make(upOutChar + " UP", fb.topPanel, null, null, w)
	b.action = function
		fb = self.parent.parent
		if fb.path == "/" then return
		sounds.blip.play 0.5, 0, noteFreq(69)/440
		wait 0.05; sounds.blip.play 0.5, 0, noteFreq(72)/440
		fb.load file.parent(fb.path)
		fb.present
	end function
	fb.pathInfo = InfoBlock.make("/usr", fb.topPanel, null, null, fb.topPanel.width - fb.style.buttonWidth)
	fb.topPanel.layout

	Button.make "Name", fb.leftPanel, null, null, null, fb.style.buttonHeight
	Button.make "Size", fb.leftPanel, null, null, null, fb.style.buttonHeight
	Button.make "Date", fb.leftPanel, null, null, null, fb.style.buttonHeight
	Button.make "Selected", fb.leftPanel, null, null, null, fb.style.buttonHeight
	Gap.make fb.leftPanel
	Button.make("Select All", fb.leftPanel, null, null, null, fb.style.buttonHeight).action = function
		self.parent.parent.selectAll true
	end function
	Button.make("Select None", fb.leftPanel, null, null, null, fb.style.buttonHeight).action = function
		self.parent.parent.selectAll false
	end function
	Gap.make fb.leftPanel
	Button.make "Move/Copy", fb.leftPanel, null, null, null, fb.style.buttonHeight
	fb.leftPanel.layout

//	Button.make "Rename", fb.bottomPanel, null, null, fb.style.buttonWidth
//	delBtn = Button.make("Delete", fb.bottomPanel, null, null, fb.style.buttonWidth)
//	delBtn.color = "#DD4444"
	Gap.make fb.bottomPanel
//	Button.make "Preview", fb.bottomPanel, null, null, fb.style.buttonWidth
	launchBtn = Button.make("Launch", fb.bottomPanel, null, null, fb.style.buttonWidth)
	launchBtn.color = "#33CC99"
	launchBtn.action = function
		sel = p.fileBox.selection
		if sel.len != 1 or not sel[0].file.path.endsWith(".ms") then
			sounds.err.play
		else
			sounds.ok.play; wait 1
			if not env.shell then env.shell = _sourceFile
			env.autorun = false
			clear; reset; run sel[0].file.path; exit
		end if
	end function
	fb.bottomPanel.layout

	y0 = fb.bottomPanel.top + 2
	y4 = fb.topPanel.bottom - 1
	bh = floor((y4 - y0) / 4)
	y1 = y0 + bh
	y2 = y0 + bh*2
	y3 = y0 + bh*3
	b = Button.make(pageDownChar, fb, fb.right - 24, y0, 24, y1-y0-1)
	b.key = char(4)  // (ctrl-D)
	b.action = function
		fb = self.parent; fb.scroll 1, true
	end function
	b = Button.make(lineDownChar, fb, fb.right - 24, y1, 24, y2-y1-1)
	b.key = char(20)  // down-arrow
	b.action = function
		fb = self.parent; fb.scroll 1, false
	end function
	b = Button.make(lineUpChar, fb, fb.right - 24, y2, 24, y3-y2-1)
	b.key = char(19)  // up-arrow
	b.action = function
		fb = self.parent; fb.scroll -1, false
	end function
	b = Button.make(pageUpChar, fb, fb.right - 24, y3, 24, y4-y3-1)
	b.key = char(21)  // ctrl-U
	b.action = function
		fb = self.parent; fb.scroll -1, true
	end function

	p.fileBox.scroll = function(direction, byPage=false)
		self.topRow += (1 + 13*byPage) * direction
		self.topRow = mathUtil.clamp(self.topRow, 0, file.children(self.path).len-13)
		if self.topRow < 0 then self.topRow = 0
		self.load self.path, false
		self.present
	end function

	p.fileBox.path = ""
	
	p.fileBox.load = function(path, resetScroll=true)
		infoPanel = p.infoPanel  // capture for fr.action closures (p is two scopes up from here)
		self.path = path
		children = file.children(path)
		if resetScroll then self.topRow = 0
		for i in range(0,13)
			if i+self.topRow >= children.len then; i -= 1; break; end if
			if i >= self.fileRows.len then
				fr = FileRow.make(self,
				  self.topPanel.left-20, self.topPanel.bottom - 36 - 32*i,
				  self.right - self.topPanel.left - 10, 24)
				fr.action = function
					if modKey.doAll then
						self.parent.selectAll not self.selected
					else
						self.select not self.selected
						infoPanel.present
					end if
				end function
				self.fileRows.push fr
			end if
			self.fileRows[i].setPath file.child(self.path, children[i+self.topRow])
		end for
		while self.fileRows.len-1 > i
			self.fileRows[-1].dismiss; self.fileRows[-1].destroy
			self.fileRows.remove -1
		end while
		self.pathInfo.text = path
		p.infoPanel.present
	end function

	p.fileBox.selectAll = function(selectEm=true)
		for fr in self.fileRows
			fr.select selectEm
		end for
		p.infoPanel.present
	end function

	p.fileBox.selection = function
		return self.fileRows.filtered("selected")
	end function

	p.present = function
		if self.fileBox.path == "" then self.fileBox.load "/usr/"
		super.present
	end function

	outer.panel = p
end function

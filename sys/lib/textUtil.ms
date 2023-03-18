// Text Utilities (related to displaying text on the Mini Micro screen).

import "stringUtil"

// Print without a carriage return (i.e. moving to the next line).
printNoCR = function(s)
	oldDelim = text.delimiter
	text.delimiter = ""
	print s
	text.delimiter = oldDelim
end function

// Draw a button with the given caption at the cursor position.
drawButton = function(caption)
	text.inverse = not text.inverse
	printNoCR char(57856) + caption + char(57857)
	text.inverse = not text.inverse
end function

// Print the given string, wrapped on word breaks (spaces) to
// fit in the given width.  Subsequent lines begin at the same
// text.column as the current text.column value.
// Parameters:
//		s: string to print
//		width: character limit per line; if null, goes to edge of screen
//		maxLines: maximum lines to print; or if null, no limit
// Returns: remaining (unprinted) portion of string, or null
printWrap = function(s, width=null, maxLines=null)
	left = text.column
	if width == null then width = 67 - left
	lineCount = 0
	while s
		text.column = left
		if s.len <= width then
			print s
			return null
		end if
		foundCut = false
		for i in range(width, 0)
			if s[i] == " " then
				print s[:i]
				s = s[i+1:]
				foundCut = true
				break
			end if
		end for
		if not foundCut then
			// Couldn't find a space to cut on...
			// so, out of desperation, just cut at width
			print s[:width]
			s = s[width:]
		end if
		lineCount = lineCount + 1
		if maxLines and lineCount == maxLines then return s
	end while
end function

// Get the text column for a given screen pixel X coordinate.
textCol = function(pixelX)
	return floor((pixelX-5)/14)
end function

// Get the text row for a given screen pixel Y coordinate.
textRow = function(pixelY)
	return floor((pixelY-6)/24)
end function

// Print a string starting at the given column and row.
// Also, if you use this to print to row 0, it avoids the usual scrolling.
printAt = function(column, row, s)
	text.row = row
	text.column = column
	if row == 0 then
		// avoid scrolling when printing to the bottom row
		delim = text.delimiter
		text.delimiter = ""
		print s
		text.delimiter = delim
	else
		print s
	end if
end function

// Print a string centered on the given column and row.
printCenteredAt = function(column, row, s)
	printAt column - s.len/2, row, s
end function

// clearToEOL: Clear from the current cursor position to the end of the line
// (by filling the rest of the line with spaces, or whatever character you specify).
// Also applies default foreground and background colors.
clearToEOL = function(character=" ")
	cols = range(text.column, 67)
	text.setCell cols, text.row, character
	text.setCellColor cols, text.row, text.color
	text.setCellBackColor cols, text.row, text.backColor
end function

// clearRow: Clear the entirety of the given row by filling it with spaces
// (or whatever character you specify).
// Also applies default foreground and background colors.
clearRow = function(row=null, character=" ")
	if row == null then row = text.row
	if not row isa list then row = [row]
	allCols = range(0, 67)
	for r in row
		text.setCell allCols, r, character
		text.setCellColor allCols, r, text.color
		text.setCellBackColor allCols, r, text.backColor
	end for
end function

// clearRect: clear a rectangular area of the screen by filling it with spaces
// (or whatever character you specify).
// Also applies default foreground and background colors.
clearRect = function(left=0, bottom=0, width=68, height=25, character=" ")
	for r in range(bottom, bottom+height-1)
		for c in range(left, left+width-1)
			text.setCell c, r, character
			text.setCellColor c, r, text.color
			text.setCellBackColor c, r, text.backColor
		end for
	end for
end function

// buttonLeft and buttonRight: combines the inverse toggles with
// the button cap glyphs.  Print these before or after a button caption.
buttonLeft = char(134) + char(57856)
buttonRight = char(57857) + char(135)

// button function: returns a complete printable button with the given
// caption, optionally padded to some caption length.
button = function(caption, minCaptionLength=0)
	if caption.len < minCaptionLength then
		pad = minCaptionLength - caption.len
		caption = " " * floor(pad/2) + caption + " " * ceil(pad/2)
	end if
	return buttonLeft + caption + buttonRight
end function

// Cell: a little class that represents the complete contents (including
// colors) of a particular row and column on a text display.
Cell = {}
Cell.character = ""
Cell.color = ""
Cell.backColor = ""
Cell.get = function(column, row)
	result = new Cell
	result.character = text.cell(column, row)
	result.color = text.cellColor(column, row)
	result.backColor = text.cellBackColor(column, row)
	return result
end function
Cell.apply = function(column, row)
	text.setCell column, row, self.character
	text.setCellColor column, row, self.color
	text.setCellBackColor column, row, self.backColor
end function

// getContent: Get the entire content of the text display as a 2D array
// of Cell objects in [row][col] order.
// (You can then restore this later with setContent.)
getContent = function
	rows = []
	for row in range(0, 25)
		cols = []
		for col in range(0, 67)
			cols.push Cell.get(col, row)
		end for
		rows.push cols
	end for
	return rows
end function

// setContent: restore the content of the text display with the given
// 2D array of Cell objects in [row][col] order.
setContent = function(data)
	row = 0
	for dataRow in data
		col = 0
		for c in dataRow
			c.apply col, row
			col = col + 1
			if col > 67 then break
		end for
		row = row + 1
		if row > 25 then break
	end for
end function

// getState: get the content of the screen as well as the text
// colors and cursor position.  Use with setState (below).
getState = function
	result = {}
	result.text = getContent
	result.color = text.color
	result.backColor = text.backColor
	result.delimiter = text.delimiter
	result.row = text.row
	result.column = text.column
	return result
end function

// setState: set the screen content, text colors, and cursor position
// (as obtained from getState).
setState = function(state)
	setContent state.text
	text.color = state.color
	text.backColor = state.backColor
	text.delimiter = state.delimiter
	text.row = state.row
	text.column = state.column
end function

// Dialog class: used to define a simple message dialog,
// with title, message, and 1-3 buttons.  Create a new Dialog,
// with Dialog.make, assign all its other properties as desired,
// then call .show on it.  The return value is the button that
// was clicked by the user.
Dialog = {}
Dialog.title = "Alert"
Dialog.message = "Your message here."
Dialog.width = 34
Dialog.backColor = "#AAAACC"
Dialog.titleColor = "#CCCCFF"
Dialog.textColor = "#444444"
DialogButton = {}
DialogButton.caption = "Button"
DialogButton.visible = false
DialogButton.key = ""  // shortcut key
DialogButton.width = function; return self.caption.len + 2; end function
DialogButton.x = 20
DialogButton.y = 10
DialogButton.draw = function
	c = text.backColor
	text.row = self.y; text.column = self.x; print buttonLeft
	text.backColor = color.black
	text.row = self.y; text.column = self.x + 1; print self.caption
	text.backColor = c
	text.row = self.y; text.column = self.x + 1 + self.caption.len; print buttonRight
end function
DialogButton.contains = function(pt)
	return textRow(pt.y) == self.y and 
	   textCol(pt.x) >= self.x and textCol(pt.x) < self.x + self.width
end function
DialogButton.trackHit = function
	c = text.cellBackColor(self.x, self.y)
	while mouse.button
		text.color = c
		if self.contains(mouse) then text.color = color.lerp(c, color.black)
		self.draw
		yield
	end while
	if text.color == c then return false
	text.color = c
	self.draw
	return true
end function

Dialog.make = function(title="", message="Your message here.")
	dlog = new Dialog
	dlog.title = title
	dlog.message = message
	dlog.okBtn = new DialogButton
	dlog.okBtn.caption = "OK"
	dlog.okBtn.visible = true
	dlog.okBtn.key = char(10)  // (return key)
	dlog.altBtn = new DialogButton
	dlog.cancelBtn = new DialogButton
	dlog.cancelBtn.caption = "Cancel"
	dlog.cancelBtn.key = char(27)
	if title.len > dlog.width then dlog.width = title.len
	dlog.msgLines = message.wrap(dlog.width-4)
	dlog.height = dlog.msgLines.len + 4
	return dlog
end function

// Helper function to draw the dialog and return the button instances.
// Most user code will not call this directly; call Dialog.show instead.
Dialog.draw = function	
	rows = range(12 - floor(self.height/2), 11 + ceil(self.height/2))
	cols = range(34 - floor(self.width/2), 33 + ceil(self.width/2))
	
	text.delimiter = char(13)
	text.row = 12 + ceil(self.height/2)
	x = 34 - self.width/2
	
	// draw title
	text.color = self.textColor
	text.backColor = self.titleColor
	spacesNeeded = self.width - self.title.len
	text.row = rows[-1] + 1; text.column = cols[0]
	print " " * floor(spacesNeeded/2) + self.title + " " * ceil(spacesNeeded/2)
	
	// draw box and content
	text.setCell cols, rows, " "
	text.setCellBackColor cols, rows, self.backColor
	self.drawContent cols, rows
	text.color = self.textColor
	text.backColor = self.backColor
	
	// draw buttons
	btnRow = rows[1]
	btnX = cols[-1] - 1
	buttons = [self.okBtn, self.altBtn, self.cancelBtn]
	for btn in buttons
		if not btn.visible then continue
		text.color = "#CCCCCC"  // (button color)
		if btn.key == char(10) then text.color = "#EEEEFF"
		btn.x = btnX - btn.width
		if btn == self.cancelBtn then btn.x = x + 2
		btn.y = btnRow
		btn.draw
		btnX = btn.x - 2
	end for
	return buttons
end function

// Another internal helper function used to draw the content of the dialog,
// given the range of rows and columns.
Dialog.drawContent = function(cols, rows)
	text.color = self.textColor
	text.backColor = self.backColor
	text.row = rows[-2]
	for line in self.msgLines
		text.column = cols[2]; print line
	end for
end function

// Methods that subclasses can override to do special event processing.
// Return true if event handled, false or null otherwise.  To close
// the dialog, set self.done = true.
Dialog.handleMouse = null
Dialog.handleKey = function(k); end function

// Main entry point: call this to show your dialog, and get back the caption
// of the button that was pressed.
Dialog.show = function(timeout=null)
	priorState = getState
	
	// draw the dialog, and get back the list of visible buttons
	buttons = self.draw
	
	// now wait until we get a key shortcut or a valid click on a button,
	// or (optionally) time out
	btnHit = null
	startTime = time
	self.done = false
	while not btnHit and not self.done
		if mouse.button and not self.handleMouse then
			for btn in buttons
				if not btn.visible or not btn.contains(mouse) then continue
				if btn.trackHit then
					btnHit = btn
					break
				end if
			end for
		end if
		if key.available then
			k = key.get
			if self.handleKey(k) then continue
			if k.code == 3 or k.code == 13 then k = char(10)
			for btn in buttons
				if btn.visible and btn.key == k then
					btnHit = btn
					break
				end if
			end for
		end if
		if timeout != null and time > startTime + timeout then break
	end while
	
	setState priorState	
	return btnHit
end function

// FileDialog: a Dialog subclass specialized for picking a folder or file.
FileDialog = new Dialog
FileDialog.width = 50
FileDialog.columns = 3
FileDialog.listTextColor = "#AAAAFF"
FileDialog.listBackColor = "#222222"
FileDialog.curDirBackColor = "#444466"
FileDialog.selTextColor = "#000044"
FileDialog.selBackColor = "#FFFF00"

FileDialog.make = function(title="Select file")
	dlog = Dialog.make(title)
	dlog.__isa = FileDialog
	dlog.height = 18
	dlog.cancelBtn.visible = true
	dlog.directory = file.curdir
	dlog.selection = file.curdir - "/"
//	children = file.children(dlog.directory)
//	if children then dlog.selection = file.child(dlog.selection, children[0])
	dlog.colInfo = {}	// map of left, top, files, etc.
	return dlog
end function

FileDialog.loadColumn = function(colNum, dirPath, width)
	info = {}
	self.colInfo[colNum] = info
	info.left = text.column
	info.top = text.row
	info.width = width
	info.dirPath = dirPath
	info.selIdx = null
	if dirPath == null then
		files = null
	else
		// load file info (path, isDirectory, etc.) for all files in this directory
		files = file.children(dirPath)
		for i in files.indexes
			files[i] = file.info(file.child(dirPath, files[i]))
			files[i].name = file.name(files[i].path)
			if self.selection.startsWith(files[i].path) then info.selIdx = i
		end for
	end if
	info.files = files
	self.drawColumn colNum
end function

FileDialog.reloadColumn = function(colNum, dirPath)
	info = self.colInfo[colNum]
	text.row = info.top
	text.column = info.left
	self.loadColumn colNum, dirPath, info.width
end function

FileDialog.drawColumn = function(colNum)
	info = self.colInfo[colNum]
	text.row = info.top
	text.column = info.left
	files = info.files
	width = info.width
	dirIndicator = char(8594)	// (right-arrow symbol)
	dirIndColor = color.lerp(self.listTextColor, self.listBackColor, 0.3)
	scroll = 0	// ToDo!
	for row in range(0, self.height-6)
		idx = scroll + row
		hilight = false; selected = false; isDir = false; s = ""
		if files and idx < files.len then
			f = files[idx]
			s = f.name
			isDir = f.isDirectory
			if idx == info.selIdx then
				hilight = true
				if f.path == self.selection then selected = true
			end if
		end if
		s = (s + " "*width)[:width]
		if selected then
			text.color = self.selTextColor
			text.backColor = self.selBackColor
		else
			text.color = self.listTextColor
			text.backColor = self.curDirBackColor * hilight + self.listBackColor * (not hilight)
		end if
		text.column = info.left; print s, ""
		if isDir then
			text.color = dirIndColor
			print char(8) + dirIndicator
			text.color = self.listTextColor
		else
			print
		end if
	end for
end function

FileDialog.drawContent = function(cols, rows)
	text.color = self.textColor
	text.backColor = self.backColor
	text.row = rows[-2]; text.column = cols[2]
	print self.directory
	pathParts = self.directory.split("/")
	
	// Start up a level or two (depending on how many columns we have)
	partIdx = pathParts.len - self.columns
	if partIdx < 0 then partIdx = 0
	
	// draw a column for each subpath
	x = cols[2]
	colWidth = floor((self.width - 4) / self.columns) - 1
	for col in range(0, self.columns - 1)
		if col == self.columns - 1 then colWidth = cols[-2] - x
		if partIdx+1+col >= pathParts.len then
			path = null
		else
			path = pathParts[:partIdx+1+col].join("/")
			if not path then path = "/"
		end if
		text.column = x; text.row = rows[-3]
		self.loadColumn col, path, colWidth
		x = x + colWidth + 1
	end for
end function

FileDialog.selectedColumn = function
	col = self.columns - 1
	while self.colInfo[col].selIdx == null and col > 0
		col -= 1
	end while
	return col
end function

FileDialog.selectNext = function(delta)
	dir = file.parent(self.selection)
	name = file.name(self.selection)
	allNames = file.children(dir)
	col = self.selectedColumn
	info = self.colInfo[col]
	info.selIdx = (info.selIdx + info.files.len + delta) % info.files.len
	self.selection = info.files[info.selIdx].path
	self.drawColumn col
	if info.files[info.selIdx].isDirectory then
		self.directory = self.selection
		if col+1 < self.columns then self.reloadColumn col+1, self.directory
	else
		if col+1 < self.columns then self.reloadColumn col+1, null
	end if
	if col+2 < self.columns then self.reloadColumn col+2, null
	return true
end function

FileDialog.reloadAll = function
	pathParts = self.directory.split("/")
	partIdx = pathParts.len - self.columns
	if partIdx < 0 then partIdx = 0
	for col in range(0, self.columns-1)
		if partIdx+1+col >= pathParts.len then
			path = null
		else
			path = pathParts[:partIdx+1+col].join("/")
			if not path then path = "/"
		end if
		self.reloadColumn col, path
	end for
end function

FileDialog.handleKey = function(k)
	kcode = k.code
	if kcode == 19 then return self.selectNext(-1)		// up-arrow
	if kcode == 20 then return self.selectNext(1)		// down-arrow
	if kcode == 10 or kcode == 3 or kcode == 18 then	// return or right-arrow
		col = self.selectedColumn
		info = self.colInfo[col]
		selFile = info.files[info.selIdx]
		if not selFile.isDirectory then return false
		children = file.children(selFile.path)
		if not children then return true
		self.directory = selFile.path
		self.selection = file.child(self.directory, children[0])
		if col < self.columns-1 then
			self.reloadColumn col+1, self.directory
			self.drawColumn col
		else
			self.reloadAll
		end if
	else if kcode == 17 then							// left-arrow
		parent = file.parent(self.selection)
		if parent == null then return true
		self.selection = self.directory
		self.directory = parent
		self.reloadAll
	end if
end function



if locals == globals and 0 then
	d = Dialog.make("Message Test", 
	"Hello world!  This is a test of the nifty text-based Dialog system.")
	d.altBtn.visible = true
	d.altBtn.key = "b"
	d.cancelBtn.visible = true
	print d.show.caption
end if

if locals == globals and 1 then
	text.color = color.orange
	text.backColor = "#00000D"
	d = FileDialog.make
	d.show
end if
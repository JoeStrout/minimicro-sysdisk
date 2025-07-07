// This module defines a StyleRun class, which represents a string of
// text in a particular style (e.g., bold); and a series of printers
// that can take a list of StyleRuns, and print that text with proper
// word wrap.
//
// It also contains a couple of parsers to easily generate a list of
// StyleRuns from a markdown-style syntax, or from a subset of HTML.
// See parse functions below for details.
//
// Still TO-DO: make printers keep their own cursor position, and possibly wrap
// settings so you can call print on them multiple times to add additional
// lines/paragraphs.

if not globals.hasIndex("stringUtil") then import "stringUtil"
if not globals.hasIndex("bmfFonts") then import "bmfFonts"

// StyleRun class: represents a bit of text with a uniform style.
StyleRun = {}
StyleRun.text = ""
StyleRun.code = false
StyleRun.bold = false
StyleRun.italic = false
StyleRun.underline = false
StyleRun.strikethrough = false
StyleRun.highlight = false
StyleRun.make = function(s, copyStyle=null)
	if copyStyle then
		result = copyStyle + {}
	else
		result = new StyleRun
	end if
	result.text = s
	return result
end function

// parseMarkup: takes a string containing markup, and returns it as 
// a list of StyleRuns.  Supports the following syntax:
//
//   `code`         -- code (monospaced), with no further interpretation within
//   *bold*         -- bold
//   _italic_       -- italic
//   __underline__  -- underlined
//   ~~struck~~     -- strikethrough
//   ##highlight##  -- highlighted
//
parseMarkup = function(markup)
	result = []
	maxi = markup.len - 1
	i = -1
	startIndex = 0
	curStyle = new StyleRun
	while i < maxi
		i = i + 1
		c = markup[i]
		if "`*_~#\".indexOf(c) == null then continue
		if curStyle.code and c != "`" then continue // (ignore markup inside code blocks)
		if (c == "_" or c == "~" or c == "#") and i < maxi and markup[i+1] == c then
			c = c+c	// detect double markup chars __, ~~, and ##
		end if		
		if c == "\" then
			// skip the backslash and ignore the next char IF it is a markup char
			if "`*_~#".indexOf(nextc) != null then
				print "Skipping at " + i
				markup = markup[:i] + markup[i+1:]
				maxi = maxi - 1
				continue
			end if
		else if c == "`" then
			if startIndex < i then
				result.push StyleRun.make(markup[startIndex:i], curStyle)
			end if
			curStyle.code = not curStyle.code
		else if c == "*" then
			if startIndex < i then
				result.push StyleRun.make(markup[startIndex:i], curStyle)
			end if
			curStyle.bold = not curStyle.bold
		else if c == "_" then
			if startIndex < i then
				result.push StyleRun.make(markup[startIndex:i], curStyle)
			end if
			curStyle.italic = not curStyle.italic
		else if c == "__" then
			if startIndex < i then
				result.push StyleRun.make(markup[startIndex:i], curStyle)
			end if
			curStyle.underline = not curStyle.underline
		else if c == "~~" then
			if startIndex < i then
				result.push StyleRun.make(markup[startIndex:i], curStyle)
			end if
			curStyle.strikethrough = not curStyle.strikethrough
		else if c == "##" then
			if startIndex < i then
				result.push StyleRun.make(markup[startIndex:i], curStyle)
			end if
			curStyle.highlight = not curStyle.highlight
		end if
		startIndex = i + c.len
		i = i + c.len - 1
	end while
	if startIndex < markup.len then
		result.push StyleRun.make(markup[startIndex:], curStyle)
	end if
	return result
end function

// parseHTML: parses a very *minimial* subset of HTML, and returns it as 
// a list of StyleRuns.  Supports the following tags:
//
//   <code>...</code> -- code (monospaced), with no further interpretation within
//   <b>...</b>       -- bold
//   <i>...</i>       -- italic
//   <u>...</u>       -- underlined
//   <s>...</s>       -- strikethrough
//   <mark>...</mark> -- highlighted
//
parseHTML = function(html)
	result = []
	maxi = html.len - 1
	i = -1
	startIndex = 0
	curStyle = new StyleRun
	while i < maxi
		i = i + 1
		c = html[i]
		if c != "<" then continue
		endPos = html.indexOf(">", i+1)
		if endPos == null then continue
		tag = html[i+1:endPos]
		if curStyle.code and tag != "/code" then continue // (ignore tags inside code blocks)
		if startIndex < i then
			result.push StyleRun.make(replaceEntities(html[startIndex:i]), curStyle)
		end if
		if tag == "code" then; curStyle.code = true
		else if tag == "/code" then; curStyle.code = false
		else if tag == "b" then; curStyle.bold = true
		else if tag == "/b" then; curStyle.bold = false
		else if tag == "i" then; curStyle.italic = true
		else if tag == "/i" then; curStyle.italic = false
		else if tag == "u" then; curStyle.underline = true
		else if tag == "/u" then; curStyle.underline = false
		else if tag == "s" then; curStyle.strikethrough = true
		else if tag == "/s" then; curStyle.strikethrough = false
		else if tag == "mark" then; curStyle.highlight = true
		else if tag == "/mark" then; curStyle.highlight = false
		end if
		startIndex = i + tag.len + 2
		i = i + tag.len + 1
	end while
	if startIndex < html.len then
		result.push StyleRun.make(replaceEntities(html[startIndex:]), curStyle)
	end if
	return result
end function

// Helper function to replace a subset of HTML entities in a string:
//		&lt;	--> 	<
//		&gt;	--> 	>
//		&amp;	--> 	&
replaceEntities = function(text)
	text = text.replace("&lt;", "<")
	text = text.replace("&gt;", ">")
	text = text.replace("&amp;", "&")
	return text
end function

//-----------------------------------------------------------------
// Printer: base class for the printers below; responsible for
// printing a string (interpreted as markup) or a list of StyleRuns.
Printer = {}
Printer._name = "Printer"
Printer.wrapAt = 960	// X position at which to wrap; units vary with subclass
Printer.wrapTo = 0		// X position to wrap to; again, units vary
Printer.x = 0			// current X position (to print at next)
Printer.y = 0			// same for Y

// Main entry point: print the given content with word-wrap and style.
// May be given a list of StyleRuns, or a string which is assumed to
// be in Markup format.  See also printPlainText and printHTML.
Printer.print = function(content, x=null, y=null, wrapAt=null, wrapTo=null)
	if content isa string then content = parseMarkup(content)
	if x != null then self.x = x
	if y != null then self.y = y
	if wrapAt != null then self.wrapAt = wrapAt
	if wrapTo != null then self.wrapTo = wrapTo else self.wrapTo = x
	self.printStyleRuns content
end function

Printer.printStyleRuns = function(runs)
	// Subclasses must override this to do the actual printing:
	print "Printer subclass must override printStyleRuns"
	exit
end function

Printer.printPlainText = function(text, x=null, y=null, wrapAt=null, wrapTo=null)
	runs = [StyleRun.make(text)]
	self.print text, x, y, wrapAt, wrapTo
end function

Printer.printHTML = function(html, x=null, y=null, wrapAt=null, wrapTo=null)
	self.print parseHTML(html), x, y, wrapAt, wrapTo
end function

//-----------------------------------------------------------------
// TextPrinter: prints using a Text display.  All units are in
// text columns and rows.
TextPrinter = new Printer
TextPrinter._name = "TextPrinter"
TextPrinter.wrapAt = 68
TextPrinter.color = {}
TextPrinter.color.normal = null			// (null: use text.color at the time of printing)
TextPrinter.color.normalBack = null		// (null: use text.backColor)
TextPrinter.color.code = color.teal
TextPrinter.color.bold = color.yellow
TextPrinter.color.italic = color.pink
TextPrinter.color.underline = color.blue
TextPrinter.color.strikethrough = color.gray
TextPrinter.color.highlight = null
TextPrinter.color.highlightBack = color.yellow

// Apply the given style to the text display.
// Feel free to override this for custom purposes!
TextPrinter.applyStyle = function(style)
	self.prevColor = text.color
	self.prevBack = text.backColor
	if style.highlight then
		if self.color.highlightBack then text.backColor = self.color.highlightBack
	else
		if self.color.normalBack then text.backColor = self.color.normalBack
	end if
	c = null
	if style.bold then
		if c == null then c = self.color.bold else c = color.lerp(c, self.color.bold, 0.5)
	end if
	if style.italic then
		if c == null then c = self.color.italic else c = color.lerp(c, self.color.italic, 0.5)
	end if
	if style.underline then
		if c == null then c = self.color.underline else c = color.lerp(c, self.color.underline, 0.5)
	end if
	if style.strikethrough then
		if c == null then c = self.color.strikethrough else c = color.lerp(c, self.color.strikethrough, 0.5)
	end if
	if style.highlight then
		if c == null then c = self.color.highlight else c = color.lerp(c, self.color.highlight, 0.5)
	end if
	if c == null then c = self.color.normal
	if c then text.color = c
end function

// Restore the previous text colors.
TextPrinter.restore = function
	text.color = self.prevColor
	text.backColor = self.prevBack
end function

// Cut the text of the given style run to fit within the given width,
// on a word boundary if possible.  Return the left part; update 
// styleRun.text to be the right part.  If we can't fit, then return
// "" unless forceCut is true.
TextPrinter.cutToFit = function(styleRun, width, forceCut=false)
	i = width
	while i > 0
		if styleRun.text[i] <= " " then
			result = styleRun.text[:i]
			styleRun.text = styleRun.text[i:].trimLeft
			return result
		end if
		i = i - 1
	end while
	if not forceCut then
		styleRun.text = styleRun.text.trimLeft
		return ""
	end if
	result = styleRun.text[:width]
	styleRun.text = styleRun.text[width:].trimLeft
	return result
end function

// Print the given StyleRuns.
TextPrinter.printStyleRuns = function(runs)
	text.column = self.x
	text.row = self.y
	if self.wrapTo == null then self.wrapTo = text.column
	for styleRun in runs
		self.applyStyle styleRun
		while self.wrapAt - text.column < styleRun.text.len
			partialText = self.cutToFit(styleRun, 
			  self.wrapAt - text.column, text.column <= self.wrapTo)
			text.print partialText
			text.column = self.wrapTo
			self.y -= 1; text.row = self.y
		end while
		text.print styleRun.text, ""
		self.restore
	end for
	text.print
	self.x = self.wrapTo
	self.y = text.row
end function

//-----------------------------------------------------------------
// GfxPrinter: Prints to a PixelDisplay (gfx by default).  Always prints in the
// current color, but you can define the color to use for the highlight background.
GfxPrinter = new Printer
GfxPrinter._name = "GfxPrinter"
GfxPrinter.highlightBackColor = color.yellow
GfxPrinter.font = "normal"
GfxPrinter.display = null	// if null, uses current gfx at time of printing

GfxPrinter.underlineOffset = {}
GfxPrinter.underlineOffset.small = -1
GfxPrinter.underlineOffset.medium = -1
GfxPrinter.underlineOffset.normal = -1
GfxPrinter.underlineOffset.large = -3

GfxPrinter.strikeOffset = {}
GfxPrinter.strikeOffset.small = 6
GfxPrinter.strikeOffset.medium = 8
GfxPrinter.strikeOffset.normal = 10
GfxPrinter.strikeOffset.large = 14

GfxPrinter.lineHeight = {}
GfxPrinter.lineHeight.small = 14
GfxPrinter.lineHeight.medium = 20
GfxPrinter.lineHeight.normal = 24
GfxPrinter.lineHeight.large = 32

GfxPrinter.width = function(text)
	if self.font == "large" then return text.len * 20
	if self.font == "medium" then return text.len * 11
	if self.font == "small" then return text.len * 8
	return text.len * 14
end function

// Cut the text of the given style run to fit within the given width,
// on a word boundary if possible.  Return the left part; update 
// styleRun.text to be the right part.  If we can't fit, then return
// "" unless forceCut is true.
GfxPrinter.cutToFit = function(styleRun, width, forceCut=false)
	charWidth = floor(width / self.width("m"))	// find character position at which to cut
	i = charWidth
	while i > 0
		if styleRun.text[i] <= " " then
			result = styleRun.text[:i]
			styleRun.text = styleRun.text[i:].trimLeft
			return result
		end if
		i = i - 1
	end while
	if not forceCut then
		styleRun.text = styleRun.text.trimLeft
		return ""
	end if
	result = styleRun.text[:charWidth]
	styleRun.text = styleRun.text[charWidth:].trimLeft
	return result
end function

// Print a single line of text in a single style, at the given
// x and y coordinates.  Return the new x coordinate after printing.
GfxPrinter.printOneRun = function(style, text, x, y)
	g = self.display
	if g == null then g = gfx
	x1 = x + self.width(text) + 2 + 2 * (self.font == "large")
	if style.highlight then
		h = self.lineHeight[self.font]
		y0 = y - floor(h * 0.08)
		y1 = y0 + h
		gfx.fillRect x-1, y0, x1 - x + 2, y1 - y0, self.highlightBackColor
	end if
	g.print text, x, y, gfx.color, self.font
	if style.underline then
		ty = y + self.underlineOffset[self.font]
		gfx.line x, ty, x1, ty
	end if
	if style.strikethrough then
		ty = y + self.strikeOffset[self.font]
		gfx.line x-1, ty, x1+1, ty
	end if
	if style.bold then gfx.print text, x+1, y-1, gfx.color, self.font
	if style.italic then
		h = self.lineHeight[self.font]
		y0 = y - floor(h * 0.12)
		y1 = y0 + h
		h4 = ceil(h * 0.25)
		img = gfx.getImage(x+2, y0, x1 - x - 2, h4)
		gfx.drawImage img, x, y0
		img = gfx.getImage(x+1, y0+h4, x1 - x - 1, h4)
		gfx.drawImage img, x, y0+h4
		img = gfx.getImage(x, y1-h4, x1 - x - 1, h4)
		gfx.drawImage img, x + 1, y1-h4
	end if
	return x1	
end function

// Print the given StyleRuns.
GfxPrinter.printStyleRuns = function(runs)
	for styleRun in runs
		while self.wrapAt - self.x < self.width(styleRun.text)
			partialText = self.cutToFit(styleRun, self.wrapAt - self.x, self.x <= self.wrapTo)
			self.printOneRun styleRun, partialText, self.x, self.y
			self.x = self.wrapTo
			self.y -= self.lineHeight[self.font]
		end while
		self.x = self.printOneRun(styleRun, styleRun.text, self.x, self.y)
	end for
	self.x = self.wrapTo
	self.y -= self.lineHeight[self.font]
end function

//-----------------------------------------------------------------
// BmfPrinter: prints using BMF fonts.
BmfPrinter = new Printer
BmfPrinter._name = "BmfPrinter"
BmfPrinter.highlightBackColor = color.yellow
BmfPrinter.font = null				// required (a BMF font)
BmfPrinter.boldFont = null			// optional
BmfPrinter.italicFont = null		// optional
BmfPrinter.boldItalicFont = null	// also optional
BmfPrinter.display = null	// if null, uses current gfx at time of printing

// Cut the text of the given style run to fit within the given width,
// on a word boundary if possible.  Return the left part; update 
// styleRun.text to be the right part.  If we can't fit, then return
// "" unless forceCut is true.
BmfPrinter.cutToFit = function(styleRun, width, forceCut=false)
	charWidth = self.font.lenToFit(styleRun.text, width)
	i = charWidth
	while i > 0
		if i == styleRun.text.len or styleRun.text[i] <= " " then
			result = styleRun.text[:i]
			styleRun.text = styleRun.text[i:].trimLeft
			return result
		end if
		i = i - 1
	end while
	if not forceCut then
		styleRun.text = styleRun.text.trimLeft
		return ""
	end if
	result = styleRun.text[:charWidth]
	styleRun.text = styleRun.text[charWidth:].trimLeft
	return result
end function

// Print a single line of text in a single style, at the given
// x and y coordinates.  Return the new x coordinate after printing.
// If dryRun is true, don't actually print; just calculate.
BmfPrinter.printOneRun = function(style, text, x, y, dryRun=false)
	g = self.display
	if g == null then g = gfx
	font = self.font
	if style.bold and style.italic and self.boldItalicFont then
		font = self.boldItalicFont
	else if style.bold and self.boldFont then
		font = self.boldFont
	else if style.italic and self.italicFont then
		font = self.italicFont
	end if
	
	x1 = x + font.width(text) + 2	// ToDo: figure correct fudge factor
	if dryRun then return x1
	if style.highlight then
		h = self.font.lineHeight
		y0 = y - self.font.sizeUnder
		y1 = y - self.font.sizeOver
		gfx.fillRect x-1, y0, x1 - x + 2, y1 - y0, self.highlightBackColor
	end if
	font.print text, x, y, 1, gfx.color
	if style.underline then
		ty = y - ceil(self.font.sizeUnder/2)
		gfx.line x, ty, x1, ty
	end if
	if style.strikethrough then
		ty = y - floor(self.font.sizeOver * 0.35)
		gfx.line x-1, ty, x1+1, ty
	end if
	if style.bold and not self.boldFont then
		// fake bold by drawing again with a slight offset
		font.print text, x+1, y-1, 1, gfx.color
	end if
	if style.italic and not self.italicFont then
		// Fake italics by pixel-shifting.
		h = self.font.lineHeight
		y0 = y - floor(h * 0.12)
		y1 = y0 + h
		h4 = ceil(h * 0.25)
		img = gfx.getImage(x+2, y0, x1 - x - 2, h4)
		gfx.drawImage img, x, y0
		img = gfx.getImage(x+1, y0+h4, x1 - x - 1, h4)
		gfx.drawImage img, x, y0+h4
		img = gfx.getImage(x, y1-h4, x1 - x - 1, h4)
		gfx.drawImage img, x + 1, y1-h4
	end if
	return x1	
end function

// Print the given StyleRuns.
BmfPrinter.printStyleRuns = function(runs)
	for styleRun in runs
		hardlines = styleRun.text.split(char(10))
		for i in hardlines.indexes
			styleLine = new styleRun
			styleLine.text = hardlines[i]
			while self.wrapAt - self.x < self.font.width(styleLine.text)
				partialText = self.cutToFit(styleLine, self.wrapAt - self.x, self.x <= self.wrapTo)
				self.printOneRun styleRun, partialText, self.x, self.y
				self.x = self.wrapTo
				self.y -= self.font.lineHeight
			end while
			self.x = self.printOneRun(styleRun, styleLine.text, self.x, self.y)
			if i < hardlines.len-1 then
				self.x = self.wrapTo
				self.y -= self.font.lineHeight
			end if
		end for
	end for
	self.x = self.wrapTo
	self.y -= self.font.lineHeight
end function

BmfPrinter.calcHeight = function(markup, x, wrapAt=null, wrapTo=null)
	if wrapAt == null then wrapAt = self.wrapAt
	if wrapTo == null then wrapTo = x
	y = 0
	top = y - self.font.sizeOver
	for styleRun in parseMarkup(markup)
		while wrapAt - x < self.font.width(styleRun.text)
			partialText = self.cutToFit(styleRun, wrapAt - x, x <= wrapTo)
			x = wrapTo
			y = y - self.font.lineHeight
		end while
		x = self.printOneRun(styleRun, styleRun.text, x, y, true)
	end for
	bottom = y - self.font.sizeUnder
	return top - bottom
end function


//-----------------------------------------------------------------
runDemo = function
	clear; text.delimiter = char(13)
	text.color = color.silver
	msg1 = "Hello *there* world, this is _italic_, but _*this*_ and *_this_* are both!"
	msg2 = "##Highlight## this, __underline__ that, and ~~strike this out~~."
	msg3 = "This is a ##much## longer message.  _So_ long, in fact, that we will need " +
	"to do *word wrap*, and it's __vital__ that we do this ~~fast~~ correctly. " +
	"Even with _*bold italic*_ text!"
	outer.tp = new TextPrinter
	tp.y = 25
	tp.print msg1
	tp.print msg2
	tp.print msg3, 4, null, 64, 4
	gfx.color = color.silver
	outer.gp = new GfxPrinter
	gp.wrapTo = 10
	y = 450
	for f in ["small", "medium", "normal", "large"]
		gp.font = f
		gp.print msg1, 10, y
		y -= gp.lineHeight[f] * 2
		//gp.print msg2, 10, y
		//y -= gp.lineHeight[f] * 3
	end for
	bp = new BmfPrinter
	bp.font = bmfFonts.Font.load("/sys/fonts/Arial14.bmf")
	bp.boldFont = bmfFonts.Font.load("/sys/fonts/Arial14Bold.bmf")
	bp.print msg3, 10, 140
	runs = parseHTML("Now <i>this</i> was parsed from <b>HTML</b>.  It supports " +
	"<u>all</u> the <code>same</code> styles as markup syntax, but uses &lt; and " +
	"&gt; a <i>lot <b>more</b></i>!")
	gp.font = "normal"
	gp.print runs, 10, 80
end function

if locals == globals then runDemo


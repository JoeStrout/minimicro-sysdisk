_EOL = char(13)
_TAB = char(9)

_printMark = function(s, altColor="#8888FF")
	colors = [text.color, altColor]
	which = 0
	oldDelim = text.delimiter
	text.delimiter = ""
	while len(s)
		pos = s.indexOf("`")
		if pos == null then
			print s
			break
		end if
		print s[:pos]
		which = not which
		text.color = colors[which]
		s = s[pos+1:]
	end while
	text.color = colors[0]
	text.delimiter = oldDelim
	print
end function
	
help = function(topic)
	if topic == "" or topic == null then topic = "_default"
	if topic == "graphics" then topic = "gfx"
	lines = _fileReadLines("/sys/help/" + topic + ".txt")
	if not lines then
		_printMark "No help available for `""" + topic + """`."
		print "Help topics:"
		text.delimiter = ""
		for topic in file.children("/sys/help").sort
			if topic[0] == "_" then continue
			topic = topic - ".txt"
			if text.column > 44 then print _EOL
			print """" + topic + """" + " " * (20 - topic.len)
		end for
		text.delimiter = _EOL
		print
	else
		for line in lines
			_printMark line
		end for
	end if
end function

usr = function
	_printMark "Remember, you `must` use quotation marks around file paths.", "#8080FF"
	_printMark "   Wrong: `cd /usr`", "#800000"
	_printMark "   Right: `cd ""/usr""`"
end function
sys = function
	_printMark "Remember, you `must` use quotation marks around file paths.", "#8080FF"
	_printMark "   Wrong: `cd /sys`", "#800000"
	_printMark "   Right: `cd ""/sys""`"
end function

gfx = display(5)
text = display(3)

// Convert a 0-255 number to a 2-digit hex string.
// (Used by some of the color methods below.)
hex2 = function(val)
	digits = "0123456789ABCDEF"
	val = floor(val)
	if val < 0 then return "00"
	if val >= 255 then return "FF"
	return digits[val / 16] + digits[val % 16]
end function

// HexVal: convert a hexadecimal string to a number.
hexVal = function(hexstr)
	result = 0
	digits = "0123456789ABCDEF"
	for c in hexstr
		cval = digits.indexOf(c.upper)
		if cval < 0 then break
		result = result * 16 + cval
	end for
	return result
end function

color = {}
color.clear     = "#00000000"
color.black 	= "#000000"
color.white		= "#FFFFFF"
color.gray		= "#808080"
color.silver	= "#C0C0C0"
color.maroon	= "#800000"
color.red		= "#FF0000"
color.olive		= "#808000"
color.yellow	= "#FFFF00"
color.orange	= "#FF8000"
color.green		= "#008000"
color.lime		= "#00FF00"
color.teal		= "#008080"
color.aqua		= "#00FFFF"
color.navy		= "#000080"
color.blue		= "#0000FF"
color.purple	= "#800080"
color.fuchsia	= "#FF00FF"
color.brown		= "#996633"
color.pink		= "#FF8080"
color.rgb = function(r, g, b)
	return "#" + hex2(r) + hex2(g) + hex2(b)
end function
color.rgba = function(r, g, b, a)
	return "#" + hex2(r) + hex2(g) + hex2(b) + hex2(a)
end function
color.hsv = function(h, s, v, a=255)
	return _HSVAtoColor([h, s, v, a])
end function
color.lerp = function(colorA, colorB, t=0.5)
	return _lerpColor(colorA, colorB, t)
end function
color.toList = function(colorString)
	return _colorToRGBA(colorString)
end function
color.fromList = function(rgbaList)
	return _RGBAtoColor(rgbaList)
end function
color.toListHSV = function(colorString)
	return _colorToHSVA(colorString)
end function
color.fromListHSV = function(hsvaList)
	return _HSVAtoColor(hsvaList)
end function

prepareKeyboard = function
	f = file.open("/sys/data/keyLayout.grfon", "r")
	data = f.read
	f.close
	import "grfon"
	key.standardLayout = grfon.parse(data)
	key.layout = key.standardLayout
end function
prepareKeyboard

pageThrough = function(lines)
	text.delimiter = ""
	printed = 0
	for i in range(0, lines.len-1)
		line = "" + lines[i]
		print line[:67]
		if line.len > 67 then text.setCell 67,text.row, line[67]
		print _EOL
		printed = printed + 1
		if printed > 24 and i+1 < lines.len then
			text.inverse = true
			print "[" + (lines.len - i - 1) + " more]"
			text.inverse = false
			done = false
			while not done
				k = key.get
				ikey = code(k)
				if ikey == 27 or k == "q" or k == "Q" then done = true
				if ikey == 10 or ikey == 13 or ikey == 3 or k == " " then break
				yield
			end while
			text.column = 0
			print " " * 32
			text.column = 0
			if done then break
			printed = 0
		end if
	end for
	text.delimiter = _EOL
end function

cd = function(path="")
	if not path then path = env.home
	dirInfo = file.info(path)
	if dirInfo isa string then
		print dirInfo + ": " + path
	else if not dirInfo or not dirInfo.isDirectory then
		print "No such directory: " + path
	else
		file.setdir path
	end if
end function

dir = function(path=".")
	spaces = " "*80
	
	dirInfo = file.info(path)
	if dirInfo == null then
		print "Invalid path"
		return
	end if

	lines = [dirInfo.path + " : "]

	files = file.children(dirInfo.path)
	if files.len == 0 then
		print lines[0]
		print "  (Directory empty)"
		return
	end if

	files.sort
	for i in range(0, files.len-1)
		finfo = file.info(file.child(dirInfo.path,files[i]))
		if finfo == null then
			lines.push "file.info failed on: " + file.child(path, files[i])
			continue
		end if
		namecol = (files[i]+spaces)[:32]
		sizecol = (spaces+finfo.size)[-8:]
		if finfo.isDirectory then sizecol = "     DIR"
		lines.push "  " + namecol + sizecol + "  " + finfo.date
	end for
	pageThrough lines
end function

_apiClassNames = {
	Image:"Image",
	Sprite:"Sprite",
	Display:"Display",
	TextDisplay:"TextDisplay",
	SpriteDisplay:"SpriteDisplay",
	PixelDisplay:"PixelDisplay",
	SolidColorDisplay:"SolidColorDisplay",
	TileDisplay:"TileDisplay",
	Sound:"Sound" }

mapName = function(m)
	if not m isa map then return null
	if m.hasIndex("_name") then return m._name
	if _apiClassNames.hasIndex(m) then return _apiClassNames[m]
	for kv in globals
		if refEquals(@kv.value, m) then return @kv.key
	end for
	return null
end function

list._refIndexOf = function(item)
	i = 0; selfLen = self.len
	while i < selfLen
		if refEquals(self[i], @item) then return i
		i += 1
	end while
	return null
end function

pprintToList = function(outList, obj, prefix="", indent=0, suffix="", alreadySeen=null)
	s = str(@obj)
	if @obj == null then s = "null"
	if @obj isa funcRef then s = "function" + s[8:]
	if s.len + prefix.len + indent < 65 then
		outList.push " "*indent + prefix + s + suffix
		return
	end if
	if indent > 32 then
		outList.push " "*indent + prefix + "..." + suffix
		return
	end if
	if alreadySeen == null then alreadySeen = []
	if @obj isa list then
		outList.push " "*indent + prefix + "["
		if alreadySeen._refIndexOf(@obj) != null then
			outList[-1] += "...]"
		else
			alreadySeen.push @obj
			for i in obj.indexes
				pprintToList outList, obj[i], "", indent + 4, "," * (i < obj.len-1), alreadySeen
			end for
			outList.push " "*indent + "]" + suffix
		end if
	else if @obj isa map then
		outList.push " "*indent + prefix + "{"
		if alreadySeen._refIndexOf(@obj) != null then
			outList[-1] += "...}"
		else
			alreadySeen.push @obj
			entries = []; for kv in obj; entries.push kv; end for
			for i in entries.indexes
				kv = entries[i]
				value = null
				if @kv.value isa map then value = mapName(@kv.value)
				if value == null then value = @kv.value
				pprintToList outList, @value, @kv.key + ": ", indent+4, "," * (i < entries.len-1), alreadySeen
			end for
			outList.push " "*indent + "}" + suffix
		end if
	else
		outList.push " "*indent + prefix + s + suffix
	end if
end function

pprint = function(obj)
	lines = []
	pprintToList lines, obj
	pageThrough lines
end function

_viewImage = function(pic)
	if not pic then
		print "Unable to read image: " + path
		return
	end if
	prevDisp = display(0)
	g = new PixelDisplay
	g.install 0
	g.clear "#00000088"
	g.drawImage pic, 480-pic.width/2, 320-pic.height/2
	for dispLayer in range(0, 7)
		d = display(dispLayer)
		if d.mode != displayMode.tile then continue
		if d.tileSet != pic then continue
		// Draw the tile numbers!
		if d.tileSetTileSize isa number then
			tx = d.tileSetTileSize; ty = d.tileSetTileSize
		else if d.tileSetTileSize isa list and len(d.tileSetTileSize == 2) then
			tx = d.tileSetTileSize[0]; ty = d.tileSetTileSize[1]
		else
			continue
		end if
		columns = floor(pic.width / tx)
		for col in range(0, columns - 1)
			for row in range(0, floor(pic.height / ty) - 1)
				x = 480-pic.width/2 + tx * col
				y = 320+pic.height/2 - ty * (row + 1)
				g.drawRect x, y, tx, ty, "#FF00FF88"
				n = row * columns + col
				x += tx*0.2; y += ty*0.2
				g.print n, x+1, y-1, color.black, "small"
				g.print n, x, y, color.fuchsia, "small"				
			end for
		end for
		break
	end for
	print pic.width + " x " + pic.height + " image"
	text.delimiter = ""
	text.inverse = true
	print "[Press any key]"
	text.inverse = false
	key.get
	text.column = 0
	print " " * 32
	g.clear
	prevDisp.install 0
	display(0).mode = prevDisp.mode
	text.delimiter = _EOL		
end function

findFile = function
	import "textUtil"
	dlog = textUtil.FileDialog.make
	hit = dlog.show
	if hit == dlog.okBtn then return dlog.selection
end function

view = function(path)
	if not path then
		print "Image or file name/path is required"
		return
	end if
	if path isa Image then
		_viewImage path
		return
	end if
	if not path isa string then
		print "Image or file name/path is required"
		return
	end if
	info = file.info(path)
	if info == null then
		print "File not found (" + path + ")"
		return
	end if
	if path[-4:] == ".png" or path[-4:] == ".jpg" or path[-5:] == ".jpeg" then
		_viewImage file.loadImage(path)
	else if path[-4:] == ".txt" or path[-3:] == ".ms" or path[-4:] == ".tsv" or path[-5:] == ".json" or path[-3:] == ".md" then
		// View a text file or MiniScript source file
		lines = file.readLines(path)
		if lines isa string then
			print lines  // (really, an error message)
		else
			// Wrap each line to 68 columns.
			i = 0
			while i < lines.len
				lines[i] = lines[i].replace(_TAB, "    ")
				if lines[i].len > 68 then
					lines.insert i+1, lines[i][68:]
					lines[i] = lines[i][:68]
				end if
				i = i + 1
			end while
			pageThrough lines
		end if
	else if path[-4:] == ".wav" or path[-4:] == ".ogg" then
		// Play a sound
		snd = file.loadSound(path)
		if snd == null then
			print "Unable to load sound: " + path
		else
			snd.play
		end if
	else
		print "No viewer available for this file type"
	end if
end function

_sourceFile = null
_source = []
_sourceSaved = true

// Check whether it's safe to load a file (i.e., we won't
// lose any unsaved changes to the current program).
// Returns true if safe, false if not safe (so don't do it!).
_checkSafeToLoad = function
	if _sourceSaved then return true
	if len(_source) == 0 or _source == [""] then return true

	// OK, looks worrisome, but one last check: 
	// let's see if the file on disk matches what's in memory.
	if _sourceFile then
		path = _sourceFile
		if len(path) < 3 or path[-3:] != ".ms" then path += ".ms"
		if path[0] != "/" then path = file.child(file.curdir, path)
		lines = file.readLines(_sourceFile)
		if lines == _source then return true	// exact same!
	end if

	print "You have unsaved changes to ", ""
	if _sourceFile then
		print _sourceFile
	else
		print "the program in memory."
	end if
	_printMark "Please `save` or `reset` before loading a file."
	return false
end function

load = function(path, checkIfSafe=true)
	if not path then
		print "file name or path is required"
		return null
	end if
	if checkIfSafe and not _checkSafeToLoad then return
	if len(path) < 3 or path[-3:] != ".ms" then path += ".ms"
	if path[0] != "/" then path = file.child(file.curdir, path)
	lines = file.readLines(path)
	if lines == null then
		print "Unable to read " + path
		return null
	else
		globals._source = lines
		globals._sourceFile = path
		globals._sourceSaved = true
		return lines.len + " line" + ("s" * (lines.len != 1)) + " loaded from " + path
	end if
	return null
end function

edit = function(path)
	if path then
		if not _checkSafeToLoad then return
		if load(path, false) == null then return
	end if
	_edit
end function

save = function(path)
	if path == null then path = _sourceFile
	if not path then
		return "filename not specified; unable to save"
	end if
	if path[-3:] != ".ms" then path = path + ".ms"
	if path[0] != "/" then path = file.child(file.curdir, path)
	err = file.writeLines(path, _source)
	if err == null then
		globals._sourceFile = path
		globals._sourceSaved = true
		print _source.len + " line" + ("s" * (_source.len != 1)) + " saved to " + path
	else
		return err
	end if
end function

run = function(path)
	if path then
		if not _checkSafeToLoad then return
		if load(path, false) == null then return
	end if
	_run
end function

source = function(fromLine=0, toLine=-1)
	if not globals.hasIndex("_source") or not _source then return
	if toLine == -1 then toLine = _source.len-1
	return _source[fromLine:toLine+1].join(_EOL)
end function

clear = function
	// Clear and reset all displays.
	for i in [0,1,2,6]
		display(i).mode = displayMode.off
	end for
	display(3).mode = displayMode.text
	display(3).clear
	display(4).mode = displayMode.sprite
	display(4).clear
	display(5).mode = displayMode.pixel
	display(5).clear "#00000D", 960, 640
	display(7).mode = displayMode.solidColor
	display(7).color = "#000000"
	globals.text = display(3)
	globals.gfx = display(5)
	text.row = 25
end function

tip = function
	tips = _fileReadLines("/sys/tips.txt")
	return tips[rnd * tips.len].replace("\n", _EOL)
end function

desktop = function;	load "/sys/demo/desktop"; run; end function
lcars = function;	load "/sys/demo/lcars"; run; end function
demos = function;	load "/sys/demo/demos"; run; end function

_saveGlobals = function
	globals._savedGlobals = {} + globals
end function

_restoreGlobals = function
	for key in globals.indexes
		if key[0] != "_" then globals.remove(key)
	end for
	for key in _savedGlobals.indexes
		if key[0] != "_" then globals[key] = _savedGlobals[key]
	end for
end function

reset = function
	Sound.stopAll
	globals._source = []
	globals._sourceFile = null
	_restoreGlobals
	env.importPaths = [".", "/usr/lib", "/sys/lib"]
	print "Program source cleared and reset"
	return null
end function

_saveGlobals

_bootOpt = function(key, default=false)
	if not env.bootOpts.hasIndex(key) then return default
	return env.bootOpts[key]
end function

welcome = function
	clear
	text.color = color.gray
	text.delimiter = ""
	print "Welcome to "
	text.color = "#8888FF"
	print "Mini Micro"
	text.color = color.gray
	text.delimiter = _EOL
	print "!"
	isPreview = version.host.indexOf("PREVIEW") != null
	text.color = "#444444" * (not isPreview) + "#FFFF44" * isPreview
	hostVers = "(version " + version.host + ", " + version.buildDate + ")"
	print hostVers
	text.color = color.gray
	_printMark tip
	print
	if isPreview then
		text.color = "#FFFF44"
		print "This is a PREVIEW RELEASE of Mini Micro."
		print "Some things may be broken; some demos are incomplete."
		print "Use at your own risk.  And share what you find.  :)"
		text.color = color.gray
		print
	end if
	_printMark "Enter `help` for help."
	text.color = color.orange
	print
end function

if _bootOpt("startupChime", true) then _startupChime
if _bootOpt("welcome", true) then welcome else clear

_printMark = function(s, altColor="#008000")
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
			if text.column > 44 then print char(13)
			print """" + topic + """" + " " * (20 - topic.len)
		end for
		text.delimiter = char(13)
		print
	else
		for line in lines
			_printMark line
		end for
	end if
end function

usr = function()
	_printMark "Remember, you `must` use quotation marks around file paths.", "#8080FF"
	_printMark "   Wrong: `cd /usr`", "#800000"
	_printMark "   Right: `cd ""/usr""`"
end function
sys = function()
	_printMark "Remember, you `must` use quotation marks around file paths.", "#8080FF"
	_printMark "   Wrong: `cd /sys`", "#800000"
	_printMark "   Right: `cd ""/sys""`"
end function


gfx = display(5)
text = display(3)

// Convert a 0-255 number to a 2-digit hex string
hex2 = function(val)
	result = 0
	digits = "0123456789ABCDEF"
	val = floor(val)
	if val < 0 then return "00"
	if val >= 255 then return "FF"
	return digits[val / 16] + digits[val % 16]
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
color.lerp = function(colorA, colorB, t=0.5)
	return _lerpColor(colorA, colorB, t)
end function
color.toList = function(colorString)
	return _colorToRGBA(colorString)
end function
color.fromList = function(rgbaList)
	return _RGBAtoColor(rgbaList)
end function

pageThrough = function(lines)
	text.delimiter = ""
	printed = 0
	for i in range(0, lines.len-1)
		line = "" + lines[i]
		print line[:67]
		if line.len > 67 then text.setCell 67,text.row, line[67]
		print char(13)
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
	text.delimiter = char(13)
end function

dir = function(path=".")
	spaces = " "*80
	if path == "/" then
		for p in ["/usr", "/usr2", "/sys"]
			if file.info(p) == null then continue
			print (p+spaces)[:39] + "DIR"
		end for
		return
	end if
	
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

_viewImage = function(pic)
	if not pic then
		print "Unable to read image: " + path
		return
	end if
	display(0).mode = displayMode.pixel
	display(0).clear "#00000088"
	display(0).drawImage pic, 480-pic.width/2, 320-pic.height/2
	print pic.width + " x " + pic.height + " image"
	text.delimiter = ""
	text.inverse = true
	print "[Press any key]"
	text.inverse = false
	key.get
	text.column = 0
	print " " * 32
	display(0).mode = displayMode.off
	text.delimiter = char(13)		
end function

view = function(path)
	if not path then
		print "file name or path is required"
		return
	end if
	if path isa Image then
		_viewImage path
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
				if lines[i].len > 68 then
					lines.insert i+1, lines[i][68:]
					lines[i] = lines[i][:68]
				end if
				i = i + 1
			end while
			pageThrough lines
		end if
	else if path[-4:] == ".wav" then
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
load = function(path)
	if not path then
		print "file name or path required"
		return
	end if
	if path[-3:] != ".ms" then path = path + ".ms"
	if path[0] != "/" then path = file.child(file.curdir, path)
	lines = file.readLines(path)
	if lines == null then
		print "Unable to read " + path
	else
		globals._source = lines
		globals._sourceFile = path
		print lines.len + " line" + ("s" * (lines.len != 1)) + " loaded from " + path
	end if
	return null
end function

save = function(path)
	if path == null then path = _sourceFile
	if not path then
		print "Filename not specified; unable to save"
		return
	end if
	if path[-3:] != ".ms" then path = path + ".ms"
	if path[0] != "/" then path = file.child(file.curdir, path)
	err = file.writeLines(path, _source)
	if err == null then
		globals._sourceFile = path
		print _source.len + " line" + ("s" * (_source.len != 1)) + " saved to " + path
	else
		return err
	end if
end function

source = function(fromLine=0, toLine=-1)
	if not globals.hasIndex("_source") or not _source then return
	if toLine == -1 then toLine = _source.len-1
	return _source[fromLine:toLine+1].join(char(13))
end function

clear = function()
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

_saveGlobals = function()
	globals._savedGlobals = {} + globals
end function

_restoreGlobals = function()
	for key in globals.indexes
		if key[0] != "_" then globals.remove(key)
	end for
	for key in _savedGlobals.indexes
		if key[0] != "_" then globals[key] = _savedGlobals[key]
	end for
end function

reset = function()
	Sound.stopAll
	globals._source = []
	globals._sourceFile = null
	_restoreGlobals
	env.importPaths = [".", "/usr/lib", "/sys/lib"]
	print("Program source cleared and reset")
	return null
end function

tip = function()
	tips = _fileReadLines("/sys/tips.txt")
	return tips[rnd * tips.len].replace("\n", char(13))
end function

_saveGlobals

_bootOpt = function(key, default=false)
	if not env.bootOpts.hasIndex(key) then return default
	return env.bootOpts[key]
end function

welcome = function()
	clear
	text.color = color.gray
	text.delimiter = ""
	print "Welcome to "
	text.color = "#8888FF"
	print "Mini Micro"
	text.color = color.gray
	text.delimiter = char(13)
	print "!"
	text.color = "#444444"
	print "(version " + version.host + ", " + version.buildDate + ")"
	text.color = color.gray
	_printMark tip
	print
	_printMark "Enter `help` for help."
	text.color = color.orange
	print
end function

if _bootOpt("startupChime", true) then _startupChime
if _bootOpt("welcome", true) then welcome else clear

// This is a shell program that presents a menu of selected
// other, making it easy to preview/run them.

// Make this program the shell (return here after running demo)
env.shell = "/sys/demo/demos.ms"

import "chars"
import "stringUtil"
import "textUtil"

simple = []
games = []
visual = []
other = []

//games.push "TD"
other.push "2dVis"
other.push "angles"

games.push "acey-deucey"
games.push "asteroids"
games.push "drumMachine"
games.push "flappyBat"
games.push "mochiBounce"
games.push "platformer"
games.push "quadris"
games.push "speedConquest"
games.push "textAdventure"
games.push "ticTacToe"
games.push "typing"
games.push "wumpusTrap"

simple.push "countdown"

visual.push "cardFlip"
visual.push "globe"
visual.push "road"
visual.push "stars"
visual.push "sunset"
visual.push "theMatrix"
visual.push "turtleDemo"

more = "(More...)"

allPrograms = simple + visual + other + games + [more]
selected = allPrograms[0]

text.delimiter = char(13)

button = function(caption)
	return chars.inverseOn + chars.buttonCapLeft + caption + 
		chars.buttonCapRight + chars.inverseOff
end function

drawList = function
	text.row = 25; text.column = 0
	for pgm in allPrograms
		print "  ", ""
		s = "  " + pgm.pad(15)
		text.inverse = (pgm == selected)
		print s
		text.inverse = false
	end for
end function

showMore = function
	gfx.clear
	textUtil.clearRect 20, 0, 48, 26, " "
	x = 23
	text.row = 23
	text.column = x; print "There are many more demos to be found"
	text.column = x; print "in the /sys/demo directory!"
	print
	text.column = x; print "To explore them:"
	print
	x += 2
	text.column = x; _printMark "1. Press `Esc` to exit to the command prompt"
	print
	text.column = x; _printMark "2. Enter `cd ""/sys/demo""`"
	print
	text.column = x; _printMark "3. Use `dir` to view the available other"
	print
	text.column = x; _printMark "4. `load` any program, e.g. `load ""pigDice""`"
	print
	text.column = x; _printMark "5. `run` to play the demo!"
	print
	text.column = x; _printMark "6. `edit` to view the code, or go to step 3"
	print
	x -= 2
	text.column = x; print "Key shortcuts in this launcher:"
	text.column = x; _printMark "  `Esc`: exit"
	text.column = x; _printMark "  ` A `: auto-run (""attract mode"")"
end function

drawProgram = function
	if selected == more then return showMore
	gfx.clear
	textUtil.clearRect 20, 2, 48, 24, " "
	path = "/sys/demo/" + selected + ".ms"
	src = file.readLines(path)
	y = 600
	x = 300
	gfx.print path, x, y, color.yellow, "large"
	y = y - 24
	for line in src
		if line.startsWith("//") then c = color.white else c = color.silver
		indent = 0
		while line and line[0] == char(9)
			indent = indent + 1
			line = line[1:]
		end while
		gfx.print line, x + indent * 24, y, c, "small"
		y = y - 16
		if y < 120 then
			gfx.print "...", x, y, color.blue, "small"
			y = y - 16
			break
		end if
	end for
	gfx.print "(" + src.len + " lines)", x, y, color.blue, "small"
end function

drawHelp = function
	oldColor = text.color
	text.color = "#444444"
	text.row = 1; text.column = 0
	print "Press " + button(chars.up) + "/" + button(chars.down) + " to select,"
	if selected != more then
		if env.device.platform.upper == "MACOS" then
			print button("Return"), ""
		else
			print button("Enter"), ""
		end if
		print " to run, ", ""
	end if
	print button("Esc") + " to exit" + " "*20, ""
	text.color = oldColor
end function

keySound = new Sound
keySound.init 0.05, 10, [1,0], Sound.noiseWave
spaceSound = new Sound
spaceSound.init 0.05, 8, [1,0], Sound.noiseWave; 0
returnSound = new Sound
returnSound.init 0.05, 5, [1,0], Sound.noiseWave; 0

printSlowly = function(s, eol=null)
	for c in s
		print c, chars.inverseOn + " " + chars.inverseOff + chars.backup
		if c == " " then spaceSound.play else keySound.play
		if key.available and key.get == char(27) then return false
		wait 0.1
	end for
	print " ", eol
	returnSound.play
	return true
end function

showCommand = function(cmd)
	text.color = color.gray; print "]", ""
	text.color = color.orange
	if not printSlowly(cmd) then return false
	for i in range(9)
		wait 0.1
		if key.available and key.get == char(27) then return false
	end for
	return true
end function

runProgram = function(program)
	if selected == more then return
	path = "/sys/demo/" + program
	textUtil.clearRect 0, 0, 60, 2, " "
	text.row = 2; text.column = 0
	if not showCommand("load """ + path + """") or
	   not showCommand("run") then return false
	load path; clear; run
	return true
end function

autorunNext = function
	pgms = ["globe", "sunset", "quadris", "theMatrix", "turtleDemo", "asteroids"]
	idx = pgms.indexOf(env.autorun)
	if idx == null then idx = 0 else idx = (idx + 1) % pgms.len
	env.autorun = pgms[idx]
	globals.selected = ""
	if not runProgram(pgms[idx]) then
		env.autorun = false
		clear
		globals.selected = allPrograms[idx]
		drawList; drawProgram
		return false
	end if
	return true
end function

if env.hasIndex("autorun") and env.autorun then
	text.row = 3
	for row in range(0, text.row); textUtil.clearRow row; end for
	text.color = color.blue
	print "(Press Esc now to exit auto-run other.)"
	if not autorunNext then
		env.autorun = false
	end if
end if

print
clear
Sound.stopAll
text.color = color.orange
text.backColor = color.clear
drawList
drawProgram
drawHelp
env.autorun = false
while true
	k = key.get
	idx = allPrograms.indexOf(selected)
	if k.code == 19 then // up-arrow
		idx = (idx + allPrograms.len - 1) % allPrograms.len
	else if k.code == 20 then  // down-arrow
		idx = (idx + allPrograms.len + 1) % allPrograms.len
	else if k.code == 10 or k.code == 13 then  // return/enter
		runProgram selected
	else if k == "a" or k == "A" then
		env.autorun = ""
		autorunNext
	else if k.code == 27 then  // esc
		text.row = 0; print
		env.autorun = false
		env.shell = ""
		exit
	end if
	selected = allPrograms[idx]
	drawList
	drawProgram
	drawHelp
end while
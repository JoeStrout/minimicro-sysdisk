// This is a shell program that presents a menu of selected
// demos, making it easy to preview/run them.

// Make this program the shell (return here after running demo)
env.shell = "/sys/demo/demos.ms"
if file.exists("/usr/demo/demos.ms") then env.shell = "/usr/demo/demos.ms"

import "chars"
import "stringUtil"

simple = []
games = []
visual = []
demos = []

//games.push "TD"
demos.push "2dVis"
demos.push "angles"

games.push "acey-deucey"
games.push "asteroids"
games.push "drumMachine"
games.push "flappyBat"
games.push "mochiBounce"
games.push "pigDice"
games.push "platformer"
games.push "speedConquest"
games.push "textAdventure"
games.push "ticTacToe"
games.push "typing"
games.push "wumpusTrap"

simple.push "countdown"
simple.push "dogYears"

visual.push "cardFlip"
visual.push "globe"
visual.push "road"
visual.push "stars"
visual.push "sunset"
visual.push "theMatrix"
visual.push "turtleDemo"

allPrograms = simple + visual + demos + games
selected = allPrograms[0]

text.delimiter = char(13)
print
clear

drawList = function
	text.row = 25
	for pgm in allPrograms
		print "  ", ""
		s = "  " + pgm.pad(15)
		text.inverse = (pgm == selected)
		print s
		text.inverse = false
	end for
end function

drawProgram = function
	gfx.clear
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
		wait 0.1
	end for
	print " ", eol
	returnSound.play
end function

showCommand = function(cmd)
	text.color = color.gray; print "]", ""
	text.color = color.orange
	printSlowly cmd
	wait
end function

runProgram = function
	path = "/sys/demo/" + selected
	text.row = 2
	showCommand "load """ + path + """"
	showCommand "run"
	load path; clear; run
end function

drawList
drawProgram
while true
	k = key.get
	idx = allPrograms.indexOf(selected)
	if k.code == 19 then // up-arrow
		idx = (idx + allPrograms.len - 1) % allPrograms.len
	else if k.code == 20 then
		idx = (idx + allPrograms.len + 1) % allPrograms.len
	else if k.code == 10 or k.code == 13 then
		runProgram
	end if
	selected = allPrograms[idx]
	drawList
	drawProgram
end while
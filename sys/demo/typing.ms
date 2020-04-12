// Typing Game
// Type the invading words before they reach the ground!

normalTextColor = text.color
clear
score = 0

printAt = function(row, col, s)
	text.row = row
	text.column = col
	text.delimiter = ""
	print s
	text.delimiter = char(13)
end function

// Define a couple of functions to find the graphics coordinates
// of the center of a character at the given given row/column.
// Text cells are 14x24 pixels, with a 4x7 offset (to which 
// the functions below add half the cell size to get to the center).
xForCol = function(col)
	return col * 14 + 11
end function
yForRow = function(row)
	return row * 24 + 19
end function

// Define sound effects
fireSnd = new Sound
fireSnd.init 0.3, [8000,100], [1,0]
hitSnd = new Sound
hitSnd.init 1, 100, [1, 0], Sound.noiseWave
missSnd = new Sound
missSnd.init 0.15, [440, 440, 440, 220, 220, 220]
gameOverSnd = new Sound
gameOverSnd.init 3, 1, [1, 0], Sound.noiseWave

// Define our Word class, which represents one invading
// word dropping down from the top of the screen.
Word = {}
Word.text = ""
Word.x = 10
Word.y = 25  // row, from 0 (bottom) to 25 (top)
Word.startTime = 0
Word.dieTime = null
Word.speed = 0.5

Word.draw = function()
	printAt self.y, self.x - self.text.len/2, self.text
end function

Word.erase = function()
	printAt self.y, self.x - self.text.len/2, " " * self.text.len
end function

Word.init = function(text)
	self.text = text.upper
	self.x = round(5 + 55*rnd)
	self.y = 25
	self.startTime = time
	self.speed = 0.5 + (score + 20)/20
end function

Word.update = function()
	if self.dieTime == null then
		t = time - self.startTime
		y = round(25 - t * self.speed)
		if y != self.y then
			self.erase
			self.y = y
			text.color = "#CCCCFF"
			self.draw
			if y <= 1 then self.endGame
		end if
	else
		t = time - self.dieTime
		if t > 1 then
			self.erase
			targets.remove targets.indexOf(self)
		else
			text.color = rgb(255-255*t, 150-150*t, 100-100*t)
			self.draw
		end if
	end if
end function

Word.pan = function()
	// how much to pan a sound based on this word position
	pan = (self.x - 34) / 34
	// Default panning is not very noticeable; let's exaggerate it!
	pan = sign(pan) * abs(pan) ^ 0.5
	return pan
end function

Word.die = function()
	self.dieTime = time
end function

Word.endGame = function()
	gameOverSnd.play 1, self.pan
	x = xForCol(self.x)
	y = yForRow(self.y)
	for i in range(10, 300, 20)
		gfx.color = rgb(260-i*0.5, 260-i*0.6, 260-i*0.7)
		gfx.fillEllipse x - i, y - i, i*2, i*2
		wait 0.1
	end for
	text.color = color.black
	text.backColor = color.aqua
	printAt 15, 34-10, " " * 20
	printAt 16, 34-10, " " * 20
	printAt 17, 34-10, " " * 20
	printAt 16, 34-4, "GAME OVER"
	text.backColor = color.clear
	globals.done = true
end function

// what text the user has entered so far:
entry = ""

// draw the ground, including the text entry and score
drawGround = function()
	c = text.color
	bc = text.backColor
	text.color = color.yellow
	text.backColor = "#006600"
	for i in range(0,68)
		text.setCellBackColor i, 0, text.backColor
		text.setCell i, 0, " "
	end for
	printAt 0, 34 - entry.len/2, entry
	text.color = "#44AA44"
	printAt 0, 62, ("00000" + score)[-5:]
	text.color = c
	text.backColor = bc
end function

// handle keyboard input
checkInput = function()
	while key.available
		k = key.get.upper
		kcode = code(k)
		if kcode == 8 then // delete
			globals.entry = entry[:-1]
		else if kcode == 10 or kcode == 13 or k == " " then
			fire
			globals.entry = ""
		else if kcode == 27 then   // Esc
			globals.done = true
		else
			globals.entry = entry + k
		end if
		drawGround
	end while
end function


// See if we have any target that matches our current entry,
// and if so, fire a beam and take that word out!
fire = function()
	target = null
	for w in targets
		if w.text == entry and not w.dieTime then
			target = w
			break
		end if
	end for
	if target == null then
		missSnd.play
		return
	end if
	text.color = color.white
	target.draw
	fireSnd.play
	for i in range(255,0,-10)
		gfx.color = rgb(i, i/2, i/4)
		gfx.line xForCol(34),yForRow(1), xForCol(target.x), yForRow(target.y)
		yield
	end for
	hitSnd.play 0.2, target.pan
	target.die
	globals.score = score + target.text.len
end function

// Prepare the list of words we can spawn
wordList = []
addWords = function(words)
	for w in words.split
		wordList.push w
	end for
end function
addWords "apple mini test scooter ball toast trick top eating"
addWords "the this that other there some than would first have"
addWords "each make water from which like been call into time"
addWords "with they word what were when your which their about"
addWords "many these number more write people come down find"
addWords "for while if then break new end function not yield print"

// Now prepare the list of target (spawned) Words, and a spawn function
targets = []
spawnNewWord = function()
	w = new Word
	w.init wordList[wordList.len * rnd]
	targets.push w
end function

done = false
nextWordTime = time
drawGround

// Main loop:
while not done
	if time > nextWordTime then
		spawnNewWord
		nextWordTime = time + 0.5 + 3 * rnd * (1 - score/(score+50))
	end if
	for w in targets
		w.update
		if done then break
	end for
	checkInput
	yield
end while

text.row = 0
text.color = normalTextColor
wait 1
print
exit


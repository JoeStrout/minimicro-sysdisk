// Mini Micro performance benchmarks.

import "listUtil"
import "mathUtil"
import "json"
import "textUtil"

boxEmpty = char(9744)
boxChecked = char(9745)

clear
text.delimiter = char(13)
text.row = 25
text.inverse = true
print " " * 21 + "MINI MICRO BENCHMARK TESTS" + " " * 21
text.inverse = false
text.row = 23
curOptIdx = -1

Option = {}
Option.textRow = 23
Option.label = "?"
Option.func = null
Option.enabled = true
Option.nominalTime = 1
Option.drawBox = function
	if self.enabled then
		text.setCell 0, self.textRow, boxChecked
	else
		text.setCell 0, self.textRow, boxEmpty
	end if
end function
options = []

addOption = function(func, label, nominalTime=1)
	opt = new Option
	opt.label = label
	opt.func = @func
	opt.nominalTime = nominalTime
	opt.textRow = 23 - options.len
	options.push opt
	text.row = opt.textRow
	print "  " + label
	opt.drawBox
end function

showProgress = function(fractionDone=null)
	if fractionDone == null then
		msg = " ... "
	else
		msg = ("    (" + round(fractionDone * 100) + "%)")[-5:]
	end if
	text.row = 23 - curOptIdx
	text.column = 63
	print msg
end function

showResult = function(time, units="s")
	msg = ("   " + mathUtil.numToStr(time, 3))[-8:] + " " + units + " "
	text.row = 23 - curOptIdx
	text.column = 40
	nom = options[curOptIdx].nominalTime
	percent = (" " * 8 + round(100 * time/nom) + "%")[-8:]
	print msg + " " * (50 - 40 - msg.len) + percent + " "*9
end function	

//----------------------------------------------------------------------
// Individual tests
//----------------------------------------------------------------------

semiprime = function
	isSemiprime = function(num)
		divisor = 2
		primes = 0
		while primes < 3 and num != 1
			if num % divisor == 0 then
				num = num / divisor;
				primes = primes + 1
			else
				divisor = divisor + 1
			end if
		end while
		return primes == 2
	end function
	results = []
	for i in range(2, 1000)
		if isSemiprime(i) then results.push i
		showProgress i/1000
	end for
end function
addOption @semiprime, "Semiprime (math, looping)", 0.459

//----------------------------------------------------------------------
recursiveFib = function(n=28)
    if n < 1 then return 0
    if n == 1 then return 1
    return recursiveFib(n-1) + recursiveFib(n-2)
end function
addOption @recursiveFib, "Recursive Fibonnaci", 2.837

//----------------------------------------------------------------------
iterativeFib = function(n=28)
    if n < 1 then return 0
    if n == 1 then return 1
	b = 0
	sum = 1
	for i in range(n-2)
		a = b
		b = sum
		sum = a + b
	end for
	return sum
end function
addOption @iterativeFib, "Iterative Fibonnaci", 0.0001

//----------------------------------------------------------------------
pixelDrawing = function
	gfx.clear
	colors = [color.red, color.green, color.blue, "#FF000088", "#00FF0088", "#0000FF88"]
	for rep in range(0,10)
		for i in range(0,33)
			gfx.drawRect 860*rnd, 540*rnd, 200*rnd, 200*rnd, colors.any
			gfx.fillRect 860*rnd, 540*rnd, 200*rnd, 200*rnd, colors.any
			showProgress (rep*100+i)/500
		end for
		for i in range(34,66)
			gfx.drawEllipse 860*rnd, 540*rnd, 200*rnd, 200*rnd, colors.any
			gfx.fillEllipse 860*rnd, 540*rnd, 200*rnd, 200*rnd, colors.any
			showProgress (rep*100+i)/500
		end for
		for i in range(67,100)
			gfx.line 960*rnd, 640*rnd, 960*rnd, 640*rnd, colors.any
			gfx.line 960*rnd, 640*rnd, 960*rnd, 640*rnd, colors.any, 10
			showProgress (rep*100+i)/500
		end for
	end for
end function
addOption @pixelDrawing, "Misc. Drawing", 0.292

//----------------------------------------------------------------------
jsonParse = function
	showProgress
	yield
	s = file.open("/sys/data/benchmark/random.json").read
	data = json.parse(s)
	showProgress 1
	yield
end function
addOption @jsonParse, "JSON Parsing", 0.531

//----------------------------------------------------------------------
jsonGeneration = function
	showProgress
	yield
	map = {"x": 123.456, "y": -987.654}
	map["name"] = "This is a JSON generation test."
	map["count"] = range(10)
	items = [map] * 1000
	data = {"items": items, "version": 42}
	s = json.toJSON(data)
	showProgress 1
	yield
end function
addOption @jsonGeneration, "JSON Generation", 0.706

//----------------------------------------------------------------------
recursiveFill = function
	gfx.clear color.black
	gfx.drawEllipse 300,50,300,200, color.blue
	fillAtPoint 400, 80
end function

fillAtPoint = function(x,y)
	if gfx.pixel(x,y) != "#000000FF" then return
	gfx.setPixel x,y, "#FF8800"
	fillAtPoint x-1, y
	fillAtPoint x, y-1
	fillAtPoint x+1, y
	fillAtPoint x, y+1
end function

addOption @recursiveFill, "Recursive Flood Fill", 1.5

//----------------------------------------------------------------------
iterativeFill = function
	gfx.clear color.black
	gfx.drawEllipse 300,50,300,200, color.blue
	toDoList = [[400, 80]]
	while toDoList
		pos = toDoList.pop
		x = pos[0]; y = pos[1]
		if gfx.pixel(x,y) != "#000000FF" then continue
		gfx.setPixel x, y, "#FF8800"
		toDoList.push [x, y+1]
		toDoList.push [x+1, y]
		toDoList.push [x, y-1]
		toDoList.push [x-1, y]
	end while
end function
addOption @iterativeFill, "Iterative Flood Fill", 2.0

//----------------------------------------------------------------------
carpet = function
	xor = function(a, b)
		result = 0
		bit = 1
		while a > 0 or b > 0
			if (a%2 == 0) != (b%2 == 0) then result = result + bit
			bit = bit * 2
			a = floor(a/2)
			b = floor(b/2)
		end while
		return result
	end function
	
	for x in range(0,96)
		for y in range(0,96)
			gfx.setPixel x + 100, y + 100, color.rgb(xor(x,y), 0, 0)
		end for
		showProgress x/96
	end for
end function
addOption @carpet, "Carpet (xor, setPixel, color.rgb)", 0.915

//----------------------------------------------------------------------
raceSim = function
	Ant = {}
	Ant.simWins = 0
	Ant.init = function
		self.meanStepTime = mathUtil.randNormal(0.5, 0.01)
		if self.meanStepTime < 0.1 then self.meanStepTime = 0.1
		self.stddev = rnd * 0.1
	end function
	
	Ant.genStepTimes = function
		result = []
		t = 0
		for i in range(0,61)
			dt = mathUtil.randNormal(self.meanStepTime, self.stddev)
			if dt < 0.1 then dt = 0.1
			t = t + dt
			result.push t
		end for
		return result
	end function
	
	ants = []
	for i in range(7)
		ants.push new Ant
		ants[-1].init
	end for
	
	simulateRace = function(ants)
		winner = null
		winTime = 0
		for a in ants
			times = a.genStepTimes
			if not winner or times[-1] < winTime then
				winner = a
				winTime = times[-1]
			end if
		end for
		winner.simWins = winner.simWins + 1
	end function
	
	for i in range(1,100)
		simulateRace ants
		showProgress i/100
	end for
end function
addOption @raceSim, "Race Sim (lists, randNormal)", 1.043

//----------------------------------------------------------------------
frameRate = function
	frameCount = 0
	t0 = time; t1 = t0 + 2
	while time < t1
		frameCount += 1
		yield
	end while
    return frameCount / (t1 - t0)
end function
addOption @frameRate, "Frame Rate", 60

//----------------------------------------------------------------------

measure = function(func)
	t0 = time
	func
	t1 = time
	elapsed = t1 - t0
	return elapsed
end function

runAll = function
	for i in options.indexes
		globals.curOptIdx = i
		if not options[i].enabled then continue
		if options[i].label == "Frame Rate" then
			fps = options[i].func
			showResult fps, "fps"
		else
			t = measure(@options[i].func)
			showResult t
		end if
		gfx.clear
	end for
end function

handleClick = function
	row = textUtil.textRow(mouse.y)
	idx = 23 - row
	if idx >= 0 and idx < options.len then
		opt = options[idx]
		opt.enabled = not opt.enabled
		opt.drawBox
		if key.pressed("left alt") or key.pressed("right alt") then
			for other in options
				other.enabled = opt.enabled
				other.drawBox
			end for
		end if
	end if
end function

configure = function
	wasDown = false
	while not key.available
		isDown = mouse.button
		if isDown and not wasDown then handleClick
		wasDown = isDown
	end while
end function

print
instructionsRow = text.row
print "Click tests above to toggle; alt-click to toggle all."
print "Press Return to run tests when ready."

configure
text.row = instructionsRow
print " " * 67
print "Running tests..." + " " * 40
print "(Times shown along with % of nominal time.)"
runAll

text.row = instructionsRow - 1
print " " * 67
print "Tests complete!" + " " * 40
print
key.clear

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
Option.drawBox = function()
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

showResult = function(time)
	msg = ("   " + round(time, 3))[-8:] + " s "
	text.row = 23 - curOptIdx
	text.column = 40
	nom = options[curOptIdx].nominalTime
	percent = (" " * 8 + round(100 * time/nom) + "%")[-8:]
	print msg + " " * (50 - 40 - msg.len) + percent + " "*9
end function	

//----------------------------------------------------------------------
// Individual tests
//----------------------------------------------------------------------

semiprime = function()
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
addOption @semiprime, "Semiprime (math, looping)", 2.260

//----------------------------------------------------------------------
pixelDrawing = function()
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
addOption @pixelDrawing, "Misc. Drawing", 1.05

//----------------------------------------------------------------------
jsonParse = function()
	showProgress
	yield
	s = file.open("/sys/data/benchmark/random.json").read
	data = json.parse(s)
	showProgress 1
	yield
end function
addOption @jsonParse, "JSON Parsing", 3.0

//----------------------------------------------------------------------
jsonGeneration = function()
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
addOption @jsonGeneration, "JSON Generation", 3.291

//----------------------------------------------------------------------
carpet = function()
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
addOption @carpet, "Carpet (xor, setPixel, color.rgb)", 4.303

//----------------------------------------------------------------------
raceSim = function()
	Ant = {}
	Ant.simWins = 0
	Ant.init = function()
		self.meanStepTime = mathUtil.randNormal(0.5, 0.01)
		if self.meanStepTime < 0.1 then self.meanStepTime = 0.1
		self.stddev = rnd * 0.1
	end function
	
	Ant.genStepTimes = function()
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
addOption @raceSim, "Race Sim (lists, randNormal)", 5.406

//----------------------------------------------------------------------

measure = function(func)
	t0 = time
	func
	t1 = time
	elapsed = t1 - t0
	return elapsed
end function

runAll = function()
	for i in options.indexes
		globals.curOptIdx = i
		if not options[i].enabled then continue
		t = measure(@options[i].func)
		showResult t
		gfx.clear
	end for
end function

handleClick = function()
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

configure = function()
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

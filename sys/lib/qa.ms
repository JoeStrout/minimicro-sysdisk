// Quality Assurance module
//
// This module provides functions for helping assure the quality of your
// code: assert conditions that you think should always be true, or otherwise
// check your assumptions and report when they fail.

if intrinsics.hasIndex("Display") and intrinsics.hasIndex("displayMode") then
	_prevMode = 0
	errDisplay = null
	
	// prepareErrDisplay is used internally to prepare the default error display.
	// You probably won't ever need to call this.
	prepareErrDisplay = function
		outer._prevMode = display(0).mode
		display(0).mode = displayMode.text
		outer._prevDisp = display(0)
		outer.errDisplay = new TextDisplay
		errDisplay.backColor = "#00000088"
		errDisplay.color = color.red
		errDisplay.clear
		errDisplay.install 0
	end function
	
	// clear: clears (just) the error display.
	clear = function
		if errDisplay == null then prepareErrDisplay
		_prevDisp.install 0
		display(0).mode = _prevMode
		outer.errDisplay = null
	end function
else
	errDisplay = {}
	errDisplay.print = @print
	clear = null
end if

// abort: print a stack trace (optionally, after an error message),
// then exit the program.
abort = function(errMsg)
	if errDisplay == null then prepareErrDisplay
	if errMsg == null then errMsg = "qa.abort has been called."
	if not errMsg isa list then errMsg = [errMsg]
	for errLine in errMsg
		errDisplay.print errLine
	end for
	errDisplay.print "Call stack:"
	i = 0
	for line in stackTrace
		if line.indexOf("qa.ms") != null then continue
		errDisplay.print "  " + i + ". " + line
		i = i + 1
	end for
	errDisplay.print "(To clear this display, enter: qa.clear)"
	if not globals.hasIndex("qa") then globals.qa = outer
	exit
end function

// assert: abort if the given condition is not true.
// Error message can include the given (optional) description.
assert = function(condition, desc)
	if condition then return
	msg = "Assert failed"
	if desc != null then msg = msg + ": " + desc
	abort msg
end function

// assertEqual: abort if the first two parameters are not equal.
// Additional descriptive note is optional.
assertEqual = function(actual, expected, note)
	if @actual == @expected then return
	msg = "Assert failed"
	if note != null then msg = msg + " (" + note + ")"
	msg = msg + ": expected `" + @expected + "`, but got `" + @actual + "`"
	abort msg
end function

// assertEqualOneScreen: like `assertEqual` but fits the message on one Mini Micro screen.
assertEqualOneScreen = function(actual, expected, note)
	if @actual == @expected then return
	
	// Converts to string and cuts to 35 characters to save screen space.
	_chop35 = function(x)
		s = str(x)
		if s.len > 35 then s = s[:35] + "…"
		unprintables = range(31) + [127]
		cc = []
		for c in s
			if unprintables.indexOf(c.code) == null then
				cc.push c
			else
				cc.push char(134) + "<char" + c.code + ">" + char(135)
			end if
		end for
		return cc.join("")
	end function
	
	msg = "Assert failed"
	if note != null then msg += " (" + note + ")"
	msg += ": expected `" + _chop35(@expected) + "`, but got `" + _chop35(@actual) + "`"
	if (@actual isa string and @expected isa string) or
		(@actual isa list and @expected isa list) or
		(@actual isa map and @expected isa map) then
		// If same type, find and report any first discrepancy
		found = false
		idx = null
		vals = null
		codes = null
		for k in actual.indexes
			if not expected.hasIndex(@k) then
				// Found unexpected data among keys in actual
				idx = "`" + _chop35(@k) + "`"
				if actual isa map then
					vals = ["no such index", "{… index: `" + _chop35(actual[@k]) + "` …}"]
				else if k > 0 then
					vals = ["end of data", "`…" + _chop35(actual[k:]) + "`"]
				end if
				found = true
				break
			else if actual[@k] != expected[@k] then
				// Found different values of the same key
				idx = "`" + _chop35(@k) + "`"
				if actual isa map then
					vals = ["{… index: `" + _chop35(expected[@k]) + "` …}", "{… index: `" + _chop35(actual[@k]) + "` …}"]
				else if k > 0 then
					vals = ["`…" + _chop35(expected[k:]) + "`", "`…" + _chop35(actual[k:]) + "`"]
					if actual isa string then codes = [expected[k].code, actual[k].code]
				end if
				found = true
				break
			end if
		end for
		if not found then
			// We didn't find difference iterating over actual keys, which means that some expected data is missing
			if actual isa map then
				for k in expected.indexes
					if not actual.hasIndex(@k) then break
				end for
			else
				k = actual.len
			end if
			idx = "`" + _chop35(@k) + "`"
			if actual isa map then
				vals = ["{… index: `" + _chop35(expected[@k]) + "` …}", "no such index"]
			else if k > 0 then
				vals = ["`…" + _chop35(expected[k:]) + "`", "end of data"]
			end if
			found = true
		end if
		// Engooden error message
		msg = [msg, "At index " + @idx]
		if vals then
			exp = vals[0]
			act = vals[1]
			if actual isa list then
				if exp[:3] == "`…[" then exp = "`…" + exp[3:]
				if act[:3] == "`…[" then act = "`…" + act[3:]
			end if
			msg += [char(9) + "expected " + exp, char(9) + "but got  " + act]
		end if
		if codes then msg += [
			char(9) + "           ↑",
			char(9) + "           code(" + codes[0] + ") != code(" + codes[1] + ")",
		]
	end if
	abort msg
end function

namedMaps = {number:"number", string:"string", list:"list", map:"map"}
for cls in ("FileHandle Image Sound Sprite Bounds " +
  "Display TextDisplay SpriteDisplay TileDisplay PixelDisplay SolidColorDisplay").split
    if intrinsics.hasIndex(cls) then
    	m = intrinsics[cls]
    	namedMaps[m] = cls
    end if
end for

typeOf = function(value)
	if @value isa funcRef then return "funcRef"
	if value isa number then return "number"
	if value isa string then return "string"
	if value isa list then return "list"
	if value == null then return "null"
	if value isa map then
		mapType = value
		if value.hasIndex("__isa") then mapType = value.__isa
		for kv in namedMaps
			if refEquals(kv.key, mapType) then return kv.value
		end for
		return "map"
	end if
	return "unknown"
end function

// assertType: abort if the first parameter is not of the specified type.
// Additional descriptive note is optional.
assertType = function(value, type, note)
	if @value isa type then return
	msg = "Assert failed"
	if note != null then msg = msg + " (" + note + ")"
	msg = msg + ": expected type " + namedMaps[type] + 
	  ", but got a " + typeOf(@value) + " (" + @value + ")"
	abort msg
end function


runUnitTests = function
	print "Unit testing: qa"

	// We can't easily test the various assert methods, but we
	// can at least test typeOf (and through that, namedMaps).
	errorCount = 0
	assertEqual = function(actual, expected)
		// for the sake of unit testing, let's round all numbers to 1 decimal place.
		if actual != expected then
			print "Unit test failure (line " + stackTrace[1].split[-1] + 
			  "): expected " + expected + ", got " + actual
			outer.errorCount = errorCount + 1
		end if
	end function
	
	assertEqual typeOf(42), "number"
	assertEqual typeOf("abc"), "string"
	assertEqual typeOf([1,2,3]), "list"
	assertEqual typeOf(@rnd), "funcRef"
	if intrinsics.hasIndex("Sprite") then
		assertEqual typeOf(new Sprite), "Sprite"
		assertEqual typeOf(gfx), "PixelDisplay"
	end if
	
	if errorCount == 0 then
		print "All tests passed.  Quality code!"
	else
		print errorCount + " error" + "s" * (errorCount!=1) + " found."
	end if	
end function

if globals == locals then runUnitTests

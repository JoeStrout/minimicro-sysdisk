// Quality Assurance module
//
// This module provides functions for helping assure the quality of your
// code: assert conditions that you think should always be true, or otherwise
// check your assumptions and report when they fail.

_prevMode = 0

errDisplay = null

// prepareErrDisplay is used internally to prepare the default error display.
// You probably won't ever need to call this.
prepareErrDisplay = function()
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
clear = function()
	if errDisplay == null then prepareErrDisplay
	_prevDisp.install 0
	display(0).mode = _prevMode
	outer.errDisplay = null
end function

// abort: print a stack trace (optionally, after an error message),
// then exit the program.
abort = function(errMsg)
	if errDisplay == null then prepareErrDisplay
	if errMsg == null then errMsg = "qa.abort has been called."
	errDisplay.print errMsg
	errDisplay.print "Call stack:"
	i = 0
	for line in stackTrace
		if line.indexOf("qa.ms") != null then continue
		errDisplay.print "  " + i + ". " + line
		i = i + 1
	end for
	errDisplay.print "(To clear this display, enter: qa.clear)"
	if not globals.hasIndex("qa") then
		globals.qa = {}
		globals.clear = @clear
	end if
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
	if actual == expected then return
	msg = "Assert failed"
	if note != null then msg = msg + " (" + note + ")"
	msg = msg + ": expected `" + expected + "`, but got `" + actual + "`"
	abort msg
end function

namedMaps = {
	number:"number", string:"string", list:"list", map:"map",
	Display:"Display", TextDisplay:"TextDisplay", SpriteDisplay:"SpriteDisplay",
	TileDisplay:"TileDisplay", PixelDisplay:"PixelDisplay", 
	SolidColorDisplay:"SolidColorDisplay",
	FileHandle:"FileHandle", Image:"Image", Sound:"Sound", Sprite:"Sprite",
	Bounds:"Bounds" }

typeOf = function(value)
	if value isa number then return "number"
	if value isa string then return "string"
	if value isa list then return "list"
	if value == null then return "null"
	if value isa funcRef then return "funcRef"
	if value isa map then
		if namedMaps.hasIndex(value) then return namedMaps[value]
		return "map"
	end if
	return "unknown"
end function

// assertType: abort if the first parameter is not of the specified type.
// Additional descriptive note is optional.
assertType = function(value, type, note)
	if value isa type then return
	msg = "Assert failed"
	if note != null then msg = msg + " (" + note + ")"
	msg = msg + ": expected type " + namedMaps[type] + 
	  ", but got a " + typeOf(value) + " (" + value + ")"
	abort msg
end function

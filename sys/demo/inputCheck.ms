// This program scans all inputs, and displays
// which ones are currently pressed or wiggled.

// First, gather up all possible inputs.
allInputs = []
for i in range(0,19)
	allInputs.push "joystick button " + i
	for joyNum in range(1,8)
		allInputs.push "joystick " + joyNum + " button " + i
	end for
end for
for c in "abcdefghijklmnopqrstuvwxyz0123456789-=[]\;',./"
	allInputs.push c
end for
for kpKey in "123456789+-/*"
	allInputs.push "[" + kpKey + "]"
end for
for f in range(1,15)
	allInputs.push "f" + f
end for
for mod in ["shift", "ctrl", "alt", "cmd"]
	allInputs.push "left " + mod
	allInputs.push "right " + mod
end for
for k in ["backspace", "tab", "return", "escape", 
	"space", "delete", "enter", "insert", "home", "end", 
	"page up", "page down", "up", "down", "left", "right"]
	allInputs.push k
end for
for i in range(0, 5)
	allInputs.push "mouse " + i
end for

// Also gather the names of all analog axes.
allAxes = ["Horizontal", "Vertical", 
           "Mouse X", "Mouse Y", "Mouse ScrollWheel"]
for i in range(1,16)
	allAxes.push "JoyAxis" + i
	for joyNum in range(1,8)
		allAxes.push "Joy" + joyNum + "Axis" + i
	end for
end for

// Main update function: scan all inputs, and
// display any which are currently active.
update = function
	active = []
	for btn in allInputs
		if key.pressed(btn) then active.push btn
	end for
	for ax in allAxes
		if key.axis(ax) != 0 then
			active.push ax + "  (" + round(key.axis(ax),2) + ")"
		end if
	end for
	for i in range(0, 19)
		if i == 0 or i == 10 then text.row = 19
		text.column = 5 + 30 * (i > 9)
		s = ""
		if i < active.len then s = active[i]
		print s + " " * (30-s.len)
	end for
end function

if locals == globals then
	// Prepare display
	clear
	text.row = 25; text.column = 28
	print "INPUT CHECK"
	print
	print "Press any key, mouse, or controller inputs to"
	print "see their names below.  (Press Ctrl+C to exit.)"

	// Main loop
	while true
		update
		yield
	end while
end if

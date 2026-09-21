// Forest Fire
// a simple cellular automaton using a Text display.
// Press Escape to exit.

// some constants used in the simulation code below
p = 0.01   // probability of a new tree appearing
f = 0.01   // probability of a fire starting

maxx = 68
maxy = 25
treeChar = char(57888)
clear

// display a tree at the given column (x) and row (y)
setTree = function(x,y)
	outp.setCell x, y, treeChar
	outp.setCellColor x, y, color.green
end function

// display a fire at the given column (x) and row (y)
setFire = function(x,y)
	outp.setCell x, y, "*"
	outp.setCellColor x, y, color.orange
end function

// clear the display at the given column (x) and row (y)
setClear = function(x,y)
	outp.setCell x, y, " "
end function

// Set up two displays, so we can work in one while
// showing the other.
display(1).mode = displayMode.text
disp1 = display(1)
disp1.backColor = "#221100"
disp1.clear
display(2).mode = displayMode.text
disp2 = display(2)
disp2.backColor = disp1.backColor
disp2.clear

outp = disp1

// Initialize our current display with a random forest.
for x in range(0, maxx)
	for y in range(0, maxy)
		if rnd < 0.35 then setTree x,y else setClear x, y
	end for
end for

// function to determine whether any neighbor of the
// tree at the given column (x) and row (y) is on fire
burningNeighbor = function(x,y)
	for dx in range(-1,1)
		for dy in range(-1,1)
			if x+dx < 0 or x+dx > maxx then continue
			if y+dy < 0 or y+dy > maxy then continue
			if inp.cell(x+dx,y+dy) == "*" then return true
		end for
	end for
end function

// Main simulation function: spread fire, or sprout a tree,
// in just one cell.
updateCell = function(x,y)
	current = inp.cell(x,y)
	if current == "*" then  // fire: clears the cell.
		setClear x, y
	else if current == " " then  // empty ground...
		// random chance of sprouting a tree
		if rnd < p then setTree x, y else setClear x, y
	else  // tree...
		// if it has a burning neighbor, or bad luck, catch fire
		if rnd < f or burningNeighbor(x,y) then
			setFire x, y
		else	
			setTree x, y
		end if
	end if
end function

// Main update function: simulate all cells, and then
// swap which display is current.
update = function(inp, outp)
	globals.inp = inp
	globals.outp = outp
	for x in range(0, maxx)
		for y in range(0, maxy)
			updateCell x, y
		end for
	end for
	inp.mode = displayMode.off
	outp.mode = displayMode.text
end function

// Main loop.
while not key.pressed("escape") and not key.pressed("q")
	update disp1, disp2
	wait 0.25
	update disp2, disp1
	wait 0.25
	if key.available then
		k = key.get
		if k == char(27) or k.lower == "q" then break
	end if
end while
inp.clear
outp.clear
key.clear
display(1).mode = displayMode.off
display(0).mode = displayMode.off

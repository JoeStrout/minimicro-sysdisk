// This module is to support creation of "tweetcarts", i.e.,
// cool little programs that can fit into a single tweet
// (i.e. 280 characters or less).  The Mini Micro API tends
// to spell things out explicitly, so to help with tweetcarts,
// this module defines some shorter aliases for commonly-used
// functions and constants.

import "stringUtil"
import "listUtil"
import "mapUtil"
import "mathUtil"
import "qa"

// oneTo: shortcut for range(1, count)
oneTo = function(count)
	return range(1, count)
end function

// graphics function aliases
rect = function(left=0, bottom=0, width=100, height=100, color, penSize=1)
	gfx.drawRect left, bottom, width, height, color, penSize
end function

frect = function(left=0, bottom=0, width=100, height=100, color)
	gfx.fillRect left, bottom, width, height, color
end function

oval = function(left=0, bottom=0, width=100, height=100, color, penSize=1)
	gfx.drawEllipse left, bottom, width, height, color, penSize
end function

foval = function(left=0, bottom=0, width=100, height=100, color)
	gfx.fillEllipse left, bottom, width, height, color
end function

circ = function(centerX=0, centerY=0, radius=100, color, penSize=1)
	gfx.drawEllipse centerX-radius, centerY-radius, radius*2, radius*2, color, penSize
end function

fcirc = function(centerX=0,centerY=0, radius=100, color)
	gfx.fillEllipse centerX-radius, centerY-radius, radius*2, radius*2, color
end function

// clr: unlike clear (or its alias cls, below), this clears ONLY the
// gfx display, and does not reset its scale or scroll.
clr = function(color="#000000")
	gfx.fillRect 0, 0, gfx.width, gfx.height, color
end function

// flip: switch visible pixel displays, by display index.
// Given two parameters: show whichever is hidden, and hide
// the other one, while making gfx ready for drawing on that
// off-screen, hidden display.
// Given one parameter: show the current gfx display, hide
// the given one, and make gfx ready for drawing on that.
// Given no parameters: flip between displays 5 and 6.
flip = function(dispIndex1=null, dispIndex2=null)
	if dispIndex1 == null then
		dispIndex1 = 5
		dispIndex2 = 6
	end if
	if dispIndex2 == null then dispIndex2 = gfx.index
	if display(dispIndex1).mode == displayMode.off then
		// show disp1, but point gfx at (off-screen) disp2
		display(dispIndex1).mode = displayMode.pixel
		display(dispIndex2).mode = displayMode.pixel
		globals.gfx = display(dispIndex2)
		display(dispIndex2).mode = displayMode.off
	else
		// show disp2, but point gfx at (off-screen) disp1
		display(dispIndex2).mode = displayMode.pixel
		display(dispIndex1).mode = displayMode.pixel
		globals.gfx = display(dispIndex1)
		display(dispIndex1).mode = displayMode.off
	end if
end function

// flc: flip and clear, optionally yielding too.
flc = function(dispIndex1=null, dispIndex2=null, andYield=true)
	flip dispIndex1, dispIndex2
	clr
	if andYield then yield
end function

// misc. aliases
cls = @clear
tau = 2 * pi
π = pi		// (don't know how to type these?  Copy & paste!)
τ = tau
c = @char
t = @time
g = function(); return gfx; end function
k = key
m = mouse
µ = @yield
wget = @http.get

// pal: our 20 standard colors, sorted by total of R, G, B, and A.
pal = [color.clear, color.black, color.maroon, color.green, color.navy,
color.red, color.lime, color.blue, color.olive, color.teal, color.purple,
color.brown, color.orange, color.gray, color.yellow, color.aqua, color.fuchsia,
color.pink, color.silver, color.white]

// img: load an image by name, anywhere under the current
// directory, /usr/pics, or /sys/pics, or somewhere else
// that you specify.
// The .png extension is not needed.
img = function(name, folder=null)
	todo = [".", "/usr/pics", "/sys/pics"]
	if folder then todo.insert 0, folder
	if not name.endsWith(".png") then name = name + ".png"
	while todo
		folder = todo.pull
		for f in file.children(folder)
			path = file.child(folder, f)
			if f == name then return file.loadImage(path)
			if file.info(path).isDirectory then todo.push path
		end for
	end while
	return null
end function

// sd: the default sprite display
sd = display(4)

// spr: create a sprite from an image name (see img)
// or URL.  Set up a localBounds based on the image size,
// and if addToSd is true, add to the sd sprites list.
spr = function(nameOrURL, x=480, y=320, addToSd=true)
	s = new Sprite
	if nameOrURL.contains("://") then
		s.image = http.get(nameOrURL)
	else
		s.image = img(nameOrURL)
	end if
	s.x = x
	s.y = y
	s.localBounds = new Bounds
	s.localBounds.width = s.image.width
	s.localBounds.height = s.image.height
	if addToSd then sd.sprites.push s
	return s
end function


if locals == globals then
	// here's an example tweetcart
	// (put all on one line after: import"tc")
	t=0;while 1;t=t+1;for i in range(15);d=cos(tau*(t/60+i/2))*50+100;	
	a=tau*(i/16+t/120);x=cos(a)*d+480;y=sin(a)*d+320;
	r=cos(tau*(t/40+i/4))*10+15; c=pal[i%8+9];circ x,y,r,c,4;
	end for;flc;end while
	
else
	// When imported, we're going to do something unusual:
	// take all our identifiers, and stuff them into the
	// global variable space.
	for kv in locals
		if kv.key[0] != "_" then globals[kv.key] = @kv.value		
	end for
	// And clear/reset the displays.
	clear
end if

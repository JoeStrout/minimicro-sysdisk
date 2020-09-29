// This module is to support creation of "tweetcarts", i.e.,
// cool little programs that can fit into a single tweet
// (i.e. 280 characters or less).  The Mini Micro API tends
// to spell things out explicitly, so to help with tweetcarts,
// this module defines some shorter aliases for commonly-used
// functions and constants.

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

// misc. aliases
cls = @clear
tau = 2 * pi

// pal: our 20 standard colors, sorted by total of R, G, B, and A.
pal = [color.clear, color.black, color.maroon, color.green, color.navy,
color.red, color.lime, color.blue, color.olive, color.teal, color.purple,
color.brown, color.orange, color.gray, color.yellow, color.aqua, color.fuchsia,
color.pink, color.silver, color.white]


if locals == globals then
	// here's an example tweetcart
	// (put all on one line after: import"tc")
	t=0;while 1;cls;t=t+1;for i in range(15);d=cos(tau*(t/60+i/2))*50+100;	
			a=tau*(i/16+t/120);x=cos(a)*d+480;y=sin(a)*d+320;
			r=cos(tau*(t/40+i/4))*10+15; c=pal[i%8+9];circ x,y,r,c,4;
	end for;yield;end while
	
else
	// When imported, we're going to do something unusual:
	// take all our identifiers, and stuff them into the
	// global variable space.
	for kv in locals
		if kv.key[0] != "_" then globals[kv.key] = @kv.value		
	end for
end if

// Color utilities, including conversion to/from HSV
// (Hue/Saturation/Value) format.

// (thanks to @DFZ on the MiniScript Discord!)

min3 = function(a,b,c)
	if a <= b and a <= c then
		return a
	else if b <= a and b <= c then
		return b
	else
		return c
	end if
end function

max3 = function(a,b,c)
	if a >= b and a >= c then
		return a
	else if b >= a and b >= c then
		return b
	else
		return c
	end if
end function

// RGBtoHSV: Convert a color in list format, [0-255, 0-255, 0-255],
// from RGB color space to HSV color space.
RGBtoHSV = function(RGB) // list of RGB values [0-255, 0-255, 0-255]
	//Rescale
	R = RGB[0] / 255
	G = RGB[1] / 255
	B = RGB[2] / 255
	min = min3(R,G,B)
	max = max3(R,G,B)
	V = round(max*100)
	delta = max-min
	if delta != 0 then
		S = round(delta/max*100)
	else
		S = 0
		H = 0
		return [H, S, V]
	end if
	if R == max then
		H = (G-B)/delta
	else if G == max then
		H = 2+(B-R)/delta
	else
		H = 4+(R-G)/delta
	end if
	H = H*60
	if H < 0 then H = H+360
	H = round(H)
	return [H, S, V]
end function

// HSVtoRGB: Convert a color in list format, [0-255, 0-255, 0-255],
// from HSV color space to RGB color space.
HSVtoRGB = function(HSV)
	//Rescale
	S = HSV[1] / 100
	V = HSV[2] / 100
	if S == 0 then
		R = V
		G = V
		B = V
		//Rescale
		R = round(R*255)
		G = round(G*255)
		B = round(B*255)
		RGB.push R
		RGB.push G
		RGB.push B
		return RGB
	end if
	H = HSV[0]/60
	i = floor(H)
	f = H-i
	p = V*(1-S)
	q = V*(1-S*f)
	t = V*(1-S*(1-f))
	if i == 0 then
		R = V
		G = t
		B = p
	else if i == 1 then
		R = q
		G = V
		B = p
	else if i == 2 then
		R = p
		G = V
		B = t
	else if i == 3 then
		R = p
		G = q
		B = V
	else if i == 4 then
		R = t
		G = p
		B = V
	else
		R = V
		G = p
		B = q
	end if
	//Rescale
	R = round(R*255)
	G = round(G*255)
	B = round(B*255)
	return [R, G, B]
end function
// Text Utilities (related to displaying text on the Mini Micro screen).

// Print without a carriage return (i.e. moving to the next line).
printNoCR = function(s)
	oldDelim = text.delimiter
	text.delimiter = ""
	print s
	text.delimiter = oldDelim
end function

// Draw a button with the given caption at the cursor position.
drawButton = function(caption)
	text.inverse = not text.inverse
	printNoCR char(57856) + caption + char(57857)
	text.inverse = not text.inverse
end function

// Print the given string, wrapped on word breaks (spaces) to
// fit in the given width.  Subsequent lines begin at the same
// text.column as the current text.column value.
// Parameters:
//		s: string to print
//		width: character limit per line; if null, goes to edge of screen
//		maxLines: maximum lines to print; or if null, no limit
// Returns: remaining (unprinted) portion of string, or null
printWrap = function(s, width=null, maxLines=null)
	left = text.column
	if width == null then width = 67 - left
	lineCount = 0
	while s
		text.column = left
		if s.len <= width then
			print s
			return null
		end if
		foundCut = false
		for i in range(width, 0)
			if s[i] == " " then
				print s[:i]
				s = s[i+1:]
				foundCut = true
				break
			end if
		end for
		if not foundCut then
			// Couldn't find a space to cut on...
			// so, out of desperation, just cut at width
			print s[:width]
			s = s[width:]
		end if
		lineCount = lineCount + 1
		if maxLines and lineCount == maxLines then return s
	end while
end function

// Get the text column for a given screen pixel X coordinate.
textCol = function(pixelX)
	return floor((pixelX-5)/14)
end function

// Get the text row for a given screen pixel Y coordinate.
textRow = function(pixelY)
	return floor((pixelY-6)/24)
end function

// Print a string starting at the given column and row.
// Also, if you use this to print to row 0, it avoids the usual scrolling.
printAt = function(column, row, s)
	text.row = row
	text.column = column
	if row == 0 then
		// avoid scrolling when printing to the bottom row
		delim = text.delimiter
		text.delimiter = ""
		print s
		text.delimiter = delim
	else
		print s
	end if
end function


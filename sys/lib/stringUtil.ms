// String Utilities.
//	This module adds some additional methods to the `string` type.


// Small words we don't capitalize in titleCase.
// This set is from the U.S. Government Printing Office Style Manual:
smallWords = ["a", "an", "the", "at", "by", "for", "in", "of", "on", "to", "up", "and", "as", "but", "or", "nor"]

TAB = char(9)
CR = char(13)
LF = char(10)

// Common whitespace characters.  Note that there are lots more defined
// in Unicode, but they are not commonly used (at least in Mini Micro).
whitespace = " " + TAB + CR + LF

// capitalized: return the given string with the first letter in
// uppercase, and the rest of the word returned as-is.
//
// Examples:
//		"hello".capitalized			// returns "Hello"
//		"miniScript".capitalized	// returns "MiniScript"
string.capitalized = function()
	if self.len < 2 then return self.upper
	return self[0].upper + self[1:]
end function

// titleCase: capitalize each word in the string, except for
// small words (defined in stringUtil.smallWords) that are
// not the first or last word of the string.
//
// Example:
//		"a tale of two cities".titleCase	// returns "A Tale of Two Cities"
string.titleCase = function(delimiter=" ")
	words = self.split(delimiter)
	for i in words.indexes
		if i == 0 or i == words.len-1 or smallWords.indexOf(words[i]) == null then
			words[i] = words[i].capitalized
		end if
	end for
	return words.join(delimiter)
end function

// startsWith: return true if this string starts with the given substring.
string.startsWith = function(s)
	return self.len >= s.len and self[:s.len] == s
end function

// endsWith: return true if this string ends with the given substring.
string.endsWith = function(s)
	return self.len >= s.len and self[-s.len:] == s
end function

// contains: return true if this string contains the given substring anywhere.
string.contains = function(s)
	return self.indexOf(s) != null
end function

// pad: return this string, padded (and optionally cut) to a desired length.
string.pad = function(length, padChar=" ", cutIfTooLong=true)
	if self.len > length then
		if cutIfTooLong then return self[:length]
	else if self.len < length then
		return self + padChar * (length - self.len)
	end if
	return self
end function

// trim: remove any leading and trailing characters that are in the given set.
// Example:
//		"  hello ".trim		// returns "hello"
string.trim = function(charsToRemove=null)
	if charsToRemove == null then charsToRemove = whitespace
	len = self.len
	p0 = 0
	while p0 < len and charsToRemove.indexOf(self[p0]) != null
		p0 = p0 + 1
	end while
	p1 = self.len - 1
	while p1 >= p0 and charsToRemove.indexOf(self[p1]) != null
		p1 = p1 - 1
	end while
	return self[p0:p1+1]
end function

// trimRight: remove any trailing characters that are in the given set.
// Example:
//		"  hello ".trimRight		// returns "  hello"
string.trimRight = function(charsToRemove=null)
	if charsToRemove == null then charsToRemove = whitespace
	p1 = self.len - 1
	while p1 >= 0 and charsToRemove.indexOf(self[p1]) != null
		p1 = p1 - 1
	end while
	return self[:p1+1]
end function

// trimLeft: remove any leading characters that are in the given set.
// Example:
//		"  hello ".trimLeft		// returns "hello "
string.trimLeft = function(charsToRemove=null)
	if charsToRemove == null then charsToRemove = whitespace
	len = self.len
	p0 = 1
	while p0 < len and charsToRemove.indexOf(self[p0]) != null
		p0 = p0 + 1
	end while
	return self[p0:]
end function

string.reverse = function()
	chars = self.split("")
	for i in range(0, chars.len/2-1)
	    negi = -1 - i
		temp = chars[i]
		chars[i] = chars[negi]
		chars[negi] = temp
	end for
	return chars.join("")
end function

// splitLines: split this string into lines, based on any of the 
// common line break patterns (CR, LF, and CRLF).  Note that it
// assumes only ONE of these patterns is used, not some crazy mix.
string.splitLines = function()
	lines = []
	if self.indexOf(CR+LF) != null then
		lines = self.split(CR+LF)
	else if self.indexOf(CR) != null then
		lines = self.split(CR)
	else
		lines = self.split(LF)
	end if
	return lines
end function

// Wrap the given string on word breaks (spaces) to
// fit in the given width.  Return as a list of strings.
// Parameters:
//		self: string to wrap
//		width: character limit per line; defaults to 67
string.wrap = function(width=67)
	if self == "" then return [""]
	result = []
	s = self
	while s
		if s.len <= width then
			result.push s
			return result
		end if
		foundCut = false
		for i in range(width, 0)
			if s[i] == " " then
				result.push s[:i]
				s = s[i+1:]
				foundCut = true
				break
			end if
		end for
		if not foundCut then
			// Couldn't find a space to cut on...
			// so, out of desperation, just cut at width
			result.push s[:width]
			s = s[width:]
		end if
	end while
	return result
end function

string.cipher = function(charMap)
	chars = self.split("")
	for i in chars.indexes
		c = chars[i]
		if charMap.hasIndex(c) then chars[i] = charMap[c]
	end for
	return chars.join("")
end function

string.rot13 = function()
	if not outer.hasIndex("rot13map") then
		outer.rot13map = {}
		c0 = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		c1 = "nopqrstuvwxyzabcdefghijklmNOPQRSTUVWXYZABCDEFGHIJKLM"
		for i in c0.indexes
			rot13map[c0[i]] = c1[i]
		end for
	end if
	return self.cipher(rot13map)
end function

runUnitTests = function()
	print "Unit testing: stringUtil"
	
	errorCount = 0
	assertEqual = function(actual, expected, note)
		if actual != expected then
			print "Unit test failure (" + testing + "): expected " + expected + ", got " + actual
			outer.errorCount = errorCount + 1
		end if
	end function

	testing = "capitalized"
	assertEqual "hello".capitalized, "Hello"
	assertEqual "miniScript".capitalized, "MiniScript"

	testing = "titleCase"
	assertEqual "a tale of two cities".titleCase, "A Tale of Two Cities"
	assertEqual "a word to live by".titleCase, "A Word to Live By"

	testing = "startsWith"
	assertEqual "hello world".startsWith("he"), true
	assertEqual "hello world".startsWith("world"), false
	assertEqual "hello world".startsWith("lo"), false
	assertEqual "hi".startsWith("hello"), false
	
	testing = "endsWith"
	assertEqual "hello world".endsWith("he"), false
	assertEqual "hello world".endsWith("world"), true
	assertEqual "hello world".endsWith("lo"), false
	assertEqual "hi".endsWith("hello"), false
	
	testing = "contains"
	assertEqual "hello world".contains("he"), true
	assertEqual "hello world".contains("world"), true
	assertEqual "hello world".contains("lo"), true
	assertEqual "hi".contains("hello"), false
	
	testing = "pad"
	assertEqual "foo".pad(5), "foo  "
	assertEqual "foo".pad(2), "fo"
	assertEqual "foo".pad(10, "."), "foo......."
	assertEqual "foo".pad(2, " ", false), "foo"
	
	s = " " + char(9) + "hello" + char(9) + " "
	testing = "trim"
	assertEqual s.trim, "hello"
	testing = "trimLeft"
	assertEqual s.trimLeft, "hello" + char(9) + " "
	testing = "trimRight"
	assertEqual s.trimRight, " " + char(9) + "hello"
	
	testing = "reverse"
	assertEqual "Hello world!".reverse, "!dlrow olleH"
	
	testing = "rot13"
	assertEqual "Hello world!".rot13, "Uryyb jbeyq!"
	assertEqual "Uryyb jbeyq!".rot13, "Hello world!"
	
	testing = "splitLines"
	assertEqual ("Hello" + CR + "world").splitLines, ["Hello", "world"]
	assertEqual ("Hello" + LF + "world").splitLines, ["Hello", "world"]
	assertEqual ("Hello" + CR + LF + "world").splitLines, ["Hello", "world"]
	assertEqual "No breaks".splitLines, ["No breaks"]
	
	testing = "wrap"
	assertEqual "".wrap(24), [""]
	assertEqual "Now is the time for all good folks to come together".wrap(24),
		["Now is the time for all", "good folks to come", "together"]
	
	if errorCount == 0 then
		print "All tests passed.  Yay!"
	else
		print errorCount + " error" + "s" * (errorCount!=1) + " found."
	end if

end function

if globals == locals then runUnitTests


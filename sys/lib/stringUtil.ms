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
string.capitalized = function
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

// isNumeric: returns true if this string is a valid number like "-3.1415".
// You should be able to get a valid value out of val() whenever this is true.
string.isNumeric = function
	state = "PRENUM"
	for c in self
		if state == "PRENUM" then
			if c <= " " then continue
			if c == "+" or c == "-" or ("0" <= c <= "9") then
				state = "WHOLEPART"
			else if c == "." then
				state = "DECPART"
			else
				return false
			end if
		else if state == "WHOLEPART" then
			if "0" <= c <= "9" then continue
			if c == "." then
				state = "DECPART"
			else if c == "E" then
				state = "PREEXP"
			else
				return false
			end if
		else if state == "DECPART" then
			if "0" <= c <= "9" then continue
			if c == "E" then state = "PREEXP" else return false
		else if state == "PREEXP" then
			if c == "+" or c == "-" or ("0" <= c <= "9") then
				state = "EXPONENT"
			else
				return false
			end if
		else if state == "EXPONENT" then
			if "0" <= c <= "9" then continue
			return false
		end if
	end for
	return state != "PRENUM" and state != "PREEXP"
end function

// lastIndexOf: returns the *last* index of the given substring, optionally
// before a given index.  Returns null if not found.
// Examples:
//		"Hello".lastIndexOf("l")		// returns 3
//		"Hello".lastIndexOf("l", 3)		// returns 2
string.lastIndexOf = function(substr, beforeIdx=null)
	sslen = substr.len
	if beforeIdx == null then i = self.len - sslen else i = beforeIdx - 1
	while i >= 0
		if self[i:i+sslen] == substr then return i
		i -= 1
	end while
	return null
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
	if not self then return self
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
	if not self then return self
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
	if not self then return self
	if charsToRemove == null then charsToRemove = whitespace
	len = self.len
	p0 = 0
	while p0 < len and charsToRemove.indexOf(self[p0]) != null
		p0 = p0 + 1
	end while
	return self[p0:]
end function

// string.compress: replaces any runs of a given character with a 
// single instance of that character.
// Example:
//		"Hi!!! Bob!!".compress("!")  // returns "Hi! Bob!"
string.compress = function(charToCompress=" ")
	s = self
	prevLen = -1
	charTimes2 = charToCompress + charToCompress
	while true
		s = s.replace(charTimes2, charToCompress)
		if s.len == prevLen then break
		prevLen = s.len
	end while
	return s
end function

// ellideEnd: shortens a string (if needed) by cutting and adding
// an ellipsis to the end.
// Example:
//		"Hello World".ellideEnd(6)	// returns "Hello…"
string.ellideEnd = function(maxLength=10)
	if self.len <= maxLength then return self
	return self[:maxLength-1] + "…"
end function

// ellideMiddle: shortens a string (if needed) by adding an ellipsis
// to the middle, cutting out the middle part of the string.
// Example:
//		"Hello World".ellideMiddle(6)	// returns "He…rld"
string.ellideMiddle = function(maxLength=10)
	if self.len <= maxLength then return self
	return self[:ceil(maxLength/2)-1] + "…" + self[-maxLength/2:]
end function

string.reverse = function
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
string.splitLines = function
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
	for s in self.split(char(13))
		while s
			if s.len <= width then
				result.push s
				break
			end if
			foundCut = false
			for i in range(width, 0, -1)
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
	end for
	return result
end function

// cipher: apply a map to every character in the string.  This
// can be used to make a simple substitution cipher (though it
// could also be used to replace special characters with HTML
// entity codes, etc.).
string.cipher = function(charMap)
	chars = self.split("")
	for i in chars.indexes
		c = chars[i]
		if charMap.hasIndex(c) then chars[i] = charMap[c]
	end for
	return chars.join("")
end function

// rot13: apply the classic (and very simple) substitution cipher
// of replacing each letter with the letter 13 positions away from
// it in the alphabet.  Note that if you apply rot13 twice, you 
// get back the original string.
string.rot13 = function
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

if intrinsics.hasIndex("RawData") then
	
	// urlEncode: Encode a string so it can be used as a URL query
	// parameter.
	string.urlEncode = function
		urlSafeChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
		  "abcdefghijklmnopqrstuvwxyz0123456789-_.~"
		bytes = new RawData
		bytes.resize self.len * 3
		len = bytes.setUtf8(0, self)
		result = []
		for i in range(0, len-1)
			b = bytes.byte(i)
			c = char(b)
			if urlSafeChars.contains(c) then
				result.push c
			else
				result.push "%" + hex2(b)
			end if
		end for
		return result.join("")
	end function
	
	// urlDecode: convert a URL-encoded string back into plain text.
	string.urlDecode = function
		bytes = new RawData
		bytes.resize self.len + 2 * (self.split("%").len - 1)
		i = 0		// where we are in self (input)
		j = 0		// where we are in bytes (output)
		while i < self.len
			c = self[i]
			if c == "%" then
				hexStr = self[i+1:i+3]
				i = i + 3
				bytes.setByte j, hexVal(hexStr)
			else
				bytes.setByte j, c.code
				i = i + 1
			end if
			j = j + 1
		end while
		return bytes.utf8(0, j)
	end function

end if

// between: find a string between two substrings.  This can be 
// used, for example, to find text between two HTML tags.
string.between = function(startTag, endTag, after=null)
	if startTag == "" then
		pos0 = 0
	else
		pos0 = self.indexOf(startTag, after)
	end if
	if pos0 == null then return null
	pos0 = pos0 + startTag.len
	if endTag == "" then
		pos1 = self.len
	else
		pos1 = self.indexOf(endTag, pos0-1)
	end if
	if pos1 == null then return null
	return self[pos0:pos1]
end function


// editDistance: return the Levenshtein distance, aka the edit 
// distance, between the two strings.  That's the number of 
// insertions, deletions, or changes required to make one string
// match the other.  A result of 0 means the strings are
// identical; higher values mean more different.
string.editDistance = function(s2)
	n = self.len
	m = s2.len
	if n == 0 then return m
	if m == 0 then return n
	
	s1chars = self.split("")
	s2chars = s2.split("")
	d = range(0, m)	
	lastCost = 0
	
	for i in range(1, n)
		s1char = s1chars[i-1]
		lastCost = i
		jMinus1 = 0
		for j in range(1, m)
			if s1char == s2chars[jMinus1] then cost = 0 else cost = 1
			
			// set nextCost to the minimum of the following three possibilities:
			a = d[j] + 1
			b = lastCost + 1
			c = cost + d[jMinus1]
			
			if a < b then
				if c < a then nextCost = c else nextCost = a
			else
				if c < b then nextCost = c else nextCost = b
			end if
			
			d[jMinus1] = lastCost
			lastCost = nextCost
			jMinus1 = j
		end for
		d[m] = lastCost
	end for
	
	return nextCost
end function

// string.fill: substitute values from argMap into
// this string at places identified by {key}.
// (See string.match for the inverse operation.)
string.fill = function(args)
	s = self
	for idx in args.indexes
		s = s.replace("{" + idx + "}", args[idx])
	end for
	return s
end function

// string.match: takes a pattern string that may
// contain fields to fill in, identified by {key}.  If
// the this string can be matched to that pattern, then
// it returns a map with the key-value pairs filled in
// with the corresponding parts of this string.  If it
// can't match, then returns null.
// (See string.fill for the inverse operation.)
string.match = function(pattern)
	// Start by splitting this pattern into literal and field parts.
	parts = []
	p = 0
	while p < pattern.len
		// find the end of a literal part
		nextp = pattern.indexOf("{", p-1)
		if nextp == null then
			parts.push pattern[p:]
			break
		end if
		if nextp > p then parts.push pattern[p:nextp]
		p = nextp
		// find the end of a field part
		nextp = pattern.indexOf("}", p)
		if p == null then
			parts[-1] = parts[-1] + pattern[p:]
			break
		end if
		parts.push pattern[p:nextp+1]
		p = nextp + 1
	end while
	// Now, find each literal parts in this string,
	// and fill in the variable parts (fields) in between.
	result = {}
	p = 0
	lastStartPos = 0
	for i in parts.indexes
		part = parts[i]
		if part[0] == "{" and part[-1] == "}" then
			lastStartPos = p
			if i == parts.len-1 then result[part[1:-1]] = self[p:]
			continue
		end if
		p = self.indexOf(part, p-1)
		if p == null then return null  // literal part not found
		if i > 0 then
			result[parts[i-1][1:-1]] = self[lastStartPos:p]
		end if
		lastStartPos = p
		p = p + part.len
	end for
	return result
end function

runUnitTests = function
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
	
	testing = "isNumeric"
	assertEqual "hello".isNumeric, false
	assertEqual "3.14abc".isNumeric, false
	assertEqual "abc3.14".isNumeric, false
	assertEqual "".isNumeric, false
	assertEqual "3.14".isNumeric, true
	assertEqual "-3.14".isNumeric, true
	assertEqual "+3.14".isNumeric, true
	assertEqual "3.14E6".isNumeric, true
	assertEqual "-3.14E-6".isNumeric, true
	assertEqual "  -3E-6".isNumeric, true	
	
	testing = "lastIndexOf"
	assertEqual "Hello world".lastIndexOf("l"), 9
	assertEqual "Hello world".lastIndexOf("l", 9), 3
	assertEqual "Hello world".lastIndexOf("l", 3), 2
	assertEqual "Hello world".lastIndexOf("l", 2), null
	assertEqual "big billy".lastIndexOf("bi"), 4
	assertEqual "big billy".lastIndexOf("bi", 4), 0
		
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
	
	s = "no extra"
	testing = "trim"; 		assertEqual s.trim, s
	testing = "trimLeft";	assertEqual s.trimLeft, s
	testing = "trimRight";	assertEqual s.trimRight, s
	
	testing = "compress"
	s = "Hi....  Bob.  SHHH"
	assertEqual s.compress, "Hi.... Bob. SHHH"
	assertEqual s.compress("."), "Hi.  Bob.  SHHH"
	assertEqual s.compress("H"), "Hi....  Bob.  SH"
	assertEqual "ooOOoo".compress("o"), "oOOo"
	assertEqual "ooOoo".compress("O"), "ooOoo"
	
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

	if intrinsics.hasIndex("RawData") then
		testing = "urlEncode/urlDecode"
		assertEqual "Hello François!".urlEncode, "Hello%20Fran%C3%A7ois%21"
		assertEqual "Hello%20Fran%C3%A7ois%21".urlDecode, "Hello François!"
	end if
	
	testing = "between"
	s = "foobarbaz"
	assertEqual s.between("foo","baz"), "bar"
	assertEqual s.between("oba","rba"), ""
	assertEqual s.between("foo",""), "barbaz"
	assertEqual s.between("","baz"), "foobar"
	
	testing = "editDistance"
	assertEqual "Foo".editDistance(""), 3
	assertEqual "".editDistance("Foo"), 3
	assertEqual "Foo".editDistance("FOO"), 2
	assertEqual "FOO".editDistance("Foo"), 2
	assertEqual "Foobar".editDistance("Boobear"), 2
	assertEqual "Boobear".editDistance("Foobar"), 2
	
	testing = "fill"
	m = {"greeting":"Hello", "place":"world"}
	assertEqual "{greeting} {place}!".fill(m), "Hello world!"
	assertEqual "{greeting} {extra}!".fill(m), "Hello {extra}!"
	assertEqual "a {1} and a {2}".fill(["zero", "one", "two"]), "a one and a two"
	
	testing = "match"
	pat = "Give {who} a {what}"
	m = "Give me a treat".match(pat)
	assertEqual m, {"who":"me", "what":"treat"}	
	assertEqual "Lend me a book".match(pat), null
	pat = "{verb} the {noun}!"
	m = "Jump the shark!".match(pat)
	assertEqual m, {"verb":"Jump", "noun":"shark"}
	m = "Batten down the hatches!".match(pat)
	assertEqual m, {"verb":"Batten down", "noun":"hatches"}
	
	if errorCount == 0 then
		print "All tests passed.  Yay!"
	else
		print errorCount + " error" + "s" * (errorCount!=1) + " found."
	end if
	
end function

if globals == locals then runUnitTests


// This is a little module to read Tab-Separated Value (TSV) files,
// such as can be exported (for example) from Google Sheets.
// The file should be organized by row and column, with row headers
// in column 1 and column headers in row 1.  The return value will
// be a map of maps, indexed first by row header and second by
// column header.
//
// Example: if your data file looks like this:
//            color    points    calories
//    apple   red      100       234.5
//    banana  yellow   200       180.75
//    cherry  red      500       85.235
//
// ...and you used this module to read this file into a variable
// called data, then you could read data.apple.points to find
// the value 100, or equivalently, data["apple"]["points"].
//
// The map for each row will also have a _lineNum entry which is
// the 1-based line number that data came from.

// tsv.parseLines: parse TSV data that's already in a list of lines.
parseLines = function(lines)
	TAB = char(9)
	CR = char(13)
	result = {}
	// First line should be column names.
	colNames = lines[0].split(TAB)
	// Subsequent lines are data, with row names at index 0.
	for lineNum in range(1, lines.len-1)
		line = lines[lineNum]
		if not line then continue
		if line[-1] == CR then line = line[:-1]  // (fix Windows line endings)
		fields = line.split(TAB)
		if fields[0] == "" then continue
		rowMap = {"_lineNum": lineNum + 1}
		result[fields[0]] = rowMap
		for col in range(1, fields.len-1)
			value = fields[col]
			if value == "0" or val(value) > 0 then value = val(value)
			rowMap[colNames[col]] = fields[col]
		end for
	end for
	return result
end function

// tsv.parseLines: parse TSV data in a file at the given path.
parseFile = function(path)
	lines = file.readLines(path)
	if lines == null then
		print "tsv.parseFile: unable to read " + path
		return null
	end if
	return parseLines(lines)
end function

// tsv.parse: parse TSV data where lines are separated by CR, LF, or CRLF.
parse = function(text)
	CR = char(13)
	LF = char(10)
	lines = []
	if text.indexOf(CR+LF) != null then
		lines = text.split(CR+LF)
	else if text.indexOf(CR) != null then
		lines = text.split(CR)
	else
		lines = text.split(LF)
	end if
	return parseLines(lines)
end function

	
//----------------------------------------------------------------------
// Unit tests (run when you load & run this script directly).
runUnitTests = function()
	print "Unit testing: tsv"
	
	errorCount = 0
	assertEqual = function(actual, expected)
		if actual != expected then
			print "Unit test failure: expected " + expected + ", got " + actual
			outer.errorCount = errorCount + 1
		end if
	end function
	
	TAB = char(9)
	sampleData = [
		TAB + "color" + TAB + "points" + TAB + "calories",
		"apple" + TAB + "red" + TAB + 100 + TAB + 234.5,
		"banana" + TAB + "yellow" + TAB + 200 + TAB + 180.75,
		"cherry" + TAB + "red" + TAB + 500 + TAB + 85.235]
	data = parseLines(sampleData)
	assertEqual data.len, 3
	assertEqual data.apple.color, "red"
	assertEqual data.banana.color, "yellow"
	assertEqual data.cherry.points, 500
	assertEqual data.cherry._lineNum, 4
	
	data = parse(sampleData.join(char(13)+char(10)))
	assertEqual data.apple.points, 100
	
	data = parse(sampleData.join(char(13)))
	assertEqual data.apple.points, 100
	
	data = parse(sampleData.join(char(10)))
	assertEqual data.apple.points, 100
	
	if errorCount == 0 then
		print "All tests passed.  Woo!"
	else
		print errorCount + " error" + "s" * (errorCount!=1) + " found."
	end if

end function

if locals == globals then runUnitTests

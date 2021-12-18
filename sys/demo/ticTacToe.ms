// Tic-Tac-Toe (aka Naughts and Crosses)

// Load the images we use for X and O marks
marks = {}
marks.O = file.loadImage("/sys/pics/XO/O-red.png")
marks.X = file.loadImage("/sys/pics/XO/X-blue.png")

// Set up the display
clear
gfx.clear color.white
boxColor = "#444444"
boxSize = 150

// We map positions to rows and columns as follows:
//    6  7  8
//    3  4  5
//    0  1  2

board = [""] * 9  // "X" or "O" in each position

// Return the winner of the current board: "X", "O", or null
winner = function(board)
	// check columns
	if board[0] and board[0]==board[3] and board[0]==board[6] then return board[0]
	if board[1] and board[1]==board[4] and board[1]==board[7] then return board[1]
	if board[2] and board[2]==board[5] and board[2]==board[8] then return board[2]
	// check rows
	if board[0] and board[0]==board[1] and board[0]==board[2] then return board[0]
	if board[3] and board[3]==board[4] and board[3]==board[5] then return board[3]
	if board[6] and board[6]==board[7] and board[6]==board[8] then return board[6]
	// check diagonals
	if board[0] and board[0]==board[4] and board[0]==board[8] then return board[0]
	if board[6] and board[6]==board[4] and board[6]==board[2] then return board[6]
	return null
end function

// functions to get the row and column for any position
col = function(position)
	return position % 3
end function
row = function(position)
	return floor(position/3)
end function

// draw a mark for the given player at the given position
drawMark = function(position, player)
	x = 480 + boxSize * (col(position) - 1)
	y = 320 + boxSize * (row(position) - 1)
	image = marks[player]
	gfx.drawImage image, x - image.width/2, y - image.height/2
	board[position] = player
end function

// draw the board
drawBoard = function
	top = 320 - boxSize*1.5
	bot = 320 + boxSize*1.5
	left = 480 - boxSize*1.5
	right = 480 + boxSize*1.5
	hb = boxSize/2   // ("half box")
	gfx.line 480 - hb, top, 480 - hb, bot, color.gray, 10
	gfx.line 480 + hb, top, 480 + hb, bot, color.gray, 10
	gfx.line left, 320 - hb, right, 320 - hb, color.gray, 10
	gfx.line left, 320 + hb, right, 320 + hb, color.gray, 10
end function
drawBoard

human = "X"
computer = "O"

// Return a list of the empty positions on the current board.
emptySpaces = function
	result = []
	for i in board.indexes
		if board[i] == "" then result.push i
	end for
	return result
end function		

// Return whether the given player move would win the game,
// if played on the given board.
wouldWin = function(board, pos, player)
	//print "wouldWin(" + board + ", " + pos + ", " + player + ")"
	newBoard = board[0:]
	newBoard[pos] = player
	return winner(newBoard) == player
end function

// Return the board position for computer's move,
// or null if no move is possible.  This is the AI
// of this game.  Can you make it any smarter?
getComputerMove = function
	// gather possible moves
	available = emptySpaces
	if not available then return null  // no empty spaces!
	available.shuffle
	
	// if there is a move that gets us a win, take it!
	//print "Checking for win in " + available
	for move in available
		if wouldWin(board, move, computer) then return move
	end for
	
	// if there is a move that blocks the player, do that
	//print "Checking for block in " + available
	for move in available
		if wouldWin(board, move, human) then return move
	end for
	
	// otherwise, let's just pick a random move
	//print "Returning first item in " + available
	return available[0]
end function

// Do the computer's move.
doComputerMove = function
	move = getComputerMove
	if move != null then
		drawMark move, computer
	end if
end function

// Handle a click from the player.
handleClick = function
	// figure out what column and row was clicked
	c = 1 + round((mouse.x - 480) / boxSize)
	r = 1 + round((mouse.y - 320) / boxSize)
	if c < 0 or c > 2 or r < 0 or r > 2 then return
	pos = r*3 + c
	if board[pos] then return  // space already taken
	
	// draw the mark, and wait a bit
	drawMark pos, human
	wait 0.25
	if winner(board) then return
	wait 0.25
	
	// then do the computer's move in response
	doComputerMove
end function

// Main loop
while winner(board) == null and emptySpaces
	if mouse.button then handleClick
	if key.pressed("escape") or key.pressed("q") then break
	yield
end while

if winner(board) then print winner(board) + " wins!"
key.clear


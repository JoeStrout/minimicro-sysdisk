// Event-driven programming!
//
// Create sprites derived from events.EventSprite, then assign
// functions to their onKey, onKeyDown, onKeyUp, onClick, etc.
// properties (see below).  You can also assign an update function
// to get called every frame.  Call .start on each Sprite.
// Then call eventLoop.run.  The various events will get invoked
// at the appropriate times.  (See test method below.)


// Sprite display used by EventSprite and eventLoop; reassign this
// after importing if you want your sprites on a different display.
spriteDisplay = display(4)

// Helper function to invoke a method as a member of
// an instance, so that the method gets 'self' bound
// to that instance just like any other class method.
invokeAsSelf = function(func, objToBeSelf)
	objToBeSelf._f = @func
	objToBeSelf._f
end function
invokeAsSelf1 = function(func, objToBeSelf, param1)
	objToBeSelf._f = @func
	objToBeSelf._f param1
end function

EventHandler = {}
EventHandler.action = null

KeyHandler = {}
KeyHandler.mode = 1  // 0: on down; 1: while held; 2: on up
KeyHandler._wasPressed = null
KeyHandler._check = function(owner)
	if self._wasPressed == null then self._wasPressed = {}
	for k in self.indexes
		if k[0] == "_" then continue
		if key.keyNames.indexOf(k) == null then continue
		if key.pressed(k) then
			if self._wasPressed.hasIndex(k) then
				// still pressed
				if self.mode == 1 then 	invokeAsSelf self[k], owner
			else
				// just now pressed, i.e. keyDown
				if self.mode == 0 then invokeAsSelf self[k], owner
				self._wasPressed.push k
			end if
		else if self._wasPressed.hasIndex(k) then
			// just released, i.e. keyUp
			if self.mode == 2 then invokeAsSelf self[k], owner
			self._wasPressed.remove k
		end if
	end for	
end function

EventSprite = new Sprite

EventSprite.onKey = new KeyHandler
EventSprite.onKeyDown = new KeyHandler
EventSprite.onKeyDown.mode = 0
EventSprite.onKeyUp = new KeyHandler
EventSprite.onKeyUp.mode = 2
EventSprite.onClick = null
EventSprite.onRightClick = null
EventSprite.onDrag = null
EventSprite.onDragEnd = null
EventSprite.onMouseOver = null
EventSprite.update = null

EventSprite._dragging = false
EventSprite.ignoreClicks = false
EventSprite.joystick = "any" // or, assign 1 through 29

EventSprite._update = function()
	self.update
	self.onKey._check self
	self.onKeyUp._check self
	self.onKeyDown._check self
end function

// Simple state machine support.  Basically just gives you
// a place to add code when you change states via spr.enterState.
EventSprite.state = ""
EventSprite.stateStartTime = time
EventSprite.timeInState = function()
	return time - self.stateStartTime
end function
EventSprite.onEnterState = function(newState); end function
EventSprite.onExitState = function(toNewState); end function
EventSprite.enterState = function(newState)
	if newState == self.state then return
	self.onExitState newState
	self.onEnterState newState
	self.state = newState
	self.stateStartTime = time
end function

EventSprite.start = function()
	// ensure we have a valid bounds
	if not self.localBounds then
		self.localBounds = new Bounds
		self.localBounds.width = self.image.width
		self.localBounds.height = self.image.height
	end if
	// add to the display
	spriteDisplay.sprites.push self
end function

eventLoop = {}
eventLoop.onKey = new KeyHandler
eventLoop.onKeyDown = new KeyHandler
eventLoop.onKeyDown.mode = 0
eventLoop.onKeyUp = new KeyHandler
eventLoop.onKeyUp.mode = 2
eventLoop.onClick = null
eventLoop.onRightClick = null
eventLoop.onDrag = null
eventLoop.onDragEnd = null
eventLoop.running = false
eventLoop.delayedCalls = []
eventLoop.lastMouseOver = null
eventLoop.stop = function()
	self.running = false
end function
spriteHitBy = function(pos)
	for i in range(spriteDisplay.sprites.len-1)
		sp = spriteDisplay.sprites[i]
		if not sp.ignoreClicks and sp.contains(pos) then return sp
	end for
	return null
end function

eventLoop.doAfter = function(delay, f)
	self.delayedCalls.push {"time":time + delay, "action":@f}
	self.delayedCalls.sort "time"
end function

eventLoop.update = function()
	self.onKey._check self
	self.onKeyUp._check self
	self.onKeyDown._check self
	while self.delayedCalls and self.delayedCalls[0].time < time
		self.delayedCalls.pull.action
	end while
	for sp in spriteDisplay.sprites
		if sp isa EventSprite then sp._update
	end for
	if mouse.button then
		if not self.mouseWasDown then
			// initial click: find sprite, start drag
			self.dragging = spriteHitBy(mouse)
			if self.dragging then self.dragging.onClick else self.onClick
			self.mouseWasDown = true
		else
			// subsequent frames: continue the drag
			if self.dragging then self.dragging.onDrag else self.onDrag
		end if
	else if self.mouseWasDown then
		// was down, but no longer is; stop dragging
		if self.dragging then
			self.dragging.onDragEnd
			self.dragging = null
		else
			self.onDragEnd
		end if
		self.mouseWasDown = false
	else
		// mouse isn't down, and wasn't before either; just do mouse-over
		mouseOver = spriteHitBy(mouse)
		if mouseOver != self.lastMouseOver then
			if mouseOver and mouseOver.hasIndex("onMouseOver") then mouseOver.onMouseOver
			self.lastMouseOver = mouseOver
		end if
	end if
	if mouse.button(1) then
		hit = spriteHitBy(mouse)
		if hit then hit.onRightClick else self.onRightClick
	end if
end function

eventLoop.run = function()
	lastTime = time
	now = time
	outer.dt = now - lastTime
	lastTime = now
	self.running = true
	self.mouseWasDown = mouse.button
	self.dragging = null
	while self.running
		self.update
		yield
	end while
end function

test = function()
	clear
	display(4).mode = displayMode.sprite
	spr = new EventSprite
	spr.image = file.loadImage("/sys/pics/Wumpus.png")
	spr.onKey = new KeyHandler
	spr.onKey["left"] = function()
		self.x = self.x - 10
		if self.x < 50 then eventLoop.stop
	end function
	spr.onKey["right"] = function()
		self.x = self.x + 10
	end function
	eventLoop.onKeyDown["space"] = function(); print "space down"; end function
	eventLoop.onKey["space"] = function(); print "space held"; end function
	eventLoop.onKeyUp["space"] = function(); print "space up"; end function

	spr.onClick = function()
		self.scale = 1.5
	end function
	spr.onDrag = function()
		self.x = mouse.x
		self.y = mouse.y
	end function
	spr.onDragEnd = function()
		self.scale = 1
	end function

	spr.x = 480
	spr.y = 320
	spr.start

	eventLoop.run
end function

if locals == globals then test

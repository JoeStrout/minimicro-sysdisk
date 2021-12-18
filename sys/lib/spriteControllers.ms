// The spriteControllers module adds some helper classes to aid with
// sprite animation and platformer games.  These are NOT required to
// use sprites; you can do it all yourself if you prefer.

// Define a class to represent an animation: this is one or more frames
// (images), plus the frames per second we should cycle through them.
// It also holds the current state, so rather than share Animation 
// objects among multiple users, you should clone them so each user can
// have a unique state.
Animation = {}
Animation.speed = 1
Animation.loop = true

// Apply this animation to the given sprite (and update its state).
Animation.applyTo = function(sprite, dt=0.1)
	if self.speed == 0 then return
	self.timeTillNextFrame = self.timeTillNextFrame - dt
	if self.timeTillNextFrame > 0 then return
	self.curFrame = self.curFrame + sign(self.speed)
	if self.curFrame < 0 or self.curFrame >= self.frames.len then
		if self.loop then
			self.curFrame = (self.curFrame + self.frames.len) % self.frames.len
		else
			self.curFrame = self.curFrame - sign(self.speed)
		end if
	end if
	sprite.image = self.frames[self.curFrame]
	self.timeTillNextFrame = 1 / (self.fps * abs(self.speed))
end function

// Create a new Animation from a list of frames, and the frames/second speed.
newAnimation = function(frameList, fps=10)
	noob = new Animation
	if frameList isa Image then frameList = [frameList]
	noob.frames = frameList  // list of images to play
	noob.fps = fps  // frames per second
	noob.curFrame = -1
	noob.timeTillNextFrame = 0
	return noob
end function

// Create an exact copy (clone) of this Animation.
// Important: do NOT share an animation between multiple sprites!  Each
// animation object maintains its own state.  So you must make a fresh
// clone for each sprite that uses it.
Animation.clone = function
	noob = {} + self  // MiniScript makes this really easy!
	return noob
end function

// Define a Sprite subclass for any sprite that uses an Animation.
Animated = new Sprite
Animated.curAnim = null
Animated.normalScale = [1,1]
Animated.flippedScale = [-1,1]

// Update method: call this on every frame to update the sprite.
Animated.update = function(dt=0.1)
	if self.curAnim then self.curAnim.applyTo self, dt
end function

// Helper method to set the given animation as curAnim,
// and start it over from the beginning.
Animated.play = function(anim)
	self.curAnim = anim
	anim.curFrame = -1
	anim.timeTillNextFrame = 0
end function

// Helper method to check an input.  The input argument can
// be a string identifying a key, or a truth value.
inputPressed = function(keyOrValue)
	if keyOrValue isa string then return key.pressed(keyOrValue)
	if keyOrValue isa number then return key > 0.5 or key < -0.5
	return keyOrValue
end function

// Helper method to move one value towards another.
// (This is also available in the mathUtil module.)
moveTowards = function(curVal, targetVal, maxChange)
	if abs(curVal - targetVal) < maxChange then return targetVal
	return curVal + maxChange * sign(targetVal - curVal)
end function

// Define some state strings (helps keep track of what a character is doing)
IDLE = "IDLE"
RUNLEFT = "RUNLEFT"
RUNRIGHT = "RUNRIGHT"
JUMPING = "JUMPING"
FALLING = "FALLING"
CLIMBING = "CLIMBING"

// Define a class for platformer characters: run, jump, and climb.
Platformer = new Animated
// Properties you should set for each character:
Platformer.idleAnim = null
Platformer.runAnim = null
Platformer.jumpUpAnim = null
Platformer.fallDownAnim = null
Platformer.climbAnim = null	  // Note that climbAnim is special:
// it's played forward going up, backward going down, and paused when not moving.

Platformer.runSpeed = 400   // run speed, in pixels/sec
Platformer.runAccel = 2000	// run acceleration, in pixels/sec^2
Platformer.stopAccel = 5000
Platformer.climbSpeed = 200	// speed when climbing up or down
Platformer.jumpSpeed = 1200	// initial vertical speed in pixels/sec
Platformer.gravity = -7000	// speed and direction of gravity, pixels/sec^2
Platformer.boost = 4000		// how much gravity is reduced by holding jump
Platformer.flyAccel = 1000	// horizontal acceleration while airborne
Platformer.maxYStep = 16	// largest amount we'll automatically climb up

Platformer.leftInput = "left"		// keys used to control this character
Platformer.rightInput = "right"
Platformer.upInput = "up"
Platformer.downInput = "down"
Platformer.jumpInput = "space"
Platformer.footOffset = null	// (defaults to 1/2 the idle frame height)

// Platformer.groundBelow:
// Return the Y level of the ground below the given x,y position on screen.
// You should override or replace this to detect your actual terrain.
Platformer.groundBelow = function(x, y)
	return 0
end function

Platformer.stateStartTime = -1
Platformer.state = null
Platformer.vx = 0
Platformer.vy = 0
Platformer.inBoost = false
Platformer.targetSpeed = 0
Platformer.jumpAvail = false
Platformer.finishSetup = function
	if self.footOffset == null then
		self.footOffset = self.idleAnim.frames[0].height/2
	end if
	self.enterState IDLE
end function

Platformer.applyFreefall = function(dt)
	// apply gravity
	// (with boost, if we've still got the jump button down)
	if self.inBoost and not inputPressed(self.jumpInput) then self.inBoost = false
	text.row = 25
	self.vy = self.vy + (self.gravity + self.boost * self.inBoost) * dt
	// apply "fly" acceleration
	self.vx = moveTowards(self.vx, self.targetSpeed, self.flyAccel * dt)
	dx = self.vx * dt
	dy = self.vy * dt
	// check for hitting the ground or (ToDo) ceiling, or grabbing ladder
	if self.vy < 0 then
		groundLevel = self.groundBelow(self.x, self.y - self.footOffset)
		if groundLevel > self.y - self.footOffset + dy then  // landed!
			self.x = self.x + dx * (groundLevel - self.y + self.footOffset) / dy
			self.y = groundLevel + self.footOffset
			self.enterState IDLE
			self.vy = 0
			return
		end if
	end if
	if (inputPressed(self.upInput) or inputPressed(self.downInput)) and self.canClimb(1) then
		self.enterState CLIMBING
	end if
	// apply velocity to position
	self.x = self.x + dx
	self.y = self.y + dy
end function

Platformer.checkForGround = function
	if self.state == JUMPING then return
	groundLevel = self.groundBelow(self.x, self.y) + self.footOffset
	if groundLevel > self.y and groundLevel < self.y + self.maxYStep then
		// ground is a bit high; move up
		self.y = groundLevel
		if self.state == FALLING then self.enterState IDLE
	else if groundLevel < self.y and self.state != FALLING then
		// whoops, we're not standing on the ground!
		// if it's only a *little* down, just shift down;
		// otherwise start falling.
		if groundLevel < self.y - self.footOffset/2 then
			self.enterState FALLING 
		else
			self.y = groundLevel
		end if
	end if
end function

Platformer.canClimb = function(direction)
	// Subclasses should override this to determine when we can climb.
	// By default, we can climb any time, as long as a climb animation is defined.
	return self.climbAnim != null
end function

Platformer.climb = function(direction, dt)
	if not self.canClimb(direction) then
		self.enterState IDLE
		return
	end if
	self.climbAnim.speed = direction
	self.y = self.y + self.climbSpeed * direction * dt
end function

// enterState: do whatever stuff we need to do when entering each state.
Platformer.enterState = function(newState)
	if newState == self.state then return
	self.exitState
	if newState == IDLE then
		if self.state == FALLING then
			// Landed!  (Here we could play a landing sound or whatever.)
		end if
		self.curAnim = self.idleAnim
		self.targetSpeed = 0
	else if newState == RUNLEFT then
		self.scale = self.flippedScale
		self.targetSpeed = -self.runSpeed
		self.curAnim = self.runAnim
	else if newState == RUNRIGHT then
		self.scale = self.normalScale
		self.targetSpeed = self.runSpeed
		self.curAnim = self.runAnim
	else if newState == JUMPING then
		self.curAnim = self.jumpUpAnim
		self.vy = self.jumpSpeed
		self.vxAtJump = self.vx
		self.inBoost = true
	else if newState == FALLING then
		self.curAnim = self.fallDownAnim
		self.inBoost = false
	else if newState == CLIMBING then
		self.curAnim = self.climbAnim
		self.vx = 0
		self.vy = 0
	end if
	self.state = newState
	self.stateStartTime = time
end function

// exitState: do whatever stuff we need to do when exiting the current state.
Platformer.exitState = function
	// Nothing to do (by default).
end function

// updateState: do whatever we do on every frame, in each state
Platformer.updateState = function(dt)
	if self.state == RUNLEFT or self.state == RUNRIGHT or self.state == IDLE then
		self.vx = moveTowards(self.vx, self.targetSpeed, self.runAccel * dt)
		self.x = self.x + self.vx * dt
		self.checkForGround
	else if self.state == JUMPING then
		self.applyFreefall dt
		if self.vy < 0 then self.enterState FALLING
	else if self.state == FALLING then
		self.applyFreefall dt
	else if self.state == CLIMBING then
		if inputPressed(self.upInput) then
			self.climb 1, dt
		else if inputPressed(self.downInput) then
			self.climb -1, dt
		else
			self.climbAnim.speed = 0
		end if
	end if
end function

Platformer.checkInputs = function
	if self.state == JUMPING or self.state == FALLING then
		// behavior of inputs is somewhat different in the air
		if inputPressed(self.leftInput) then
			self.targetSpeed = -self.runSpeed
		else if inputPressed(self.rightInput) then
			self.targetSpeed = self.runSpeed
		else
			self.targetSpeed = 0
		end if
	else if self.state == CLIMBING then
		// Up/down is actually handled in update.  Here, handle jump.
		if self.jumpAvail and inputPressed(self.jumpInput) then
			// special case: check for left/right input,
			// and set our horizontal speed accordingly.
			self.vx = self.runSpeed * inputPressed(self.rightInput) -
				self.runSpeed * inputPressed(self.leftInput)
			if self.vx != 0 then self.enterState JUMPING
		end if
	else
		// behavior on the ground
		if self.jumpAvail and inputPressed(self.jumpInput) then
			self.enterState JUMPING
		else if inputPressed(self.leftInput) then
			self.enterState RUNLEFT
		else if inputPressed(self.rightInput) then
			self.enterState RUNRIGHT
		else if inputPressed(self.upInput) and self.canClimb(1) then
			self.enterState CLIMBING
		else if inputPressed(self.downInput) and self.canClimb(-1) then
			self.enterState CLIMBING
		else
			self.enterState IDLE
		end if
	end if
	// Don't allow more jumping as long as the jump key is down:
	self.jumpAvail = not inputPressed(self.jumpInput)
end function

// Platformer.update: main update function for Platformer characters.
Platformer.update = function(dt)
	if self.state == null then self.finishSetup
	self.checkInputs
	self.updateState dt
	super.update dt
end function

// updateSprites: update all Animated sprites on the given display.
// To use this method, either set spriteControllers.disp to your
// sprite display, or pass it in as the second parameter.
// If you do neither, then it will try to use display(4).
disp = display(4)
updateSprites = function(dt=0.1, disp=null)
	if disp == null then disp = outer.disp
	for s in disp.sprites
		if s isa Animated then s.update dt
	end for
end function

// Note that this library module does not have a built-in demo;
// for a demo, see /sys/demo/platformer.

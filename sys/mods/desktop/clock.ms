// This desk accessory puts the current date/time in the menu bar,
// but also provides (via menu commands) windows for an analog
// clock and a calendar.

import "dateTime"

// Required stuff for all mods: menuItemText, enable, disable, update.
menuItemText = "Clock"

currentDateTimeStr = function
	return dateTime.str(dateTime.nowVal, "ddd MMM d, h:mm tt")
end function

menuBarItem = null
clockWindow = null
calendarWindow = null

AnalogClock = new gui.Window
AnalogClock.scratchDisp = null
AnalogClock.lastUpdate = 0

AnalogClock.update = function
	now = dateTime.nowVal
	if now - self.lastUpdate < 1 then return
	self.lastUpdate = now
	
	if self.scratchDisp == null then self.scratchDisp = new PixelDisplay
	g = self.scratchDisp
	g.clear color.white, self.width, self.height
	midx = self.width/2
	midy = self.height/2
	r = self.width/2 * 0.9

	// draw circular frame and tick marks
	g.drawEllipse midx-r, midy-r, r*2, r*2, color.black
	r1 = r * 0.96
	r2 = r * 0.94
	for ang in range(0, 2*pi-0.01, pi/30)
		g.line midx + r*cos(ang), midy + r*sin(ang), midx + r1*cos(ang), midy + r1*sin(ang), color.black
	end for
	for ang in range(0, 2*pi-0.01, pi/6)
		g.line midx + r*cos(ang), midy + r*sin(ang), midx + r2*cos(ang), midy + r2*sin(ang), color.black, 3
	end for

	// draw hour hand
	handPoly = [[r*0.06, r*0.6], [r*0.08, -r*0.1], [-r*0.08, -r*0.1], [-r*0.06, r*0.6]]
	degrees = -360 / 12 * dateTime.hour(now)
	handPoly = mathUtil.rotatePoly(handPoly, degrees)
	handPoly = mathUtil.shiftPoly(handPoly, midx, midy)
	g.fillPoly handPoly, color.black
	
	// draw minute hand
	handPoly = [[r*0.05, r*0.9], [r*0.07, -r*0.1], [-r*0.07, -r*0.1], [-r*0.05, r*0.9]]
	degrees = -360 / 60 * dateTime.minute(now)
	handPoly = mathUtil.rotatePoly(handPoly, degrees)
	handPoly = mathUtil.shiftPoly(handPoly, midx, midy)
	g.fillPoly handPoly, "#444444"
	
	// draw second hand
	handPoly = [[r*0.01, r], [r*0.01, -r*0.05], [r*0.03, -r*0.05],
	   [r*0.03, -r*0.25], [-r*0.03, -r*0.25], [-r*0.03, -r*0.05],
	   [-r*0.01, -r*0.05], [-r*0.01, r]]
	degrees = -360 / 60 * dateTime.second(now)
	handPoly = mathUtil.rotatePoly(handPoly, degrees)
	handPoly = mathUtil.shiftPoly(handPoly, midx, midy)
	g.fillPoly handPoly, color.red
	
	self.contentImage = g.getImage
	self.updateContent
end function

Calendar = new gui.Window
Calendar.scratchDisp = null
Calendar.dateShown = ""  // date string e.g. "Jul 7, 2026"
Calendar.lastSize = []

Calendar.update = function
	curDate = dateTime.now("MMM d, yyyy")
	curSize = [self.width, self.height]
	if curDate == self.dateShown and curSize == self.lastSize then return
	self.dateShown = curDate
	self.lastSize = curSize

	if self.scratchDisp == null then self.scratchDisp = new PixelDisplay
	oldgfx = gfx
	globals.gfx = self.scratchDisp
	gfx.clear "#CCCCCC", self.width, self.height

	now = dateTime.nowVal
	gui.medFont.printCentered dateTime.str(now, "MMM yyyy"), self.width/2, self.height-16,
	   1.0, color.black
	ch = floor((self.height - 32) / 5)  // cell height
	cw = floor(self.width / 7)  // cell width
	
	x = 0
	for dow in "Su Mo Tu We Th Fr Sa".split
		gui.smallFont.printCentered dow, x + cw/2, self.height - 25, 1.0, color.black
		x += cw
	end for
	
	curMonth = dateTime.month(now)
	secsPerDay = 60 * 60 * 24
	d = now - secsPerDay * (dateTime.day(now) - 1)  // get to start of month
	d -= secsPerDay * dateTime.weekday(d)  // and then to the start of that week
	y = self.height - 32
	for row in range(0, 4)
		x = 0
		for col in range(0, 6)
			if dateTime.month(d) == curMonth then
				gfx.color = "#FFFFFF"
				if dateTime.str(d, "MMM d, yyyy") == curDate then gfx.color = "#CCCCFF"
			else
				gfx.color = "#CCCCCC"
			end if
			gfx.fillRect x, y-ch, cw, ch
			gfx.drawRect x, y-ch, cw+1, ch+1, color.black
			gui.smallFont.printCentered dateTime.day(d), x + cw/2, y - 10, 1, color.black
			x += cw
			d += secsPerDay
		end for
		y -= ch
	end for

	self.contentImage = gfx.getImage
	globals.gfx = oldgfx
	self.updateContent
end function


showAnalogClock = function
	if clockWindow then
		clockWindow.moveToFront
		return
	end if
	outer.clockWindow = new AnalogClock
	clockWindow.init 200, 200, 50, 100, "Clock"
	clockWindow.goTo menuBarItem.left - 10, 500
end function

showCalendar = function
	if calendarWindow then
		calendarWindow.moveToFront
		return
	end if
	outer.calendarWindow = new Calendar
	calendarWindow.init 200, 200, 50, 100, "Calendar"
	calendarWindow.goTo menuBarItem.left + 10, 500
end function

menuCommands = []
menuCommands.push gui.MenuItem.Make("Analog Clock")
menuCommands[-1].action = @showAnalogClock
menuCommands.push gui.MenuItem.Make("Calendar")
menuCommands[-1].action = @showCalendar

enable = function
	outer.menuBarItem = gui.MenuItem.Make(currentDateTimeStr + " ")
	menuBarItem.submenu = gui.Menu.Make(menuCommands)
	globals.menubar.rightItems.push menuBarItem
end function

disable = function
	globals.menubar.rightItems.removeVal menuBarItem
	outer.menuBarItem = null
end function

update = function
	if self.clockWindow then self.clockWindow.update

	newText = currentDateTimeStr + " "
	if dateTime.nowVal % 1 > 0.5 then newText = newText.replace(":", " ")
	if not menuBarItem or newText == menuBarItem.text then return
	menuBarItem.text = newText
	
	x = menuBarItem.left// + gui.menuDisp.scrollX
	w = menuBarItem.width
	y = gui.kMenuBarBottom + gui.menuDisp.scrollY
	gui.menuDisp.drawImage gui.images.menuBar, x, y, w, gui.kMenuBarHeight
	gui.drawMenuItemText gui.menuDisp, newText, x, y, w, gui.kMenuBarHeight
end function


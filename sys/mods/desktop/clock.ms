// This desk accessory puts the current date/time in the menu bar,
// but also provides (via menu commands) windows for an analog
// clock and a calendar.

import "dateTime"

// Required stuff for all mods: menuItemText, enable, disable, update.
menuItemText = "Clock"

currentDateTimeStr = function
	return dateTime.str(dateTime.nowVal, "ddd MMM d, h:mm:ss tt")
end function

menuBarItem = null
clockWindow = null

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


showAnalogClock = function
	if clockWindow then
		clockWindow.moveToFront
		return
	end if
	outer.clockWindow = new AnalogClock
	clockWindow.init 200, 200, 50, 100, "Clock"
	clockWindow.goTo menuBarItem.left, 500
end function

showCalendar = function

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


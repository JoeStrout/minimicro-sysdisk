// sounds
//
//	This is just a little module of handy sounds you might want to use in
//	your own games, demos, or quick testing.  It also serves as examples
//	of how to define synthesized sounds in code.

all = []

bounce = new Sound
bounce.init 0.3, [100,1000], [1,0]
all.push bounce

ding = new Sound
ding.init 0.5, noteFreq(72), [1, 0]
all.push ding

dingHi = new Sound
dingHi.init 0.5, noteFreq(84), [1, 0]
all.push dingHi

daDing = new Sound
daDing.init 0.5, noteFreq(72), [1, 1, 0]
dd2 = new Sound
dd2.init 0.5, noteFreq(84), [0]*40 + range(1,0,-0.01)
daDing.mix dd2
all.push daDing

fall = new Sound
fall.init 1, [1000, 20], [1, 0.5, 0.1, 0]
all.push fall

land = new Sound
land.init 0.1, 440, [0.1,0], Sound.noiseWave
all.push land

byName = {}
for kv in locals
	if all.indexOf(@kv.value) != null then
		byName[kv.key] = @kv.value
	end if
end for

demo = function()
	clear
	text.delimeter = char(13)
	names = byName.indexes.sort
	for i in names.indexes
		print " " * (i<10) + i + ". " + names[i]
	end for
	while true
		istr = input("Sound number (or Return to exit): ")
		if istr == "" then break
		name = names[val(istr)]
		print name
		byName[name].play
	end while
end function

if globals == locals then demo



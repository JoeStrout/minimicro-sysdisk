// sounds
//
//	This is just a little module of handy synthesized sounds you might 
//	want to use in your own games, demos, or quick testing.  It also 
//	serves as examples of how to define synthesized sounds in code.

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

ds6 = noteFreq(75+12)
gs5 = noteFreq(80)
a5 = noteFreq(81)
d7 = noteFreq(74+12*2)
uhoh = new Sound
uhoh.init 0.6, ds6, [1,1,0,1,0,0,0,0,0]
a2 = new Sound
a2.init 0.6, gs5, [1,1,0,1,0,0,0,0,0]
b1 = new Sound
b1.init 0.6, a5, [0,0,0,0,1,1,1,1,1]
b2 = new Sound
b2.init 0.6, d7, [0,0,0,0,1,1,1,1,1]
uhoh.mix(a2,0.7)
uhoh.mix(b1,1)
uhoh.mix(b2,0.3)
all.push uhoh

wow = new Sound
wow.init 0.5, noteFreq(72), 1, Sound.noiseWave
all.push wow

warning = new Sound
warning.duration = 0.5
warning.freq = 120
warning.waveform = []
for i in range(7)
	// a series of decreasing triangles
	warning.waveform = warning.waveform + 
	   [i/7, i/7*0.8, i/7*0.6, i/7*0.4, i/7*0.2, 0]
end for
warning.envelope = [1,1,1,1,0] * 9
all.push warning

roboWhat = new Sound
roboWhat.init 0.4, [60,120], 1, warning.waveform
all.push roboWhat

roboSad = new Sound
roboSad.init 0.6, [130, 60], [1,1,0], warning.waveform
all.push roboSad

byName = {}
for kv in locals
	if all.indexOf(@kv.value) != null then
		byName[kv.key] = @kv.value
	end if
end for

demo = function
	clear
	text.delimeter = char(13)
	names = byName.indexes.sort
	for i in names.indexes
		print " " * (i<10) + i + ". " + names[i]
	end for
	print
	row = text.row
	while true
		text.row = row
		istr = input("Sound number (or Return to exit): ")
		if istr == "" then break
		name = names[val(istr)]
		print name + " "*40
		byName[name].play
	end while
	print " "*40
end function

if globals == locals then demo



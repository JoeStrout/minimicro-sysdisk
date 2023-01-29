// Tiny program to generate a star field.
// Demonstrates gfx.clear, gfx.setPixel, rnd,
// and your basic for-loop.

colors = ["#FFFFFF", "#AAAAFF", "#FFFFAA", "#FFCCCC"]
gfx.clear
for i in range(1000)
	gfx.setPixel rnd*960, rnd*640, colors[rnd * colors.len]
end for

// If we are returning to the shell, wait for a keypress
if env.hasIndex("shell") and env.shell then key.get

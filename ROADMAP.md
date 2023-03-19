# Mini Micro v1.2

## MiniScript (language) v1.6

- ☑︎ ︎add math-assignment operators (+=, etc.)
- ☑︎ fix: using line continuation after `and` no longer produces unreliable, random results
- ☑︎ fix: using an expression as a parameter default value now throws an error, rather than exposes the underlying temp variable
- ☑︎ fix: string.hasIndex(string) returns false rather than true (because string indexes must be numbers); e.g.: "foo".hasIndex("x")
- ☑︎ fix: missing `end if` in a function is now caught [#38]
- ☑︎ fix: `else if(x)` no longer fails unless you have a space after `else if`
- ☑︎ when attempting to index into `null`, you now get a more specific error
- ☑︎ added a special compiler error for common mistake of using = in an `if` statement
- ☑︎ ︎fix: x = someList[null] sometimes failed to throw an error, and didn't assign to x either.
- ☑︎ fix: someList[1:3] = foo now throws an error, instead of failing silently
- ☑︎ fix: the REPL failed to print results of any function that takes more than one run cycle to complete (e.g., a function containing a `yield`).
- ☑︎ fix: trying to store a function reference in a map literal didn't work, e.g. `a = {"b":@color.lerp}`
- ☑︎ fix: a function ref in a list literal didn't show properly as an implicit result, but worked fine when assigned to something, e.g. `[@color.lerp]`
- ☑︎ ︎`print` now takes an optional second argument, `delimiter` which defaults to the line break character.  Specify "" for no delimiter at all.
- ☑︎ comparisons and hashing of lists and maps are now much faster and smarter in cases where they contain reference cycles
- ☑︎ added new `refEquals` intrinsic to test for reference (rather than value) equality
- ☑︎ fix: loops in the `__isa` chain now throw a proper error instead of freezing the app.
- ☑︎ fix: `a[3]` where `a` is `null` now reliably throws a runtime error.

- **Command-line MiniScript v1.6**
  - ☑︎ on launch, adds MS_SCRIPT_DIR and MS_EXE_DIR to the environment variables, as well as MS_IMPORT_PATH if not already defined
  - ☑︎ new `import` intrinsic now searches directories in MS_IMPORT_PATH for the import module and imports them, just like Mini Micro
  - ☑︎ binaries ship with a set of core libraries similar to /sys/lib in Mini Micro, including dateTime 
  - ☐ rename linux package to miniscript-linux.tar.gz, so it will unpack more easily
  
- **Documentation**
  - ☐ document `super` in the Quick Reference
  - ☐ document parsing edge case: `1-2` and `1 - 2` work as expected, but `1 -2` fails, seeing this as a call with an argument
  - ☐ document that mutating a list or map used as a map key produces undefined behavior
  - ☐ document `refEquals` in the wiki and/or manual
  - ☐ document sound.adjust and all new APIs in Mini Micro Cheat Sheet
  - ☐ document `funcRef` and other types in the manual

## Contents of /sys disk

- ☑︎ /sys/demo/demos: presents menu of demos, and includes an auto-run ("screen saver" or "attract mode") feature that auto-runs several of the smaller demos; also shows you how to load and run these manually
- ☐ New `demos`, `desktop`, and `lcars` commands load and run the respective shells
- ☑︎ /sys/demo/asteroids: from [here](https://github.com/JoeStrout/minimicro-asteroids)
- ☐ /sys/demo/desktop: a GUI shell
  - ☐ scrollbars and close boxes on file windows
  - ☐ working menubar: new Folder, etc.
  - ☐ move/copy files by drag & drop
  - ☐ contextual menu on files (Open/Launch/View, Rename, Delete, etc.)
  - ☐ in-GUI viewer windows for pictures, source files, text files, and sounds
  - ☐ launch a program
- ☐ /sys/demo/lcars: a different GUI shell
  - ☑︎ calculator
  - ☐ clock
  - ☐ file manager
  - ☑︎ primary file browser
  - ☐ secondary (destination) file browser
  - copy, move, rename, delete files
  - preview of images, sounds, and text files
  - launch of program files
- ☑︎ /sys/fonts folder of built-in fonts
- ☐ update /sys/help to include info about `demo` and shells
- ☑︎ /sys/lib/bmfFonts: latest and greatest BMF font support
- ☐ /sys/lib/gui: support for GUI windows, scrollbars, buttons, and menus
- ☑︎ add a simple file picker/browser to /sys/lib/textUtil, and a related `findFile` utility command
- ☑︎ `view` command now shows tiles and tile numbers if viewing the image assigned as the tileset of a current tile display
- ☑ qa module: now correctly returns "map" for `qa.typeOf {}`

## Mini Micro itself

- ☑︎ Added key.axis("Tilt X") and similar "Tilt Y" and "Tilt Z" for reading the accelerometer on devices that have one.
- ☑︎ `grfon.Parse` now returns an empty map for `{}`, rather than returning null.
- ☑︎ `file.loadImage` new stores the image name and path on the image object; `www.get` does the same with the name and URL.
- ☑︎ fixed: TileDisplay no longer shows LOL emojis if you don't assign a tileSet
- ☑︎ fixed: TileDisplay: you could set tileSet but not get it
- ☑︎ fixed: TileDisplay didn't work well when set up detached and then installed
- ☑︎ fixed: shift-return gets confused and inserts the wrong closer on certain code
- ☑︎ `env.prompt` can now be a function.  If it is, invoke it, give it something like 0.2 seconds to run, and then print the implicit result (if any).  This allows you to make a custom prompt that shows the current working directory, time, etc.
- ☑︎ Added new "medium" font for PixelDisplay.print, in between "small" and "normal"
- ☑︎ Revised how PixelDisplay.drawImage does alpha blending to match industry standards.
- ☑︎ `cd` now validates the given path, and refuses to change to an invalid path.
- ☑︎ `"/"` is now a valid path (in cd, dir, etc.)
- ☑︎ The `edit` and `run` commands now take an optional filename to `load`.  If you have unsaved changes, the user is advised to `save` or `reset` and the operation is aborted.
- ☑︎ Fixed: Esc key did not enter the keyboard buffer (as seen by `key.available` and `key.get`) on Windows and Linux.
- ☑︎ `key.axis`: added a `smoothed` parameter (default true), enabling raw (unsmoothed) inputs.
- ☑︎ `Image.fromScreen` takes a screen shot, including all layers
- ☑︎ `Image.flip` and `Image.rotate` (in 90° increments)
- ☑︎ `key.put` allows you to enqueue a string, or single character by code point, into the keyboard buffer
- ☑︎ fixed: assigning to the `freq`, `duration`, etc. of a synthesized sound while it is playing now stops it, rather than leaving it orphaned and uncontrollable
- ☑︎ fixed the default value of `mode` for `file.open` (now "r+")
- ☐ BUG: if you remove the folders/files previously mounted, Mini Micro locks up on launch (according to [a report on Discord](https://discord.com/channels/646000428441534474/646000634222477313/959208056854577205))
- ☑︎ fixed: installing a PixelDisplay no longer resets its .color to white
- ☑︎ fixed: f.readLine now returns `null` (instead of "") at end of file
- ☑︎ Added `mouse.locked` to lock the mouse cursor, e.g. for FPS games	
- ☑︎ Added `env.shell`, which is the path to a "shell" app that should be automatically (re)launched after the current program exits.  This should be cleared by Control-C or any error break, and will be used by `demo` and `desktop` to return to these after running a program.  On the command line, `exit` will relaunch the current shell (if any).
- ☑︎ Added `sound.amp` to get the current amplitude of a playing sound (in the range 0-1, but typically closer to 0), enabling you to make a sort of graphic equalizer display, or do lip-syncing to speech, etc.
- ☑︎ remove test characters currently at char(29) and char(30)
- ☐ BUG: Display.install does not work with a display of type 0 (off)
- ☑︎ fix crash that occurs when setting gfx.scrollX to NaN
- **Code Editor**
  - ☑︎ Code editor uses a new custom font, including all special characters available in the text display.
  - ☑︎ Added customizable editor colors, via the `env.editorColors` map.
  - ☐ increase scroll wheel speed in code editor -- should be ~1 line/click
  - ☐ code editor autocomplete should include any identifiers (found as parameters, and assignments in local and global scope)
  - ☐ make sure the code editor shows the unknown-character glyph for unknown chars, rather than just blank, on all platforms
  - ☐ Correctly color parens after a line (or several lines?) continued by `and`
  - ☐ Home keypress or cmd-left: scroll all the way to the left (showing line numbers).
  - ☐ When opening different file, editor should reset to top left most position (including line-numbers) not previous position.
  - ☐ Add keyboard shortcut/navigation for the Navigate menu.
- **Building & Packaging**
  - ☐ use IL2CPP on all platforms for faster executable
  - ☐ produce both Apple Silicon (M1/M2) and Intel builds for Mac
  - ☐ code-sign the build for both Mac and Windows
  - ☐ release on Steam

# Other Projects

While not on the direct path to Mini Micro 1.2, it's worth pointing out some of the related projects that are in the works and may need some time/attention during this development period too.  In the case of the font editor, some additional work is needed there in order to finish tweaking the built-in fonts for Mini Micro.

- font editor (in [minimicro-fonts](https://github.com/JoeStrout/minimicro-fonts))
  - ☐ change font/character metrics by dragging the handles
  - ☐ adjust kerning
  - ☐ add/remove glyphs
  - ☐ add scrollbar (from /sys/lib/gui) to glyph list
- Inversion Institute
- Farmtronics
- Soda
- Desktop Font Converter (TrueType to BMF)
 
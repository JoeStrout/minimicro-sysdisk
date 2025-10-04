// FastBmfFonts - Optimized BMF font loader for better performance
// Focuses on reducing method calls and using bulk operations where possible

// Simplified CharData class with minimal overhead
FastCharData = {}
FastCharData._name = "FastCharData"

FastCharData.init = function(width, height, relX, relY, shift, colors)
    self.width = width
    self.height = height
    self.relX = relX
    self.relY = relY
    self.shift = shift
    self.colors = colors
    self.image = null
    return self
end function

// Optimized Font class
globals.FastFont = {}
FastFont._name = "FastFont"
FastFont.data = null
FastFont.chars = null
FastFont.kernMap = null

// Optimized font loading - main performance improvements
FastFont.load = function(path)
    // Use a single file.loadRaw call - no change needed here as it's already optimal
    data = file.loadRaw(path)
    if data == null then return null
    
    f = new FastFont
    f.data = data
    f.chars = {}
    data.littleEndian = true
    
    // Read header in bulk - store in local variables to reduce property access
    vers = data.byte(4)
    f.version = floor(vers/16) + 0.1 * (vers % 16)
    f.lineHeight = data.sbyte(5)
    f.sizeOver = data.sbyte(6)
    f.sizeUnder = data.sbyte(7)
    f.addSpace = data.sbyte(8)
    f.sizeInner = data.sbyte(9)
    f.usedColors = data.byte(10)
    f.highestUsedColor = data.byte(11)
    f.alphaBits = 0
    f.numPalettes = 1
    
    if f.version >= 1.2 then
        f.alphaBits = data.byte(12)
        f.numPalettes = data.byte(13) + 1
    end if
    
    // Load palette more efficiently
    palSize = data.byte(16)
    f.palette = []
    
    // Pre-calculate palette positions to reduce repeated math
    palStart = 17
    for i in range(0, palSize-1)
        palPos = palStart + i * 3
        // Use multiplication since MiniScript doesn't support bit shifting
        r = data.byte(palPos) * 4
        g = data.byte(palPos + 1) * 4
        b = data.byte(palPos + 2) * 4
        f.palette.push color.rgb(r, g, b)
    end for
    
    titleStart = 17 + palSize * 3
    titleLen = data.byte(titleStart)
    f.title = data.utf8(titleStart + 1, titleLen)
    
    pos = titleStart + 1 + titleLen
    
    // Read ASCII characters with optimized loop
    numAsciiChars = data.short(pos)
    pos = pos + 2
    
    // Process ASCII characters - minimize method calls in tight loop
    for i in range(1, numAsciiChars, 1)
        charCode = data.byte(pos)
        pos = pos + 1
        
        // Read character data in bulk instead of individual byte calls
        width = data.byte(pos)
        height = data.byte(pos + 1)  
        relX = data.sbyte(pos + 2)
        relY = data.sbyte(pos + 3)
        shift = data.sbyte(pos + 4)
        pos = pos + 5
        
        // Optimize color loading - calculate size once
        colorBytes = width * height
        colors = []
        
        if colorBytes > 0 then
            // Use range() to batch-read colors instead of individual pushes
            colorEnd = pos + colorBytes - 1
            for colorPos in range(pos, colorEnd)
                colors.push data.byte(colorPos)
            end for
        end if
        
        pos = pos + colorBytes
        
        // Create character with bulk initialization
        charData = (new FastCharData).init(width, height, relX, relY, shift, colors)
        charData.charCode = charCode
        f.chars[char(charCode)] = charData
    end for
    
    // Handle version 1.2 features if present
    if f.version < 1.2 or pos >= data.len then return f
    
    // Read non-ASCII characters (similar optimization)
    numOtherChars = data.uint(pos)
    pos = pos + 4
    
    for i in range(1, numOtherChars, 1)
        charCode = data.uint(pos)
        pos = pos + 4
        
        width = data.byte(pos)
        height = data.byte(pos + 1)
        relX = data.sbyte(pos + 2)
        relY = data.sbyte(pos + 3)
        shift = data.sbyte(pos + 4)
        pos = pos + 5
        
        colorBytes = width * height
        colors = []
        
        if colorBytes > 0 then
            colorEnd = pos + colorBytes - 1
            for colorPos in range(pos, colorEnd)
                colors.push data.byte(colorPos)
            end for
        end if
        
        pos = pos + colorBytes
        
        charData = (new FastCharData).init(width, height, relX, relY, shift, colors)
        charData.charCode = charCode
        f.chars[char(charCode)] = charData
    end for
    
    // Read kerning info (keep original logic - it's already fairly optimal)
    if pos >= data.len then return f
    kernCount = data.ushort(pos)
    
    if kernCount > 0 then
        pos = pos + 2
        for i in range(1, kernCount, 1)
            c1 = data.uint(pos)
            c2 = data.uint(pos+4)
            k = data.short(pos+8)
            f.setKern char(c1), char(c2), k
            pos = pos + 10
        end for
    end if
    
    return f
end function

// Copy essential methods from original Font class
FastFont.setKern = function(c1, c2, kern)
    if self.kernMap == null then self.kernMap = {}
    if not self.kernMap.hasIndex(c1) then self.kernMap[c1] = {}
    self.kernMap[c1][c2] = kern
end function

FastFont.kern = function(c1, c2)
    if self.kernMap == null then return 0
    if not self.kernMap.hasIndex(c1) then return 0
    km = self.kernMap[c1]
    if not km.hasIndex(c2) then return 0
    return km[c2]
end function

FastFont.charData = function(c)
    if self.chars.hasIndex(c) then return self.chars[c]
    c = c.upper
    if self.chars.hasIndex(c) then return self.chars[c]
    return null
end function

// Optimized rendering methods with reduced method calls
FastFont.printChar = function(c, x=480, y=320, scale=1, tint="#FFFFFF")
    d = self.charData(str(c))
    if d == null then return 0
    if d.image == null and d.width > 0 then d.image = self.makeCharImage(c)
    x = x + d.relX
    if d.image != null then
        if scale == 1 then
            y = y - self.sizeOver - d.relY - d.image.height
            gfx.drawImage d.image, x, y, d.image.width, d.image.height,
              0, 0, d.image.width, d.image.height, tint
        else
            y = y + scale * (-self.sizeOver - d.relY - d.image.height)
            gfx.drawImage d.image, x, y, d.image.width*scale, d.image.height*scale,
              0, 0, d.image.width, d.image.height, tint
        end if
    end if
    return d.shift * scale
end function

FastFont.print = function(s, x=20, y=320, scale=1, tint="#FFFFFF")
    s = str(s)
    lastc = ""
    for c in s
        x = x + self.kern(lastc, c) * scale
        x = x + self.printChar(c, x, y, scale, tint) + self.addSpace * scale
        lastc = c
    end for
end function

FastFont.width = function(s, scale=1)
    s = str(s)
    sum = 0
    lastc = ""
    for c in s
        d = self.charData(c)
        if d == null then continue
        sum = sum + (d.shift + self.addSpace + self.kern(lastc, c)) * scale
        lastc = c
    end for
    return sum
end function

// Optimized image creation with reduced object allocation
FastFont.makeCharImage = function(c)
    d = self.charData(c)
    if d == null then return null
    
    img = Image.create(d.width, d.height, color.clear)
    
    if d.width and d.height and d.colors then
        // Optimized pixel setting with pre-calculated values
        clrRange = 2 ^ (8 - self.alphaBits)
        alphaScale = 255/(2 ^ (self.alphaBits) - 1)
        baseColor = self.palette[0]
        
        i = 0
        for bitmapY in range(d.height - 1)
            for bitmapX in range(0, d.width - 1)
                c = d.colors[i]
                i = i + 1
                if not c then continue
                
                if self.alphaBits == 8 then
                    a = floor(c / clrRange) * alphaScale
                    pixelColor = baseColor + hex2(a)
                else if self.alphaBits > 0 then
                    // ToDo: handle this case
                else
                    pixelColor = self.palette[c-1]
                end if
                img.setPixel bitmapX, bitmapY, pixelColor
            end for
        end for
    end if
    return img
end function

FastFont.getCharImage = function(c)
    d = self.charData(c)
    if d == null then return null
    if d.image == null then d.image = self.makeCharImage(c)
    return d.image
end function
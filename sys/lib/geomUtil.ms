// --- geomUtil.ms ---
// Bounding Box helpers
Bounds.Create = function(x, y, w, h)
    b = new Bounds
    b.x = x; b.y = y; b.width = w; b.height = h
    return b
end function

Bounds.fromImage = function(img)
    qa.assert(img isa Image, "Bounds.fromImage: 'img' is not a valid Image.")
    return Bounds.Create(0, 0, img.width, img.height)
end function
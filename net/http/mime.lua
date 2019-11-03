-- A few MIME types. Keep list short. If you need something that is missing, let's add it.
local mt = {
    css = "text/css",
    gif = "image/gif",
    html = "text/html",
    ico = "image/x-icon",
    jpeg = "image/jpeg",
    jpg = "image/jpeg",
    js = "application/javascript",
    json = "application/json",
    png = "image/png",
    xml = "text/xml"
}

return function(ext)
    return mt[ext] or "text/plain"
end

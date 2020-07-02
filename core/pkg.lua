local pkg = {}

function pkg.unload(packageName)
    package.loaded[packageName] = nil
    _G[packageName] = nil
end

function pkg.unloadAll()
    local packages = {}
    for packageName, _ in pairs(package.loaded) do
        packages[#packages] = packageName
    end
    for _, packageName in ipairs(packages) do pkg.unload(packageName) end
end

function pkg.require(packageName, unload)
    local p = package.loaded[packageName]
    if p then return p end
    p = require(packageName)
    if unload then pkg.unload(packageName) end
    return p
end

return pkg

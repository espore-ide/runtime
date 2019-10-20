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
    for _, packageName in ipairs(packages) do
        pkg.unload(packageName)
    end
end

return pkg

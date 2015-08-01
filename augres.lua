#!/usr/bin/lua

local libPath = "libs.lua"
local remove  = package.config:sub(0, 1) == "\\" and "del" or "rm"
local libraries = nil 
local tmpname   = ".augres" --os.tmpname() is no go without admin on windows

local function loadLibPaths(location)
  location = location or libPath
  local source = "return " .. io.open(location, "r"):read("*all")
  local fn = assert(loadstring(source))
  return fn()
end

local function collectByteCode(fileName)
  os.execute("luac -p -l " .. fileName .. " > " .. tmpname)
  local tmpfile = io.open(tmpname, "r")
  local result = {} 
  for l in tmpfile:lines() do result[#result + 1] = l end
  tmpfile:close()
  return result
end

local function parseByteCode(byteCode, debug)
  local globals = {}
  for i, line in ipairs(byteCode) do 
    -- find the names of any GLOBALS
    local name = string.match(line, ".*GETGLOBAL.*; ([%a_][%w_]*)")
    if name then 
      if debug then print("Global found: ", name) end
      globals[#globals + 1] = name
    end
  end
  return globals
end

local function resolveGlobals(fileName, debug)
  local file     = io.open(fileName, "r+")
  local source   = file:read("*all")
  local byteCode = collectByteCode(fileName)
  local globals = parseByteCode(byteCode, debug)
  local outsource = {}
  libraries = libraries or loadLibPaths(libPath)
  for i, global in pairs(globals) do
    local libEntry = libraries[global]
    if libEntry then
      if type(libEntry) == "string" then
        outsource[#outsource + 1] = "local " .. global .. " = require('" .. libraries[global] .. "')"
      else
        error("Child tables not yet implemented.")
      end
    end
  end
  if #outsource > 0 then
    outsource[#outsource + 1] = '' --add a spacer
  end
  outsource[#outsource + 1] = source
  outsource = table.concat(outsource, '\n') --add the localized includes
  file:seek("set")
  if debug then 
    print(outsource)
  else 
    file:write(outsource)
  end
end


local files   = {}
for i=1, #arg do
  files[#files + 1] = arg[i]
end

for i, file in ipairs(files) do 
  if file ~= libPath then
    resolveGlobals(file, false)
  end
end

--clean up .augres
os.execute(remove .. " " .. tmpname)

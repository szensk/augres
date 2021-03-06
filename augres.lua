#!/usr/bin/lua
local libPath = "libs.lua"
local libraries  = nil 
local version    = "0.0.1"

local function showHelp()
  print("Augres (" .. version .. ") Help:")
  print("usage: augres luaFile1 luaFile2")
  print("\t-l location  set the path for the library dictionary.")
  print("\t-h           show this help.")
end

local function loadLibPaths(location)
  location = location or libPath
  local libEntries = assert(io.open(location, "r"), "Unable to find " .. libPath)
  local source = "return " ..libEntries:read("*all")
  local fn = assert(loadstring(source))
  return fn()
end

local function collectByteCode(fileName)
  local f = io.popen("luac -p -l " .. fileName)
  local result = {}
  for l in f:lines() do result[#result + 1] = l end
  return result
end

local function parseByteCode(byteCode, debug)
  local globals = {}
  for i, line in ipairs(byteCode) do 
    -- find the names of any GLOBALS
    local name = string.match(line, ".*GETGLOBAL.*; ([%a_][%w_]*)")
    if name then 
      if debug then print("Global found: ", name) end
      globals[name] = name
    end
  end
  return globals
end

local function resolveGlobals(fileName, debug)
  local file      = assert(io.open(fileName, "r+"), "Unable to open file: " .. fileName)
  local source    = file:read("*all")
  local byteCode  = collectByteCode(fileName)
  local globals   = parseByteCode(byteCode, debug)
  local outsource = {}
  libraries = libraries or loadLibPaths(libPath)
  for _, global in pairs(globals) do
    local libEntry = libraries[global]
    if libEntry then
      if type(libEntry) == "string" then
        outsource[#outsource + 1] = "local " .. global .. " = require('" .. libraries[global] .. "')"
      elseif type(libEntry) == "table" then
        error("Child tables not yet implemented.")
      else
        error("This will never be implemented.")
      end
    end
  end
  if #outsource > 0 then --only rewrite the file if we have anything to add
    outsource[#outsource + 1] = '' -- add a gap to separate the original source
    outsource[#outsource + 1] = source
    outsource = table.concat(outsource, '\n') 
    if debug then 
      print(outsource)
    else 
      file:seek("set")
      file:write(outsource)
    end
    return 1
  end
  return 0
end

local start = 1
local files = {}
if arg[1] == "-l" then
  start = 3 --start at 3rd argument as 1 is -l and 2 is the library dictionary
  libPath = arg[2] 
elseif arg[1] == "-h" then
  showHelp()
  os.exit(0)
end
for i=start, #arg do
  files[#files + 1] = arg[i]
end

local function doFiles()
  local filesWritten = 0
  for i, file in ipairs(files) do 
    if file ~= libPath then
      print(file, libPath)
      filesWritten = filesWritten + resolveGlobals(file)
    end
  end
  return filesWritten
end

local status, err = pcall(doFiles) 
if status then
  print("Success. Wrote " .. err .. " file(s).")
else
  print("Error:")
  print('\t'..err)
end 
os.exit(status and 0 or 1)

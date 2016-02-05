augres
======
Sick and tired of importing libraries in every Lua file? Still want to avoid globals? *Au*tomatic *G*lobal *Res*olver may be for you. It accepts a table of library names and the Lua path (as used in `require`) where they can be found. It then inserts the appropriate local requires at the top of the any given file. Take a look at the example. 

This could also be done by defining a loader which replaces the execution environment of scripts to `package.loaded`. I tried this but globals defined within the script can then overwrite loaded libraries and any true global table (such as `math` and `io`) would be inaccessible without setting an `__index = _G` metatable for package.loaded. While this simplifies the build process I find that it causes too many unexpected errors and leaves the GETGLOBAL byte code, which is slower than local look ups. 

# Synapse Naming Standard Function Support For Your Exploits

made by your dearest raz [RazAPIx64.dll32]

to use this just do

```lua
local syn = loadstring(game:HttpGet("https://raw.githubusercontent.com/RazAPIx64/Syn-X-Functions/refs/heads/main/syn_main.luau"))()
local Syn = syn; -- doesnt matter which var you do, just use syn and not Syn
```

# REQUIREMENTS:

hookmetamethod (syn.protect_gui, syn.unprotect_gui): if you don't have hookmetamethod then you cannot use this
getnamecallmethod (syn.protect_gui, syn.unprotect_gui)

getthreadidentity/getidentity (syn.get_thread_identity)
setthreadidentity/setidentity (syn.set_thread_identity)

request/gethwid (syn.request)
cache (syn.cache)

clipboard (syn.write_clipboard, etc)

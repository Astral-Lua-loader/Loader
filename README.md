# Loader

`loader.lua` is the only file users get. Put it in `astral\lua` and load it in Astral.
Every run it downloads `entry.lua` from [Lua](https://github.com/Astral-Lua-loader/Lua) (branch `main`) and runs it,
so pushing to Lua updates everyone on their next load.

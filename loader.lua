-- Astral loader: share this file once. Every run it pulls the latest Lua from
-- github.com/Astral-Lua-loader/Lua (branch main) and runs entry.lua from it.

local OWNER_REPO = "Astral-Lua-loader/Lua"

local function log(text) print("[loader] " .. text) end

-- a value that differs every load (Astral's `os` has no os.time; math.random unseeded repeats)
local stamp
do
    local ok, t = pcall(globals.get_real_time)
    local ok2, f = pcall(globals.get_frame_count)
    stamp = tostring(ok and t or 0):gsub("%D", "") .. tostring(ok2 and f or 0) .. tostring({}):gsub("%W", "")  -- (no collectgarbage in Astral)
end

-- the newest commit's id: files fetched by commit are never a stale cached copy, and all come from one commit
local ref = "main"
do
    local ok, r = pcall(http.get, "https://api.github.com/repos/" .. OWNER_REPO .. "/commits/main?t=" .. stamp,
        {["Accept"] = "application/vnd.github.sha", ["User-Agent"] = "astral-lua-loader"})
    local sha = ok and r and r.code == 200 and tostring(r.text):match("^%s*(%x+)%s*$")
    if sha and #sha == 40 then ref = sha else log("couldn't read the latest commit, using main") end
end
local REPO = "https://raw.githubusercontent.com/" .. OWNER_REPO .. "/" .. ref .. "/"

local cache = {}

local function fetch(path)
    local url = REPO .. path .. (ref == "main" and "?t=" .. stamp or "")
    local ok, r = pcall(http.get, url)
    if not ok or not r or r.code ~= 200 then
        error(("can't download %s (%s)"):format(path, ok and r and r.code or tostring(r)), 0)
    end
    return r.text
end

local env = setmetatable({}, {__index = _G})

-- import("modules.menu") -> runs modules/menu.lua once, returns what it returns
local function import(name)
    if cache[name] ~= nil then return cache[name] end
    local path = name:gsub("%.", "/") .. ".lua"
    local chunk, err = load(fetch(path), "=" .. path, "t", env)
    if not chunk then error(err, 0) end
    local result = chunk()
    if result == nil then result = true end
    cache[name] = result
    return result
end

env.import = import
env.loader = {repo = REPO, ref = ref, fetch = fetch, log = log}

log("Lua " .. ref:sub(1, 7))
local ok, err = pcall(import, "entry")
if not ok then log("failed: " .. tostring(err)) end

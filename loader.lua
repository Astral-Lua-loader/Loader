-- Astral loader: share this file once. Every run it pulls the latest Lua from
-- github.com/Astral-Lua-loader/Lua (branch main) and runs entry.lua from it.

local REPO = "https://raw.githubusercontent.com/Astral-Lua-loader/Lua/main/"

local function log(text) print("[loader] " .. text) end

-- query string skips GitHub's ~5 min raw cache, so a push is live on the next run
local stamp = tostring((pcall(os.time) and os.time()) or math.random(1, 1e9))

local cache = {}

local function fetch(path)
    local ok, r = pcall(http.get, REPO .. path .. "?t=" .. stamp)
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
env.loader = {repo = REPO, fetch = fetch, log = log}

local ok, err = pcall(import, "entry")
if not ok then log("failed: " .. tostring(err)) end

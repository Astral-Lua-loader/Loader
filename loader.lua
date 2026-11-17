local OWNER_REPO = "Astral-Lua-loader/Lua"

local function log(text) print("[loader] " .. text) end

local stamp
do
    local ok, t = pcall(globals.get_real_time)
    local ok2, f = pcall(globals.get_frame_count)
    stamp = tostring(ok and t or 0):gsub("%D", "") .. tostring(ok2 and f or 0) .. tostring({}):gsub("%W", "")
end

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

local SEALED = {k = 55311798, d = {202, 220, 76, 188, 223, 210, 102, 213, 222, 166, 192, 223, 45, 123, 80, 171, 74, 78, 113, 189, 193, 77, 147, 128, 254, 90, 1, 205, 157, 187, 166, 194, 146, 242, 126, 86, 179, 227, 26, 13, 129, 123, 76, 187, 168, 208, 53, 209, 211, 170, 26, 243, 246, 14, 85, 147, 153, 191, 122, 18, 144, 199, 33, 24, 26, 67, 144, 174, 172, 17, 67, 196, 206, 200, 212, 215, 62, 57, 127, 145, 3, 206, 158, 94, 162, 80, 85, 172, 24, 68, 193, 1, 108}, o = {48, 43, 40, 41, 34, 31, 14, 91, 61, 38, 37, 70, 57, 54, 52, 76, 9, 63, 81, 68, 33, 92, 18, 7, 74, 66, 24, 46, 42, 19, 77, 84, 8, 64, 88, 79, 16, 56, 13, 80, 59, 22, 30, 83, 36, 67, 72, 89, 71, 6, 55, 49, 27, 45, 1, 86, 73, 3, 12, 87, 50, 39, 11, 21, 15, 26, 51, 2, 85, 23, 4, 47, 5, 90, 17, 29, 62, 53, 75, 10, 78, 35, 25, 58, 32, 20, 65, 82, 28, 60, 69, 44, 93}}
local function unseal(s)
    if type(s) ~= "table" or not s.d then return nil end
    local bxor = (rawget(_G, "bit") or require("bit")).bxor
    local x, out = s.k, {}
    for i = 1, #s.d do
        x = (x * 48271) % 2147483647
        out[s.o[i]] = string.char(bxor(s.d[i], x % 256))
    end
    return table.concat(out)
end

env.import = import
env.loader = {repo = REPO, ref = ref, fetch = fetch, log = log, scripts_token = unseal(SEALED)}

log("Lua " .. ref:sub(1, 7))
local ok, err = pcall(import, "entry")
if not ok then log("failed: " .. tostring(err)) end

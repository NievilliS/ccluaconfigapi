--[[
* Config API Ver 1.0
* Created by Nievillis on Github, Discord and YouTube
* The contents are free to be modified and used with no warranty.
* Content and testing files are openly available at https://github.com/NievilliS/ccluaconfigapi.git
--]]

local _fetch = http.get("https://raw.githubusercontent.com/NievilliS/ccluaconfigapi/main/cfg_api.lua")
local _str_dat = _fetch.readAll()
_fetch.close()

if not _str_dat or _str_dat:len() < 10 then
    error"Something went wrong whilst trying to get the files."
end
print("Data received!")
print([[
* Config API Ver 1.0
* Created by Nievillis on Github, Discord and YouTube
* The contents are free to be modified and used with no warranty.
* Content and testing files are openly available at https://github.com/NievilliS/ccluaconfigapi.git

Continuing in 3 seconds...
]])
sleep(3)

local _f_path = "cfg_api"
while fs.exists(_f_path .. ".lua") do
	_f_path = "cfg_api_(" .. tostring(1 + (tonumber((_f_path:match "[0-9]+") or "0"))) .. ")"
end
_f_path = _f_path .. ".lua"

print("Saving as " .. _f_path)
local _file = fs.open(_f_path, "w")
_file.write(_str_dat)
_file.close()
print("Done!")

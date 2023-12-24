--[[
* Config API Ver 1.0
* Created by Nievillis on Github, Discord and YouTube
* The contents are free to be modified and used with no warranty.
--]]


--! Function to extract a configuration table out of a file. Compatible data types: Tables, Strings, Numbers
--! Also supports implicit type casting. Note: Any values after declaring a key with attribute t@[...] will be ignored.
--! Identical keys will return a warning message and override its previous value.
_G.generic_get_config_table = _G.generic_get_config_table or function(_path, _surpress_warnings)

    local _file_input = fs.open(_path, "r")
	if not _file_input then
		error("No such file \"" .. _path .. "\"", 2)
	end
    local _data = _file_input.readAll()
    _file_input.close()
    _file_input = nil
    
	--! Clean up data by removing blank spaces and comments
	_data = _data:gsub("[-][-][^\n]*", "")
	_data = _data:gsub("\n +", "\n")
	_data = _data:gsub("^ +", "")
	while _data:match"\n *\n" do
		_data = _data:gsub("\n *\n", "\n")
	end
	while _data:match"^ *\n" do
		_data = _data:gsub("^ *\n", "")
	end
	
	--! Contains attribute
    local _dataline = table.pack(_data:match "^([bnstBNST][?>@])([^:]+): ?([^\n]*)\n?")
	--! Does not contain attribute and casts implicitly in later steps
	_dataline = _dataline[2] and _dataline or table.pack(nil, _data:match "^([^:]+): ?([^\n]*)\n?")
	
    local _output = {}
    local _table_scope = {n = 0}
	local _skip = false
    
	--!! Declared as function as they are used multiple times
	local function _enter_scope(_keyname)
		_table_scope.n = _table_scope.n + 1
		_table_scope[_table_scope.n] = _keyname
		_skip = true
	end
	local function _exit_scope()
		if _table_scope.n < 1 then
			error("Attempt to close table that was never opened at entry \"" .. _data:match("^[^:]+: ?[^\n]*") .. "\"", 3)
		end
		_table_scope[_table_scope.n] = nil
		_table_scope.n = _table_scope.n - 1
		_skip = true
	end
	
	--! Get current scope
	local function _trace_table_scope(_max)
		local _rts = "root."
		for i = 1, math.min(_table_scope.n, _max or math.huge) do
			_rts = _rts .. _table_scope[i] .. "."
		end
		return _rts
	end
	
    while _dataline[2] do
	
        local _attribute = _dataline[1]
		local _key = _dataline[2]
		local _value = _dataline[3]
		
		--!! Cases:
			-- Implicit Casting:	nil, set, set
			-- Explicit Casting:	set, set, set
			-- Implicit Table Init:	nil, set, {
			-- Explicit Table Init: t@,  set, any
			-- Implicit Table End:	nil, set, }
			-- Explicit Table End:	t@,  set, any
		
		--! Explicit Casting Cases
		if _attribute then
			
			--! Integer Casting "i@"
			if _attribute:match"[nN]" then
				--! Require check
				if _value:match"^ *[%d.]+ *$" then
					_value = tonumber(_value)
				else
					error("Attempt to explicitly cast invalid string into number at entry \"i@" .. _dataline[2] .. ": " .. _dataline[3] .. "\"", 2)
				end
				
			--! Boolean Casting "b@"
			elseif _attribute:match"[bB]" then
				--! Require check
				if _value:match"^ *[fF][aA][lL][sS][eE] *$" or _value:match"^ *[fF0] *$" then
					_value = false
				elseif _value:match"^ *[tT][rR][uU][eE] *$" or _value:match"^ *[tT1] *$" then
					_value = true
				else
					error("Attempt to explicitly cast invalid string into boolean at entry \"b@" .. _dataline[2] .. ": " .. _dataline[3] .. "\"", 2)
				end
			
			--! Table Casting "t@"
			elseif _attribute:match"[tT]" then
				--! Require to check if this table is being opened or closed
				if _table_scope.n > 0 and _key == _table_scope[_table_scope.n] then
					_exit_scope()
				else
					_enter_scope(_key)
				end
			end
			--! String Casting is not required as _value is a string by default
		
		--! Implicit Casting Cases
		else
			
			--! Integer check
			if _value:match"^ *[%d.]+ *$" then
				_value = tonumber(_value)
				
			--! "false" word boolean check
			elseif _value:match"^ *[fF][aA][lL][sS][eE] *$" then
				_value = false
				
			--! "true" word boolean check
			elseif _value:match"^ *[tT][rR][uU][eE] *$" then
				_value = true
				
			--! Table open check
			elseif _value:match"^ *[{] *$" then
				_enter_scope(_key)
			
			--! Table close check
			elseif _value:match"^ *[}] *$" then
				_exit_scope()
			
			end
		end
    
		if not _skip then
			local _ref_table = _output
				
			--! This will change table reference until inside the last scope, or it will create if it is not there yet, not required to be called as skipped: Empty tables cannot be created! Intended behavior
			for i = 1, _table_scope.n do
				if type(_ref_table[_table_scope[i]]) == "nil" then --< Nonexistent, create new table here
					_ref_table[_table_scope[i]] = {}
				elseif type(_ref_table[_table_scope[i]]) ~= "table" then --< This key is already occupied by another non-table value, print warning and create new table here
					if not _surpress_warnings then
						printError("Warning: Table \"" .. _trace_table_scope(i) .. "\" is created at already occupied keyvalue. Previous value of type " .. type(_ref_table[_table_scope[i]]) .. " was \"" .. tostring(_ref_table[_table_scope[i]]) .. "\"")
					end
					_ref_table[_table_scope[i]] = {} 
				end
				_ref_table = _ref_table[_table_scope[i]] --< Set reference to the advancing table
			end
	
			--! Cannot override an initiated table
			if type(_ref_table[_key]) == "table" then
				error("Attempt to overwrite table \"" .. _trace_table_scope() .. _key .. "\" at entry \"" .. _data:match("^[^\n]+") .. "\"", 2)
			--! Checks if the keyvalue has already been written
			elseif type(_ref_table[_key]) ~= "nil" and not _surpress_warnings then
				printError("Warning: Key \"" .. _trace_table_scope() .. _key .. "\" is being overwritten with value of type " .. type(_value) .. " \"" .. tostring(_value) .. "\". Previous value of type " .. type(_ref_table[_key]) .. " was \"" .. tostring(_ref_table[_key]) .. "\"")
			end
			_ref_table[_key] = _value
		end
		_skip = false
		
		--! Delete current line
        _data = _data:gsub("^[^\n]+\n?","")
		
		--! Contains attribute
		_dataline = table.pack(_data:match "^([nstbBNST][?>@])([^:]+): ?([^\n]*)\n?")
		--! Does not contain attribute and casts implicitly in later steps
		_dataline = _dataline[2] and _dataline or table.pack(nil, _data:match "^([^:]+): ?([^\n]*)\n?")
    end
    
    return _output
end

--! Function used to point to keys within table, originating from root
_G.generic_get_entry = _G.generic_get_entry or function(_base_ref, _entrykey)
	_entrykey = _entrykey:gsub("^%.", "")
	
	--! Self reference
	if _entrykey == "" then
		return _base_ref
	end
	
	--!! Enter tables until theres no more table to enter into, as per _entrykey
	while _entrykey:match("%.") do
		_base_ref = _base_ref[_entrykey:match "^[^.]*"]
		if _base_ref == nil then
			return nil
		end
		_entrykey = _entrykey:gsub("^[^.]+%.", "")
	end
	
	return _base_ref[_entrykey]
end

--! Function used to list every key
_G.generic_get_all_keys = _G.generic_get_all_keys or function(_table)
	local _keylist = {}
	local _keylist_queue = {""}
	local _new_queue = {}
	local _c_scope = ""
	
	while #_keylist_queue > 0 do
		for _, _scope in pairs(_keylist_queue) do
			for _k, _v in pairs(generic_get_entry(_table, _scope)) do
				if type(_v) == "table" then
					_new_queue[#_new_queue + 1] = _scope .. "." .. _k
				end
				--! Note: Tables are also included as they're scoped into
				_keylist[#_keylist + 1] = _scope .. "." .. _k
			end
		end
		
		_keylist_queue = _new_queue
		_new_queue = {}
	end
	
	return _keylist
end

--! Sorts integer-keyed tables with bubble sort
local function __gen_sort_alphabetically(_t)
	local function __cmp_keys(a,b)
		return (a > b) and 1 or ((a < b) and -1 or 0)
	end
	
	for _ofs = 1, #_t - 2 do
		for i = 1, #_t - _ofs do
			if __cmp_keys(_t[i], _t[i + 1]) > 0 then
				local tmp = _t[i]
				_t[i] = _t[i + 1]
				_t[i + 1] = tmp
			end
		end
	end
end

--! Get index based on key
local function __get_indent(_k)
	local function __rep(_n)
		local str = ""
		for i = 1, _n do
			str = str .. "  "
		end
		return str
	end
	
	_k = _k:gsub("^%.","")
	local _ct = 0
	for i = 1, _k:len() do
		_ct = _ct + (_k:sub(i,i) == "." and 1 or 0)
	end
	
	return __rep(_ct)
end

--! Function used to save a formatted config table into _path. The file may become appended by the boolean _append parameter
--! A description table may be added, which automatically adds comments above or next to entries. _desc may be nil
_G.generic_save_config_table = _G.generic_save_config_table or function(_table, _path, _append, _desc)
	_desc = _desc or {}
	local _sv_str = _desc["."] and ("--!! " .. _desc["."] .. "\n\n") or ""
	
	--! Aquire alphabetically sorted keylist, which guarantees, that all scoped entries are correctly written into _sv_str
	local _keylist = generic_get_all_keys(_table)
	__gen_sort_alphabetically(_keylist)
	
	--! Scope is being tracked as tables are created. This way, if the next key does not contain this string, we know that the table has been closed, and it can be removed from this stack 
	local _track_scope_stack = {[0] = "."}
	
	for _,k in ipairs(_keylist) do
		local v = generic_get_entry(_table, k)
		local _indent = __get_indent(k)
		local _lastkey = k:match("[^.]*$")
		local _vtype = type(v)
		local _attrkey = ({table = "t@", string = "s@", boolean = "b@", number = "n@"})[_vtype]
		
		--!! All types of values require scope tracking. If this statement is false, then atleast one table has been closed, as the current key does not contain the previous tables before itself
		while #_track_scope_stack > 0 and not k:match(_track_scope_stack[#_track_scope_stack]) do
			local _pr_sc = _track_scope_stack[#_track_scope_stack]:gsub("%%%.$","")
			_track_scope_stack[#_track_scope_stack] = nil
			_sv_str = _sv_str .. __get_indent(_pr_sc) .. "t@" .. _pr_sc:match("[^.]*$") .. ": } --> " .. _track_scope_stack[#_track_scope_stack]:gsub("%%%.$","") .. " >\n\n"
		end
		
		--!! Table and string are saved so that the comment is above them
		if _vtype == "table" then
			_track_scope_stack[#_track_scope_stack + 1] = k:gsub("%.","%.") .. "%."
			_sv_str = _sv_str .. "\n" .. _indent ..
				(_desc[k] and ("--! " .. _desc[k] .. "\n" .. _indent) or "") ..
				_attrkey .. _lastkey .. ": { --> " .. k .. " >\n"
		elseif _vtype == "string" then
			_sv_str = _sv_str .. _indent ..
				(_desc[k] and ("--! " .. _desc[k] .. "\n" .. _indent) or "") ..
				_attrkey .. _lastkey .. ": " .. v .. "\n"
		--!! As for numbers and booleans, their comment is beside them
		else
			_sv_str = _sv_str .. _indent .. _attrkey .. _lastkey .. ": " .. tostring(v) ..
				(_desc[k] and (" --< " .. _desc[k]) or "") .. "\n"
		end
	end
	
	--! Write to file if path is not nil
	if _path then
		local _file = fs.open(_path, _append and "a" or "w")
		_file.write(_sv_str)
		_file.close()
	end
	
	return _sv_str
end


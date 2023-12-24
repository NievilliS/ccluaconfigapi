if not generic_get_all_keys then
    shell.run"cfg_api"
end

local tbl =
{
    zzz = "amogus",
    ["$"] = true,
    ["n@"] = 69.420,
    a = {
        _plc = false,
        b = {
            b = "b",
            c = {
                _filler = "He l l o   t he ere  .   "
                , c = 22
            }
        },
        a = "a",
        bdc = "b.c"
    }
}

local ds = {
["."] = "Hello world",
[".a"] = "Foo",
[".a.b"]  = "Bar",
[".$"] = "I dont speak hamburger",
[".a.b.c.c"] = ".a.b.c.c"
}

print(generic_save_config_table(tbl, ".test.api.conf", false, ds))


--[[
 Author: RazAPIx64.dll32 or razapix64.dll32 (on Discord)
 Filename: syn_main.luau
]]


--[[
 REQUIREMENTS:

 - A level 3-8 internal-external (not possible on external since you need getreg which is implemented internally)
]]

local syn = {}
local cached = {}
local Protected = {}

local identity;
local function Err() error('Cannot use this method in a secure sandboxed function') end;

if getidentity then identity = getidentity else identity = nil end

syn.__index = syn;
local env = getfenv() or getfenv(0);

local function syn_ref(ref: Instance)
    local Proxy = newproxy(true);
    local Mt = getmetatable(Proxy);

    Mt.__index = function(self, idx)
        if type(ref[idx]) == 'function' then
            return function(...)
                return ref[idx](...)
            end
        end

        return ref[idx]
    end

    Mt.__newindex = function(self, key, idx)
        ref[key] = idx
    end

    Mt.__tostring = function()
        return tostring(ref)
    end

    return ref
end

function PROTOSMASHER_LOADED() return true end -- or return true;

is_syn_function = PROTOSMASHER_LOADED
is_synapse_function = is_syn_function
syn_isbeta = PROTOSMASHER_LOADED

syn.protect_gui = false;

if hookmetamethod then
    if getnamecallmethod and checkcaller then
        local ProtectHook; ProtectHook = hookmetamethod(game, '__namecall', function(...)
            local Args = {...};
            if not checkcaller() and Args[1] == game and getnamecallmethod() == 'FindFirstChild' and Args[3] == true then
                for i,v in Protected do
                    if v.Name == Args[2] then
                        return nil
                    end
                end
            end
        end)

        function syn.protect_gui(gui: ScreenGui | Instance)
            table.insert(Protected, gui);

            for i,v in gui:GetDescendants() do
                table.insert(Protected, v);
            end

            local Connection; -- ts method so buns bro
            Connection = gui.DescendantAdded:Connect(function(Descendant)
                if Protected[Descendant] ~= nil and table.find(Protected, Descendant) then
                    table.insert(Protected, Descendant)
                else
                    Connection:Disconnect();
                end
            end)
        end

        function syn.unprotect_gui(gui: ScreenGui | Instance)
            assert(Protected[gui] ~= nil, "This Instance isn't protected with syn.protect_gui.")
            table.remove(Protected, gui or table.find(Protected, gui));

            for i,v in gui:GetDescendants() do
                if Protected[v] ~= nil or table.find(Protected, v) then
                    table.remove(Protected, v or table.find(Protected, v))
                end
            end
        end
    end
end

function syn.checkcaller()
    return (checkcaller and checkcaller() or (isexecutorclosure and isexecutorclosure(debug.info(2, 'f')))) or true
end

local function find_and_nill_registry_value(target: Instance)
	local registry = getreg and getreg() or (debug and debug.getregistry and debug.getregistry())
	if not registry then return end

	for i, v in pairs(registry) do
		if type(v) == "table" then
			for key, val in pairs(v) do
				if val == target then
					v[key] = nil -- actually remove from the table
				end
			end
		elseif v == target then
			registry[i] = nil -- ts shit PSISING ME OFF
		end
	end
end

function syn.cache_invalidate(invalidated_Cache: Instance)
	if cache and cache.invalidate then
		return cache.invalidate(invalidated_Cache)
	end

	find_and_nill_registry_value(invalidated_Cache)

	syn.Cached[invalidated_Cache] = nil
	pcall(function() invalidated_Cache.Parent = nil end)
end

function syn.cache_replace(Cache1: Instance, Cache2: Instance)
	syn.insert(syn.Cached, Cache1, syn.Cached, Cache2)

	if cache and cache.replace then
		return cache.replace(Cache1, Cache2)
	end

	if getreg or (env and env.getreg) then
		local reg = getreg and getreg() or env.getreg()
		for i, v in pairs(reg) do
			if v == Cache1 then
				reg[i] = Cache2
			elseif type(v) == "table" then
				for k, val in pairs(v) do
					if val == Cache1 then
						v[k] = Cache2
					end
				end
			end
		end
	else
		local main = getmetatable(syn.Cached[Cache1]) or syn.Cached[Cache1]
		local main2 = getmetatable(syn.Cached[Cache2]) or syn.Cached[Cache2]
		syn.Cached[main] = main2
	end
end

function syn.cache_iscached(iscached_Cache: Instance): boolean
	if (cache and cache.iscached) then
		return cache.iscached(iscached_Cache)
	end

	if getreg or (env and env.getreg) then
		local reg = getreg and getreg() or env.getreg()
		for _, v in pairs(reg) do
			if v == iscached_Cache then
				return true
			elseif type(v) == "table" then
				for _, val in pairs(v) do
					if val == iscached_Cache then
						return true
					end
				end
			end
		end
		return false
	end

	return syn.Cached[iscached_Cache] ~= nil
end

syn.is_cached = syn.cache_iscached

function syn.request(options: { Url: string, Method: any?, Body: string })
	local hwid = (gethwid and gethwid() or game:GetService('RbxAnalyticsService'):GetClientId())
	local user = game.Players.LocalPlayer.Name;

	if env.request or request then
		options["Syn-Fingerprint"] = hwid;
		options["Syn-User-Identifier"] = user;

        -- this can fck up your luarmor support so i wouldnt recommend it

        local success, status = pcall(function() options.Header = {["User-Agent"] = "synx v2.1.3b"} end);
        if not success and status then return status, nil end

		return (request or http_request or (http and http.request))
	end

	return {}
end

local crypt = (crypt or {})
syn.crypt = crypt

function syn.secure_call(target_func, fake_script, ...)
    assert(getsenv, 'Your executor must support getsenv inorder to use syn.secure_call');
    assert(getthreadidentity, 'Your executor must support getthreadidentity inorder to use syn.secure_call');
    assert(setthreadidentity, 'Your executor must support setthreadidentity inorder to use syn.secure_call');

    getfenv(target_func).getgenv = nil;
    getfenv(target_func).getfenv = function() return getfenv(0) end

    setfenv(target_func, getsenv(fake_script));
    local saved = getidentity();
    setidentity(2);
    local f = target_func(...);
    setidentity(tonumber(saved));
    setfenv(target_func, env);

	return f(...) -- my work here is done
end

function syn.run_secure_function(func, ...)
	task.spawn(func, ...)
end

function syn.create_secure_function(arg) -- at this point bro just newcclosure
	assert(type(arg) == 'function', 'expected a function, got ' .. type(arg))
	table.insert(syn, {func = arg})

    arg = newcclosure(arg);
    local t = clonefunction(arg);
    if not getfenv(t) == getfenv(arg) then
        setfenv(t, getfenv(arg))
    end

    getfenv(t).getfenv = function() return getfenv(0) end
    getfenv(t).game = syn_ref(workspace.Parent);

    return t
end


function syn.is_luau()
	return _VERSION == 'Luau' -- are we srs
end

syn.set_thread_identity = function(identity: number)
    return (setidentity and setidentity(identity) or (setthreadidentity and setthreadidentity(identity)));
end

syn._getthreadidentity = function(): number
    return (getidentity and getidentity()) or 3
end

function syn.toast_notification(T: string, T2: string, image) -- this will not be added.
	game.GetService(game, 'StarterGui'):SetCore("SendNotification", {
		Title = T,
		Text = T2,
		Icon = image or nil
    })
end

	-- function syn.definetly_not_bsod()
	--     game:GetService("RunService").RenderStepped:Connect(function()
	--         while task.wait(0.01) do
	--             buffer.create(0x4000000000)
	--         end
	--     end)
	-- end



function syn.isreadonly(main: {}): boolean
    return (isreadonly or function(tb: {}) return table.isfrozen(tb) end)
end


function syn.setreadonly(tb: {}, option: boolean)
    return (setreadonly or function() end)
end

return syn -- i like mine in a cup

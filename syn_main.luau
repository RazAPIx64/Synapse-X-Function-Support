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

identity = (getidentity and getidentity()) or nil

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
    (cache and cache.invalidate)(invalidated_Cache)

    if not cache then
        find_and_nill_registry_value(invalidated_Cache)

        syn.Cached[invalidated_Cache] = nil
        pcall(function() invalidated_Cache.Parent = nil end)
    end
end

function syn.cache_replace(a,b)
	if cache and cache.replace then return cache.replace(a,b) end
	syn.Cached[a], syn.Cached[b] = nil, syn.Cached[a]
	local r = (getreg and getreg()) or (env and env.getreg and env.getreg())
	if not r then
		local m1 = getmetatable(syn.Cached[a]) or syn.Cached[a]
		local m2 = getmetatable(syn.Cached[b]) or syn.Cached[b]
		syn.Cached[m1] = m2
		return
	end
	for i,v in pairs(r) do
		if v == a then r[i] = b
		elseif type(v) == "table" and table.find(v, a) then
			for k,val in pairs(v) do if val == a then v[k] = b end end
		end
	end
end

function syn.cache_iscached(i)
	if cache and cache.iscached then return cache.iscached(i) end
	if syn.Cached[i] ~= nil then return true end
	local r = (getreg and getreg()) or (env and env.getreg and env.getreg())
	if not r then return false end
	for _,v in pairs(r) do
		if v == i then return true
		elseif type(v) == "table" and table.find(v, i) then return true end
	end
	return false
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
syn.crypt = crypt;
syn.crypto = crypt;

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

syn.run_on_actor = (run_on_actor or function(actor: Instance, source: string, ...)
    assert(typeof(actor) == 'Instance', 'syn.run_on_actor: expected Instance, got ' .. typeof(actor));
    assert(actor.ClassName == 'Actor', 'argument #1 is not an Actor');

    assert(actor:FindFirstChildOfClass('LocalScript') or actor:FindFirstChildOfClass('ModuleScript'), 'No script found inside of Actor');

    (loadstring or (function(...) return function(...) end end))(actor:FindFirstChildOfClass('LocalScript').Source)();
end);

syn.clear_teleport_queue = (clear_teleport_queue or function()
    (queue_on_teleport or (queueonteleport or (function(s) return s end)))('')
end)

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

syn.get_thread_identity = function(): number
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

function syn.write_clipboard(content: string)
    return (setclipboard and setclipboard(content));
end


return syn -- i like mine in a cup

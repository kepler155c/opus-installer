local GIT_URL        = 'https://raw.githubusercontent.com'
local DEFAULT_UPATH  = GIT_URL .. '/kepler155c/opus-installer/master/sys/apis'

local http   = _G.http
local os     = _G.os
local string = _G.string

local function loadUrl(url)
	local c
	local h = http.get(url)
	if h then
		c = h.readAll()
		h.close()
	end
	if c and #c > 0 then
		return c
	end
end

-- Add require and package to the environment
return function(env)
	local function loadedSearcher(modname)
			if env.package.loaded[modname] then
			return function()
				return env.package.loaded[modname]
			end
		end
	end

	local function urlSearcher(modname)
		local fname = modname:gsub('%.', '/') .. '.lua'

		if fname:sub(1, 1) ~= '/' then
			for entry in string.gmatch(env.package.upath, "[^;]+") do
				local url = entry .. '/' .. fname
				local c = loadUrl(url)
				if c then
					return load(c, modname, nil, env)
				end
			end
		end
	end

	-- place package and require function into env
	env.package = {
		upath  = env.LUA_UPATH or _G.LUA_UPATH or DEFAULT_UPATH,
		config = '/\n:\n?\n!\n-',
		preload = { },
		loaded = {
			coroutine = coroutine,
			io     = io,
			math   = math,
			os     = os,
			string = string,
			table  = table,
		},
		loaders = {
			loadedSearcher,
			urlSearcher,
		}
	}

	function env.require(modname)
		for _,searcher in ipairs(env.package.loaders) do
			local fn, msg = searcher(modname)
			if fn then
				local module, msg2 = fn(modname, env)
				if not module then
					error(msg2 or (modname .. ' module returned nil'), 2)
				end
				env.package.loaded[modname] = module
				return module
			end
			if msg then
				error(msg, 2)
			end
		end
		error('Unable to find module ' .. modname)
	end
end

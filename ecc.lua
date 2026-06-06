	
	-- Include module if it is not embedded
	if premake.modules.ecc == nil then
		include ( "_preload.lua" )
	end

	local p = premake
	local project = p.project

	p.modules.ecc = {}
	local m = p.modules.ecc

	m._VERSION = "1.0.1-alpha"

	function m.generateFile()
		p.push("[")
		for wks in p.global.eachWorkspace() do
			for prj in p.workspace.eachproject(wks) do
				m.onProject(prj)
			end
		end
		p.pop("]")
	end

	function m.onProject(prj)
		if project.isc(prj) or project.iscpp(prj) then
			local cfg = m.getConfig(prj)
			local args = m.getArguments(prj, cfg)
			local files = table.shallowcopy(prj._.files)
			-- "directory" must be a path that exists on disk so clangd can chdir
			-- there. prj.location is often a virtual workspace path that hasn't
			-- been created on disk; fall back to where we're writing the JSON.
			local outdir = path.getabsolute(_OPTIONS["ecc-output"] or _MAIN_SCRIPT_DIR)
			for i,node in ipairs(files) do
				local output = path.getabsolute(cfg.objdir .. "/" ..  node.objname .. ".o")
				p.push("{")
				p.push("\"arguments\": [")
				m.writeArgs(args, prj.location, output, node.abspath)
				p.pop("],")
				p.w("\"directory\": \"%s\",", outdir)
				p.w("\"file\": \"%s\",", node.abspath)
				p.w("\"output\": \"%s\"", output)
				p.pop("},")
			end
		end
	end

	-- Flags premake's toolsets emit as "<flag> <path>" in a single string. In a
	-- Makefile that's fine — the shell re-tokenizes — but compile_commands.json
	-- treats each array entry as one verbatim argv slot, so clangd otherwise looks
	-- up a path that begins with a literal space. Split these into two tokens.
	local two_token_flags = {
		["-isystem"] = true,
		["-iquote"] = true,
		["-iframework"] = true,
		["-isysroot"] = true,
		["-include"] = true,
		["-imacros"] = true,
		["-idirafter"] = true,
	}

	local function jsonEscape(s)
		-- Escape backslashes first so existing escapes (e.g. -DVERSION=\"x.y.z\")
		-- aren't double-mangled when we then escape the embedded quotes.
		return s:gsub("\\", "\\\\"):gsub("\"", "\\\"")
	end

	-- Resolve a path that premake authored relative to `base` to an absolute
	-- path so clangd doesn't need a particular CWD to find it.
	local function absPath(base, rel)
		if path.isabsolute(rel) then
			return rel
		end
		return path.getabsolute(path.join(base, rel))
	end

	function m.writeArgs(args, base, obj, src)
		for _,arg in ipairs(args) do
			-- Defines like the following will break JSON format, quotes need to be escaped
			-- -DEXPORT_API=__attribute__((visibility("default")))
			local space_idx = arg:find(" ", 1, true)
			local first = space_idx and arg:sub(1, space_idx - 1) or nil
			if first and two_token_flags[first] then
				local rest = arg:sub(space_idx + 1)
				if #rest >= 2 and rest:sub(1, 1) == "\"" and rest:sub(-1) == "\"" then
					rest = rest:sub(2, -2)
				end
				p.w("\"%s\",", first)
				p.w("\"%s\",", jsonEscape(absPath(base, rest)))
			elseif arg:sub(1, 2) == "-I" and #arg > 2 then
				p.w("\"-I%s\",", jsonEscape(absPath(base, arg:sub(3))))
			else
				p.w("\"%s\",", jsonEscape(arg))
			end
		end
		p.w("\"-c\",")
		p.w("\"-o\",")
		p.w("\"%s\",", obj)
		p.w("\"%s\"", jsonEscape(src))
	end

	function m.getConfig(prj)
		local ocfg = _OPTIONS.config
		local cfg = {}
		if ocfg and prj.configs[ocfg] then
			cfg = prj.configs[ocfg]
		else
			cfg = m.defaultconfig(prj)
		end
		return cfg
	end

	function m.getArguments(prj, cfg)
		local toolset = m.getToolSet(cfg)
		local args = {}
		local tool = iif(project.iscpp(prj), "cxx", "cc")
		local toolname = iif(cfg.prefix, toolset.gettoolname(cfg, tool), toolset.tools[tool])
		args = table.join(args, toolname)
		args = table.join(args, toolset.getcppflags(cfg)) -- Preprocessor
		args = table.join(args, toolset.getdefines(cfg.defines))
		args = table.join(args, toolset.getundefines(cfg.undefines))
		args = table.join(args, toolset.getincludedirs(cfg, cfg.includedirs, cfg.externalincludedirs or cfg.sysincludedirs))
		if project.iscpp(prj) then
			args = table.join(args, toolset.getcxxflags(cfg))
		else
			args = table.join(args, toolset.getcflags(cfg))
		end
		args = table.join(args, cfg.buildoptions)
		return args
	end

	-- Copied from gmake2 module
	-- Return default toolset of given config or  system default toolset
	function m.getToolSet(cfg)
		local default = iif(cfg.system == p.MACOSX, "clang", "gcc")
		local toolset = p.tools[_OPTIONS.cc or cfg.toolset or default]
		if not toolset then
			error("Invalid toolset '" .. cfg.toolset .. "'")
		end
		return toolset
	end

	-- Copied from gmake2 module
	function m.defaultconfig(target)
		-- find the right configuration iterator function for this object
		local eachconfig = iif(target.project, project.eachconfig, p.workspace.eachconfig)
		local defaultconfig = nil

		-- find the right default configuration platform, grab first configuration that matches
		if target.defaultplatform then
			for cfg in eachconfig(target) do
				if cfg.platform == target.defaultplatform then
					defaultconfig = cfg
					break
				end
			end
		end

		-- grab the first configuration and write the block
		if not defaultconfig then
			local iter = eachconfig(target)
			defaultconfig = iter()
		end

		return defaultconfig
	end

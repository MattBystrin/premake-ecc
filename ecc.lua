
	local p = premake
	local project = p.project

	p.modules.ecc = {}
	local m = p.modules.ecc

	newoption {
		trigger = "config",
		value = "CFG",
		description = "Select config for export compile_commands.json"
	}

	newaction {
		trigger         = "ecc",
		shortname       = "Export compile commands",
		description     = "Export compile_commands.json for language server",
		toolset         = "gcc",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		valid_languages = { "C", "C++" },
		valid_tools     = {
			cc     = { "clang", "gcc" }
		},

		--onWorkspace = function(wks)
		--	p.escaper(p.make.esc)
		--	p.generate(wks, p.make.getmakefilename(wks, false), p.make.generate_workspace)
		--end,

		-- Module iterates through the projects and adds data to
		-- modules' global talbe, which is after encoded to a json

		onProject = function(prj)
			--p.escaper(p.make.esc)
			--local makefile = p.make.getmakefilename(prj, true)
			if project.isc(prj) or project.iscpp(prj) then
				--p.generate(prj, makefile, p.make.cpp.generate)
				print(prj.name)
				local config = _OPTIONS.config
				local cfg = {}
				if config then
					cfg = prj.configs[config]
					if not cfg then
						cfg = m.defaultconfig(prj)
						print("Not valid config. Using default one")
					end
				else
					cfg = m.defaultconfig(prj)
				end

				m.getArguments(cfg)

				--local objdir = project.getrelative(cfg.project, cfg.objdir)
				--local includes = toolset.getincludedirs(cfg, cfg.includedirs, cfg.sysincludedirs)
				-- print(includes)
			end
		end,
	}

	function m.getArguments(cfg)
		local toolset = m.getToolSet(cfg)
		local toolname = iif(cfg.prefix, toolset.gettoolname(cfg, "cxx"), toolset.tools["cxx"])
		print(toolname)
		local cxxflags
		local defines
		local includes
		local forcesincludes
	end

	function m.getDirectory(cfg)
		print(cfg)
	end

	function m.getFile(cfg)
		print(cfg)
	end

	function m.getOutput(cfg)
		print(cfg)
	end

	-- Copied from gmake2 module
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

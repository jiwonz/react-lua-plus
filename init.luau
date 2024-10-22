--!strict

local argparse = require("./submodules/argparse")
local process = require("@lune/process")
local serde = require("@lune/serde")
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local TYPED_REACT_PACKAGE = "jiwonz/react-lua-plus"
local TYPED_REACT_VERSION = "0.1.3"

local function stringStarts(str, start)
	return string.sub(str, 1, string.len(start)) == start
end

local function toHashTable(array: { any })
	local tbl = {}
	for _, v in array do
		tbl[v] = true
	end
	return tbl
end

local function generate(args: {
	output: string?,
	classes: string?
})
	local output = args.output or "GeneratedReactTypes"
	local db = roblox.getReflectionDatabase()
	--local classes = args.classes and args.classes:split(",") or db:GetClassNames()
	-- {
	-- -- 	"Frame",
	-- -- 	"TextLabel",
	-- -- 	"TextBox",
	-- -- 	"TextButton",
	-- -- 	"ImageButton",
	-- -- 	"ImageLabel",
	-- -- 	"ViewportFrame",
	-- -- 	"ScrollingFrame",
	-- -- 	"CanvasGroup",
	-- -- }
	-- local freepassClasses = {}
	-- for _, name in db:GetClassNames() do
	-- 	if name:sub(1, 2) == "UI" then
	-- 		freepassClasses[name] = true
	-- 	end
	-- end
	local allowedSuperClasses = {
		BasePart = true,
		GuiBase2d = true,
		GuiBase3d = true,
		GuiObject = true,
	}
	local base = "local r=require(script.Parent.react);export type e=(<T>((T)->())->((T)->(r.ReactElement<(T)->(),T>)))&%s;return nil"
	local elementsType = {}
	local datatypeMap = {
		String = "string",
		Bool = "boolean",
		Float32 = "number",
		Float64 = "number",
		Content = "string",
		Int64 = "number",
		Int32 = "number",
		Int16 = "number",
		Ref = "Instance"
	}
	for _, name in db:GetClassNames() :: { string } do
		local function processClass(className, ptbl: {}?): boolean?
			local class = db:FindClass(className)
			if class and not table.find(class.Tags, "Deprecated") then
				if not ptbl then
					local allowed = false
					do
						local currentClass = class.Superclass
						while currentClass ~= nil do
							if allowedSuperClasses[currentClass] then
								allowed = true
								break
							else
								local nex = db:FindClass(currentClass)
								if nex then
									currentClass = nex.Superclass
								end
							end
						end
					end
					if not allowed then
						return true
					end
					local tags = toHashTable(class.Tags)
					if tags.Deprecated or tags.NotCreatable or tags.NotBrowsable or tags.Settings or tags.UserSettings or tags.Service then
						return true
					end
				end
				local props = ptbl or {}
				for _, v in class.Properties do
					if v.Datatype ~= "RBXScriptSignal" and v.Scriptability ~= "Write" and v.Scriptability ~= "ReadWrite" then
						continue
					end
					local typeName = datatypeMap[v.Datatype] or v.Datatype
					table.insert(props, v.Name..":"..typeName.."?,")
				end
				local superclass = class.Superclass
				if superclass then
					processClass(superclass, props)
				end
				if not ptbl then
					local propsType = "{"..table.concat(props).."}"
					table.insert(elementsType, `(("{className}")->({propsType})->r.ReactElement<"{className}",{propsType}>)`)
				end
			end
			return
		end
		if processClass(name) then
			continue
		end
	end
	fs.writeDir(output)
	fs.writeFile(output.."/init.luau", base:format(table.concat(elementsType, "&")))
end

local function applyReactPlus()
	if fs.isDir("Packages") then
		local indexDir
		for _, name in fs.readDir("Packages/_Index") do
			local indexName = TYPED_REACT_PACKAGE:gsub("/", "_")
			--print(name, indexName)
			if stringStarts(name, indexName) then
				indexDir = "Packages/_Index/" .. name
			end
		end
		if indexDir and fs.isDir(indexDir) then
			generate({
				output = indexDir.."/GeneratedReactTypes"
			})
		else
			error(`Package(typed-react) index not found: {indexDir}`)
		end
	else
		error("Failed to find Packages folder")
	end
end

-- only supports wally for now.. sorry pesde
local parser = argparse("react-lua-plus")
local setupCommand = parser:command("setup", "Setups react-lua-setup")
setupCommand:action(function(_)
	process.spawn("wally", {"init"})
	if fs.isFile("wally.toml") then
		local wally = serde.decode("toml", fs.readFile("wally.toml"))
		local dependencies = wally.dependencies
		if not dependencies then
			dependencies = {}
			wally.dependencies = dependencies
		end
		dependencies["react"] = TYPED_REACT_PACKAGE.."@"..TYPED_REACT_VERSION
		dependencies["react-roblox"] = "jsdotlua/react-roblox@17.1.0"
		fs.writeFile("wally.toml", serde.encode("toml", wally))
		local result = process.spawn("wally", {"install"})
		if result.ok then
			applyReactPlus()
		else
			print(result.stderr)
			error("Failed to install packages from wally")
		end
	else
		error("wally.toml not found")
	end
end)

local generateCommand = parser:command("generate", "Generate react types")
generateCommand:option("--output", "Generated react types module path")
generateCommand:option("--classes", "CSV list of roblox class names to generate")
generateCommand:action(generate)

local applyCommand = parser:command("apply", "Applies react-lua-plus features")
applyCommand:action(applyReactPlus)

parser:parse()

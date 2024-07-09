--!strict

local argparse = require("./submodules/argparse")
local process = require("@lune/process")
local serde = require("@lune/serde")
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local function updateReact(packagePath: string?) -- packagePath ex. Packages/react.lua

end

local parser = argparse("react-lua-setup")
parser:option("--project", "Project directory path")
parser:action(function(args: {
	project: string?
})
	if args.project then
		process.spawn("cd", {args.project})
	end
	process.spawn("wally", {"init"})
	if fs.isFile("wally.toml") then
		local wally = serde.decode("toml", fs.readFile("wally.toml"))
		local dependencies = wally.dependencies
		if not dependencies then
			dependencies = {}
			wally.dependencies = dependencies
		end
		dependencies["react"] = "jiwonz/typed-react@0.1.0"
		dependencies["react-roblox"] = "jsdotlua/react-roblox@17.1.0"
		fs.writeFile("wally.toml", serde.encode("toml", wally))
		process.spawn("wally", {"install"})
	else
		error("wally.toml not found")
	end
end)
local generateCommand = parser:command("generate", "Generate react types")
generateCommand:option("--output", "Generated react types module path")
generateCommand:option("--classes", "CSV list of roblox class names to generate")
generateCommand:action(function(args: {
	output: string?,
	classes: string?
})
	local output = args.output or "GeneratedReactTypes"
	local db = roblox.getReflectionDatabase()
	local classes = args.classes and args.classes:split(",") or {
		"Frame",
		"TextLabel",
		"TextBox",
		"TextButton",
		"ImageButton",
		"ImageLabel",
		"ViewportFrame",
		"ScrollingFrame",
		"CanvasGroup"
	}
	local base = "export type Element=%s;return nil"
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
	for _, name in classes :: { string } do
		local function processClass(className, ptbl: {}?)
			local class = db:FindClass(className)
			if class then
				local props = ptbl or {}
				for _, v in class.Properties do
					if v.Scriptability ~= "Write" and v.Scriptability ~= "ReadWrite" then
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
					table.insert(elementsType, `(("{className}")->({"{"..table.concat(props).."}"})->(any))`)
				end
			end
		end
		processClass(name)
	end
	fs.writeDir(output)
	fs.writeFile(output.."/init.luau", base:format(table.concat(elementsType, "&")))
end)

parser:parse()

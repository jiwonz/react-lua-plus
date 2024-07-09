# react-lua-plus
A lune script that setups `react-lua` with some additional features

# Note
Not tested yet in game, only tested intellisenses for `createElement`

# Requirements
- `lune`
- `wally`

# Installation
Use git submodule
```sh
git submodule add
```

# Usage
```sh
lune run react-lua-plus setup # to install react-lua and generate types in cwd
lune run react-lua-plus apply # for apply types for react-lua-plus, useful when you perform `wally install`
lune run react-lua-plus generate -- --output "path/to/output" -- --classes "Class1,Class2,Class3" # to generate react-lua-plus types
```
```lua
local function App()
	local message, setMessage = React.useState("Hello world")
	return React.Element("TextLabel"){
		Text = message,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(300, 100),
		React.Element("UICorner"){}
	}
end
```

# Features
- Simple to setup and use
- Intellisenses for React `createElement` (but in alternative way called `Element`)
- (wip) Event listening and children in props
- (wip) Server-Sided Rendering (SSR) support for Roblox

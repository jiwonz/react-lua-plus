--!strict

local React = require(script.Parent.react)
local GeneratedReactTypes = require(script.Parent.GeneratedReactTypes)

type TypedReact = typeof(React) & {
	Element: GeneratedReactTypes.Element
}

;(React :: TypedReact).Element = function(type_)
	return function(props)
		local children = {}
		for _, child in ipairs(props) do
			table.insert(children, child)
		end
		return React.createElement(type_, props, children)
	end
end :: any

return React :: TypedReact

--!nocheck

local React = require(script.Parent.react)
local GeneratedReactTypes = require(script.Parent.GeneratedReactTypes)

type TypedReact = typeof(React) & {
	Element: GeneratedReactTypes.e
}

;(React :: TypedReact).Element = function(type_)
	return function(props)
		local children = {}
		for _, child in ipairs(props) do
			table.insert(children, child)
		end
		return React.createElement(type_, props, children)
	end
end

return React :: TypedReact

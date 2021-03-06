local segment_priority = plc_priority_npm or 60

plc_npm_segment_textColor = colorWhite
plc_npm_segment_fillColor = colorCyan

local function get_package_json_file(path)
  if not path or path == '.' then path = clink.get_cwd() end

  local parent_path = toParent(path)
  return io.open(joinPaths(path, 'package.json')) or (parent_path ~= path and get_package_json_file(parent_path) or nil)
end

-- * Segment object with these properties:
---- * isNeeded: sepcifies whether a segment should be added or not. For example: no Git segment is needed in a non-git folder
---- * text
---- * textColor: Use one of the color constants. Ex: colorWhite
---- * fillColor: Use one of the color constants. Ex: colorBlue
local segment = {
  isNeeded = false,
  text = "",
  textColor = nil,
  fillColor = nil
}

---
-- Sets the properties of the Segment object, and prepares for a segment to be added
---
local function init()
  segment.isNeeded = get_package_json_file()
  if segment.isNeeded then
    local package_info = segment.isNeeded:read('*a')
    segment.isNeeded:close()

    local package_name = string.match(package_info, '"name"%s*:%s*"(%g-)"')
    if package_name == nil then
            package_name = ''
    end

    local package_version = string.match(package_info, '"version"%s*:%s*"(.-)"')
    if package_version == nil then
            package_version = ''
    end

    if plc_npm_npmSymbol then
      segment.text = " "..plc_npm_npmSymbol.." "..package_name.."@"..package_version.." "
    else
      segment.text = " "..package_name.."@"..package_version.." "
    end

    segment.textColor = plc_npm_segment_textColor
    segment.fillColor = plc_npm_segment_fillColor
  end
end

-- Register this addon with Clink
local addAddonSegment = nil

---
-- Uses the segment properties to add a new segment to the prompt
---
if not clink.version_major then

  -- Old Clink API (v0.4.x)
  addAddonSegment = function ()
    init()
    if segment.isNeeded then 
      addSegment(segment.text, segment.textColor, segment.fillColor)
    end 
  end

  clink.prompt.register_filter(addAddonSegment, segment_priority)

else

  -- New Clink API (v1.x)
  addAddonSegment = clink.promptfilter(segment_priority)

  function addAddonSegment:filter(prompt)
    init()
    if segment.isNeeded then
      return addSegment(segment.text, segment.textColor, segment.fillColor)
    end
    return prompt
  end

end

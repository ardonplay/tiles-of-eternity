local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local cpu = sbar.add("item", "widgets.memory",{
  position = "right",
  background = {
    height = 22,
    color = { alpha = 0 },
    border_color = { alpha = 0 },
    drawing = true,
  },
  icon = { string = icons.cpu },
  label = {
    string = "0%",
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 13.0,
    },
    align = "right",
  },
  padding_right = settings.paddings + 6
})

cpu:subscribe("system_stats", function(env)
  local load = tonumber(env.CPU_USAGE)
  cpu:set({
    label = env.CPU_USAGE,
  })
end)
-- Background around the cpu item
sbar.add("bracket", "widgets.memory.bracket", { cpu.name }, {
  background = { color = colors.bg1 }
})

-- Background around the cpu item
sbar.add("item", "widgets.memory.padding", {
  position = "right",
  width = settings.group_paddings
})

local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local popup_width = 250

local volume_percent = sbar.add("item", "widgets.volume1", {
  position = "right",
  icon = { drawing = false },
  label = {
    string = "??%",
    padding_left = -1,
    font = { family = settings.font.numbers }
  },
})

local volume_icon = sbar.add("item", "widgets.volume2", {
  position = "right",
  padding_right = -1,
  icon = {
   drawing="off"
  },
  label = {
    width = 25,
    align = "left",
    font = {
      style = settings.font.style_map["Regular"],
      size = 14.0,
    },
  },
})

local volume_bracket = sbar.add("bracket", "widgets.volume.bracket", {
  volume_icon.name,
  volume_percent.name
}, {
  background = { color = colors.bg1 },
  popup = { align = "center" }
})



local function get_audio_device_info()
  local device_info = { type = "Unknown", name = "Unknown" }
  local output = io.popen("system_profiler SPAudioDataType"):read("*a") -- Читаем весь вывод сразу

  local current_device_name = nil
  local is_default = false

  for line in output:gmatch("[^\r\n]+") do
    line = line:match("^%s*(.-)%s*$") -- Убираем пробелы в начале и конце

    -- Находим заголовок устройства (имя)
    local device_header = line:match("^(.*):$")
    if device_header and not line:match("Manufacturer:") then
      current_device_name = device_header
      is_default = false -- Сбрасываем флаг для нового устройства
    end

    -- Проверяем, что устройство — Default Output Device
    if line:match("Default Output Device: Yes") then
      is_default = true
    end

    -- Если это устройство по умолчанию, собираем данные
    if is_default then
      if line:match("Transport:") then
        device_info.type = line:match("Transport:%s*(.*)") or "Unknown"
      end
      if current_device_name then
        device_info.name = current_device_name:gsub(" USB", "")   -- Убираем 'USB'
                                          :gsub(" Speakers", "") -- Убираем 'Speakers'
                                          :gsub(" Microphone", "") -- 'Microphone'
      end
    end
  end

  return device_info
end


local function get_volume_icon(device_type, device_name)
  local icon = "􀊩" 

  if device_type == "USB" then
    icon = "􁏎" 
  elseif device_type == "Bluetooth" then
    icon = "􀑈"
  end

  return icon
end

local function get_volume_label(volume, device_type, device_name)
  local label = volume .. "%"
  if device_type == "USB" then
    label = device_name 
  end
  return label
end


sbar.add("item", "widgets.volume.padding", {
  position = "right",
  width = settings.group_paddings
})

local volume_slider = sbar.add("slider", popup_width, {
  position = "popup." .. volume_bracket.name,
  slider = {
    highlight_color = colors.blue,
    background = {
      height = 6,
      corner_radius = 3,
      color = colors.bg2,
    },
    knob= {
      string = "􀀁",
      drawing = true,
    },
  },
  background = { color = colors.bg1, height = 2, y_offset = -20 },
  click_script = 'osascript -e "set volume output volume $PERCENTAGE"'
})

volume_percent:subscribe("volume_change", function(env)
  local volume = tonumber(env.INFO)

  local device_info = get_audio_device_info()

  local icon = get_volume_icon(device_info.type, device_info.name)
  local label = get_volume_label(volume, device_info.type, device_info.name)

  if volume > 60 then
    icon = icons.volume._100
  elseif volume > 30 then
    icon = icons.volume._66
  elseif volume > 10 then
    icon = icons.volume._33
  elseif volume > 0 then
    icon = icons.volume._10
    label=""
  end


  volume_icon:set({ label = icon })
  volume_percent:set({ label = label })
  volume_slider:set({ slider = { percentage = volume } })
end)

local function volume_collapse_details()
  local drawing = volume_bracket:query().popup.drawing == "on"
  if not drawing then return end
  volume_bracket:set({ popup = { drawing = false } })
  sbar.remove('/volume.device\\.*/')
end

local current_audio_device = "None"
local function volume_toggle_details(env)
  if env.BUTTON == "right" then
    sbar.exec("open /System/Library/PreferencePanes/Sound.prefpane")
    return
  end

  local should_draw = volume_bracket:query().popup.drawing == "off"
  if should_draw then
    volume_bracket:set({ popup = { drawing = true } })
    sbar.exec("SwitchAudioSource -t output -c", function(result)
      current_audio_device = result:sub(1, -2)
      sbar.exec("SwitchAudioSource -a -t output", function(available)
        current = current_audio_device
        local color = colors.grey
        local counter = 0

        for device in string.gmatch(available, '[^\r\n]+') do
          local color = colors.grey
          if current == device then
            color = colors.white
          end
          sbar.add("item", "volume.device." .. counter, {
            position = "popup." .. volume_bracket.name,
            width = popup_width,
            align = "center",
            label = { string = device, color = color },
            click_script = 'SwitchAudioSource -s "' .. device .. '" && sketchybar --set /volume.device\\.*/ label.color=' .. colors.grey .. ' --set $NAME label.color=' .. colors.white

          })
          counter = counter + 1
        end
      end)
    end)
  else
    volume_collapse_details()
  end
end

local function volume_scroll(env)
  local delta = env.INFO.delta
  if not (env.INFO.modifier == "ctrl") then delta = delta * 10.0 end

  sbar.exec('osascript -e "set volume output volume (output volume of (get volume settings) + ' .. delta .. ')"')
end

volume_icon:subscribe("mouse.clicked", volume_toggle_details)
volume_icon:subscribe("mouse.scrolled", volume_scroll)
volume_percent:subscribe("mouse.clicked", volume_toggle_details)
volume_percent:subscribe("mouse.exited.global", volume_collapse_details)
volume_percent:subscribe("mouse.scrolled", volume_scroll)

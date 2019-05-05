-- NoIndex: true

local Buffer = require("gui.buffer")

local Font = require("public.font")
local Color = require("public.color")
local Math = require("public.math")
local GFX = require("public.gfx")
local Text = require("public.text")
-- local Table = require("public.table")
local Config = require("gui.config")

local Slider = require("gui.element"):new()
Slider.__index = Slider
Slider.defaultProps = {

  type = "Slider",

  x = 0,
  y = 0,
  w = 64,

  horizontal = true,

  caption = "Slider",
  bg = "windowBg",

  captionFont = 3,
  textFont = 4,

  textColor = "txt",
  handleColor = "elmFrame",
  fillColor = "elmFill",

  min = 0,
  max = 10,
  defaults = 5,

  alignValues = 0,
  inc = 1,

  captionX = 0,
  captionY = 0,

  showHandles = true,
  showValues = true,

}

function Slider:new(props)
  local slider = self:addDefaultProps(props)

  slider.w, slider.h = table.unpack(slider.horizontal
    and {slider.w, 8}
    or  {8, slider.w}
  )

  local min = slider.min
  local max = slider.max

  if min > max then
    min, max = max, min
  elseif min == max then
    max = max + 1
  end

  if not slider.horizontal then
    min, max = max, min
  end
  slider.min, slider.max = min, max

  self:assignChild(slider)

  slider.defaults = slider.defaults

  -- If the user only asked for one handle
  if type(slider.defaults) == "number" then slider.defaults = {slider.defaults} end

  slider:initHandles(slider.defaults)

  return slider
end


function Slider:init()

  self.buffers = self.buffers or Buffer.get(2)

  -- In case we were given a new set of handles without involving GUI.Val
  if not self.handles[1].default then self:initHandles() end

  local w, h = self.w, self.h

  -- Track
  gfx.dest = self.buffers[1]
  gfx.setimgdim(self.buffers[1], -1, -1)
  gfx.setimgdim(self.buffers[1], w + 4, h + 4)

  Color.set("elmBg")
  GFX.roundRect(2, 2, w, h, 4, 1, 1)
  Color.set("elmOutline")
  GFX.roundRect(2, 2, w, h, 4, 1, 0)


  -- Handle
  local hw, hh = table.unpack(self.horizontal and {8, 16} or {16, 8})

  gfx.dest = self.buffers[2]
  gfx.setimgdim(self.buffers[2], -1, -1)
  gfx.setimgdim(self.buffers[2], 2 * hw + 4, hh + 2)

  Color.set(self.handleColor)
  GFX.roundRect(1, 1, hw, hh, 2, 1, 1)
  Color.set("elmOutline")
  GFX.roundRect(1, 1, hw, hh, 2, 1, 0)

  local r, g, b, a = table.unpack(Color.colors["shadow"])
  gfx.set(r, g, b, 1)
  GFX.roundRect(hw + 2, 1, hw, hh, 2, 1, 1)
  gfx.muladdrect(hw + 2, 1, hw + 2, hh + 2, 1, 1, 1, a, 0, 0, 0, 0 )

end


function Slider:onDelete()

  Buffer.release(self.buffers)

end


function Slider:draw()

  local x, y, w, h = self.x, self.y, self.w, self.h

  -- Draw track
  gfx.blit(self.buffers[1], 1, 0, 1, 1, w + 2, h + 2, x - 1, y - 1)

  -- To avoid a LOT of copy/pasting for vertical sliders, we can
  -- just swap x-y and w-h to effectively "rotate" all of the math
  -- 90 degrees.

  if not self.horizontal then x, y, w, h = y, x, h, w end

  -- Limit everything to be drawn within the square part of the track
  x, w = x + 4, w - 8

  -- Size of the handle
  self.handleW, self.handleH = 8, h * 2
  local inc = w / self.steps
  local handleY = y + (h - self.handleH) / 2

  -- Get the handles' coordinates and the ends of the fill bar
  local min, max = self:updateHandleCoords(x, handleY, inc)

  self:drawFill(x, y, h, min, max, inc)

  self:drawSliders()
  if self.caption and self.caption ~= "" then self:drawCaption() end

end


function Slider:val(newvals)

  if newvals then

    if type(newvals) == "number" then newvals = {newvals} end

    for i = 1, #self.handles do

      self:setCurrentStep(i, newvals[i])

    end

    self:redraw()

  else

    local ret = {}
    for i = 1, #self.handles do

      table.insert(ret, tonumber(self.handles[i].retval))

    end

    if #ret == 1 then
      return ret[1]
    else
      table.sort(ret)
      return ret
    end

  end

end




------------------------------------
-------- Input methods -------------
------------------------------------


function Slider:onMouseDown(state)

  -- Snap the nearest slider to the nearest value
  local mouseValue = self.horizontal
    and (state.mouse.x - self.x) / self.w
    or  (state.mouse.y - self.y) / self.h

  self.currentHandle = self:getNearestHandle(mouseValue)

  self:setCurrentVal(self.currentHandle, Math.clamp(mouseValue, 0, 1) )

  self:redraw()

end


function Slider:onDrag(state, last)

  local n, ln = table.unpack(self.horizontal
    and {state.mouse.x, last.mouse.x}
    or  {state.mouse.y, last.mouse.y}
  )

  local cur = self.currentHandle or 1

  -- Ctrl?
  local ctrl = state.mouse.cap&4==4

  -- A multiplier for how fast the slider should move. Higher values = slower
  --						Ctrl							Normal
  local adj = ctrl and math.max(1200, (8*self.steps)) or 150
  local adjustedScale = (self.horizontal and self.w or self.h) / 150
  adj = adj * adjustedScale

  self:setCurrentVal(cur, Math.clamp( self.handles[cur].currentVal + ((n - ln) / adj) , 0, 1 ) )

  self:redraw()

end


function Slider:onWheel(state)

  local mouseValue = self.horizontal
    and (state.mouse.x - self.x) / self.w
    or  (state.mouse.y - self.y) / self.h

  local inc = Math.round( self.horizontal
    and state.mouse.wheelInc
    or -state.mouse.wheelInc )

  local cur = self:getNearestHandle(mouseValue)

  local ctrl = state.mouse.cap&4==4

  -- How many steps per wheel-step
  local fine = 1
  local coarse = math.max( Math.round(self.steps / 30), 1)

  local adj = ctrl and fine or coarse

    self:setCurrentVal(cur, Math.clamp( self.handles[cur].currentVal + (inc * adj / self.steps) , 0, 1) )

  self:redraw()

end


function Slider:onDoubleclick(state)

    -- Ctrl+click - Only reset the closest slider to the mouse
  if state.mouse.cap & 4 == 4 then

    local mouseValue = (state.mouse.x - self.x) / self.w
    local smallestDiff, closestIndex
    for i = 1, #self.handles do

      local diff = math.abs( self.handles[i].currentVal - mouseValue )
      if not smallestDiff or diff < smallestDiff then
        smallestDiff = diff
        closestIndex = i
      end

    end

    self:setCurrentStep(closestIndex, self.handles[closestIndex].default)

  -- Reset all sliders
  else

    for i = 1, #self.handles do

      self:setCurrentStep(i, self.handles[i].default)

    end

  end

  self:redraw()

end




------------------------------------
-------- Drawing helpers -----------
------------------------------------


function Slider:updateHandleCoords(x, handleY, inc)

  local min, max

  for i = 1, #self.handles do

    local center = x + inc * self.handles[i].currentStep
    self.handles[i].x, self.handles[i].y = center - (self.handleW / 2), handleY

    if not min or center < min then min = center end
    if not max or center > max then max = center end

  end

  return min, max

end


function Slider:drawFill(x, y, h, min, max, inc)

    -- Get the color
  if (#self.handles > 1)
  or self.handles[1].currentStep ~= self.handles[1].default then

    self:setfill()

  end

  -- Cap for the fill bar
  if #self.handles == 1 then
    min = x + inc * self.handles[1].default

    if self.horizontal then
      gfx.circle(min, y + (h / 2), h / 2 - 1, 1, 1)
    else
      gfx.circle(y + (h / 2), min, h / 2 - 1, 1, 1)
    end

  end

  if min > max then min, max = max, min end

  if self.horizontal then
    gfx.rect(min, y + 1, max - min, h - 1, 1)
  else
    gfx.rect(y + 1, min, h - 1, max - min, 1)
  end

end


function Slider:setfill()

  -- If the user has given us two colors to make a gradient with
  if self.fillColorA and #self.handles == 1 then

    local gradientStep = self.handles[1].currentStep / self.steps
    local r, g, b, a = Color.gradient(self.fillColorA, self.fillColorB, gradientStep)

    gfx.set(r, g, b, a)

  else
    Color.set(self.fillColor)
  end

end


function Slider:drawSliders()

  Color.set(self.textColor)
  Font.set(self.textFont)

  -- Drawing them in reverse order so overlaps match the shadow direction
  for i = #self.handles, 1, -1 do

    local handleX, handleY = Math.round(self.handles[i].x) - 1, Math.round(self.handles[i].y) - 1

    if self.showValues then

      if self.horizontal then
          self:drawSliderValue(handleX + self.handleW/2, handleY + self.handleH + 4, i)
      else
          self:drawSliderValue(handleY + self.handleH + self.handleH, handleX, i)
      end

    end

    if self.showHandles then

      if self.horizontal then
          self:drawSliderHandle(handleX, handleY, self.handleW, self.handleH)
      else
          self:drawSliderHandle(handleY, handleX, self.handleH, self.handleW)
      end

    end

  end

end


function Slider:drawSliderValue(x, y, sldr)

  local output = self:formatOutput(self.handles[sldr].retval)

  gfx.x, gfx.y = x, y

  Text.drawBackground(output, self.bg, self.alignValues + 256)
  gfx.drawstr(output, self.alignValues + 256, gfx.x, gfx.y)

end


function Slider:drawSliderHandle(hx, hy, hw, hh)

  for j = 1, Config.shadowSize do

    gfx.blit(self.buffers[2], 1, 0, hw + 2, 0, hw + 2, hh + 2, hx + j, hy + j)

  end

  gfx.blit(self.buffers[2], 1, 0, 0, 0, hw + 2, hh + 2, hx, hy)

end


function Slider:drawCaption()

  Font.set(self.captionFont)

  local strWidth, strHeight = gfx.measurestr(self.caption)

  gfx.x = self.x + (self.w - strWidth) / 2 + self.captionX
  gfx.y = self.y - (self.horizontal and self.h or self.w) - strHeight + self.captionY
  Text.drawBackground(self.caption, self.bg)
  Text.drawWithShadow(self.caption, self.textColor, "shadow")

end




------------------------------------
-------- Slider helpers ------------
------------------------------------


function Slider:getNearestHandle(val)

  local smallestDiff, closestIndex

  for i = 1, #self.handles do

    local diff = math.abs( self.handles[i].currentVal - val )

    if not smallestDiff or (diff < smallestDiff) then
      smallestDiff = diff
      closestIndex = i

    end

  end

  return closestIndex

end


function Slider:setCurrentStep(sldr, step)

  self.handles[sldr].currentStep = step
  self.handles[sldr].currentVal = self.handles[sldr].currentStep / self.steps
  self:setRetval(sldr)

end


function Slider:setCurrentVal(sldr, val)

  self.handles[sldr].currentVal = val
  self.handles[sldr].currentStep = Math.round(val * self.steps)
  self:setRetval(sldr)

end


function Slider:setRetval(sldr)

  local val = self.horizontal
    and self.inc * self.handles[sldr].currentStep + self.min
    or self.min - self.inc * self.handles[sldr].currentStep

  self.handles[sldr].retval = self:formatRetval(val)

end

function Slider:formatRetval(val)

  local decimal = tonumber(string.match(val, "%.(.*)") or 0)
  local places = decimal ~= 0 and string.len( decimal) or 0
  return string.format("%." .. places .. "f", val)

end

function Slider:initHandles()

  self.steps = math.abs(self.max - self.min) / self.inc

  -- Make sure the handles are all valid
  for i = 1, #self.defaults do
    self.defaults[i] = math.floor( Math.clamp(0, tonumber(self.defaults[i]), self.steps) )
  end

  self.handles = {}
  local step
  for i = 1, #self.defaults do

    step = self.defaults[i]

    self.handles[i] = {}
    self.handles[i].default = (self.horizontal and step or (self.steps - step))
    self.handles[i].currentStep = step
    self.handles[i].currentVal = step / self.steps
    self.handles[i].retval = self:formatRetval( ((self.max - self.min) / self.steps)
                                                * step + self.min)
  end

end

return Slider

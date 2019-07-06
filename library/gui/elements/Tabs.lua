-- NoIndex: true

local Font = require("public.font")
local Color = require("public.color")
local Math = require("public.math")
local Buffer = require("public.buffer")
-- local Table = require("public.table")
local Config = require("gui.config")

local Tabs = require("gui.element"):new()
Tabs.__index = Tabs
Tabs.defaultProps = {

  type = "Tabs",

  x = 0,
  y = 0,
  tabW = 72,
  tabH = 20,

  captionFont = 3,
  textFont = 4,

  bg = "elmBg",
  textColor = "txt",
  tabColorActive = "windowBg",
  tabColorInactive = "tabBg",

  -- Placeholder for if I ever figure out downward tabs
  dir = "u",

  pad = 8,

  firstTabOffset = 16,

  -- Currently-selected option
  retval = 1,
  state = 1,

  fullWidth = true,
}

function Tabs:new(props)

  local tab = self:addDefaultProps(props)

  tab.tabs = tab.tabs or {}

	-- Figure out the total size of the tab frame now that we know the
  -- number of buttons, so we can do the math for clicking on it
  tab.w = Tabs.getOverallWidth(tab)
  tab.h = tab.tabH

	return setmetatable(tab, self)
end


function Tabs:init()

  self.buffer = self.buffer or Buffer.get()
  self:updateSets()

  self.bufferSize = (#self.tabs * (self.tabW + 4))

  gfx.dest = self.buffer
  gfx.setimgdim(self.buffer, -1, -1)
  gfx.setimgdim(self.buffer, self.bufferSize, self.bufferSize)

  Color.set(self.bg)
  gfx.rect(0, 0, self.bufferSize, self.bufferSize, true)

  local xOffset = self.tabW + self.pad - self.tabH

  -- Because of anti-aliasing, we can't just draw and blit the tabs individually
  -- We'll draw the entire row separately for each state
  for state = 1, #self.tabs do
    for tab = #self.tabs, 1, -1 do
      if tab ~= state then
        -- Inactive
        self:drawTab(
          (tab - 1) * (xOffset),
          (state - 1) * (self.tabH + 4) + Config.shadowSize,
          self.tabW,
          self.tabH,
          self.dir, self.textFont, self.textColor, self.tabColorInactive, self.tabs[tab].label)
      end
    end

    -- Active
    self:drawTab(
      (state - 1) * (xOffset),
      (state - 1) * (self.tabH + 4),
      self.tabW,
      self.tabH,
      self.dir, self.textFont, self.textColor, self.tabColorActive, self.tabs[state].label)
  end

end

function Tabs:onDelete()

	Buffer.release(self.buffers)

end


function Tabs:draw()

	local x, y = self.x + self.firstTabOffset, self.y
  local tabW, tabH = self.tabW, self.tabH
	local state = self.state

  -- Make sure w is at least the size of the tabs.
  -- (GUI builder will let you try to set it lower)
  self.w = self.fullWidth
    and (self.layer.window.currentW - self.x)
    or math.max(self.w, self:getOverallWidth())

  -- Background
	Color.set(self.bg)
	gfx.rect(x - 16, y, self.w, self.h, true)

  -- Current tab state
  local xOffset = tabW + self.pad - tabH
  gfx.blit(
    self.buffer, 1, 0,
    0, (state - 1) * (tabH + 4),
    self.bufferSize, (tabH),
    x, y
  )

  -- Keep the active tab's top separate from the window background
	Color.set(self.bg)
  gfx.line(x + (state - 1) * xOffset, y, x + state * xOffset, y, 1)

end


function Tabs:val(newval)

	if newval then
		self.state = newval
		self.retval = self.state

		self:updateSets()
		self:redraw()
	else
		return self.state
	end

end


function Tabs:onResize()
  if self.fullWidth then self:redraw() end
end


------------------------------------
-------- Input methods -------------
------------------------------------


function Tabs:onMouseDown(state)

  local xOffset = (state.mouse.x - (self.x + self.firstTabOffset))
  local width = (#self.tabs * (self.tabW + self.pad - self.tabH))

  local mousePct = xOffset / width

	local mouseOption = Math.clamp((math.floor(mousePct * #self.tabs) + 1), 1, #self.tabs)

	self.state = mouseOption

	self:redraw()

end


function Tabs:onMouseUp(state)
	-- Set the new option, or revert to the original if the cursor isn't inside the list anymore
	if self:isInside(state.mouse.x, state.mouse.y) then

		self.retval = self.state
		self:updateSets()

	else
		self.state = self.retval
	end

	self:redraw()

end


function Tabs:onDrag(state, last)

	self:onMouseDown(state, last)
	self:redraw()

end


function Tabs:onWheel(state)

	self.state = Math.round(self.state + state.mouse.wheelInc)

	if self.state < 1 then self.state = 1 end
	if self.state > #self.tabs then self.state = #self.tabs end

	self.retval = self.state
	self:updateSets()
	self:redraw()

end




------------------------------------
-------- Drawing helpers -----------
------------------------------------


function Tabs:drawTab(x, y, w, h, dir, font, textColor, background, lbl)

	local dist = Config.shadowSize
  local y1, y2 = table.unpack(dir == "u" and  {y, y + h}
                                         or   {y + h, y})

  local adjustedX = x + (h / 2)
  local adjustedW = w - h
  local adjustedRight = adjustedX + adjustedW

	Color.set("shadow")

  -- tab shadow
  for i = 1, dist do

    gfx.rect(adjustedX + i, y, adjustedW, h, true)

    self:drawTabLeft(adjustedX, i, y1, y2, h)
    self:drawTabRight(adjustedRight, i, y1, y2, h)

  end

  self:drawAliasingFix(adjustedX, adjustedRight, dist, y1, y2, h)

  Color.set(background)

  gfx.rect(adjustedX, y, adjustedW, h, true)

  self:drawTabLeft(adjustedX, 0, y1, y2, h)
  self:drawTabRight(adjustedRight, 0, y1, y2, h)
  self:drawAliasingFix(adjustedX, adjustedRight, 0, y1, y2, h)

	-- Draw the tab's label
	Color.set(textColor)
	Font.set(font)

	local strWidth, strHeight = gfx.measurestr(lbl)
	gfx.x = adjustedX + ((adjustedW - strWidth) / 2)
	gfx.y = y + ((h - strHeight) / 2)
	gfx.drawstr(lbl)

end


function Tabs:drawTabLeft(x, i, y1, y2, h)
  gfx.triangle(x + i, y1, x + i, y2, x + i - (h / 2), y2)
end

function Tabs:drawTabRight(r, i, y1, y2, h)
  gfx.triangle(r + i, y1, r + i, y2, r + i + (h / 2), y2)
end

function Tabs:drawAliasingFix(x, r, i, y1, y2, h)
  gfx.line(x + i, y1, x + i - (h / 2), y2, 1)
  gfx.line(r + i, y1, r + i + (h / 2), y2, 1)
end




------------------------------------
-------- Tab helpers ---------------
------------------------------------


function Tabs:getOverallWidth()
  return (self.tabW + self.pad) * #self.tabs + 2*self.pad + 12
end


-- Updates visibility for any layers assigned to the tabs
function Tabs:updateSets()

	if not self.tabs or #self.tabs == 0 or #self.tabs[1].layers < 1 then return end

	for i = 1, #self.tabs do
    local show = (i == self.state)
    for _, layer in pairs(self.tabs[i].layers) do
      if show then
        layer:show()
      else
        layer:hide()
      end
    end
	end

end

return Tabs

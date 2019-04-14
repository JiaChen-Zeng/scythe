-- NoIndex: true

--[[	Lokasenna_GUI - Knob class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Knob

    Creation parameters:
	name, z, x, y, w, caption, min, max, default,[ inc, vals]

]]--

local Buffer = require("gui.buffer")

local Font = require("public.font")
local Color = require("public.color")
local Math = require("public.math")
local GFX = require("public.gfx")
local Text = require("public.text")
local Table = require("public.table")

local Knob = require("gui.element"):new()
Knob.__index = Knob

function Knob:new(props)

	local knob = Table.copy({
	  type = "Knob",
	  x = 0,
    y = 0,
    w = 64,
	  caption = "Knob",
	  bg = "wnd_bg",
    cap_x = 0,
    cap_y = 0,
	  font_a = 3,
	  font_b = 4,
	  col_txt = "txt",
	  col_head = "elm_fill",
    col_body = "elm_frame",

    min = 0,
    max = 10,
    inc = 1,

    default = 5
  }, props)

  knob.h = knob.w
  knob.steps = knob.steps or (math.abs(knob.max - knob.min) / knob.inc)
  knob.vals = knob.vals or (knob.vals == nil and true)

  -- Determine the step angle
  knob.stepangle = (3 / 2) / knob.steps

  knob.curstep = knob.default
	knob.curval = knob.curstep / knob.steps

  -- knob.prototype = Knob
	-- setmetatable(knob, self)
  -- self.__index = self
  self:assignChild(knob)

  knob.retval = knob:formatretval(
    ((knob.max - knob.min) / knob.steps) * knob.curstep + knob.min
  )

  return knob
end


function Knob:init()

	self.buff = self.buff or Buffer.get()

	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)

	-- Figure out the points of the triangle

	local r = self.w / 2
	local rp = r * 1.5
	local curangle = 0
	local o = rp + 1

	local w = 2 * rp + 2

	gfx.setimgdim(self.buff, 2*w, w)

	local side_angle = (math.acos(0.666667) / Math.pi) * 0.9

	local Ax, Ay = Math.polar2cart(curangle, rp, o, o)
    local Bx, By = Math.polar2cart(curangle + side_angle, r - 1, o, o)
	local Cx, Cy = Math.polar2cart(curangle - side_angle, r - 1, o, o)

	-- Head
	Color.set(self.col_head)
	GFX.triangle(true, Ax, Ay, Bx, By, Cx, Cy)
	Color.set("elm_outline")
	GFX.triangle(false, Ax, Ay, Bx, By, Cx, Cy)

	-- Body
	Color.set(self.col_body)
	gfx.circle(o, o, r, 1)
	Color.set("elm_outline")
	gfx.circle(o, o, r, 0)

	--gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs] )
	gfx.blit(self.buff, 1, 0, 0, 0, w, w, w + 1, 0)
	gfx.muladdrect(w + 1, 0, w, w, 0, 0, 0, Color.colors["shadow"][4])

end


function Knob:ondelete()

	Buffer.release(self.buff)

end


-- Knob - Draw
function Knob:draw()

	local x, y = self.x, self.y

	local r = self.w / 2
	local o = {x = x + r, y = y + r}


	-- Value labels
	if self.vals then self:drawvals(o, r) end

  if self.caption and self.caption ~= "" then self:drawcaption(o, r) end


	-- Figure out where the knob is pointing
	local curangle = (-5 / 4) + (self.curstep * self.stepangle)

	local blit_w = 3 * r + 2
	local blit_x = 1.5 * r

	-- Shadow
	for i = 1, Text.shadow_size do

		gfx.blit(   self.buff, 1, curangle * Math.pi,
                blit_w + 1, 0, blit_w, blit_w,
                o.x - blit_x + i - 1, o.y - blit_x + i - 1)

	end

	-- Body
	gfx.blit(   self.buff, 1, curangle * Math.pi,
              0, 0, blit_w, blit_w,
              o.x - blit_x - 1, o.y - blit_x - 1)

end


-- Knob - Get/set value
function Knob:val(newval)

	if newval then

    self:setcurstep(newval)

		self:redraw()

	else
		return self.retval
	end

end


-- Knob - Dragging.
function Knob:ondrag(state, last)

  -- Ctrl?
	local ctrl = state.mouse.cap&4==4

	-- Multiplier for how fast the knob turns. Higher = slower
	--					Ctrl	Normal
	local adj = ctrl and 1200 or 150

    self:setcurval(
      Math.clamp(self.curval + ((last.mouse.y - state.mouse.y) / adj),
      0,
      1
    ))

	self:redraw()
end


function Knob:ondoubleclick()

  self:setcurstep(self.default)

	self:redraw()

end


function Knob:onwheel(state)

	local ctrl = state.mouse.cap&4==4

	-- How many steps per wheel-step
	local fine = 1
	local coarse = math.max( Math.round(self.steps / 30), 1)

	local adj = ctrl and fine or coarse

  self:setcurval( Math.clamp( self.curval + (state.mouse.inc * adj / self.steps), 0, 1))

	self:redraw()

end



------------------------------------
-------- Drawing methods -----------
------------------------------------

function Knob:drawcaption(o, r)

  local str = self.caption

	Font.set(self.font_a)
	local cx, cy = Math.polar2cart(1/2, r * 2, o.x, o.y)
	local str_w, str_h = gfx.measurestr(str)
	gfx.x, gfx.y = cx - str_w / 2 + self.cap_x, cy - str_h / 2  + 8 + self.cap_y
	Text.text_bg(str, self.bg)
	Text.drawWithShadow(str, self.col_txt, "shadow")

end


function Knob:drawvals(o, r)

  for i = 0, self.steps do

    local angle = (-5 / 4 ) + (i * self.stepangle)

    -- Highlight the current value
    if i == self.curstep then
      Color.set(self.col_head)
      Font.set({Font.fonts[self.font_b][1], Font.fonts[self.font_b][2] * 1.2, "b"})
    else
      Color.set(self.col_txt)
      Font.set(self.font_b)
    end

    local output = self:formatOutput(
      self:formatretval( i * self.inc + self.min )
    )

    if output ~= "" then

      local str_w, str_h = gfx.measurestr(output)
      local cx, cy = Math.polar2cart(angle, r * 2, o.x, o.y)
      gfx.x, gfx.y = cx - str_w / 2, cy - str_h / 2
      Text.text_bg(output, self.bg)
      gfx.drawstr(output)
    end

  end

end




------------------------------------
-------- Value helpers -------------
------------------------------------

function Knob:setcurstep(step)

  self.curstep = step
  self.curval = self.curstep / self.steps
  self:setretval()

end


function Knob:setcurval(val)

  self.curval = val
  self.curstep = Math.round(val * self.steps)
  self:setretval()

end


function Knob:setretval()

  self.retval = self:formatretval(self.inc * self.curstep + self.min)

end


function Knob:formatretval(val)
  local decimal = tonumber(string.match(val, "%.(.*)") or 0)
  local places = decimal ~= 0 and string.len( decimal) or 0
  return string.format("%." .. places .. "f", val)
end

return Knob

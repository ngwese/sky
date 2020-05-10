--
-- NornsInput
--
local NornsInput = sky.InputBase:extend()
NornsInput.KEY_EVENT = 'KEY'
NornsInput.ENC_EVENT = 'ENC'
NornsInput.REDRAW_EVENT = 'REDRAW'

local SingletonInput = nil

local function do_key(...)
  if SingletonInput then SingletonInput:on_key_event(...) end
end

local function do_enc(...)
  if SingletonInput then SingletonInput:on_enc_event(...) end
end

local function do_redraw()
  if SingletonInput then SingletonInput:on_redraw() end
end

local function has_focus()
  -- test to see if our redraw method has been replaced, if so we've lost focus
  -- and the menu taken over redraw
  return redraw == do_redraw
end

function NornsInput:new(props)
  NornsInput.super.new(self, props)
  -- note this (re)defined script global handlers
  key = do_key
  enc = do_enc
  redraw = do_redraw

  self._redraw_event = self.mk_redraw()
end

function NornsInput.mk_key(num, z)
  return { type = NornsInput.KEY_EVENT, num = num, z = z }
end

function NornsInput.is_key(event)
  return event.type == NornsInput.KEY_EVENT
end

function NornsInput.mk_enc(num, delta)
  return { type = NornsInput.ENC_EVENT, num = num, delta = delta }
end

function NornsInput.is_enc(event)
  return event.type == NornsInput.ENC_EVENT
end

function NornsInput.mk_redraw()
  return { type = NornsInput.REDRAW_EVENT, beat = clock.get_beats() }
end

function NornsInput.is_redraw(event)
  return event.type == NornsInput.REDRAW_EVENT
end

function NornsInput:on_key_event(num, z)
  if self.chain then self.chain:process(self.mk_key(num, z)) end
end

function NornsInput:on_enc_event(num, delta)
  if self.chain then self.chain:process(self.mk_enc(num, delta)) end
end

function NornsInput:on_redraw()
  if self.chain then self.chain:process(self.mk_redraw()) end
end

local function shared_input(props)
  if SingletonInput == nil then
    SingletonInput = NornsInput(props)
  end
  return SingletonInput
end

--
-- NornsDisplay
--
local NornsDisplay = sky.Device:extend()

local SingletonDisplay = nil

function NornsDisplay:new(props)
  NornsDisplay.super.new(self, props)
end

function NornsDisplay:process(event, output, state)
  -- FIXME: this really demands double buffering the screen. If each redraw pass
  -- assumed that the screen is cleared first then we have to clear the screen
  -- before we know if any of the children will render into it. Ideally we'd
  -- allow children to render into an offscreen buffer then swap it at the end
  -- if it was dirtied.
  if has_focus() and sky.is_type(event, NornsInput.REDRAW_EVENT) then
    local props = {}
    for i, child in ipairs(self) do
      if type(child) == 'function' then
        child()
      else
        props.position = i
        child:render(event, props)
      end
    end
  else
    output(event)
  end
end

local function shared_display(props)
  if SingletonDisplay == nil then
    SingletonDisplay = NornsDisplay(props)
  end
  return SingletonDisplay
end


return {
  NornsInput = shared_input,
  NornsDisplay = shared_display,

  -- events
  mk_key = NornsInput.mk_key,
  mk_enc = NornsInput.mk_enc,
  mk_redraw = NornsInput.mk_redraw,

  is_key = NornsInput.is_key,
  is_enc = NornsInput.is_enc,
  is_redraw = NornsInput.is_redraw,

  KEY_EVENT = NornsInput.KEY_EVENT,
  ENC_EVENT = NornsInput.ENC_EVENT,
  REDRAW_EVENT = NornsInput.REDRAW_EVENT,
}





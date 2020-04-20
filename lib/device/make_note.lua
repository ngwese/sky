local MakeNote = {}
MakeNote.__index = MakeNote

function MakeNote.new(o)
  local o = setmetatable(o or {}, MakeNote)
  o._scheduler = nil
  return o
end

function MakeNote:device_inserted(chain)
  if self._scheduler ~= nil then
    error('MakeNote: one instance cannot be used in multiple chains at the same time')
  end
  self._scheduler = chain:scheduler(self)
end

function MakeNote:device_removed(chain)
  self._scheduler = nil
end

function MakeNote:process(event, output, state)
  -- just output it if we previously scheduled it
  if event.from == self then
    output(event)
    return
  end

  -- filter out any note offs if we are going to apply a duration
  if sky.is_type(event, sky.types.NOTE_OFF) and self.duration then
    return
  end

  -- set duration if need be and schedule
  if sky.is_type(event, sky.types.NOTE_ON) then
    -- stamp duration if there isn't one
    if event.duration == nil then
      event.duration = self.duration
    end

    output(event)

    if event.duration ~= nil then
      local note_off = sky.mk_note_off(event.note, 0, event.ch)
      note_off.from = self
      self._scheduler:sync(event.duration, note_off)
    end
    return
  end

  -- something else or a NOTE_OFF because we aren't setting duration
  output(event)
end

return {
  MakeNote = MakeNote.new,
}
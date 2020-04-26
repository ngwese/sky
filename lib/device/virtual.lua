local Observers = {}

local function _add(name, receiver)
  local existing = Observers[name]
  if existing == nil then
    existing = {}
    Observers[name] = existing
  end
  -- set like behavior
  local listening = false
  for _, r in ipairs(existing) do
    if r == receiver then
      listening = true
      break
    end
  end
  if not listening then
    table.insert(existing, receiver)
  end
end

local function _remove(name, receiver)
  local existing = Observers[name]
  if existing then
    table.remove(existing, receiver)
  end
end

--
-- Receive
--

local Receive = sky.Device()
Receive.__index = Receive

function Receive.new(sender_name)
  local o = setmetatable({}, Receive)
  o.from = sender_name
  _add(o.from, o)
  o._scheduler = nil
  return o
end

function Receive:device_inserted(chain)
  if self._scheduler ~= nil then
    error('Receive: one instance cannot be used in multiple chians at the same time')
  end
  self._scheduler = chain:scheduler(self)
end

function Receive:device_removed(chain)
  self._scheduler = nil
end

function Receive:inject(event)
  if not self.bypass and self._scheduler then
    --print('injecting;', self.from, self, sky.to_string(event), self._scheduler.device_index )
    self._scheduler:now(event)
  end
end

function Receive:process(event, output, state)
  output(event)
end

--
-- Send
--

local Send = sky.Device()
Send.__index = Send

function Send.new(name)
  local o = setmetatable({}, Send)
  o.to = name
  return o
end

function Send:process(event, output, state)
  output(event) -- pass events through to this chain
  local listeners = Observers[self.to]
  if listeners then
    for _, r in ipairs(listeners) do
      r:inject(event)
    end
  end
end

--
-- Forward
--

local Forward = sky.Device()
Forward.__index = Forward

function Forward.new(chain)
  local o = setmetatable({}, Forward)
  o.chain = chain
  return o
end

function Forward:process(event, output, state)
  output(event) -- pass events through to this chain
  if self.chain then
    self.chain:process(event)
  end
end

--
-- module
--

return {
  Receive = Receive.new,
  Send = Send.new,
  Forward = Forward.new,
}



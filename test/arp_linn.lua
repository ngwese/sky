include('sky/lib/prelude')
sky.use('sky/lib/device/arp')
sky.use('sky/lib/device/switcher')
sky.use('sky/lib/engine/polysub')
sky.use('sky/lib/io/norns')
sky.use('sky/lib/io/grid')
sky.use('sky/lib/device/ui')
sky.use('sky/lib/device/linn')

local halfsecond = include('awake/lib/halfsecond')

g = grid.connect()

logger = sky.Logger{
  filter = sky.is_clock,
  bypass = true
}

out1 = sky.Switcher{
  which = 1,
  sky.Output{ name = "UM-ONE" },
  sky.PolySub{},
}

arp1 = sky.Group{
  bypass = false,
  sky.Held{},      -- track held notes, emit on change
  sky.Pattern{},   -- generate pattern when held notes change
  sky.Arp{},       -- generate notes from pattern
}

chain = sky.Chain{
  sky.GridGestureRegion{
    sky.linnGesture{}
  },
  arp1,
  logger,
  sky.GridDisplay{
    grid = g,
    sky.linnRender{},
  },
  out1,
}

in1 = sky.Input{
  name = "AXIS-49",
  chain = chain,
}

in2 = sky.GridInput{
  grid = g,
  chain = chain,
}

clk = sky.Clock{
  interval = sky.bpm_to_sec(120, 4),
  chain = chain,
}

ui = sky.NornsInput{
  chain = sky.Chain{
    sky.Toggle{
      match = sky.matcher{ type = sky.KEY_EVENT, num = 3 },
      action = function(state) arp1.bypass = state end,
    },
    sky.Toggle{
      match = sky.matcher{ type = sky.KEY_EVENT, num = 2},
      action = function(state)
        if state then out1.which = 1 else out1.which = 2 end
      end,
    },
  }
}


function init()
  halfsecond.init()

  -- halfsecond
  params:set('delay', 0.13)
  params:set('delay_rate', 0.95)
  params:set('delay_feedback', 0.27)
  -- polysub
  params:set('amprel', 0.1)

  clk:start()
  chain:init()
end

function redraw()
  screen.clear()
  screen.update()
  chain:redraw()
end

function cleanup()
  chain:cleanup()
  clk:cleanup()
  in1:cleanup()
end

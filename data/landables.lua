return {
["Merle's Refuge"] =  {
  name = "Merle's Refuge",
  description = "This planet serves as a tranquil paradise for the rich noobinians. The absolute safety of the system and temperate climate of the planet created a truly hedonistic population. This level of welfare is only possible due to the very lucrative ore mining business.",
  x =  200,
  y =-1100,
  radius = 300,
  type = "planet",
  color = {25/255, 134/255, 201/255},
  buttons = {
    spaceport = { description = "The spaceport is filled to the brim with noobinians, it's always high season in Merle's Refuge." },
    bar       = { description = "A very high end bar." },
    bank      = { description = "This is a giant bank agency, it's while columns tower over you, and the weight of money materializes in a giant bull statue held high by a thick pillar."},
    trade     = {},
  },
  market = {
    capacity = 20000,
    demanded = {
        ["Silver Ore"]   = 2.0,
        ["Cocaine"]      = 3.0,
    },
    stock = {},
  },
},
["Mother's Heart"] =  {
  name = "Mother's Heart",
  description = "The home planet of the Noobi Empire, a very pretentious regime that took over the Noobinobi, the alien race they belong to. The Empire tried for many years to invade the free systems that lie beyond The Wall, but ended up bankrupt and deep in a food crisis that was only resolved once the Grand Noobi Navy (GNN) redirected troops to man the fertile fields of Mother's Heart.",
  x =  1200,
  y = -1800,
  radius = 300,
  type = "planet",
  color = {78/255, 183/255, 64/255},
  buttons = {
    spaceport = { description = "An amazing green field extends in every direction around the crowded spaceport From here you can take the electric bullet train straight to the planet's capital, Noobinori." },
    bar       = { description = "The smell of fresh mowed grass fills the air around the bar's open area. It's a nice place to read a book and sip on a drink." },
    bank      = { description = "A very small Galaxy Bank unit. There's one sad attendant behind a glass pane calling people's tickets."},
    trade     = {},
  },
  market = {
    capacity = 20000,
    demanded = {
    },
    stock = {},
  },
},
["Trading Station"] = {
  name = "Trading Station",
  description = "This is a trading station, many trading booths and lounges lay in waiting for great exchanges of goods, favours and power.",
  x = -900,
  y = -400,
  radius = 60,
  type = "station",
  color = {1/255, 125/255, 137/255},
  buttons = {
    spaceport = { description = "An amazing green field extends in every direction around the crowded spaceport From here you can take the electric bullet train straight to the planet's capital, Noobinori." },
    bar       = { description = "The smell of fresh mowed grass fills the air around the bar's open area. It's a nice place to read a book and sip on a drink." },
    bank      = { description = "A very small Galaxy Bank unit. There's one sad attendant behind a glass pane calling people's tickets."},
    trade     = {},
  },
  market = {
    capacity = 20000,
    demanded = {
    },
    stock = {},
  },
},
["Mining Depot"] =   {
  name        = "Mining Depot",
  description = "A big warehouse that starts the path of metal ores through the industrial pipeline. This facility buys and stores metal ore, in waiting for the freighters that deliver the material to the refineries.",
  x      = 1200,
  y      = 600,
  radius = 120,
  type   = "station",
  color  = {170/255, 154/255, 3/255},
  buttons = {
  trade = { description = "Station market. Metals are always in high demand here." },
  bar   = { description = "A crowded bar. Pilots share routes and rumors." },
  },
  market = {
  capacity = 20000,
  demanded = {
  ["Iron Ore"]     = 1.8,
  ["Silver Ore"]   = 2.0,
  ["Titanium Ore"] = 2.0,
  },
  stock = {
  { item = "Steel Sheets",   min = 100, max = 500 },
  { item = "Silver Ingot",   min = 200, max = 800 },
  { item = "Titanium Alloy", min = 0,   max = 50  },
  },
  },
},
["Metal Refinery"] = {
  name = "Metal Refinery",
  description = "A floating foundry that purifies the metal from ore. The station is almost completely autonomously operated, except for the small crew that manages a little trading hub anexed to the melting warehouse.",
  x = 500,
  y = -800,
  radius = 100,
  type = "station",
  color = {1/255, 125/255, 137/255},
  buttons = {
    spaceport = { description = "An amazing green field extends in every direction around the crowded spaceport From here you can take the electric bullet train straight to the planet's capital, Noobinori." },
    bar       = { description = "The smell of fresh mowed grass fills the air around the bar's open area. It's a nice place to read a book and sip on a drink." },
    bank      = { description = "A very small Galaxy Bank unit. There's one sad attendant behind a glass pane calling people's tickets."},
    trade     = {},
  },
  market = {
    capacity = 20000,
    demanded = {
    },
    stock = {},
  },
},
["Shipyard"] = {
  name = "Shipyard",
  description = "The Shipyard is a very pragmatic place. Giant elevators and conveyor belts allow the potential buyer to find the desired ship, by asking the little computer on one of the landing bays, and take it for a test flight.",
  x = -500,
  y = 900,
  radius = 80,
  type = "station",
  color = {1/255, 125/255, 137/255},
  buttons = {
    spaceport = { description = "An amazing green field extends in every direction around the crowded spaceport From here you can take the electric bullet train straight to the planet's capital, Noobinori." },
    bar       = { description = "The smell of fresh mowed grass fills the air around the bar's open area. It's a nice place to read a book and sip on a drink." },
    bank      = { description = "A very small Galaxy Bank unit. There's one sad attendant behind a glass pane calling people's tickets."},
    trade     = {},
  },
  market = {
    capacity = 20000,
    demanded = {
    },
    stock = {},
  },
},
["Golden Fortress"] = {
  name = "Golden Fortress",
  description = "The Golden Fortress is the first line of defence of the inner systems of the Noobi Empire. The fortress beats off marauder raids very frequently, but has never faced a organized massive attack.",
  x = -2000,
  y = 0,
  radius = 180,
  type = "station",
  color = {239/255, 221/255, 59/255},
  buttons = {
    spaceport = { description = "An amazing green field extends in every direction around the crowded spaceport From here you can take the electric bullet train straight to the planet's capital, Noobinori." },
    bar       = { description = "The smell of fresh mowed grass fills the air around the bar's open area. It's a nice place to read a book and sip on a drink." },
    bank      = { description = "A very small Galaxy Bank unit. There's one sad attendant behind a glass pane calling people's tickets."},
    trade     = {},
  },
  market = {
    capacity = 20000,
    demanded = {
    },
    stock = {},
  },
  },
}

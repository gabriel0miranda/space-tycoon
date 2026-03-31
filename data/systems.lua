local NORTH = {x=0,y=-6000}
local SOUTH = {x=0,y=6000}
local WEST = {x=-6000,y=0}
local EAST = {x=6000,y=0}

return {
  [1] = {
    name         = "Eagle's Nest",
    starX        = 0,
    starY        = 0,
    starMass     = 65000,
    starColor    = {1,1,1},
    asteroidCount= 30,
    asteroidOres = {
    {item="Iron Ore", min=5, max=10},
    {item="Silver Ore", min=2, max=6},
    },
    landables    = {
      "Trading Station",
      "Mining Depot",
      "Merle's Refuge",
    },
    wormholes    = {
      { name = "To Softsky", x=EAST.x, y=EAST.y, toSystem = 2},
    },
  },
  [2] = {
    name         = "Softsky",
    starX        = 0,
    starY        = 0,
    starMass     = 80000,
    starColor    = {1,1,1},
    asteroidCount= 50,
    asteroidOres = {
      {item="Sulfur", min=2, max=5},
    },
    landables    = {
      "Shipyard",
      "Mother's Heart",
      "Metal Refinery",
      "Trading Station",
    },
    wormholes    = {
      { name = "To Eagle's Nest", x=WEST.x, y=WEST.y, toSystem = 1},
      { name = "To The Wall", x=EAST.x, y=EAST.y, toSystem = 3},
    },
  },
  [3] = {
    name         = "The Wall",
    starX        = -3000,
    starY        = 0,
    starMass     = 30000,
    starColor    = {1,1,1},
    asteroidCount= 5,
    asteroidOres = {
      {item="Iron Ore", min=2, max=6},
    },
    landables    = {
      "Golden Fortress",
    },
    wormholes    = {
      { name = "To Softsky", x=WEST.x, y=WEST.y, toSystem = 2},
      { name = "To Bone Zone", x=EAST.x, y=EAST.y, toSystem = 4},
    },
  },
}

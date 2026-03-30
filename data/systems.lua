return {
    [1] = {
        name         = "Eagle's Nest",
        starX        = 0,
        starY        = 0,
        starMass     = 65000,
        asteroidCount= 30,
        asteroidOres = {
          {item="Iron Ore", min=5, max=10},
          {item="Silver Ore", min=2, max=6},
        },
        landables    = {
            { name = "Trading Station", x = -900, y = -400, radius = 60, type = "station" },
            { name = "Mining Depot",    x = 1200, y =  600, radius = 80, type = "station" },
            { name = "Merle's Refuge",  x =  200, y =-1100, radius = 300, type = "planet" },
        },
    },
    [2] = {
        name         = "Softsky",
        starX        = 0,
        starY        = 0,
        starMass     = 80000,
        asteroidCount= 50,
        asteroidOres = {
          {item="Sulfur", min=2, max=5},
        },
        landables    = {
            { name = "Outpost Kepler", x = 500, y = -800, radius = 50, type = "station" },
        },
    },
}

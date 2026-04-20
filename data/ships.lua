return {
  ["PP-2340"] = {
    name = "PP-2340",
    price = 1500,
    cargo       = 100,
    movement    = { linearAcceleration=800, strafeAcceleration=800, angularAcceleration=1200, linearDamping=0.8 },
    weapons = {"laser"},
    parts = {
      {
        points = {0, -25, 50, 0, 0, 25},
        color  = {255/255, 200/255, 48/255},
      },
    },
  },
  ["NN-Interceptor"] = {
    name        = "NN-Interceptor",
    price       = 15000,
    cargo       = 50,
    movement    = { linearAcceleration=1200, strafeAcceleration=800, angularAcceleration=1600, linearDamping=0.8 },
    weapons = {"laser"},
    -- Definição visual: lista de partes, cada uma com seus pontos e cor
    parts = {
      {
        points = { 0,-50, 12,-10, 20,0, 12,15, 0,25, -12,15, -20,0, -12,-10 },
        color  = { 0.7, 0.8, 0.9 },
      },
      {
        points = { 0,-30, 6,-10, 10,0, 6,10, 0,15, -6,10, -10,0, -6,-10 },
        color  = { 0.3, 0.5, 0.7, 0.8 },
      },
    },
  },

  ["NN-Gunship"] = {
    name    = "NN-Gunship",
    price   = 40000,
    cargo   = 120,
    movement = { linearAcceleration=800, strafeAcceleration=500, angularAcceleration=900, linearDamping=0.6 },
    weapons = {"laser"},
    parts = {
      {
        points = { 0,-60, 10,-20, 18,0, 10,30, 0,40, -10,30, -25,10, -25,-10, -10,-20 },
        color  = { 0.6, 0.65, 0.7 },
      },
      {
        points = { 18,0, 40,-8, 45,0, 40,8 },
        color  = { 0.8, 0.4, 0.2 },
      },
      {
        points = { -25,-10, -25,10, -45,5, -45,-5 },
        color  = { 0.8, 0.4, 0.2 },
      },
    },
  },

  ["NN-Dreadnought"] = {
    name    = "NN-Dreadnought",
    price   = 200000,
    cargo   = 2000,
    movement = { linearAcceleration=300, strafeAcceleration=200, angularAcceleration=300, linearDamping=0.3 },
    weapons = {"laser"},
    parts = {
      {
        points = { 0,-80, 20,-50, 30,-20, 30,30, 20,50, 0,60, -20,50, -30,30, -30,-20, -20,-50 },
        color  = { 0.5, 0.55, 0.6 },
      },
      {
        points = { 30,-20, 55,-30, 60,-10, 60,10, 55,20, 30,10 },
        color  = { 0.4, 0.45, 0.5 },
      },
      {
        points = { -30,-20, -55,-30, -60,-10, -60,10, -55,20, -30,10 },
        color  = { 0.4, 0.45, 0.5 },
      },
      {
        points = { 20,-50, 40,-60, 45,-45, 35,-30, 20,-30 },
        color  = { 0.35, 0.4, 0.45 },
      },
      {
        points = { -20,-50, -40,-60, -45,-45, -35,-30, -20,-30 },
        color  = { 0.35, 0.4, 0.45 },
      },
    },
  },
}

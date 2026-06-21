return {
  ["PP-2340"] = {
    name = "PP-2340",
    price = 1500,
    cargo       = 100,
    movement    = { linearAcceleration=800, strafeAcceleration=800, angularAcceleration=1200, linearDamping=0.8, angularDampingFactor=0.9 },
    weapons = {[1] = "Photon Cannon", [2] = "Vacuum Machinegun", [3] = "Predator Missile", [4] = "Proximity Mine", [5] = "EMP"},
    generatorPower = 30,
    shields     = {capacity=100,cooldown=3},
    hull        = 200,
    parts = {
      {
        points = {0, -25, 50, 0, 0, 25},
        color  = {0.1, 0.8, 0.4, 1},
      },
    },
  },
  ["GHM-1"] = {
    name = "GHM-1",
    price = 1800,
    cargo       = 600,
    movement    = { linearAcceleration=800, strafeAcceleration=800, angularAcceleration=1200, linearDamping=0.8, angularDampingFactor=0.9 },
    weapons = {[1] = "Predator Missile", [2] = "Proximity Mine", [3] = "EMP"},
    generatorPower = 45,
    shields     = {capacity=180,cooldown=3},
    hull        = 150,
    parts = {
      {
        points = {0, -25, 50, -25, 100, 0, 50, 25, 0, 25},
        color  = {0.2, 0.3, 0.9, 1},
      },
    },
  },
  ["O-lopa LTV-1"] = {
    name = "O-lopa LTV-1",
    price = 2600,
    cargo       = 300,
    movement    = { linearAcceleration=1200, strafeAcceleration=900, angularAcceleration=1600, linearDamping=0.8, angularDampingFactor=0.9 },
    weapons = {[1] = "Vacuum Machinegun", [2] = "Proximity Mine"},
    generatorPower = 45,
    shields     = {capacity=220,cooldown=3},
    hull        = 150,
    parts = {
      {
        points = {-5, -25, 80, 0, -5, 25},
        color  = {0.7, 0.7, 0.5, 1},
      },
    },
  },
  ["GMT-1"] = {
    name = "GMT-1",
    price = 1400,
    cargo       = 500,
    movement    = { linearAcceleration=800, strafeAcceleration=800, angularAcceleration=1200, linearDamping=0.8, angularDampingFactor=0.9 },
    weapons = {[1] = "Photon Cannon", [2] = "Predator Missile", [3] = "Proximity Mine"},
    generatorPower = 45,
    shields     = {capacity=180,cooldown=3},
    hull        = 250,
    parts = {
      {
        points = {0, -25, 50, -25, 100, 0, 50, 25, 0, 25},
        color  = {0.5, 0.1, 0.5, 1},
      },
    },
  },
  ["NN-Interceptor"] = {
    name        = "NN-Interceptor",
    price       = 15000,
    cargo       = 50,
    movement    = { linearAcceleration=1200, strafeAcceleration=800, angularAcceleration=1600, linearDamping=0.8, angularDampingFactor=0.8 },
    weapons = {[1] = "Photon Cannon", [2] = "Vacuum Machinegun", [3] = "Predator Missile", [4] = "Proximity Mine", [5] = "EMP"},
    generatorPower = 500,
    shields     = {capacity=250,cooldown=0.8},
    hull        = 350,
    parts = {
      {
        points = {50,0, 10,12, 0,20, -15,12, -25,0, -15,-12, 0,-20, 10,-12},
        color  = { 0.7, 0.8, 0.9 },
      },
      {
        points = {30,0, 10,6, 0,10, -10,6, -15,0, -10,-6, 0,-10, 10,-6},
        color  = { 0.3, 0.5, 0.7, 0.8 },
      },
    },
  },
  ["NN-Gunship"] = {
    name    = "NN-Gunship",
    price   = 40000,
    cargo   = 120,
    movement = { linearAcceleration=800, strafeAcceleration=500, angularAcceleration=1500, linearDamping=0.6, angularDampingFactor=0.8 },
    weapons = {[1] = "Photon Cannon", [2] = "Vacuum Machinegun", [3] = "Predator Missile", [4] = "Proximity Mine", [5] = "EMP"},
    generatorPower = 1000,
    shields     = {capacity=400,cooldown=0.6},
    hull        = 450,
    parts = {
      {
        -- corpo principal: simplificado de 9 para 8 vértices
        points = {60,0, 20,10, 0,18, -30,10, -40,0, -30,-10, 0,-18, 20,-10},
        color  = { 0.6, 0.65, 0.7 },
      },
      {
        -- asa direita
        points = {0,18, 8,40, 0,45, -8,40},
        color  = { 0.8, 0.4, 0.2 },
      },
      {
        -- asa esquerda
        points = {0,-18, 8,-40, 0,-45, -8,-40},
        color  = { 0.8, 0.4, 0.2 },
      },
    },
  },
  ["NN-Dreadnought"] = {
    name    = "NN-Dreadnought",
    price   = 200000,
    cargo   = 2000,
    movement = { linearAcceleration=300, strafeAcceleration=200, angularAcceleration=300, linearDamping=0.5, angularDampingFactor=0.6 },
    weapons = {[1] = "Photon Cannon", [2] = "Vacuum Machinegun", [3] = "Predator Missile", [4] = "Proximity Mine", [5] = "EMP"},
    generatorPower = 4000,
    shields     = {capacity=1500,cooldown=5},
    hull         = 720,
    parts = {
      {
        -- corpo principal: simplificado de 10 para 8 vértices
        points = {80,0, 50,20, 0,30, -50,20, -60,0, -50,-20, 0,-30, 50,-20},
        color  = { 0.5, 0.55, 0.6 },
      },
      {
        -- ala direita
        points = {20,30, 30,55, 10,60, -10,55, -20,30, -10,30},
        color  = { 0.4, 0.45, 0.5 },
      },
      {
        -- ala esquerda
        points = {20,-30, 30,-55, 10,-60, -10,-55, -20,-30, -10,-30},
        color  = { 0.4, 0.45, 0.5 },
      },
      {
        -- nacele direita
        points = {50,20, 60,40, 45,45, 30,35, 30,20},
        color  = { 0.35, 0.4, 0.45 },
      },
      {
        -- nacele esquerda
        points = {50,-20, 60,-40, 45,-45, 30,-35, 30,-20},
        color  = { 0.35, 0.4, 0.45 },
      },
    },
  },
  ["BAL Gunship"] = {
    name    = "BAL Gunship",
    price   = 40000,
    cargo   = 120,
    movement = { linearAcceleration=800, strafeAcceleration=500, angularAcceleration=1500, linearDamping=0.6, angularDampingFactor=0.8 },
    weapons = {[1] = "Photon Cannon", [2] = "Vacuum Machinegun", [3] = "Predator Missile", [4] = "Proximity Mine", [5] = "EMP"},
    generatorPower = 1000,
    shields     = {capacity=400,cooldown=0.6},
    hull        = 450,
    parts = {
      {
        -- corpo principal: simplificado de 9 para 8 vértices
        points = {60,0, 20,10, 0,18, -30,10, -40,0, -30,-10, 0,-18, 20,-10},
        color  = { 0.8, 0.5, 0.1, 1 },
      },
      {
        -- asa direita
        points = {0,18, 8,40, 0,45, -8,40},
        color  = { 0.9, 0.3, 0.2, 1 },
      },
      {
        -- asa esquerda
        points = {0,-18, 8,-40, 0,-45, -8,-40},
        color  = { 0.9, 0.3, 0.2, 1 },
      },
    },
  },
}

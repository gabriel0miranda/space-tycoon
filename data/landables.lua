return {
["Merle's Refuge"] =  {
  name = "Refúgio de Merle",
  description = "Esse planeta serve como um paraíso tranquilo aos noobinianos ricos, aposentados e desocuptados. A segurança absoluta do sistema e o clima temperado do planeta criaram uma população verdadeiramente hedonista. Esse nível de bem estar só é possível por conta do mercado extremamente lucrativo de mineração.",
  x =  200,
  y =-1100,
  radius = 300,
  type = "planet",
  color = {25/255, 134/255, 201/255},
  buttons = {
    spaceport = { description = "O porto espacial é cheio até a boca de noobinianos, é sempre alta temporada no Refúgio de Merle."},
    bar       = { description = "Um bar bem chique e noir. A nobreza noobinobi aprecisa momentos de descontração calmos e elegantes." },
    bank      = { description = "Essa é uma agência bancária gigantesca, suas colunas brancas se impõem sobre você, e o peso do dinheiro é materializado na forma de uma estátua enorme de touro suspendida num pedestal grosso."},
    trade     = {},
    shipyard  = {},
  },
  shipyard = {
    stock = {
    "PP-2340","NN-Interceptor","NN-Gunship","NN-Dreadnought"
    },
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
  name = "Coração de Mãe",
  description = "O planeta principal do Empério Noobi, um regime pretencioso que consolidou o povo Noobinobi. O Emperio tentou, por vários anos, invadir um sistemas livres que se estendem além da Parede, mas acabou falido e numa onda de fome que só se resolveu quando a Grande Frota Noobi (GNN) redirecionou suas tropas para tender os campos do Coração de Mãe",
  x =  1200,
  y = -1800,
  radius = 300,
  type = "planet",
  color = {78/255, 183/255, 64/255},
  buttons = {
    spaceport = { description = "Um enorme campo verde se extente em todas as direções em volta do porto espacial. Daqui você pode pegar um trem bala direto para a capital do Coração de Mãe." },
    bar       = { description = "O cheiro de grama fresca e o vento do campo é extremamente agradável quando se tenta aproveitar uma boa bebida. Homens e mulheres de todas as castas se reunem nos bares do Coração de Mãe." },
    bank      = { description = "Esta agência do Banco Galático é arejada e espaçosa, alguns clientes trazem seus animais para negociar empréstimos rurais."},
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
  name = "Estação de Troca",
  description = "Essa é uma estação de troca, muitas câmaras de troca e louges esperam por grandes câmbios de bens, favores e poder.",
  x = -900,
  y = -400,
  radius = 60,
  type = "station",
  color = {1/255, 125/255, 137/255},
  buttons = {
    spaceport = { description = "A doca da estação é minúscula, a maioria dos visitantes nem mesmo para para fazer negócios." },
    bar       = { description = "Um bar escuro e neblinoso, apenas os negócios mais obscuros se realizam nas cabines privadas." },
    bank      = { description = "Uma pequena agência do Banco Galático. A atendente entediada do outro lado do vidro chama os clientes por senha."},
    trade     = { description = "O som de comércio, dinheiro e telefones tocando monta uma sinfonia aterrorizante, você se recolhe e senta em um dos terminais de troca, o uso dos headphones abafadores dos terminais é uma necessidade aqui."},
  },
  market = {
    capacity = 20000,
    demanded = {
    },
    stock = {},
  },
},
["Mining Depot"] =   {
  name        = "Depósito de Mineração",
  description = "Um enorme armazem de minérios que inicia o caminho do metal pela indústria galática. Aguardando silenciosamente pelos cargueiros que vendem e compram minérios.",
  x      = 1200,
  y      = 600,
  radius = 120,
  type   = "station",
  color  = {170/255, 154/255, 3/255},
  buttons = {
  trade = { description = "Uma doca de compra e venda. Minérios estão sempre em alta demanda aqui." },
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
  name = "Refinaria de Metal",
  description = "Uma fundição flutuante que opera quase que autonomamente. Apenas alguns funcionários residem na estação e gerenciam um pequeno armazem de trocas anexado à estação.",
  x = 500,
  y = -800,
  radius = 100,
  type = "station",
  color = {1/255, 125/255, 137/255},
  buttons = {
    spaceport = { description = "A doca é simples e eficiente." },
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
  name = "Estaleiro",
  description = "O Estaleiro é um lugar bastante pragmático. Elevadores gigantes rotacionam as naves em cada doca, trazendo aquelas escolhidas pelos compradores em um computador falante.",
  x = -500,
  y = 900,
  radius = 80,
  type = "station",
  color = {1/255, 125/255, 137/255},
  buttons = {
    bar       = { description = "Um pequeno café serve drinks diversos e comida de dedo para os clientes que aguardam reparos e despachos de documentos." },
    bank      = { description = "Um mínusculo caixa eletrônico do Banco Galático."},
    shipyard  = {},
  },
  shipyard = {
    stock = {
    "PP-2340","NN-Interceptor","NN-Gunship","NN-Dreadnought"
    },
  },
},
["Golden Fortress"] = {
  name = "Fortaleza Dourada",
  description = "A Fortaleza Dourada é um massivo planeta artifical que serve como último bastião de defesa do Empério Noobi. A fortaleza repele piratas o tempo todo com facilidade, mas nunca enfrentou um ataque massivo coordenado.",
  x = -2000,
  y = 0,
  radius = 180,
  type = "station",
  color = {239/255, 221/255, 59/255},
  buttons = {
    spaceport = { description = "O Porto Espacial da Fortaleza Dourada é militarizado por natureza, milhares de soldados noobinobi se locomovem com velocidade e precisão por entre as naves." },
    bank      = { description = "Uma agência comum do Banco Galático. O banheiro está em reformas."},
  },
  },
}

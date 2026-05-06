return {
["Young Noobinobi"] =  {
  name = "Jovem Noobinobi",
  description = "Você cresceu em Coração de Mãe, mas acabou preso com sua mãe e seu padrasto na gigantesca colônia de férias que é o Refúgio de Merle. O Império Noobi encolheu, e a liberdade lhe pareceu mais próxima em um belo dia de primavera.\nCom a PP-2340 que sua mãe recebeu de herança (mas nunca pilotou) você parte em direção ao desconhecido. Escape do espaço Noobinobi, venda qualquer mercadoria que puder encontrar e assuma as rédeas do seu destino.",
  starting_system = "Eagle's Nest",
  starting_systemId = 1,
  starting_place = "Merle's Refuge",
-- Se não tiver starting place
-- x = 400,
-- y = 300, 
  dificulty = "standard",
  starting_property = {
    {
      ship = true,
      flagShip = true,
      name = "Noite Branca",
      type = "PP-2340",
      cargo = {
        {name = "Cocaine", quantity = 12},
        {name = "Steel Sheets", quantity = 2},
      },
    },
  },
  starting_credits = 500000,
  landedAt = false,
},
}

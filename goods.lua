
-- int[3][25]
local addr_StartGoods = core.AOBScan("00 00 00 00 00 00 00 00 64 00 00 00 00 00 00 00 32 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3C 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 64 00 00 00 00 00 00 00 32 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3C 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 96 00 00 00 14 00 00 00 96 00 00 00 00 00 00 00 19 00 00 00 30 00 00 00 00 00 00 00 19 00 00 00 C8 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 0A 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
local StartGoods_size = 4 * 3 * 25

local GAME_MODE_INDEX = {
  normal      = 0,
  crusader    = 1,
  deathmatch  = 2,
}

local StartingResource = {
  wood = 2,
  hop = 3,
  stone = 4,
  
  iron = 6,
  pitch = 7,

  wheat = 9,
  bread = 10,
  cheese = 11,
  meat = 12,
  fruit = 13,
  beer = 14,
  -- gold = 15,
  flour = 16,
  bows = 17,
  crossbows = 18,
  spears = 19,
  pikes = 20,
  maces = 21,
  swords = 22,
  leatherarmor = 23,
  metalarmor = 24,
}

local function translateResourceKey(k) 
  if type(k) == "string" then
    local tk = StartingResource[k]
    if tk == nil then
      error("Unknown key: " .. tostring(k))
    end

    return tk
  end

  if type(k) == "number" then return k end

  error("Invalid key: " .. tostring(k))
end

local IntegerArrayMarshal = {
  new = function(offset, translateKey)

    return setmetatable(
      {},
      {
        __index = function(self, k)
          local addr = offset + (translateKey(k)*4)
          log(2, "[startGoods] Reading: " .. tostring(addr))
          return core.readInteger(string.format("0x%X", addr))
        end,
        __newindex = function(self, k, v)
          local addr = offset + (translateKey(k)*4)
          v = tonumber(v)
          if v == nil then return end
          log(2, "[startGoods] Writing: " .. tostring(string.format("0x%X", addr)) .. " value: " .. tostring(v))
          core.writeInteger(addr, v)
        end
      }
    )
  end
}

local StartGoodsMarshal = {}
for k, v in pairs(GAME_MODE_INDEX) do
  StartGoodsMarshal[k] = IntegerArrayMarshal.new(addr_StartGoods + (4*25*v), translateResourceKey)
end

local vanillaStartGoods = core.readBytes(addr_StartGoods, StartGoods_size)

--[[



--]]

local balance = {
  majorHumanAdvantage = 0,
  minorHumanAdvantage = 1,
  noAdvantage = 2,
  minorComputerAdvantage = 3,
  majorComputerAdvantage = 4,
}

local playerTypes =  {
  human = 0,
  computer = 1,
}

-- int[3][5][2]
local addr_StartGold = core.AOBScan("40 1F 00 00 D0 07 00 00 A0 0F 00 00 D0 07 00 00 D0 07 00 00 D0 07 00 00 D0 07 00 00 A0 0F 00 00 D0 07 00 00 40 1F 00 00 40 1F 00 00 D0 07 00 00 A0 0F 00 00 D0 07 00 00 D0 07 00 00 D0 07 00 00 D0 07 00 00 A0 0F 00 00 D0 07 00 00 40 1F 00 00 40 9C 00 00 B8 0B 00 00 20 4E 00 00 58 1B 00 00 10 27 00 00 10 27 00 00 58 1B 00 00 20 4E 00 00 B8 0B 00 00 40 9C 00 00")
local StartGoldMarshal = {}

for gamemode, gamemodeindex in pairs(GAME_MODE_INDEX) do
  StartGoldMarshal[gamemode] = {}
  local gamemodeOffset = 4 * gamemodeindex * 5 * 2
  for balancelevel, balancelevelindex in pairs(balance) do
    StartGoldMarshal[gamemode][balancelevel] = {}
    local balanceOffset = 4 * balancelevelindex * 2
    local offset = addr_StartGold + gamemodeOffset + balanceOffset
    StartGoldMarshal[gamemode][balancelevel] = IntegerArrayMarshal.new(offset, function(k) 

      k = playerTypes[k]
      if k == nil then
        log(WARNING, "[startGoods] Invalid player type key: " .. tostring(k))
      end

      return k
    end)
  end
  
end

return {
  setStartGoods = function(startGoods)
    for gamemode, goods in pairs(startGoods) do
      if StartGoodsMarshal[gamemode] ~= nil then
        for goodname, count in pairs(goods) do
          if StartingResource[goodname] ~= nil then
              if tonumber(count) ~= nil then
                log(2, "[startGoods] Setting: " .. tostring(gamemode) .. " "  .. tostring(goodname) .. " value: " .. tostring(count))
                StartGoodsMarshal[gamemode][goodname] = count
              else
                log(WARNING, string.format("%s is not a valid good count: %s.%s", count, gamemode, goodname))
              end
          else
            log(WARNING, string.format("%s is not a valid goodname: %s.%s", goodname, gamemode, goodname))
          end
          
        end
      else
        log(WARNING, string.format("%s is not a valid gamemode", gamemode))
      end
    end  
  end,
  
  setStartGold = function(startGold)
    for gamemode, fairnesses in pairs(startGold) do
      if GAME_MODE_INDEX[gamemode] ~= nil then


        for fairness, playertypes in pairs(fairnesses) do

          if balance[fairness] ~= nil then

            for playertype, count in pairs(playertypes) do
              if playerTypes[playertype] ~= nil then
                if tonumber(count) ~= nil then
                  log(2, "[startGoods] Setting gold: " .. tostring(gamemode) .. " " .. tostring(fairness) .. " " .. tostring(playertype) .. " value: " .. tostring(count))
                  StartGoldMarshal[gamemode][fairness][playertype] = count
                else
                  log(WARNING, string.format("%s is not a valid gold count", count))
                end
              else
                log(WARNING, string.format("%s is not a valid player type", playertype))
              end
            end
          else
            log(WARNING, string.format("%s is not a valid fairness level", fairness))
          end

        end

      else
        log(WARNING, string.format("%s is not a valid gamemode", gamemode))
      end
    end
  end,
  
  resetStartGoods = function() core.writeBytes(addr_StartGoods, vanillaStartGoods) end,
  
  
  getStartGood = function(gamemode, goodname)
    return StartGoodsMarshal[gamemode][goodname]
  end,

  setStartGood = function(gamemode, goodname, goodcount)
    StartGoodsMarshal[gamemode][goodname] = goodcount
  end,
}
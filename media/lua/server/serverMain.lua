if not(isServer()) then return end

local json = require('json')
local print = print
local getModFileReader = getModFileReader
local getModFileWriter = getModFileWriter
local createHordeInAreaTo = createHordeInAreaTo
local getOnlinePlayers = getOnlinePlayers
local table = table
local isGamePaused = isGamePaused
local getAllRecipes = getAllRecipes
local getHourMinute = getHourMinute
local getServerOptions = getServerOptions
local Perks = PerkFactory.PerkList
local sendServerCommand = sendServerCommand
local BodyPartType = BodyPartType
local getClimateManager = getClimateManager
local WeatherPeriod = WeatherPeriod
local ClimateManager = ClimateManager
-- x, y, z, #, outfit, %female, fallOnFront, fakeDead, knockedDown, health
local addZombiesInOutfit = addZombiesInOutfit
local SafeHouse = SafeHouse
local getSquare = getSquare
local getAllOutfits = getAllOutfits
local ipairs = ipairs
local pairs = pairs
local ZombRand = ZombRand

local WalkTypes = {
	"1",
	"2",
	"3",
	"4",
	"5",
	"sprint1",
	"sprint2",
	"sprint3",
	"sprint4",
	"sprint5",
	"slow1",
	"slow2",
	"slow3",
	NUM = 13
}

local playerInventoryCache = {}

local writePipe = function(type, data)
	local writer = getModFileWriter('BrainSlug', 'outpipe', false, false)

	writer:write(json:encode({
		type = type,
		data = data
	}))

	writer:close()
end

local getClimateInfo = function()
	local globalLightColorInfo = getClimateManager():getClimateColor(ClimateManager.COLOR_GLOBAL_LIGHT):getInternalValue()
	local globalLightInterior = globalLightColorInfo:getInterior()
	local globalLightExterior = globalLightColorInfo:getExterior()

	local newFogColorInfo = getClimateManager():getClimateColor(ClimateManager.COLOR_NEW_FOG):getInternalValue()
	local newFogColorInterior = newFogColorInfo:getInterior()
	local newFogColorExterior = newFogColorInfo:getExterior()

	return {
		desaturation = getClimateManager():getClimateFloat(ClimateManager.FLOAT_DESATURATION):getInternalValue(),
		globalLightIntensity = getClimateManager():getClimateFloat(ClimateManager.FLOAT_GLOBAL_LIGHT_INTENSITY):getInternalValue(),
		nightStrength = getClimateManager():getClimateFloat(ClimateManager.FLOAT_NIGHT_STRENGTH):getInternalValue(),
		precipitationIntensity = getClimateManager():getClimateFloat(ClimateManager.FLOAT_PRECIPITATION_INTENSITY):getInternalValue(),
		temperature = getClimateManager():getClimateFloat(ClimateManager.FLOAT_TEMPERATURE):getInternalValue(),
		fogIntensity = getClimateManager():getClimateFloat(ClimateManager.FLOAT_FOG_INTENSITY):getInternalValue(),
		windIntensity = getClimateManager():getClimateFloat(ClimateManager.FLOAT_WIND_INTENSITY):getInternalValue(),
		windAngleIntensity = getClimateManager():getClimateFloat(ClimateManager.FLOAT_WIND_ANGLE_INTENSITY):getInternalValue(),
		cloudIntensity = getClimateManager():getClimateFloat(ClimateManager.FLOAT_CLOUD_INTENSITY):getInternalValue(),
		ambient = getClimateManager():getClimateFloat(ClimateManager.FLOAT_AMBIENT):getInternalValue(),
		viewDistance = getClimateManager():getClimateFloat(ClimateManager.FLOAT_VIEW_DISTANCE):getInternalValue(),
		daylightStrength = getClimateManager():getClimateFloat(ClimateManager.FLOAT_DAYLIGHT_STRENGTH):getInternalValue(),
		humidity = getClimateManager():getClimateFloat(ClimateManager.FLOAT_HUMIDITY):getInternalValue(),
		snow = getClimateManager():getClimateBool(ClimateManager.BOOL_IS_SNOW):getInternalValue(),
		globalLightColor = {
			interior = {
				a = globalLightInterior:getAlpha(),
				r = globalLightInterior:getRed(),
				g = globalLightInterior:getGreen(),
				b = globalLightInterior:getBlue()

			},
			exterior = {
				a = globalLightExterior:getAlpha(),
				r = globalLightExterior:getRed(),
				g = globalLightExterior:getGreen(),
				b = globalLightExterior:getBlue()

			}
		},
		newFogColor = {
			interior = {
				a = newFogColorInterior:getAlpha(),
				r = newFogColorInterior:getRed(),
				g = newFogColorInterior:getGreen(),
				b = newFogColorInterior:getBlue()
			},
			exterior = {
				a = newFogColorExterior:getAlpha(),
				r = newFogColorExterior:getRed(),
				g = newFogColorExterior:getGreen(),
				b = newFogColorExterior:getBlue()
			}
		}
	}
end

local getMoodles = function(isoPlayer)
	local moodles = isoPlayer:getMoodles()
	local returnMoodles = {}

	for i = 0, moodles:getNumMoodles() - 1 do
		local moodleLevel = moodles:getMoodleLevel(i)
		if moodleLevel > 0 then
			table.insert(returnMoodles, {
				name = moodles:getMoodleDisplayString(i),
				level = moodleLevel
			})
		end
	end

	return returnMoodles
end

local getPerks = function(isoPlayer)
	local perks = {}

	for i = 0, Perks:size() - 1 do
		local gamePerk = Perks:get(i)
		local perkInfo = isoPlayer:getPerkInfo(gamePerk)
		if perkInfo then
			table.insert(perks, {
				name = gamePerk:getName(),
				level = perkInfo:getLevel()
			})
		end
	end

	return perks
end

local getNutrition = function(isoPlayer)
	local nutrition = isoPlayer:getNutrition()

	return {
		calories = nutrition:getCalories(),
		carbohydrates = nutrition:getCarbohydrates(),
		lipids = nutrition:getLipids(),
		proteins = nutrition:getProteins(),
		weight = nutrition:getWeight()
	}
end

local getStats = function(isoPlayer)
	local stats = isoPlayer:getStats()

	return {
		numVeryCloseZombies = stats:getNumVeryCloseZombies(),
		thirst = stats:getThirst(),
		endurance = stats:getEndurance(),
		hunger = stats:getHunger(),
		sanity = stats:getSanity(),
		enduranceRecharging = stats:getEnduranceRecharging(),
		tripping = stats:isTripping(),
		sickness = stats:getSickness(),
		fear = stats:getFear(),
		trippingRotAngle = stats:getTrippingRotAngle(),
		enduranceDanger = stats:getEndurancedanger(),
		stressFromCigarettes = stats:getStressFromCigarettes(),
		fitness = stats:getFitness(),
		numVisibleZombies = stats:getNumVisibleZombies(),
		idleBoredom = stats:getIdleboredom(),
		fatigue = stats:getFatigue(),
		numChasingZombies = stats:getNumChasingZombies(),
		stress = stats:getStress(),
		enduranceLast = stats:getEndurancelast(),
		visibleZombies = stats:getVisibleZombies(),
		anger = stats:getAnger(),
		boredom = stats:getBoredom(),
		maxStressFromCigarettes = stats:getMaxStressFromCigarettes(),
		drunkenness= stats:getDrunkenness(),
		enduranceWarn = stats:getEndurancewarn(),
		pain = stats:getPain()
	}
end

local deflateInventory = function(inventory)
	local deflatedInventory = {}
	local finalInventory = {}

	if inventory == nil then
		return nil
	end

	for _, cachedPlayerInventoryItem in ipairs(inventory) do
		if deflatedInventory[cachedPlayerInventoryItem.name] == nil then
			deflatedInventory[cachedPlayerInventoryItem.name] = {
				name = cachedPlayerInventoryItem.name,
				type = cachedPlayerInventoryItem.type,
				num = 1
			}
		else
			local num = deflatedInventory[cachedPlayerInventoryItem.name].num
			deflatedInventory[cachedPlayerInventoryItem.name] = {
				name = cachedPlayerInventoryItem.name,
				type = cachedPlayerInventoryItem.type,
				num = num + 1
			}
		end
	end

	for _, deflatedInventoryItem in pairs(deflatedInventory) do
		table.insert(finalInventory, deflatedInventoryItem)
	end

	return finalInventory
end

local getInventory = function(isoPlayer)
	local cachedPlayerInventory = playerInventoryCache[isoPlayer:getUsername()]
	return deflateInventory(cachedPlayerInventory)
end

local getBodyParts = function(isoPlayer)
	local playerBodyDamage = isoPlayer:getBodyDamage()
	local bodyParts = playerBodyDamage:getBodyParts()

	local playerBody = {
		parts = {},
		infectionLevel = playerBodyDamage:getInfectionLevel(),
		isSneezingCoughing = playerBodyDamage:IsSneezingCoughing(),
		isInfected = playerBodyDamage:isInfected(),
		isOnFire = playerBodyDamage:IsOnFire()
	}

	for i = 0, BodyPartType.ToIndex(BodyPartType.MAX) - 1 do
		local bodyPart = bodyParts:get(i)
		local bodyPartType = bodyPart:getType()

		table.insert(playerBody.parts, {
			name = BodyPartType.getDisplayName(bodyPartType),
			health = bodyPart:getHealth(),
			scratched = bodyPart:scratched(),
			deepWounded = bodyPart:deepWounded(),
			bitten = bodyPart:bitten(),
			stitched = bodyPart:stitched(),
			bleeding = bodyPart:bleeding(),
			isBurnt = bodyPart:isBurnt(),
			bandaged = bodyPart:bandaged(),
			isCut = bodyPart:isCut()
		})
	end

	return playerBody
end

local getTraits = function(isoPlayer)
	local playerTraits = isoPlayer:getTraits()
	local traits = {}

	for i = 0, playerTraits:size() - 1 do
		table.insert(traits, playerTraits:get(i))
	end

	return traits
end

local getPlayerInfo = function(isoPlayer)
	return {
		username = isoPlayer:getUsername(),
		onlineId = isoPlayer:getOnlineID(),
		steamId = isoPlayer:getSteamID(),
		accessLevel = isoPlayer:getAccessLevel(),
		zombieKills = isoPlayer:getZombieKills(),
		foreName = isoPlayer:getDescriptor():getForename(),
		surName = isoPlayer:getDescriptor():getSurname(),
		displayName = isoPlayer:getDisplayName(),
		x = isoPlayer:getX(),
		y = isoPlayer:getY(),
		z = isoPlayer:getZ(),
		hoursSurvived = isoPlayer:getHoursSurvived(),
		attackType = isoPlayer:getAttackType(),
		moodles = getMoodles(isoPlayer),
		perks = getPerks(isoPlayer),
		traits = getTraits(isoPlayer),
		stats = getStats(isoPlayer),
		nutrition = getNutrition(isoPlayer),
		inventory = getInventory(isoPlayer),
		playerBody = getBodyParts(isoPlayer)
	}
end

local getSafeHouseInfo = function()
	local safeHouses = {}

	for i = 0, SafeHouse.getSafehouseList():size() - 1 do
		local safeHouse = SafeHouse.getSafehouseList():get(i)
		local allItems = {}

		local posX = safeHouse:getX()
		local posY = safeHouse:getY()
		local h = safeHouse:getH()
		local w = safeHouse:getW()

		local safeHouseInfo = {
			id = safeHouse:getId(),
			title = safeHouse:getTitle(),
			owner = safeHouse:getOwner(),
			players = {},
			items = {},
			x = posX,
			y = posY,
			h = h,
			w = w
		}

		for j = 0, safeHouse:getPlayers():size() - 1 do
			table.insert(safeHouseInfo.players, safeHouse:getPlayers():get(j))
		end

		for x = posX, w + posX - 1 do
			for y = posY, h + posY - 1 do
				for z = 0, 2 do
					local safeHouseSquare = getSquare(x, y, z)
					if safeHouseSquare then
						local worldObjects = safeHouseSquare:getWorldObjects()
						for k = 0, worldObjects:size() - 1 do
							table.insert(allItems, {
								name = worldObjects:get(k):getItem():getDisplayName(),
								type = worldObjects:get(k):getItem():getType()
							})
						end
					end
				end
			end
		end

		safeHouseInfo.items = deflateInventory(allItems)

		table.insert(safeHouses, safeHouseInfo)
	end

	return safeHouses
end

local getServerOptionsInfo = function()
	local options = {}
	local serverOptions = getServerOptions():getOptions()

	for i = 0, serverOptions:size() - 1 do
		local serverOption = serverOptions:get(i)
		table.insert(options, {
			name = serverOption:getName(),
			value = serverOption:getValue(),
			defaultValue = serverOption:getDefaultValue()
		})
	end

	return options
end

local getPlayersInfo = function()
	local players = {}
	local onlinePlayers = getOnlinePlayers()

	if onlinePlayers then
		for i = 0, onlinePlayers:size() -1 do
			local onlinePlayer = onlinePlayers:get(i)
			table.insert(players, getPlayerInfo(onlinePlayer))
		end
	end

	return players
end

local clearClimateFloats = function()
	getClimateManager():getClimateFloat(ClimateManager.FLOAT_DESATURATION):setEnableAdmin(false)
	getClimateManager():getClimateFloat(ClimateManager.FLOAT_GLOBAL_LIGHT_INTENSITY):setEnableAdmin(false)
	getClimateManager():getClimateFloat(ClimateManager.FLOAT_NIGHT_STRENGTH):setEnableAdmin(false)
	getClimateManager():getClimateFloat(ClimateManager.FLOAT_PRECIPITATION_INTENSITY):setEnableAdmin(false)
	getClimateManager():getClimateFloat(ClimateManager.FLOAT_TEMPERATURE):setEnableAdmin(false)
	getClimateManager():getClimateFloat(ClimateManager.FLOAT_FOG_INTENSITY):setEnableAdmin(false)
	getClimateManager():getClimateFloat(ClimateManager.FLOAT_WIND_INTENSITY):setEnableAdmin(false)
	getClimateManager():getClimateFloat(ClimateManager.FLOAT_WIND_ANGLE_INTENSITY):setEnableAdmin(false)
	getClimateManager():getClimateFloat(ClimateManager.FLOAT_CLOUD_INTENSITY):setEnableAdmin(false)
	getClimateManager():getClimateFloat(ClimateManager.FLOAT_AMBIENT):setEnableAdmin(false)
	getClimateManager():getClimateFloat(ClimateManager.FLOAT_VIEW_DISTANCE):setEnableAdmin(false)
	getClimateManager():getClimateFloat(ClimateManager.FLOAT_DAYLIGHT_STRENGTH):setEnableAdmin(false)
	getClimateManager():getClimateFloat(ClimateManager.FLOAT_HUMIDITY):setEnableAdmin(false)
	getClimateManager():getClimateBool(ClimateManager.BOOL_IS_SNOW):setEnableAdmin(false)
	getClimateManager():getClimateColor(ClimateManager.COLOR_GLOBAL_LIGHT):setEnableAdmin(false)
	getClimateManager():getClimateColor(ClimateManager.COLOR_NEW_FOG):setEnableAdmin(false)
end

local getRecipesInfo = function()
	local recipes = {}
	local allRecipes = getAllRecipes()

	for i = 0, allRecipes:size() - 1 do
		local recipe = allRecipes:get(i)
		table.insert(recipes, recipe:getName())
	end

	return recipes
end

local getOutfitInfo = function(female)
	local allOutfits = getAllOutfits(female)
	local outfits = {}

	for i = 0, allOutfits:size() -1 do
		table.insert(outfits, allOutfits:get(i))
	end

	return outfits
end

local staticInfo = {
	server = {
		options = getServerOptionsInfo()
	},
	recipes = getRecipesInfo(),
	femaleOutfits = getOutfitInfo(true),
	maleOutfits = getOutfitInfo(false)
	getItemNameFromFullType()
}

local sendInfo = function()
	local info = {
		players = getPlayersInfo(),
		safeHouses = getSafeHouseInfo(),
		game = {
			paused = isGamePaused(),
			hourMinute = getHourMinute(),
			climate = getClimateInfo()
		}
	}
	writePipe('info', info)
end

local sendPong = function()
	writePipe('pong', {
		server = staticInfo.server,
		game = {
			recipes = staticInfo.recipes,
			femaleOutfits = staticInfo.femaleOutfits,
			maleOutfits = staticInfo.maleOutfits
		}
	})
end

local execCommand = function(command, payload)
	payload = payload or {}

	if command ~= 'info' then
		print('command received: ' .. command)
	else
		sendInfo()
	end

	if command == 'ping' then
		print('BrainSlug CnC Server connected')
		sendPong()
	end

	if command == 'comegetsome' then
		sendServerCommand('BrainSlug', command, payload)
	end

	if command == 'message' then
		sendServerCommand('BrainSlug', command, payload)
	end

	if command == 'slap' then
		sendServerCommand('BrainSlug', command, payload)
	end

	if command == 'gift' then
		sendServerCommand('BrainSlug', command, payload)
	end

	if command == 'horde' then
		local players = getOnlinePlayers()
		for i = 0, players:size() -1 do
			local player = players:get(i)
			if player ~= nil and (payload.username == nil or player:getUsername() == payload.username) then
				local x = player:getX()
				local y = player:getY()
				createHordeInAreaTo(x, y, 100, 100, x, y, 100)
				print('Spawning horde for', player:getUsername(), x, y)
			end
		end
	end

	if command == 'zombieJumpScare' then
		local onlinePlayers = getOnlinePlayers()
		for i = 0, onlinePlayers:size() -1 do
			local player = onlinePlayers:get(i)
			if player ~= nil and (payload.username == nil or player:getUsername() == payload.username) then
				local xJitter = ZombRand(5,10)
				local yJitter = ZombRand(5,10)
				local addXJitter = ZombRand(1)
				local addYJitter = ZombRand(1)
				local female = ZombRand(1)
				local zombieX
				if addXJitter == 1 then
					zombieX = player:getX() + xJitter
				else
					zombieX = player:getX() - xJitter
				end
				local zombieY
				if addYJitter == 1 then
					zombieY = player:getY() + yJitter
				else
					zombieY = player:getY() - yJitter
				end
				local outfit = getAllOutfits(female > 0):get(ZombRand(0, getAllOutfits(female > 0):size()))
				local randomZombie = addZombiesInOutfit(zombieX, zombieY, 0, 1, outfit, female * 100):get(0)
				randomZombie:setTarget(player)
				randomZombie:setWalkType(WalkTypes[ZombRand(1, WalkTypes.NUM)])
				print('Spawning random zombie for', player:getUsername(), zombieX, zombieY)
			end
		end
	end

	if command == 'storm' then
		getClimateManager():stopWeatherAndThunder()
		getClimateManager():triggerCustomWeatherStage(WeatherPeriod.STAGE_STORM, 1)
	end

	if command == 'blizzard' then
		getClimateManager():stopWeatherAndThunder()
		getClimateManager():triggerCustomWeatherStage(WeatherPeriod.STAGE_BLIZZARD, 1)
	end

	if command == 'tropical' then
		getClimateManager():stopWeatherAndThunder()
		getClimateManager():triggerCustomWeatherStage(WeatherPeriod.STAGE_TROPICAL_STORM, 1)
	end

	if command == 'sunny' then
		clearClimateFloats()
		getClimateManager():stopWeatherAndThunder()
	end

	if command == 'climate' then
		clearClimateFloats()

		if payload.desaturation ~= nil then
			print('setting desaturation to: ', payload.desaturation)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_DESATURATION):setEnableAdmin(true)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_DESATURATION):setAdminValue(payload.desaturation)
		end

		if payload.globalLightIntensity ~= nil then
			print('setting globalLightIntensity to: ', payload.globalLightIntensity)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_GLOBAL_LIGHT_INTENSITY):setEnableAdmin(true)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_GLOBAL_LIGHT_INTENSITY):setAdminValue(payload.globalLightIntensity)
		end

		if payload.nightStrength ~= nil then
			print('setting nightStrength to: ', payload.nightStrength)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_NIGHT_STRENGTH):setEnableAdmin(true)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_NIGHT_STRENGTH):setAdminValue(payload.nightStrength)
		end

		if payload.precipitationIntensity ~= nil then
			print('setting precipitationIntensity to: ', payload.precipitationIntensity)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_PRECIPITATION_INTENSITY):setEnableAdmin(true)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_PRECIPITATION_INTENSITY):setAdminValue(payload.precipitationIntensity)
		end

		if payload.temperature ~= nil then
			print('setting temperature to: ', payload.temperature)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_TEMPERATURE):setEnableAdmin(true)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_TEMPERATURE):setAdminValue(payload.temperature)
		end

		if payload.fogIntensity ~= nil then
			print('setting fogIntensity to: ', payload.fogIntensity)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_FOG_INTENSITY):setEnableAdmin(true)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_FOG_INTENSITY):setAdminValue(payload.fogIntensity)
		end

		if payload.windIntensity ~= nil then
			print('setting windIntensity to: ', payload.windIntensity)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_WIND_INTENSITY):setEnableAdmin(true)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_WIND_INTENSITY):setAdminValue(payload.windIntensity)
		end

		if payload.windAngleIntensity ~= nil then
			print('setting windAngleIntensity to: ', payload.windAngleIntensity)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_WIND_ANGLE_INTENSITY):setEnableAdmin(true)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_WIND_ANGLE_INTENSITY):setAdminValue(payload.windAngleIntensity)
		end

		if payload.cloudIntensity ~= nil then
			print('setting cloudIntensity to: ', payload.cloudIntensity)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_CLOUD_INTENSITY):setEnableAdmin(true)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_CLOUD_INTENSITY):setAdminValue(payload.cloudIntensity)
		end

		if payload.ambient ~= nil then
			print('setting ambient to: ', payload.ambient)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_AMBIENT):setEnableAdmin(true)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_AMBIENT):setAdminValue(payload.ambient)
		end

		if payload.viewDistance ~= nil then
			print('setting viewDistance to: ', payload.viewDistance)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_VIEW_DISTANCE):setEnableAdmin(true)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_VIEW_DISTANCE):setAdminValue(payload.viewDistance)
		end

		if payload.daylightStrength ~= nil then
			print('setting daylightStrength to: ', payload.daylightStrength)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_DAYLIGHT_STRENGTH):setEnableAdmin(true)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_DAYLIGHT_STRENGTH):setAdminValue(payload.daylightStrength)
		end

		if payload.humidity ~= nil then
			print('setting humidity to: ', payload.humidity)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_HUMIDITY):setEnableAdmin(true)
			getClimateManager():getClimateFloat(ClimateManager.FLOAT_HUMIDITY):setAdminValue(payload.humidity)
		end

		if payload.snow ~= nil then
			print('setting snow to: ', payload.snow)
			getClimateManager():getClimateBool(ClimateManager.BOOL_IS_SNOW):setEnableAdmin(true)
			getClimateManager():getClimateBool(ClimateManager.BOOL_IS_SNOW):setAdminValue(payload.snow)
		end

		if payload.globalLightColor ~= nil then
			getClimateManager():getClimateColor(ClimateManager.COLOR_GLOBAL_LIGHT):setEnableAdmin(true)
			getClimateManager():getClimateColor(ClimateManager.COLOR_GLOBAL_LIGHT):setAdminValue(
					payload.globalLightColor.interior.r, payload.globalLightColor.interior.g, payload.globalLightColor.interior.b, payload.globalLightColor.interior.a,
					payload.globalLightColor.exterior.r, payload.globalLightColor.exterior.g, payload.globalLightColor.exterior.b, payload.globalLightColor.exterior.a
			)
		end

		if payload.newFogColor ~= nil then
			getClimateManager():getClimateColor(ClimateManager.COLOR_NEW_FOG):setEnableAdmin(true)
			getClimateManager():getClimateColor(ClimateManager.COLOR_NEW_FOG):setAdminValue(
					payload.newFogColor.interior.r, payload.newFogColor.interior.g, payload.newFogColor.interior.b, payload.newFogColor.interior.a,
					payload.newFogColor.exterior.r, payload.newFogColor.exterior.g, payload.newFogColor.exterior.b, payload.newFogColor.exterior.a
			)
		end
	end
end

local reader = getModFileReader('BrainSlug', 'inpipe', false)

local flushPipe = function()
	print('flushing pipe')
	while reader:ready() do
		reader:readLine()
	end
	print('done')
end

local readPipe = function()
	if reader:ready() then
		local line = reader:readLine()
		if line then
			local message = json:decode(line)
			execCommand(message.command, message.payload)
		end
	end
end

local init = function()
	flushPipe()
	sendPong()
end

local onZombieDeath = function()
	writePipe('zombieDied')
end

local onClientCommand = function(module, command, player, args)
	if command == 'playerInventory' then
		playerInventoryCache[args.username] = args.inventory
	end

	if command == 'playerDied' then
		writePipe('playerDied', { username = args.username })
	end
end

local onConnected = function()
	writePipe('playerConnected', { username = 'args.username' })
end

local onDisconnect = function()
	writePipe('playerDisconnected', { username = 'args.username' })
end

Events.OnConnected.Add(onConnected)
Events.OnDisconnect.Add(onDisconnect)
Events.OnServerStarted.Add(init)
Events.OnClientCommand.Add(onClientCommand)
Events.OnTickEvenPaused.Add(readPipe)
Events.OnZombieDead.Add(onZombieDeath)
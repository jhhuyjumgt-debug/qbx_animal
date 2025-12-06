-- ============================================
-- qbx_animal CLIENT SCRIPT - MULTIPLE PETS
-- Version: 1.0.0
-- ============================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Variables
local activePet = nil
local activePetModel = nil
local activePetType = nil
local hunger = 100
local isPetSpawned = false
local isPetAttached = false
local isInVehicle = false
local ballObject = nil
local isFetchingBall = false
local myPets = {} -- Tableau pour stocker les animaux possédés

-- Configuration
local Config = {
    Locale = 'en',
    FoodItem = 'pet_food',
    MaxPets = 5, -- Nombre maximum d'animaux qu'un joueur peut posséder

    -- Modèles d'animaux
    PetModels = {
        ['chien'] = GetHashKey('a_c_chop'),        -- Dog
        ['chat'] = GetHashKey('a_c_cat_01'),       -- Cat
        ['lapin'] = GetHashKey('a_c_rabbit_01'),   -- Rabbit
        ['husky'] = GetHashKey('a_c_husky'),       -- Husky
        ['cochon'] = GetHashKey('a_c_pig'),        -- Pig
        ['caniche'] = GetHashKey('a_c_poodle'),    -- Poodle
        ['carlin'] = GetHashKey('a_c_pug'),        -- Pug
        ['retriever'] = GetHashKey('a_c_retriever'), -- Retriever
        ['berger'] = GetHashKey('a_c_shepherd'),   -- German Shepherd
        ['westie'] = GetHashKey('a_c_westy'),      -- Westie
        ['chop'] = GetHashKey('a_c_chop'),         -- Chop
        ['loup'] = GetHashKey('a_c_coyote'),       -- Wolf
        ['bunny'] = GetHashKey('a_c_rabbit_01'),   -- Bunny
        ['rottweiler'] = GetHashKey('a_c_rottweiler') -- Rottweiler
    },

    -- Animalerie
    PetShop = {
        location = vector3(562.19, 2741.30, 41.86),
        pets = {
            { name = 'chien', label = 'Dog', price = 50000 },
            { name = 'chat', label = 'Cat', price = 15000 },
            { name = 'lapin', label = 'Bunny', price = 25000 },
            { name = 'husky', label = 'Husky', price = 35000 },
            { name = 'cochon', label = 'Pig', price = 10000 },
            { name = 'caniche', label = 'Poodle', price = 50000 },
            { name = 'carlin', label = 'Pug', price = 6000 },
            { name = 'retriever', label = 'Retriever', price = 10000 },
            { name = 'berger', label = 'German Shepherd', price = 55000 },
            { name = 'westie', label = 'Westie', price = 50000 },
            { name = 'chop', label = 'Chop', price = 12000 },
            { name = 'loup', label = 'Wolf', price = 30000 },
            { name = 'bunny', label = 'Bunny', price = 8000 },
            { name = 'rottweiler', label = 'Rottweiler', price = 45000 }
        }
    },

    -- Animations
    Animations = {
        sit = { dict = 'creatures@rottweiler@amb@world_dog_sitting@base', anim = 'base' },
        lie_down = { dict = 'creatures@rottweiler@amb@sleep_in_kennel@', anim = 'sleep_in_kennel' },
        call = { dict = 'rcmnigel1c', anim = 'hailing_whistle_waive_a' }
    },

    -- Faim
    Hunger = {
        decreaseInterval = 60000,
        decreaseAmount = 1,
        warningThreshold = 30,
        deathThreshold = 0,
        foodRestoreMin = 10,
        foodRestoreMax = 25
    },

    -- Distances
    InteractionDistance = 5.0,
    VehicleDistance = 8.0
}

-- Traductions
local function t(key, ...)
    local translations = {
        -- Menu principal
        pet_management = 'Pet Management',
        my_pets = 'My Pets',
        select_pet = 'Select Pet',
        active_pet = 'Active Pet: %s',
        hunger = 'Hunger: %s',
        give_food = 'Give Food',
        attach_pet = 'Attach/Detach Pet',
        get_in_vehicle = 'Get in Vehicle',
        get_out_vehicle = 'Get out of Vehicle',
        give_orders = 'Give Orders',
        call_pet = 'Call Pet',
        return_pet = 'Return Pet',
        switch_pet = 'Switch Pet',

        -- Commandes
        pet_orders = 'Pet Orders',
        sit = 'Sit',
        lie_down = 'Lie Down',
        stand_up = 'Stand Up',
        fetch_ball = 'Fetch Ball',
        come_here = 'Come Here',
        go_home = 'Go Home',

        -- Notifications
        pet_called = 'You called your %s!',
        pet_arrived = 'Your %s has arrived!',
        pet_attached = 'Pet attached',
        pet_detached = 'Pet detached',
        pet_fed = 'You fed your pet',
        pet_not_hungry = 'Your pet is not hungry',
        no_food = 'You don\'t have pet food!',
        pet_too_far = 'Your pet is too far away!',
        vehicle_too_far = 'Your pet is too far from the vehicle!',
        need_vehicle = 'You need to be in a vehicle!',
        still_in_vehicle = 'You are still in a vehicle',
        cant_attach_vehicle = 'You cannot attach pet in a vehicle!',
        pet_returning_home = 'Your pet is returning home',
        pet_dead = 'Your %s has died! Feed it next time.',
        no_ball = 'You don\'t have a ball!',
        pet_switched = 'Switched to %s',
        pet_returned = 'Pet returned',
        max_pets_reached = 'You have reached the maximum number of pets (%s)',

        -- Animalerie
        pet_shop = 'Pet Shop',
        buy_pet = 'Buy %s',
        price = 'Price: $%s',
        confirm_purchase = 'Confirm Purchase',
        purchase_success = 'You bought a %s for $%s!',
        insufficient_funds = 'You don\'t have enough money!',
        already_owned = 'You already own this pet!',

        -- Interactions
        press_to_interact = 'Press [E] to interact',
        press_to_open_shop = 'Press [E] to open Pet Shop'
    }

    local text = translations[key] or key
    if ... then
        return string.format(text, ...)
    end
    return text
end

-- Notifications
local function Notify(msg, type)
    if type == 'success' then
        QBCore.Functions.Notify(msg, 'success', 3000)
    elseif type == 'error' then
        QBCore.Functions.Notify(msg, 'error', 3000)
    elseif type == 'info' then
        QBCore.Functions.Notify(msg, 'primary', 3000)
    else
        QBCore.Functions.Notify(msg, 'primary', 3000)
    end
end

-- ============================================
-- FONCTIONS DE BASE
-- ============================================

local function LoadModel(modelHash)
    if not IsModelValid(modelHash) then
        print('Invalid model hash:', modelHash)
        return false
    end

    RequestModel(modelHash)
    local timeout = 5000
    local start = GetGameTimer()

    while not HasModelLoaded(modelHash) do
        if GetGameTimer() - start > timeout then
            print('Timeout loading model:', modelHash)
            return false
        end
        Citizen.Wait(0)
    end

    return true
end

local function LoadAnim(dict)
    RequestAnimDict(dict)
    local timeout = 5000
    local start = GetGameTimer()

    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() - start > timeout then
            print('Timeout loading anim dict:', dict)
            return false
        end
        Citizen.Wait(0)
    end

    return true
end

-- Retirer l'animal actif
local function ReturnCurrentPet()
    if not activePet or not DoesEntityExist(activePet) then return end

    Notify(t('pet_returning_home'), 'info')

    local group = GetPlayerGroup(PlayerId())
    SetGroupSeparationRange(group, 1.9)
    SetPedNeverLeavesGroup(activePet, false)

    local coords = GetEntityCoords(PlayerPedId())
    local farCoords = vector3(coords.x + 100, coords.y, coords.z)
    TaskGoToCoordAnyMeans(activePet, farCoords, 5.0, 0, 0, 786603, 0xbf800000)

    Citizen.SetTimeout(5000, function()
        if activePet and DoesEntityExist(activePet) then
            DeleteEntity(activePet)
            activePet = nil
            activePetModel = nil
            activePetType = nil
            isPetSpawned = false
            isPetAttached = false
            isInVehicle = false
            Notify(t('pet_returned'), 'success')
        end
    end)
end

-- Appeler un animal spécifique
local function CallSpecificPet(petType, petLabel)
    -- Retirer l'animal actif s'il y en a un
    if isPetSpawned then
        ReturnCurrentPet()
        Citizen.Wait(1000)
    end

    activePetModel = Config.PetModels[petType]
    activePetType = petType

    if not activePetModel then
        Notify('Invalid pet type!', 'error')
        return
    end

    if not LoadModel(activePetModel) then
        Notify('Failed to load pet model', 'error')
        return
    end

    -- Animation d'appel
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    if LoadAnim(Config.Animations.call.dict) then
        TaskPlayAnim(playerPed, Config.Animations.call.dict, Config.Animations.call.anim,
                    8.0, -8, -1, 120, 0, false, false, false)
    end

    Notify(t('pet_called', petLabel), 'success')

    -- Créer le pet après 5 secondes
    Citizen.SetTimeout(5000, function()
        local forward = GetEntityForwardVector(playerPed)
        local spawnCoords = vector3(
            coords.x + (forward.x * 2),
            coords.y + (forward.y * 2),
            coords.z - 1
        )

        -- Vérifier le sol
        local found, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z, false)
        if found then
            spawnCoords = vector3(spawnCoords.x, spawnCoords.y, groundZ)
        end

        activePet = CreatePed(28, activePetModel, spawnCoords.x, spawnCoords.y, spawnCoords.z,
                           GetEntityHeading(playerPed) + 90.0, true, false)

        if activePet and DoesEntityExist(activePet) then
            SetEntityAsMissionEntity(activePet, true, true)
            SetPedFleeAttributes(activePet, 0, false)
            SetPedCombatAttributes(activePet, 17, true)
            SetPedCanRagdollFromPlayerImpact(activePet, false)
            SetPedCanBeTargetted(activePet, false)
            SetBlockingOfNonTemporaryEvents(activePet, true)

            -- Groupe pour suivre le joueur
            local group = GetPlayerGroup(PlayerId())
            SetPedAsGroupLeader(playerPed, group)
            SetPedAsGroupMember(activePet, group)
            SetPedNeverLeavesGroup(activePet, true)
            SetGroupSeparationRange(group, 999999.9)

            -- Faire suivre le joueur
            TaskFollowToOffsetOfEntity(activePet, playerPed, 0.0, -1.0, 0.0, 5.0, -1, 10.0, true)

            hunger = math.random(40, 90)
            isPetSpawned = true

            Notify(t('pet_arrived', petLabel), 'success')

            -- Libérer le modèle
            SetModelAsNoLongerNeeded(activePetModel)
        else
            Notify('Failed to spawn pet', 'error')
        end
    end)
end

-- Nourrir l'animal
local function FeedPet()
    if not isPetSpawned or not activePet then
        Notify('No pet found', 'error')
        return
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local petCoords = GetEntityCoords(activePet)
    local distance = #(playerCoords - petCoords)

    if distance > Config.InteractionDistance then
        Notify(t('pet_too_far'), 'error')
        return
    end

    QBCore.Functions.TriggerCallback('qbx_animal:hasFood', function(hasFood)
        if not hasFood then
            Notify(t('no_food'), 'error')
            return
        end

        if hunger >= 100 then
            Notify(t('pet_not_hungry'), 'info')
            return
        end

        local restore = math.random(Config.Hunger.foodRestoreMin, Config.Hunger.foodRestoreMax)
        hunger = math.min(100, hunger + restore)

        TriggerServerEvent('qbx_animal:consumeFood')
        Notify(t('pet_fed'), 'success')
    end)
end

-- Attacher/Détacher
local function ToggleAttach()
    if not isPetSpawned or not activePet then
        Notify('No pet found', 'error')
        return
    end

    if IsPedSittingInAnyVehicle(PlayerPedId()) then
        Notify(t('cant_attach_vehicle'), 'error')
        return
    end

    local group = GetPlayerGroup(PlayerId())

    if isPetAttached then
        -- Détacher
        SetGroupSeparationRange(group, 999999.9)
        SetPedNeverLeavesGroup(activePet, true)
        FreezeEntityPosition(activePet, false)
        isPetAttached = false
        Notify(t('pet_detached'), 'success')
    else
        -- Attacher
        SetGroupSeparationRange(group, 1.9)
        SetPedNeverLeavesGroup(activePet, false)
        FreezeEntityPosition(activePet, true)
        isPetAttached = true
        Notify(t('pet_attached'), 'success')
    end
end

-- Gestion véhicule
local function HandleVehicle()
    if not isPetSpawned or not activePet then
        Notify('No pet found', 'error')
        return
    end

    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local playerCoords = GetEntityCoords(playerPed)
    local petCoords = GetEntityCoords(activePet)
    local distance = #(playerCoords - petCoords)

    if not isInVehicle then
        -- Faire monter
        if vehicle ~= 0 then
            if distance > Config.VehicleDistance then
                Notify(t('vehicle_too_far'), 'error')
                return
            end

            -- Chercher un siège libre
            for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
                if IsVehicleSeatFree(vehicle, i) then
                    SetPedIntoVehicle(activePet, vehicle, i)
                    isInVehicle = true
                    Notify('Pet entered vehicle', 'success')
                    return
                end
            end

            Notify('No free seats', 'error')
        else
            Notify(t('need_vehicle'), 'error')
        end
    else
        -- Faire descendre
        if vehicle == 0 then
            SetEntityCoords(activePet, playerCoords.x, playerCoords.y, playerCoords.z)
            isInVehicle = false
            Notify('Pet exited vehicle', 'success')
        else
            Notify(t('still_in_vehicle'), 'error')
        end
    end
end

-- Donner des ordres
local function GiveOrders()
    if not isPetSpawned or not activePet then
        Notify('No pet found', 'error')
        return
    end

    local options = {
        {
            title = t('sit'),
            description = 'Make your pet sit',
            event = 'qbx_animal:order',
            args = { order = 'sit' }
        },
        {
            title = t('lie_down'),
            description = 'Make your pet lie down',
            event = 'qbx_animal:order',
            args = { order = 'lie_down' }
        },
        {
            title = t('stand_up'),
            description = 'Make your pet stand up',
            event = 'qbx_animal:order',
            args = { order = 'stand_up' }
        },
        {
            title = t('come_here'),
            description = 'Call your pet to you',
            event = 'qbx_animal:order',
            args = { order = 'come_here' }
        },
        {
            title = t('fetch_ball'),
            description = 'Throw a ball for your pet',
            event = 'qbx_animal:order',
            args = { order = 'fetch_ball' }
        },
        {
            title = t('go_home'),
            description = 'Send your pet home',
            event = 'qbx_animal:order',
            args = { order = 'go_home' }
        }
    }

    lib.registerContext({
        id = 'pet_orders',
        title = t('pet_orders'),
        options = options
    })

    lib.showContext('pet_orders')
end

-- Traiter les ordres
RegisterNetEvent('qbx_animal:order', function(data)
    if not isPetSpawned or not activePet then return end

    if data.order == 'sit' then
        if LoadAnim(Config.Animations.sit.dict) then
            TaskPlayAnim(activePet, Config.Animations.sit.dict, Config.Animations.sit.anim,
                        8.0, -8, -1, 1, 0, false, false, false)
        end
    elseif data.order == 'lie_down' then
        if LoadAnim(Config.Animations.lie_down.dict) then
            TaskPlayAnim(activePet, Config.Animations.lie_down.dict, Config.Animations.lie_down.anim,
                        8.0, -8, -1, 1, 0, false, false, false)
        end
    elseif data.order == 'stand_up' then
        ClearPedTasks(activePet)
    elseif data.order == 'come_here' then
        local playerCoords = GetEntityCoords(PlayerPedId())
        TaskGoToCoordAnyMeans(activePet, playerCoords, 5.0, 0, 0, 786603, 0xbf800000)
    elseif data.order == 'fetch_ball' then
        local ball = GetClosestObjectOfType(GetEntityCoords(activePet), 50.0, `w_am_baseball`)
        if ball and ball ~= 0 then
            isFetchingBall = true
            ballObject = ball
            local ballCoords = GetEntityCoords(ball)
            TaskGoToCoordAnyMeans(activePet, ballCoords, 5.0, 0, 0, 786603, 0xbf800000)
        else
            Notify(t('no_ball'), 'error')
        end
    elseif data.order == 'go_home' then
        ReturnCurrentPet()
    end
end)

-- ============================================
-- MENU PRINCIPAL (MULTIPLE PETS)
-- ============================================

-- Menu de sélection des animaux
local function OpenPetSelectionMenu()
    if #myPets == 0 then
        Notify('You don\'t have any pets! Buy one at the pet shop.', 'error')
        return
    end

    local options = {}

    for _, petData in ipairs(myPets) do
        local petLabel = GetPetLabel(petData.pet_type)
        local isActive = (activePetType == petData.pet_type)

        table.insert(options, {
            title = petLabel .. (isActive and ' (Active)' or ''),
            description = isActive and 'Currently active' or 'Click to select',
            event = isActive and nil or 'qbx_animal:selectPet',
            args = {
                pet_type = petData.pet_type,
                pet_label = petLabel,
                disabled = isActive
            }
        })
    end

    lib.registerContext({
        id = 'pet_selection',
        title = t('select_pet'),
        options = options
    })

    lib.showContext('pet_selection')
end

-- Sélectionner un animal
RegisterNetEvent('qbx_animal:selectPet', function(data)
    CallSpecificPet(data.pet_type, data.pet_label)
    Notify(t('pet_switched', data.pet_label), 'success')
end)

-- Menu principal
local function OpenPetMenu()
    local options = {}

    -- Section: Animal actif
    if isPetSpawned and activePetType then
        local petLabel = GetPetLabel(activePetType)

        table.insert(options, {
            title = t('active_pet', petLabel),
            disabled = true
        })

        table.insert(options, {
            title = t('hunger', hunger),
            disabled = true
        })

        table.insert(options, {
            title = t('give_food'),
            description = 'Feed your pet',
            event = 'qbx_animal:feed',
            args = {}
        })

        table.insert(options, {
            title = t('attach_pet'),
            description = 'Attach or detach your pet',
            event = 'qbx_animal:toggleAttach',
            args = {}
        })

        if isInVehicle then
            table.insert(options, {
                title = t('get_out_vehicle'),
                description = 'Tell pet to exit vehicle',
                event = 'qbx_animal:handleVehicle',
                args = {}
            })
        else
            table.insert(options, {
                title = t('get_in_vehicle'),
                description = 'Tell pet to enter vehicle',
                event = 'qbx_animal:handleVehicle',
                args = {}
            })
        end

        table.insert(options, {
            title = t('give_orders'),
            description = 'Give commands to your pet',
            event = 'qbx_animal:giveOrders',
            args = {}
        })

        table.insert(options, {
            title = t('return_pet'),
            description = 'Send pet back home',
            event = 'qbx_animal:returnPet',
            args = {}
        })
    end

    -- Section: Gestion des animaux
    table.insert(options, {
        title = t('my_pets'),
        description = 'View and switch pets',
        event = 'qbx_animal:openSelection',
        args = {}
    })

    if not isPetSpawned and #myPets > 0 then
        table.insert(options, {
            title = t('call_pet'),
            description = 'Call a pet',
            event = 'qbx_animal:openSelection',
            args = {}
        })
    end

    lib.registerContext({
        id = 'pet_menu',
        title = t('pet_management'),
        options = options
    })

    lib.showContext('pet_menu')
end

-- Événements pour le menu
RegisterNetEvent('qbx_animal:feed', FeedPet)
RegisterNetEvent('qbx_animal:toggleAttach', ToggleAttach)
RegisterNetEvent('qbx_animal:handleVehicle', HandleVehicle)
RegisterNetEvent('qbx_animal:giveOrders', GiveOrders)
RegisterNetEvent('qbx_animal:returnPet', ReturnCurrentPet)
RegisterNetEvent('qbx_animal:openSelection', OpenPetSelectionMenu)

-- Obtenir le label d'un animal
function GetPetLabel(petType)
    for _, pet in ipairs(Config.PetShop.pets) do
        if pet.name == petType then
            return pet.label
        end
    end
    return petType
end

-- Charger les animaux du joueur
local function LoadPlayerPets()
    QBCore.Functions.TriggerCallback('qbx_animal:getPets', function(pets)
        myPets = pets or {}
        print('[qbx_animal] Loaded pets:', #myPets)
    end)
end

-- ============================================
-- ANIMALERIE (MULTIPLE PETS)
-- ============================================

local inPetShopZone = false

-- Créer le blip
Citizen.CreateThread(function()
    local blip = AddBlipForCoord(Config.PetShop.location.x, Config.PetShop.location.y, Config.PetShop.location.z)
    SetBlipSprite(blip, 463)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(t('pet_shop'))
    EndTextCommandSetBlipName(blip)
end)

-- Zone de l'animalerie
Citizen.CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = #(playerCoords - Config.PetShop.location)

        if distance < 2.0 then
            if not inPetShopZone then
                inPetShopZone = true
                lib.showTextUI(t('press_to_open_shop'))
            end

            if IsControlJustReleased(0, 38) then -- E
                OpenPetShopMenu()
                Citizen.Wait(1000)
            end
        else
            if inPetShopZone then
                inPetShopZone = false
                lib.hideTextUI()
            end
        end

        Citizen.Wait(0)
    end
end)

-- Ouvrir l'animalerie
function OpenPetShopMenu()
    local options = {}

    for _, petData in ipairs(Config.PetShop.pets) do
        -- Vérifier si le joueur possède déjà cet animal
        local alreadyOwned = false
        for _, myPet in ipairs(myPets) do
            if myPet.pet_type == petData.name then
                alreadyOwned = true
                break
            end
        end

        local description = t('price', petData.price)
        if alreadyOwned then
            description = description .. ' (Already owned)'
        end

        table.insert(options, {
            title = t('buy_pet', petData.label),
            description = description,
            event = alreadyOwned and nil or 'qbx_animal:buyPet',
            args = {
                pet = petData.name,
                price = petData.price,
                label = petData.label,
                disabled = alreadyOwned
            }
        })
    end

    lib.registerContext({
        id = 'pet_shop_menu',
        title = t('pet_shop'),
        options = options
    })

    lib.showContext('pet_shop_menu')
end

-- Acheter un animal
RegisterNetEvent('qbx_animal:buyPet', function(data)
    QBCore.Functions.TriggerCallback('qbx_animal:buyPet', function(success, reason)
        if success then
            Notify(t('purchase_success', data.label, data.price), 'success')
            -- Recharger la liste des animaux
            LoadPlayerPets()
        else
            if reason == 'max_pets' then
                Notify(t('max_pets_reached', Config.MaxPets), 'error')
            elseif reason == 'already_owned' then
                Notify(t('already_owned'), 'error')
            else
                Notify(t('insufficient_funds'), 'error')
            end
        end
    end, data.pet, data.price)
end)

-- ============================================
-- LOGIQUES
-- ============================================

-- Logique pour la balle
Citizen.CreateThread(function()
    while true do
        if isFetchingBall and activePet and ballObject then
            local petCoords = GetEntityCoords(activePet)
            local ballCoords = GetEntityCoords(ballObject)
            local distance = #(petCoords - ballCoords)

            if distance < 0.5 then
                local bone = GetPedBoneIndex(activePet, 17188) -- Bouche
                AttachEntityToEntity(ballObject, activePet, bone, 0.12, 0.01, 0.01, 5.0, 150.0, 0.0,
                                    true, true, false, true, 1, true)

                local playerCoords = GetEntityCoords(PlayerPedId())
                TaskGoToCoordAnyMeans(activePet, playerCoords, 5.0, 0, 0, 786603, 0xbf800000)
            end

            local playerDistance = #(GetEntityCoords(PlayerPedId()) - petCoords)
            if playerDistance < 1.5 then
                DetachEntity(ballObject, false, false)
                DeleteEntity(ballObject)
                ballObject = nil
                isFetchingBall = false

                GiveWeaponToPed(PlayerPedId(), `WEAPON_BALL`, 1, false, true)

                local group = GetPlayerGroup(PlayerId())
                SetGroupSeparationRange(group, 999999.9)
                SetPedNeverLeavesGroup(activePet, true)

                Notify('Pet brought the ball!', 'success')
            end
        end

        Citizen.Wait(500)
    end
end)

-- Système de faim
Citizen.CreateThread(function()
    while true do
        if isPetSpawned then
            hunger = hunger - Config.Hunger.decreaseAmount

            if hunger <= Config.Hunger.warningThreshold and hunger > Config.Hunger.deathThreshold then
                Notify('Your pet is getting hungry!', 'warning')
            elseif hunger <= Config.Hunger.deathThreshold then
                local petLabel = GetPetLabel(activePetType)
                TriggerServerEvent('qbx_animal:petDied', activePetType)
                if activePet and DoesEntityExist(activePet) then
                    DeleteEntity(activePet)
                    activePet = nil
                end
                isPetSpawned = false
                activePetType = nil
                Notify(t('pet_dead', petLabel), 'error')
                -- Recharger la liste
                LoadPlayerPets()
            end
        end

        Citizen.Wait(Config.Hunger.decreaseInterval)
    end
end)

-- ============================================
-- COMMANDES ET INITIALISATION
-- ============================================

-- Touche pour ouvrir le menu
RegisterCommand('petmenu', OpenPetMenu, false)
RegisterKeyMapping('petmenu', 'Open Pet Menu', 'keyboard', 'F7')

-- Commande de debug
RegisterCommand('debugpet', function()
    print('=== PET DEBUG ===')
    print('Active pet:', activePetType)
    print('Pet exists:', isPetSpawned)
    print('Pet entity:', activePet)
    print('Pet model:', activePetModel)
    print('Hunger:', hunger)
    print('Is attached:', isPetAttached)
    print('Is in vehicle:', isInVehicle)
    print('My pets:', #myPets)
    for i, pet in ipairs(myPets) do
        print('  ' .. i .. '. ' .. pet.pet_type)
    end

    if activePet and DoesEntityExist(activePet) then
        local coords = GetEntityCoords(activePet)
        print('Pet location:', coords)

        Citizen.CreateThread(function()
            for i = 1, 100 do
                DrawMarker(28, coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                          0.5, 0.5, 0.5, 0, 255, 0, 100, false, true, 2, false, nil, nil, false)
                Citizen.Wait(0)
            end
        end)

        Notify('Debug: Pet marker shown for 10 seconds', 'info')
    else
        Notify('No active pet found', 'error')
    end
end)

-- Test rapide pour spawner un chien
RegisterCommand('testpet', function()
    local testModel = Config.PetModels['chien']
    if not testModel then return end

    if not LoadModel(testModel) then
        Notify('Failed to load dog model', 'error')
        return
    end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local spawnCoords = vector3(
        coords.x + (forward.x * 2),
        coords.y + (forward.y * 2),
        coords.z
    )

    local testPet = CreatePed(28, testModel, spawnCoords.x, spawnCoords.y, spawnCoords.z,
                   GetEntityHeading(playerPed) + 90.0, true, false)

    if testPet and DoesEntityExist(testPet) then
        SetEntityAsMissionEntity(testPet, true, true)
        SetPedCanBeTargetted(testPet, false)

        local group = GetPlayerGroup(PlayerId())
        SetPedAsGroupLeader(playerPed, group)
        SetPedAsGroupMember(testPet, group)
        SetPedNeverLeavesGroup(testPet, true)

        TaskFollowToOffsetOfEntity(testPet, playerPed, 0.0, -1.0, 0.0, 5.0, -1, 10.0, true)

        activePet = testPet
        activePetType = 'chien'
        activePetModel = testModel
        isPetSpawned = true
        hunger = 100

        Notify('Test pet (dog) spawned!', 'success')
        SetModelAsNoLongerNeeded(testModel)
    else
        Notify('Failed to spawn test pet', 'error')
    end
end)

-- Nettoyage à la déconnexion
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if activePet and DoesEntityExist(activePet) then
            DeleteEntity(activePet)
        end
        if ballObject and DoesEntityExist(ballObject) then
            DeleteEntity(ballObject)
        end
        lib.hideTextUI()
    end
end)

-- Initialisation
Citizen.CreateThread(function()
    Citizen.Wait(2000) -- Attendre que le joueur soit connecté
    LoadPlayerPets()

    print('^2========================================^7')
    print('^2      qbx_animal Client Started^7')
    print('^2      Version: 1.0.0 (Multiple Pets)^7')
    print('^2      Press F7 to open Pet Menu^7')
    print('^2      Use /debugpet for debugging^7')
    print('^2========================================^7')
end)
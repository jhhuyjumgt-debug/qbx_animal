-- ============================================
-- qbx_animal SERVER SCRIPT - MULTIPLE PETS
-- Version: 1.0.0
-- ============================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Configuration serveur
local Config = {
    MaxPets = 5,
    FoodItem = 'pet_food'
}

-- Créer la table des animaux
CreateThread(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS player_pets (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(255) NOT NULL,
            pet_type VARCHAR(50) NOT NULL,
            pet_name VARCHAR(100) DEFAULT NULL,
            hunger INT DEFAULT 100,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_pet (citizenid, pet_type)
        )
    ]], {}, function()
        print('[qbx_animal] Database table player_pets created/verified')
    end)
end)

-- Récupérer TOUS les animaux d'un joueur
QBCore.Functions.CreateCallback('qbx_animal:getPets', function(source, cb)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return cb({}) end

    local citizenid = player.PlayerData.citizenid

    MySQL.Async.fetchAll('SELECT pet_type, pet_name, hunger FROM player_pets WHERE citizenid = @citizenid', {
        ['@citizenid'] = citizenid
    }, function(results)
        cb(results or {})
    end)
end)

-- Animal mort
RegisterNetEvent('qbx_animal:petDied', function(petType)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local citizenid = player.PlayerData.citizenid

    MySQL.Async.execute('DELETE FROM player_pets WHERE citizenid = @citizenid AND pet_type = @pet_type', {
        ['@citizenid'] = citizenid,
        ['@pet_type'] = petType
    }, function(rowsChanged)
        if rowsChanged > 0 then
            print('[qbx_animal] Pet died:', petType, 'for', citizenid)
            QBCore.Functions.Notify(src, 'Your ' .. petType .. ' has died!', 'error', 5000)
        end
    end)
end)

-- Consommer de la nourriture
RegisterNetEvent('qbx_animal:consumeFood', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    if player.Functions.RemoveItem(Config.FoodItem, 1) then
        print('[qbx_animal] Food consumed by:', player.PlayerData.citizenid)
    else
        QBCore.Functions.Notify(src, 'You don\'t have pet food!', 'error', 3000)
    end
end)

-- Vérifier si le joueur a de la nourriture
QBCore.Functions.CreateCallback('qbx_animal:hasFood', function(source, cb)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return cb(false) end

    local item = player.Functions.GetItemByName(Config.FoodItem)
    cb(item ~= nil and item.amount > 0)
end)

-- Acheter un animal
QBCore.Functions.CreateCallback('qbx_animal:buyPet', function(source, cb, petType, price)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return cb(false, 'error') end

    local citizenid = player.PlayerData.citizenid

    -- Vérifier le nombre maximum d'animaux
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM player_pets WHERE citizenid = @citizenid', {
        ['@citizenid'] = citizenid
    }, function(count)
        if count >= Config.MaxPets then
            print('[qbx_animal] Max pets reached for:', citizenid)
            cb(false, 'max_pets')
            return
        end

        -- Vérifier si le joueur possède déjà cet animal
        MySQL.Async.fetchScalar('SELECT id FROM player_pets WHERE citizenid = @citizenid AND pet_type = @pet_type', {
            ['@citizenid'] = citizenid,
            ['@pet_type'] = petType
        }, function(existingPet)
            if existingPet then
                print('[qbx_animal] Player already has this pet:', petType)
                cb(false, 'already_owned')
                return
            end

            -- Liste des animaux valides avec prix
            local validPets = {
                ['chien'] = 50000,
                ['chat'] = 15000,
                ['lapin'] = 25000,
                ['husky'] = 35000,
                ['cochon'] = 10000,
                ['caniche'] = 50000,
                ['carlin'] = 6000,
                ['retriever'] = 10000,
                ['berger'] = 55000,
                ['westie'] = 50000,
                ['chop'] = 12000,
                ['loup'] = 30000,
                ['bunny'] = 8000,
                ['rottweiler'] = 45000
            }

            -- Vérifier si l'animal est valide
            if not validPets[petType] or validPets[petType] ~= price then
                print('[qbx_animal] Invalid pet or price:', petType, price)
                cb(false, 'invalid')
                return
            end

            -- Vérifier l'argent
            if player.Functions.RemoveMoney('cash', price) then
                -- Insérer le nouvel animal
                MySQL.Async.insert('INSERT INTO player_pets (citizenid, pet_type, hunger) VALUES (@citizenid, @pet_type, 100)', {
                    ['@citizenid'] = citizenid,
                    ['@pet_type'] = petType
                }, function(insertId)
                    if insertId then
                        -- Ajouter de la nourriture
                        player.Functions.AddItem(Config.FoodItem, 5)

                        cb(true, 'success')
                    else
                        -- Rembourser l'argent
                        player.Functions.AddMoney('cash', price)
                        cb(false, 'database_error')
                    end
                end)
            else
                cb(false, 'insufficient_funds')
            end
        end)
    end)
end)

-- Mettre à jour la faim
RegisterNetEvent('qbx_animal:updateHunger', function(petType, newHunger)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local citizenid = player.PlayerData.citizenid

    MySQL.Async.execute('UPDATE player_pets SET hunger = @hunger WHERE citizenid = @citizenid AND pet_type = @pet_type', {
        ['@citizenid'] = citizenid,
        ['@pet_type'] = petType,
        ['@hunger'] = newHunger
    })
end)

-- Renommer un animal
RegisterNetEvent('qbx_animal:renamePet', function(petType, newName)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local citizenid = player.PlayerData.citizenid

    if string.len(newName) > 100 then
        newName = string.sub(newName, 1, 100)
    end

    MySQL.Async.execute('UPDATE player_pets SET pet_name = @pet_name WHERE citizenid = @citizenid AND pet_type = @pet_type', {
        ['@citizenid'] = citizenid,
        ['@pet_type'] = petType,
        ['@pet_name'] = newName
    }, function(rowsChanged)
        if rowsChanged > 0 then
            QBCore.Functions.Notify(src, 'Pet renamed to ' .. newName, 'success')
        end
    end)
end)

-- Vendre un animal
RegisterNetEvent('qbx_animal:sellPet', function(petType)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local citizenid = player.PlayerData.citizenid

    local sellPrices = {
        ['chien'] = 25000,
        ['chat'] = 7500,
        ['lapin'] = 12500,
        ['husky'] = 17500,
        ['cochon'] = 5000,
        ['caniche'] = 25000,
        ['carlin'] = 3000,
        ['retriever'] = 5000,
        ['berger'] = 27500,
        ['westie'] = 25000,
        ['chop'] = 6000,
        ['loup'] = 15000,
        ['bunny'] = 4000,
        ['rottweiler'] = 22500
    }

    local sellPrice = sellPrices[petType] or 0

    MySQL.Async.execute('DELETE FROM player_pets WHERE citizenid = @citizenid AND pet_type = @pet_type', {
        ['@citizenid'] = citizenid,
        ['@pet_type'] = petType
    }, function(rowsChanged)
        if rowsChanged > 0 then
            player.Functions.AddMoney('cash', sellPrice)
            QBCore.Functions.Notify(src, 'You sold your ' .. petType .. ' for $' .. sellPrice, 'success')
        else
            QBCore.Functions.Notify(src, 'You don\'t have this pet!', 'error')
        end
    end)
end)

-- Message de démarrage
CreateThread(function()
    Citizen.Wait(1000)
    print('^2========================================^7')
    print('^2      qbx_animal Server Started^7')
    print('^2      Version: 1.0.0 (Multiple Pets)^7')
    print('^2      Max pets per player: ' .. Config.MaxPets .. '^7')
    print('^2      MySQL connected^7')
    print('^2========================================^7')
end)
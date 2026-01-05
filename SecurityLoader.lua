-- UPDATED SECURITY LOADER - Includes EventTeleportDynamic
-- Replace your SecurityLoader.lua with this

local SecurityLoader = {}

-- ============================================
-- CONFIGURATION
-- ============================================
local CONFIG = {
    VERSION = "2.3.0",
    ALLOWED_DOMAIN = "raw.githubusercontent.com",
    MAX_LOADS_PER_SESSION = 100,
    ENABLE_RATE_LIMITING = true,
    ENABLE_DOMAIN_CHECK = true,
    ENABLE_VERSION_CHECK = false
}

-- ============================================
-- OBFUSCATED SECRET KEY
-- ============================================
local SECRET_KEY = (function()
    local parts = {
        string.char(74, 97, 121, 90),
        string.char(71, 85, 73, 95),
        "SuperSecret_",
        tostring(2024),
        string.char(33, 64, 35, 36, 37, 94)
    }
    return table.concat(parts)
end)()

-- ============================================
-- DECRYPTION FUNCTION
-- ============================================
local function decrypt(encrypted, key)
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    encrypted = encrypted:gsub('[^'..b64..'=]', '')
    
    local decoded = (encrypted:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b64:find(x)-1)
        for i=6,1,-1 do 
            r = r .. (f%2^i-f%2^(i-1)>0 and '1' or '0') 
        end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i=1,8 do 
            c = c + (x:sub(i,i)=='1' and 2^(8-i) or 0) 
        end
        return string.char(c)
    end))
    
    local result = {}
    for i = 1, #decoded do
        local byte = string.byte(decoded, i)
        local keyByte = string.byte(key, ((i - 1) % #key) + 1)
        table.insert(result, string.char(bit32.bxor(byte, keyByte)))
    end
    
    return table.concat(result)
end

-- ============================================
-- RATE LIMITING
-- ============================================
local loadCounts = {}
local lastLoadTime = {}

local function checkRateLimit()
    if not CONFIG.ENABLE_RATE_LIMITING then
        return true
    end
    
    local identifier = game:GetService("RbxAnalyticsService"):GetClientId()
    local currentTime = tick()
    
    loadCounts[identifier] = loadCounts[identifier] or 0
    lastLoadTime[identifier] = lastLoadTime[identifier] or 0
    
    if currentTime - lastLoadTime[identifier] > 3600 then
        loadCounts[identifier] = 0
    end
    
    if loadCounts[identifier] >= CONFIG.MAX_LOADS_PER_SESSION then
        warn("⚠️ Rate limit exceeded. Please wait before reloading.")
        return false
    end
    
    loadCounts[identifier] = loadCounts[identifier] + 1
    lastLoadTime[identifier] = currentTime
    
    return true
end

-- ============================================
-- DOMAIN VALIDATION
-- ============================================
local function validateDomain(url)
    if not CONFIG.ENABLE_DOMAIN_CHECK then
        return true
    end
    
    if not url:find(CONFIG.ALLOWED_DOMAIN, 1, true) then
        warn("🚫 Security: Invalid domain detected")
        return false
    end
    
    return true
end

-- ============================================
-- ENCRYPTED MODULE URLS (ALL 28 MODULES)
-- ============================================
local encryptedURLs = {
    instant = "U2FsdGVkX18aMgGLj2FkbeRsQFhDkkZh3vxaFkhWBDLOnlTcBBFskdizVisQugTPtLTBYb+5HeXpJdaFs+sD/4t+84c5i3fECmHdhnSPeAw9UBQ6+oped6X01a5jdvoNqGhj1NzU0ypNfA8TuGi1Ug==",
    instant2 = "U2FsdGVkX1+ZWU0d1Sb6BFKA+TX0JdUZPeR3ZNiTYakT44t4vGnD4c9Al0k4uNcPxN+pyc424vJYjZrfoUyiemvDO7zguPmNcRjUf7LRgDGknST4oX4NZrNbWENJNjgilrHtGv8dFPrQ629fWnAe8lRWDHuvDeJ7486X80kvej8=",
    blatantv1 = "U2FsdGVkX187pNhM4cIp1VWnGrf3V0GyrMYoggvOFVXknWj2beuinB23+KaH61uOqLbqMSB32YffzthAtOkBXWdNLkaVTSm96kw3YbVbuPLufsxJTHJtUb/Ro5x+7A1r3xUsP3XR0RppO58VxjbNm/9Os7cXLmyn2220Lu40Ipo=",
    UltraBlatant = "U2FsdGVkX19gYGW+74zg56HlNyFRywAPni8bt1u/bgROSlTcnxaMte8KFqAjexkRNSQS49zrSuKQg28bfbJjOMA1pOSBTZBhnrB/01xJ/qqy5AJSmJ0+5RfMYd0GEJfm3AoZp1kvYJiTW7au6aneSHGkll8Q60N8ju4BpTAmlRs=",
    blatantv2 = "U2FsdGVkX19ndIeLe2YiHEvWFxaiqf/a2Ikoh3arRFDn3SQgGX3hwxKNadPwcpkJsa54p0VYMlOSLNhhQlDUzHcPdqZKz50Pxl4izZJwqZB4AuuoknROnR4hGuI4/fpXY4+8F1Txkjdxoz4omBBzfL/pZqB0wUomnk6BVcbpCkc=",
    blatantv2fix = "U2FsdGVkX1+cxFIyLQ3pDOzBYiWkavDCCel8BQdfmVOYleF5JiEjNWz33SOgQBSb5Mg3qHpVDh7uD7bzjbW5OEXnQvjJcB+0GmRELI9Lck1CEqfIODUEFvc/wvUiI7QE/yxU3o5pVfg3G3D8nCo77w==",
    NoFishingAnimation = "U2FsdGVkX1+ApiBOHdOPXs5Bdpy+YS8YH2d+Oy2HIMIHL15NJf4SBcxUjq2lWVcVLl4aiUY4nIqTFsKydtenBCqfVufrXjTygXeQERVuTUK4tPbU/j1QVAD0OF+pE/p657UBHjBnQsCsHDfnSLah+v3e+p6h0DzfyXIT5fJV0vw=",
    LockPosition = "U2FsdGVkX1/FIUQHVYyk8h03gvgzy0bDRkOxaUTbXP3Njwsh0wzBexI8P2+3r2ZsZ14zpYWMU90lPrhMpKftURCDTSiMdVGaPunhw4U4Gdr8oaCEK5tdtIUsGpZuGVvmNd6uV8vqEU7+YiAx8LU/1MyFO+cq8DFnDJpNrEUGC5A=",
    AutoEquipRod = "U2FsdGVkX19hD2QA28zccwEMeB2ealKcAtlEy1ge3P0C5GMWUt5JMAtDfj9QnXRvWFGgVmmGVIKG29vVEH61npc21OScOru25mCUDI1vKTTvdGErCy82FKCftxw8hS/7kGKqPP0bUZEdWt2gzXbO/XObcerxUJFJzsXcRThXcdA=",
    DisableCutscenes = "U2FsdGVkX1/wYlKyqAioJ05r/syhZihY4Kt/Cc2EXoGGrCDEgFcRKMwry2FjdU5VCScFRkSRyrbpyMBF6v46CV8QBgKdIfunBcjJ7xdq9q9qR4JZ5uqDdgg69fwo3tEjuWOzKVrZuAZfZk8Mb8ZlRVTEK+8NO6p5RO5B/EG1XgQ=",
    DisableExtras = "U2FsdGVkX18q7GXOTSVgGiL/SgeUR+mMC0DonXI3oRlxPfdyAFuvT2/xMMOpcCPGEYsRIy46EjW0knUJ83Qh/LBVzx45b3AIdLmDXNxh4epzSp49x2kHjgLjmL7jiM+QIGLKBHY07k74S4coqoULE/6yhIKOoeJf7TY61a2+F7o=",
    AutoTotem3X = "U2FsdGVkX1/BdQ1tqUcpuzvOAioNnwgsiTz7cKb2s6V0d+fsVYDso1eFUQQtBj6R5JFGdVaTMEh3jRMvilM9KWRX0ck8kqYXXBeEg2PQlyyohyUg1II4F4ewx89ozMXXwoPRw757+xeFqmiGWoLsbeZwNUnH0FTMPdzA+2I43xo=",
    SkinAnimation = "U2FsdGVkX1/AJMWvLyE1Z1Zabr8cK4egMX2cbrE9lcciah6pOutUZAElDutIVLIGCx8NPWPE6lHmFNVKiN6ZhPUxkdCnd6i4dOuH7bhv0dHLKtjvBD7ocP1DT1ryPqYi5l8LpLhgsHVz0lRDLBfy9GHejrCTJtV9J5CMmXYV4SM=",
    WalkOnWater = "U2FsdGVkX1/MUMtxOCb4Ky5myQQ1lfi6OJLjf0ygt88ytoivk3uuI0MR/ffGdVJDPY/AfJjpvfwws/6hIimWNuHOAR8jL8m1oD1oNha73w4xEeI9WHyhlZwJCV9kY5lIO6/tQm+w2mmJAYf9EaIFN+7lGFIj9WmfV+5osuSU91M=",
    TeleportModule = "U2FsdGVkX1+p01l6vKPLAA4/x4pig/vmKqSQhVOL0waxj06dEefeoTuoZmfV2hkDIPlRwOjjaX6XEyHpQRviuJ8i8k3pF6KQ1ZpK1vfc9vKqqVcfILwUQSiD4Ke8SbQq5bKKwvSWS77s0s3F8TfiDFu8h6La8t1a2KKUNLkHe5Q=",
    TeleportToPlayer = "U2FsdGVkX1+VIn0rw75+xgVrYT7IT9SGe5x2eOfWwnG8J0uui9Q+HN3alGqVum5Y6XTmOKpoi3HRDCWVP1ucQmcfXVbuyYfwQr3qNJn+1gTNI9RGghCcSk6SmIcCcjO0rjzxrQ3FylHVit9aMte0nGUk/Diuh0xFOA+Jm0CkfeVVF6lCdmU7ZzOeKFJXx2iw",
    SavedLocation = "U2FsdGVkX19aw1iBEl1/GhW19q81kksbmRAFXkyPrlBilHJIs8sh7lPUHBQXW25u2y3V4TPsOrq3W0KXlVW3Wj3RhE4yaBr+//k+NQmR9Wehx/t10NRogqf+qGMbPvpdD6MrFLnnB7MkevcEwCID2O6bixVHwtwWSOYfZYiwFjwFeF08WVwjBUwoezGcu+gy",
    AutoQuestModule = "U2FsdGVkX199Nh0ALZ7+PMwXe/DH40EDmPkorrlvILoibhcfLQNnE097mu+hCC9VUJFNl2OoN3apJ3Npe+6FW+vMRShI+4W/jGw4kJ2T73ulRNA7Y5ANktvi0EGrHzbMFXjJ6EKja3OTpq5q43Apgk88/w1K7oJn4xYcsI2QlRw=",
    AutoTemple = "U2FsdGVkX1/y7RsG/WHeoQTdm2nqAXCHSK4/8DoxTop3oc8r0nrkIC+QsyhbNVt5RhG2qD9YoDa2Vwqe+fzXU6Rd9k1NGcBoYwsxuPiJtKqDoSa/AByMxQmugOg7u9nhOiIfRfxoF/iiYVOGi+il6Qxq2cNMTATtGPzuiNrvxcA=",
    TempleDataReader = "U2FsdGVkX18UcGTJGbLMIVwj9yeT9ijwxmN5bh59B6YuOspZ2FZLM5EbID7VyqvcZkGObqy5v5QN+798WQVG0WVlN9ktTVXQNG170KV/dqmQc8HJcerM0GQDOzp/ikhKalYNUFXjiGU7Dm54zL1nGSvN/E55rMPGpstWZr3qYxk=",
    AutoSell = "U2FsdGVkX18kNP5gfMr7L/P+RjaYOo3onkudc8eNa+fNzJa7SE1byJxn+ibywxkv6DVnABRaeTQL4wdCWWDMNaJKV8jlvjUHMNhdT3Nq8QX/2gNMdOwy/SrLlostt1WE8qkVS7coC3CKgnvSctL55lxzMpSrbDMaD//qitgrmxE=",
    AutoSellTimer = "U2FsdGVkX18N4IUSgg4Y9g6n50Z+0Exh8vDwAev5DA7hhZpt9mEBmJT5fjwaf6tIy/Ypoup9IyKvfIh9/UP+sBdVwUX8fAWP2CTUK6bWhCcVkZ5C27faUaxrY1gAaLZrkDg9HKlc4WCy4fikwZWsgoBcAjcw8zPo/0dHdHkQaR0=",
    MerchantSystem = "U2FsdGVkX1/yREETquDz+9bSx7QPWxgyl9uKp4dRdk9m6tUmij1rPRTkwGUZ2azBmTA4hkc+z8wbgejAQujjP4GJNQdrjBgIrQjIxhERQr0zqWAj+aefWyuPkfhxRz3vrotNmF9ctdzvy1QjEAhWiK6Gl08a9S4RXRwQdkP/wwg=",
    RemoteBuyer = "U2FsdGVkX1+pH8M5poFtCSLTg23q7aSqxIz1finkHTW1M9TmqcJszdQv1GHazpgJGGA+bPXwfR9RR7nKhwOxNQ+vutNpyowut8leC60sgm5nFSP+4PrNnkxkr3XeVRTyGSpkoVISh9XbkN0QVd1U/FPEyA/baDPjIWHMcrI5Mqs=",
    FreecamModule = "U2FsdGVkX18v6+64I3H9hUfZ8NIhyZeNzSnMnfwFejubK7blxDhMwcOfJ6RbEmRNO74jqEBQ0n6jFUnJpn16yk7NsES6rMTgxP4IXlS4R9l4osm8FELAS7y0bwP1DfhmhJF+YOF5/iS3cWpAIiUpLYpX4G4IzlTNxwRt8Rf7VRA=",
    UnlimitedZoomModule = "U2FsdGVkX185xjgE/zjChuqUFnnVeYKeO59mMCacrbacY2HQzPYu4lsk2Xaj9TOtJ7XbIA6VUUCwxDdQuHwiv5bIS+X4b3/Oxn0XUWn4K744B6yK2JCU9qEtHDEus7HnKPJD4C36Wfh59oHU8Z7QfYgUBdMuEPwooAH2LgnDxew=",
    AntiAFK = "U2FsdGVkX193mtP6js9EgRpUqfTsugnTA2Yfji/5K1Xqvt3lQXhR9MnFggDjn4NqOK/dUI5EEHTfAI0BM62qO4rUy9e+4LXU15hfLjWUt4iCVPOGYeHHwyJYQC3smr3pYkGEGGr8+6Hi2WW69jI/bJ3Pqx4+8wk5tt1/UwFFcrM=",
    UnlockFPS = "U2FsdGVkX1+xSVy0c55DjRxeDZpCA7+ZbfwIm0n87ULIJzGuT1or0gypqJqL4O0r+GisV/v/3S+fjYeLMI03A5bj2+R3x2g7T8tKzo2eYLvN5dXaeBQs4H55cwPxiWq/iGar6ckqCNXAmRbGc/X4v8m0gl1wVvYakQijMPEgrMc=",
    FPSBooster = "U2FsdGVkX186FHKvN5dXmapbRz4Gp579CTrp+vGn2XkRx/7p8o2uKbYXA6EAl5D5THwtzEa2UvU2Rye76VRE78bLmk8AQK/ObbLMiWtLQUFnnui+7BMD5180LWyXYNB+zaGaOxeHfcjrusmeaL1AWjICKemE7ETkZq8zbY+rD0I=",
    AutoBuyWeather = "U2FsdGVkX1/4wJpnDE79ZLzTBsIld+aS0xQsiaHdS0I+pBfTbkP2JmL+RhNMdm6o8YIKtqJxxVXJw5oFmJgVYsGLcUMh+pvCsFQ0DornPXYO8Lupuo/vk71qWNWlkVqcZ1v7q5d8S4/9uU2bCLSay9Il0OWSxdq8P4FvkPtsmt0=",
    Notify = "U2FsdGVkX1+osKVQOalz8Yg4Af74f5l5v+p4PZu+0sGlgk6E3nko/AJj5tiJ+YPVM3SSwsSeUXCbzKHyLsiMKIwcJtMiMo6euYK0N3aU67/b26Gk6VxIHrNXNCxym7UwR/UXHn0fNI4UM3J9HNB/UjZQHtlfsTNJbnAurBLzuV8=",
    
    -- ✅ NEW: EventTeleportDynamic (ADDED)
    EventTeleportDynamic = "U2FsdGVkX18/6b75sQdSGnTL4wUm72YUKLSF6NJjoA3S2/60nsk/7i1cWeruyzFh2YgTMu65tmaBcw4a9xP9gLgxI+gBa+KWQq+U+mGMIbdbTgmWpahzxjdbqA5YjLxV7INjDOUeXUlcpdAULmRr5Ttk8G259KScbVdT1ZZXjW1ag8Rjbj+VqCdUpGirgSCa",
    
    -- ✅ EXISTING: HideStats & Webhook (already encrypted)
    HideStats = "U2FsdGVkX190HYeQMni5EgB1PqT97iv0B26+pnudBsEZuFWRG6Fm82ERK1BSJYfUD4RmaQqhEUkQbfBvPK89oF2Ghe5RyyrBGsN/2eBoqghk823MNpBuEP26y40wo/mUBxHlbHfeQcNo6tpiJkR/XDhnTh+FZdC3V1w0St33sD8=",
    Webhook = "U2FsdGVkX1+U1hqDkau9TEM8m1iy05PHMaR0h4LWGslxVXJrm5Q/UmjirQdbeyfDgM84vChHlGhiny8/qCEmdxoGuZ6FqQTnQ+9l852Ub8MBvlXpQod48/XUiXmiRlS1y7cPNRqcTHLHRJW2U+gvVK10lx+qo/HJfyyvRCTA4cc=",
    GoodPerfectionStable = "U2FsdGVkX1/qxYLFeTnNxki6RCe/Xkl/1Qr0Fp7mkGw8JyTrq640ey+KcfNLJmrKbeaqnfN+ba8/p6hPsTFhYiCqSNt5MrOIQny/Cp2HX++R/cO0bCNUgwxlkAhILx2MPAWZK8krsU6G1amnV011vIlco+/TACYnkVIkyvK4WEE=",
    DisableRendering = "U2FsdGVkX1+oNQLkfbX9wF3dVaYDVb27VRXKL2Hc/exADiohueaK6lZWzBOQ0bl8IMZ075ZdiLFJv5n0pO6jMu/JtKcMZxpj6PqEqMlKaXAve2vHd6QkHRkbsGrLkEu0AEmQch69PdQeJ6ghVL0YuSxTOKa2WtEgMI/0wiRUgmM=",
    AutoFavorite = "U2FsdGVkX1/dMz8h8VAL/7ywt4DOuKWsHb/YmWBAHHRSuUxktJl17ELdUqp92PkOMhrRPLQFm6osF93eQfoRbj/PHAwR9YzPuBNojcfYmeqgtXOFloeQwB9aGLXRqTMlKGcfO/fDmQzLQGuNTK+50Hmnxceqzz2Jq5/5shZtEEI=",
}

-- ============================================
-- LOAD MODULE FUNCTION
-- ============================================
function SecurityLoader.LoadModule(moduleName)
    if not checkRateLimit() then
        return nil
    end
    
    local encrypted = encryptedURLs[moduleName]
    if not encrypted then
        warn("❌ Module not found:", moduleName)
        return nil
    end
    
    local url = decrypt(encrypted, SECRET_KEY)
    
    if not validateDomain(url) then
        return nil
    end
    
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if not success then
        warn("❌ Failed to load", moduleName, ":", result)
        return nil
    end
    
    return result
end

-- ============================================
-- ANTI-DUMP PROTECTION (COMPATIBLE VERSION)
-- ============================================
function SecurityLoader.EnableAntiDump()
    local mt = getrawmetatable(game)
    if not mt then 
        warn("⚠️ Anti-Dump: Metatable not accessible")
        return 
    end
    
    local oldNamecall = mt.__namecall
    
    -- Check if newcclosure is available
    local hasNewcclosure = pcall(function() return newcclosure end) and newcclosure
    
    local success = pcall(function()
        setreadonly(mt, false)
        
        local protectedCall = function(self, ...)
            local method = getnamecallmethod()
            
            if method == "HttpGet" or method == "GetObjects" then
                local caller = getcallingscript and getcallingscript()
                if caller and caller ~= script then
                    warn("🚫 Blocked unauthorized HTTP request")
                    return ""
                end
            end
            
            return oldNamecall(self, ...)
        end
        
        -- Use newcclosure if available, otherwise use regular function
        mt.__namecall = hasNewcclosure and newcclosure(protectedCall) or protectedCall
        
        setreadonly(mt, true)
    end)
    
    if success then
        print("🛡️ Anti-Dump Protection: ACTIVE")
    else
        warn("⚠️ Anti-Dump: Failed to apply (executor limitation)")
    end
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
function SecurityLoader.GetSessionInfo()
    local info = {
        Version = CONFIG.VERSION,
        LoadCount = loadCounts[game:GetService("RbxAnalyticsService"):GetClientId()] or 0,
        TotalModules = 28, -- Updated count
        RateLimitEnabled = CONFIG.ENABLE_RATE_LIMITING,
        DomainCheckEnabled = CONFIG.ENABLE_DOMAIN_CHECK
    }
    
    print("━━━━━━━━━━━━━━━━━━━━━━")
    print("📊 Session Info:")
    for k, v in pairs(info) do
        print(k .. ":", v)
    end
    print("━━━━━━━━━━━━━━━━━━━━━━")
    
    return info
end

function SecurityLoader.ResetRateLimit()
    local identifier = game:GetService("RbxAnalyticsService"):GetClientId()
    loadCounts[identifier] = 0
    lastLoadTime[identifier] = 0
    print("✅ Rate limit reset")
end

print("━━━━━━━━━━━━━━━━━━━━━━")
print("🔒 JayZ Security Loader v" .. CONFIG.VERSION)
print("✅ Total Modules: 28 (EventTeleport added!)")
print("✅ Rate Limiting:", CONFIG.ENABLE_RATE_LIMITING and "ENABLED" or "DISABLED")
print("✅ Domain Check:", CONFIG.ENABLE_DOMAIN_CHECK and "ENABLED" or "DISABLED")
print("━━━━━━━━━━━━━━━━━━━━━━")

return SecurityLoader

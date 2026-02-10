--                   ▩▩▩▩▩▩▩▩▩▩▩▩▩▩▩▩▩▩▩              
--                     ▩▩▩▩▩▩▩▩▩▥▥▥▥▥▥▥▥▩▩            
--                        ▩▩  ▩▩▩▥▥▥▥||■⩑■▮|▥▥▩▩▩▩     
--                   ▩▩▩    ▩▩▩  ▩▥▥▥▥\⩣/▥▩▩▩▩▩▩▩
--                        ▩▩▩▩  ▩▩▩▩▥▥▥▥▥▥▩▩▩  ▩▩
--                     ▩▩▩▩  ▩▩▩▩▩▩▩▩▩          ▩   
--                           ▩▩▩▩▩▩▩▩▩
--
-- ▩▩▩▩▩ ▩▩▩▩▩  ▩▩      ▩▩        ▩     |▩▩   ▩ |▩▩▩ ▩       ▩
-- ▩▩     ▩▩    ▩  ▩▩      ▩▩      ▩  ▩   |▩ ▩  ▩   ▩|  ▩▩|   ▩▩
-- ▩▩     ▩▩    ▩  ▩▩      ▩▩     ▩|  |▩  |▩   ▩▩   ▩|  ▩  ▩▩  ▩
-- ▩▩▩▩▩ ▩▩▩▩▩  ▩▩▩▩▩ ▩▩▩▩▩ ▩▩▩▩▩  ▩▩   ▩▩ ▩▩▩ ▩       ▩
-- ===================== Brought to you by: PrezzyCh =====================
---@version 0.1.0
---@module "Collate Animation Library <0.1.0>"
---
--Checkers==========================================================================================

local GSAnimBlend = pcall(require, "GSAnimBlend")
if GSAnimBlend then require("GSAnimBlend") end

--Globals===========================================================================================

local animSetTable = {}
local CollateAnims = {} -- Used for class shinanegans
CollateAnims.__index = CollateAnims

-- =================================================================================================
-- Debugging functions
-- =================================================================================================
-- Due to the beta this library is in, you are free to use these debug functions to help in the bug
-- reporting process!

function CollateAnims:dbgPrintArr() 
    print("[=======".. self.name .."=====]")
    for i, value in pairs(self.arr) do
        print(i:getName() .. " + " .. tostring(value))
    end
    print("[=================================]")
end

--- Debugging function that prints out all identified animation sets.
function CollateAnims.dbgPrintAllSets() 
    print("[========All Identified Anims=====]")
    for index, value in pairs(animSetTable) do
        print("|- " .. index)
    end
    print("[=================================]")
end

-- =================================================================================================
-- Local Helpers
-- =================================================================================================
local function setAnims(name, blendIn, blendOut)
    local allAnimsTbl = animations:getAnimations()
    local result = {}
    
    --gets all animations, if it matches the set names, add it to the result.
    for i, value in ipairs(allAnimsTbl) do
        if string.match(value:getName(), "^" .. name .. "_") then
            result[value] = true

            --Sets blend time to each animation that matches.
            if GSAnimBlend then
                blendIn = blendIn or 0
                blendOut = blendOut or 0  
                value:setBlendTime(blendIn, blendOut)
            end
        end
    end

    return result;
end

-- Private version of `setPlayingSelect` that does not call resetPriority.
local function resetAnim(anim, state, arr) 
    anim:setPlaying(state and arr[anim])
end

-- Resets the priority for the entire animation set
local function resetSetPriority(arr)
    for i in pairs(arr) do
        arr[i] = true
    end
end

-- Resets the priority for a single animation
local function resetPriority(setArr, anim)
    setArr[anim] = true
end

-- Checks if any of the animations in the animation set is playing
local function checkPlaying(setArr)
    for i in pairs(setArr) do
        if i:isPlaying() then
            return true
        end
    end
    return false
end

--- Checks the priority of the two inputted animation by grabbing the anim set associated to
--- each animation and checking the priority of the set.
local function modPriorities(animA, animB)
    local animASetName = string.match(animA:getName(), "^(.-)_")
    local animBSetName = string.match(animB:getName(), "^(.-)_")
    local animSetTableA = animSetTable[animASetName]
    local animSetTableB = animSetTable[animBSetName]
    local animASetPriority = animSetTableA:getPriority()
    local animBSetPriority = animSetTableB:getPriority()
    
    if animASetPriority > animBSetPriority then 
        animSetTableB.arr[animB] = false
        resetAnim(animB, animB:isPlaying(), animSetTableB.arr) -- Allows the animation to update
    end
    if animBSetPriority > animASetPriority then 
        animSetTableA.arr[animA] = false
        resetAnim(animA, animA:isPlaying(), animSetTableA.arr)
    end
end

--- Checks the priority of each active animation and setting each `arr` to the according
--- override.
--- 
--- Where if a priority is greater, then it will set the lower priority animation override to
--- false. If priority is equal, both animations will play.
-- local function priorityCheck(arr) 
--     local allAnimsTbl = animations:getPlaying()
--     local currAnim = arr
--     for _, animB in ipairs(allAnimsTbl) do
--         local nameB = string.match(animB:getName(), "_(.-)$")
--         for animA in pairs(currAnim) do
--             local nameA = string.match(animA:getName(), "_(.-)$")
--             if (nameA == nameB) then
--                 modPriorities(animA, animB)
--             end
--         end
--     end
-- end

function CollateAnims.priorityCheck() 
    local allAnimsTbl = animations:getPlaying()
    -- Goes through checking each animation to each.
    for i = 1, #allAnimsTbl, 1 do
        local animAName = string.match(allAnimsTbl[i]:getName(), "_(.-)$")
        for j = i + 1, #allAnimsTbl, 1 do
            local animBName = string.match(allAnimsTbl[j]:getName(), "_(.-)$")
            if animAName == animBName then
                modPriorities(allAnimsTbl[i], allAnimsTbl[j])
            end
        end
    end
end

-- =================================================================================================
-- Public Functions
-- =================================================================================================

--- Creates a new animation set with the `name`, `priority`, and `blendIn`/`blendOut` 
--- for GSAnimBlend blending.
--- 
--- Default value for `priority` is 0
--- @generic self
--- @param name string
--- @param priority number
--- @param blendIn number
--- @param blendOut number
--- @return self
function CollateAnims:newSet(name, priority, blendIn, blendOut)
    priority = priority or 0
    if not GSAnimBlend and (blendIn or blendOut) then
        error("GSAnim is not loaded, but blendIn or blendOut values have been filled!")
    end
    local metaTable = setmetatable({name = name, -- String name of set
                                    priority = priority, -- Int priority of set
                                    arr = setAnims(name, blendIn, blendOut)}, -- All anims of this 
                                                    --set, where [Animation key, Boolean override] 
                                    self)
    animSetTable[name] = metaTable
    return metaTable
end

--Anim Methods======================================================================================

--- Sets and updates the animation state of the animation set.
--- 
--- Until updated, the animation will continue to play. This will also reset 
--- priority overrides.
--- @generic self
--- @param state boolean
function CollateAnims:setPlayingAnim(state) 
    resetSetPriority(self.arr); -- Reset priority to the specified set 
    for i, value in pairs(self.arr) do
        i:setPlaying(state and value)
    end
    --if state then priorityCheck(self.arr) end
end

--- Plays and the animation set.
--- 
--- The animation will play until the end of the animation.
--- @generic self
function CollateAnims:playAnim()
    resetSetPriority(self.arr);
    for i in pairs(self.arr) do
        i:play()
    end
    --priorityCheck(self.arr)
end

--- Stops the animation set.
--- @generic self
function CollateAnims:stopAnim()
    for i in pairs(self.arr) do
        i:stop()
    end
end

--- Plays a specific animation within an animation set. 
--- 
--- Until updated, the animation will continue to play.
--- @generic self
--- @param anim Animation
--- @param state boolean
function CollateAnims:setPlayingSelectAnim(anim, state)
    -- Uses the animation
    resetPriority(self.arr, anim)
    anim:setPlaying(state and self.arr[anim])
    --if state then priorityCheck(self.arr) end
end

--- Plays a specific animation within an animation set.
--- 
--- The animation will play until the end of the animation.
--- @generic self
--- @param anim Animation
function CollateAnims:playSelectAnim(anim)
    resetPriority(self.arr, anim);
    anim:play()
    --priorityCheck(self.arr)
end


--Getters/Setters===================================================================================

--- Gets the animation set name.
--- @generic self
--- @return string
function CollateAnims:getName() 
    return self.name
end

--- Gets the animation set priority. 
--- @generic self
--- @return number
function CollateAnims:getPriority()
    return self.priority
end

--- Sets the animation set priority.
--- @generic self
--- @param priority number
function CollateAnims:setPriority(priority)
    self.priority = priority
end

--- Checks if any of the animations in the animation set is currently playing.
--- If any one animation is playing, it will return `true`, and `false` otherwise.
--- @generic self
--- @return boolean
function CollateAnims:isPlaying() 
    return checkPlaying(self.arr)
end

--- Sets the speed of the animation set and all of it's animations.
--- @generic self
--- @param speed number
function CollateAnims:setSpeed(speed)
    for i in pairs(self.arr) do
        i:setSpeed(speed)
    end
end

-- =================================================================================================
-- Documentation - Fields
-- =================================================================================================

---@class CollateAnims
---Main table containing an Animation as a key and a override boolean
---@field arr table<Animation, boolean>
---Name of the animation set
---@field name string 
---The priority of the set that can be greater than or equal to 0
---@field priority number 
---Contains the animation name as a key and the metatable of an AnimationSet.
---@field animSetTable table<string, metatable>

return CollateAnims

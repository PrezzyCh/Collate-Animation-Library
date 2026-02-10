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

local queue = {}
local playingQueue = {}
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
    for index in pairs(animSetTable) do
        print("|- " .. index)
    end
    print("[=================================]")
end

--- Prints the animation queue that will activate all anims.
function CollateAnims.dbgPrintQueue()
    print("[==============Queue==============]")
    for index, value in pairs(queue) do
        print("|- " .. index:getName())
    end
    print("[=================================]")
end
-- =================================================================================================
-- Local Helpers
-- =================================================================================================
-- Grabs similar name animations and adds them to an animationSet tbl
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

-- Resets the priority for all anims from the inputted table
local function resetPriority(arr)
    for key, value in pairs(arr) do
        local animSet = animSetTable[value]
        animSet.arr[key] = true
    end
end

-- Plays all animations from the inputted table, checking their values.
-- The inputted arr must be of <Animation, string> where string is the AnimationSet name
local function playQueue(queue, animSetTable)
    for anim, value in pairs(queue) do
        local animSet = animSetTable[value]
        if animSet.arr[anim] then
            anim:play() --Play to just play it, prevents shinanegans with loops.
        end
    end
end

--Syncs a playing queue 
local function syncQueue(playingQueue)
    local playing = animations:getPlaying()
    for _, anim in ipairs(playing) do
        if playingQueue[anim] == null then
            playingQueue[anim] = string.match(anim:getName(), "^(.-)_")
        end
    end
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

-- Checks queues, if overrriden, queueA will not be changed
local function compareQueues(queueA, queueB, override)
    for animA, valueA in pairs(queueA) do -- Contains the animations and the animation's AnimationSet name as value
        local animAName = string.match(animA:getName(), "_(.-)$") --Gets the aftward name ie. armL or armR
        for animB, valueB in pairs(queueB) do
            local animBName = string.match(animB:getName(), "_(.-)$")
            if valueA ~= valueB and animAName == animBName then
                local animSetA = animSetTable[valueA] --Gets the metatable thus the set itself
                local animSetB = animSetTable[valueB]
                local animAPriority = animSetA:getPriority()
                local animBPriority = animSetB:getPriority()

                if animAPriority > animBPriority then 
                    animSetB.arr[animB] = false;
                    animB:stop() -- Stops animation if it's already playing
                end
                if animBPriority > animAPriority then 
                    if not override then -- Prevents queueA from being changed
                        animSetA.arr[animA] = false;
                        animA:stop() 
                    end
                end
            end
        end
    end 
end

-- =================================================================================================
-- Public Functions
-- =================================================================================================

--- Checks the priority of each active animation and setting each `arr` to the according
--- override.
--- 
--- Where if a priority is greater, then it will set the lower priority animation override to
--- false. If priority is equal, both animations will play.
function CollateAnims.priorityCheck() 
    resetPriority(queue)
    syncQueue(playingQueue)
    compareQueues(queue, queue) --Comparing to the rest of the animations
    compareQueues(playingQueue, queue, true) --Comparing playing animations
    playQueue(queue, animSetTable)
    queue = {} --Empties the queue
    playingQueue = {}
end

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
function CollateAnims:setPlaying(state) 
    if (state) then
        for anim in pairs(self.arr) do
            queue[anim] = self.name
        end
    else 
        self:stop()
    end
end

--- Plays and the animation set.
--- 
--- The animation will play until the end of the animation.
--- @generic self
function CollateAnims:play()
    for anim in pairs(self.arr) do
        queue[anim] = self.name
    end
end

--- Stops the animation set.
--- @generic self
function CollateAnims:stop()
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
function CollateAnims:setPlayingSelect(anim, state)
    --Add exception
    if state then
        queue[anim] = self.name
    else 
        anim:stop()
    end
end

--- Plays a specific animation within an animation set.
--- 
--- The animation will play until the end of the animation.
--- @generic self
--- @param anim Animation
function CollateAnims:playSelect(anim)
    --Add exception
    queue[anim] = self.name
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
---Contains the animation as the key and the string of the AnimationSet pertaining to the animation queued to play.
---@field queue table<Animation, string>
return CollateAnims

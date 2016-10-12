local n_name, FSH = ...

local config = {
    key = 'NeP_fishingBot',
    profiles = true,
    title = n_name,
    subtitle = 'Settings',
    width = 250,
    height = 310,
    config = {
        { type = 'header', text = 'Fishing Bot', size = 25, align = 'Center'},
        { type = 'text', text = FSH.Version, align = 'Center'},
        { type = 'text', text = '|cfffd1c15[Warning]|r Requires A Supported Unlocker', align = 'Center' },
        -- [[ Settings ]]
        { type = 'rule' },{ type = 'spacer' },
            { type = 'dropdown', text = 'Bait:', key = 'bait', width = 170, list = {
                {text = 'None', key = 'none'},  
                {text = 'Jawless Skulker', key = 'jsb'},
                {text = 'Fat Sleeper', key = 'fsb'},
                {text = 'Blind Lake Sturgeon', key = 'blsb'},
                {text = 'Fire Ammonite', key = 'fab'},
                {text = 'Sea Scorpion', key = 'ssb'},
                {text = 'Abyssal Gulper Eel', key = 'ageb'},
                {text = 'Blackwater Whiptail', key = 'bwb'},
            }, default = 'none' },
            { type = 'checkbox', text = 'Use Fishing Hat', key = 'FshHat', default = true },
            { type = 'checkbox', text = 'Use Fishing Poles', key = 'FshPole', default = true },
            { type = 'checkbox', text = 'Use Fish Hooks', key = 'ApplyFishHooks', default = true },
            { type = 'checkbox', text = 'Use Bladebone Hooks', key = 'BladeBoneHook', default = false },
            {  type = 'checkbox',  text = 'Destroy Lunarfall Carp', key = 'LunarfallCarp', default = false },
        -- [[ Timer ]]
            { type = 'rule' },{ type = 'spacer' },
            { type = 'text', text = 'Running For: ', size = 11, offset = -11 },
            { key = 'current_Time', type = 'text', text = '...', size = 11, align = 'right', offset = 0 },
            -- Looted Items Counter
            { type = 'text', text = 'Looted Items: ', size = 11, offset = -11 },
            { key = 'current_Loot', type = 'text', text = '...', size = 11, align = 'right', offset = 0 },
            -- Predicted Average Items Per Hour
            { type = 'text', text = 'Average Items Per Hour: ', size = 11, offset = -11 },
            { key = 'current_average', type = 'text', text = '...', size = 11, align = 'right', offset = 0 },
        -- [[ Start Button ]]
        { type = 'spacer' },
            { type = 'button', text = 'Start Fishing', width = 230, height = 20, callback = function(self, button)
                -- Required APIS
                if InteractUnit and ObjectField then
                    SetOffsets()
                    if OBJECT_BOBBING_OFFSET and OBJECT_CREATOR_OFFSET then
                        if _fishRun then
                            self:SetText('Start Fishing')
                            JumpOrAscendStart() -- Jump to stop channeling.
                            equipNormalGear()
                            _timeStarted = nil
                        else
                            self:SetText('Stop Fishing')
                            local currentTime = GetTime()
                            _timeStarted = currentTime
                            _Lootedcounter = 0
                        end
                        _fishRun = not _fishRun
                    else
                        error('Failed to find the offsets')
                    end
                else
                    error('Your unlocker is not supported!')
                end
            end},
    }   
}

FSH.GUI = NeP.Interface:BuildGUI(config)
NeP.Interface:Add(n_name..' v:'..FSH.Version, function() FSH.GUI:Show() end)
FSH.GUI:Hide()
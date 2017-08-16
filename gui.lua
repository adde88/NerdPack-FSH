local n_name, FSH = ...

local config = {
    key = n_name,
    profiles = true,
    title = n_name,
    subtitle = 'Settings',
    width = 250,
    height = 250,
    config = {
        { type = 'header', text = n_name..' |r'..FSH.Version, size = 25, align = 'CENTER'},
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
            { type = 'text', text = 'Running For: ', size = 11, offset = 0 },
            { key = 'current_Time', type = 'text', text = '...', size = 11, align = 'right' },
            -- Looted Items Counter
            { type = 'text', text = 'Looted Items: ', size = 11, offset = 0 },
            { key = 'current_Loot', type = 'text', text = '...', size = 11, align = 'right' },
            -- Predicted Average Items Per Hour
            { type = 'text', text = 'Average Items Per Hour: ', size = 11, offset = 0 },
            { key = 'current_average', type = 'text', text = '...', size = 11, align = 'right' },
        -- [[ Start Button ]]
        { type = 'spacer' },
            { type = 'button', text = 'Start Fishing', width = 230, height = 20, callback = function(val) FSH:Start(val) end},
    }
}

FSH.GUI = NeP.Interface:BuildGUI(config)
NeP.Interface:Add(n_name..' v:'..FSH.Version, function() FSH.GUI.parent:Show() end)
FSH.GUI.parent:Hide()

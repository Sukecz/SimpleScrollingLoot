local addonName, ns = ...

ns.Defaults = {
    version = 2,
    enabled = true,
    minQuality = 1,
    showItems = true,
    showMoney = false,
    showHonor = false,
    showVendorValue = false,
    showQuantity = true,
    showIcons = true,
    showBackground = true,
    backgroundOpacity = 0.2,
    backgroundRounded = false,
    direction = "UP",
    staticMode = false,
    duration = 3.5,
    fadeDuration = 1.2,
    travelDistance = 190,
    maxVisible = 5,
    iconSize = 30,
    fontSize = 18,
    rowSpacing = 1,
    scale = 1.0,
    anchor = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 120,
    },
    lootFrameMode = "DEFAULT", -- "DEFAULT", "HIDE_AUTO", "ALWAYS_HIDE"
    lootFrameBypassModifier = "SHIFT", -- "SHIFT", "CTRL", "ALT"
    debug = false,
}

ns.ValidationRanges = {
    minQuality = { min = 0, max = 5 },
    duration = { min = 0.5, max = 20.0 },
    fadeDuration = { min = 0.1, max = 5.0 },
    travelDistance = { min = 10, max = 500 },
    maxVisible = { min = 1, max = 20 },
    iconSize = { min = 12, max = 64 },
    fontSize = { min = 8, max = 32 },
    rowSpacing = { min = 0, max = 50 },
    scale = { min = 0.5, max = 3.0 },
    backgroundOpacity = { min = 0.0, max = 1.0 },
}

local addonName, ns = ...

ns.Defaults = {
    version = 2,
    enabled = true,
    minQuality = 0,
    showItems = true,
    showMoney = true,
    showHonor = true,
    showVendorValue = true,
    showQuantity = true,
    showIcons = true,
    showBackground = false,
    backgroundOpacity = 0.35,
    backgroundRounded = false,
    direction = "UP",
    staticMode = false,
    duration = 4.0,
    fadeDuration = 0.8,
    travelDistance = 90,
    maxVisible = 6,
    iconSize = 24,
    fontSize = 14,
    rowSpacing = 4,
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

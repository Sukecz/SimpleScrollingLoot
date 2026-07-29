local function ReadFile(path)
    local file = assert(io.open(path, "r"))
    local contents = file:read("*a")
    file:close()
    return contents
end

local options = ReadFile("Options.lua")
local locale = ReadFile("Locales/enUS.lua")

assert(options:find('TAB_GENERAL', 1, true), "options must provide simple page navigation")
assert(options:find('TAB_APPEARANCE', 1, true), "options must include an appearance page")
assert(options:find('TAB_MOVEMENT', 1, true), "options must include a movement and position page")
assert(options:find('TAB_ADVANCED', 1, true), "options must keep technical controls separate")
assert(options:find('CreateDescription', 1, true), "controls must support always-visible descriptions")
assert(options:find('QUALITY_ALL', 1, true), "quality selection must use named choices")
assert(options:find('RefreshDependencies', 1, true), "irrelevant controls must be visually disabled")

assert(locale:find('OPT_MOVE_NOTIFICATIONS = "Move Notifications"', 1, true),
    "user-facing position control must avoid anchor jargon")
assert(locale:find('OPT_FINISH_MOVING = "Finish Moving"', 1, true),
    "moving mode must have a clear completion action")
assert(locale:find('OPT_SAVE_POSITION = "Save"', 1, true),
    "the standalone moving mode must have a concise save action")
assert(options:find("SimpleScrollingLootSavePositionButton", 1, true),
    "moving mode must provide a standalone save button")
assert(options:find("frame:Hide%(%s*%)%s+ns%.NotificationManager%.UnlockAnchor%(%s*%)"),
    "settings must close before the notification anchor is unlocked")
assert(options:find("ns%.NotificationManager%.LockAnchor%(%s*%)%s+if optionsWindowFrame then%s+optionsWindowFrame:Show%(%s*%)"),
    "saving the notification position must lock the anchor and reopen settings")
assert(options:find('previewButton:SetPoint%("BOTTOMRIGHT", frame, "BOTTOMRIGHT", %-28, 60%)'),
    "preview must occupy its own row above the bottom-right close action")
assert(options:find('closeButton:SetPoint%("BOTTOMRIGHT", frame, "BOTTOMRIGHT", %-28, 24%)'),
    "close must remain on the bottom row below preview")
assert(locale:find('QUALITY_UNCOMMON = "|cff1eff00Uncommon or better|r"', 1, true),
    "quality choices must be named and color coded")
assert(not locale:find('OPT_ROW_OPACITY = "Row Opacity"', 1, true),
    "technical row opacity wording must not return")

print("Options usability tests passed")

-- Headless unit test for modules/SetCollectionData.lua.
-- Run from the GamePadHelper dir:  lua5.1 tests/SetCollectionData_test.lua
-- Stubs the ESO globals the data module calls.

-- ---- ESO constant stubs ----
LINK_STYLE_DEFAULT = 0
ITEM_TRAIT_TYPE_NONE = 0
SI_GPH_TOOLTIP_SET_COLLECTION_COLLECTED = "collected"
SI_GPH_TOOLTIP_SET_COLLECTION_MISSING = "missing"

local EQUIP_LABELS = {
    [1] = "Head", [2] = "Chest", [3] = "Shoulders", [4] = "Hands",
    [5] = "Waist", [6] = "Legs", [7] = "Feet", [8] = "Neck", [9] = "Ring",
}

function GetString(prefixOrId, value)
    if prefixOrId == "SI_EQUIPTYPE" then
        return EQUIP_LABELS[value] or ""
    end
    return prefixOrId -- the word ids are stubbed to their own text above
end

-- ---- fixture-driven API stubs ----
local DB = {}            -- setId -> { total, collected, unperfected, pieces = { {pieceId, slot, equip, unlocked}, ... } }
local PIECE_EQUIP = {}   -- pieceId -> equipType

local function installFixture(setId, fixture)
    DB[setId] = fixture
    for _, p in ipairs(fixture.pieces or {}) do
        PIECE_EQUIP[p.pieceId] = p.equip
    end
end

function GetNumItemSetCollectionPieces(setId)
    return (DB[setId] and DB[setId].total) or 0
end
function GetNumItemSetCollectionSlotsUnlocked(setId)
    return (DB[setId] and DB[setId].collected) or 0
end
function GetItemSetCollectionPieceInfo(setId, i)
    local p = DB[setId] and DB[setId].pieces[i]
    if not p then return nil end
    return p.pieceId, p.slot
end
function IsItemSetCollectionSlotUnlocked(setId, slot)
    for _, p in ipairs(DB[setId].pieces) do
        if p.slot == slot then return p.unlocked end
    end
    return false
end
function GetItemSetCollectionPieceItemLink(pieceId)
    return "link:" .. tostring(pieceId)
end
function GetItemLinkEquipType(link)
    return PIECE_EQUIP[tonumber(link:match("link:(%d+)"))]
end
function GetItemSetUnperfectedSetId(setId)
    return (DB[setId] and DB[setId].unperfected) or 0
end

-- ---- load module under test ----
dofile("modules/SetCollectionData.lua")
local M = _G["GPH_SetCollection"]

-- ---- assertions ----
local function assertEq(got, want, msg)
    if got ~= want then
        error(string.format("FAIL: %s\n  got:  %s\n  want: %s", msg, tostring(got), tostring(want)), 2)
    end
end

-- partial: 6/9, missing Head/Hands/Legs (slots 1,4,6 locked)
installFixture(100, {
    total = 9, collected = 6, pieces = {
        { pieceId = 1, slot = 1, equip = 1, unlocked = false },
        { pieceId = 2, slot = 2, equip = 2, unlocked = true },
        { pieceId = 3, slot = 3, equip = 3, unlocked = true },
        { pieceId = 4, slot = 4, equip = 4, unlocked = false },
        { pieceId = 5, slot = 5, equip = 5, unlocked = true },
        { pieceId = 6, slot = 6, equip = 6, unlocked = false },
        { pieceId = 7, slot = 7, equip = 7, unlocked = true },
        { pieceId = 8, slot = 8, equip = 8, unlocked = true },
        { pieceId = 9, slot = 9, equip = 9, unlocked = true },
    },
})
assertEq(M.BuildProgressLine(100, "Vicecanon of Venom"),
    "Vicecanon of Venom — 6/9 collected — missing: Head, Hands, Legs",
    "partial line")

-- complete: 7/7, no missing clause
installFixture(200, {
    total = 7, collected = 7, pieces = {
        { pieceId = 21, slot = 1, equip = 1, unlocked = true },
        { pieceId = 22, slot = 2, equip = 2, unlocked = true },
        { pieceId = 23, slot = 3, equip = 3, unlocked = true },
        { pieceId = 24, slot = 4, equip = 4, unlocked = true },
        { pieceId = 25, slot = 5, equip = 5, unlocked = true },
        { pieceId = 26, slot = 6, equip = 6, unlocked = true },
        { pieceId = 27, slot = 7, equip = 7, unlocked = true },
    },
})
assertEq(M.BuildProgressLine(200, "Hist Bark"), "Hist Bark — 7/7 collected", "complete line")

-- no collection: total 0 -> nil
installFixture(300, { total = 0, collected = 0, pieces = {} })
assertEq(M.BuildProgressLine(300, "Nope"), nil, "no-collection line is nil")

-- dedupe: two missing pieces with same equip label -> label once
installFixture(400, {
    total = 2, collected = 0, pieces = {
        { pieceId = 41, slot = 1, equip = 9, unlocked = false },
        { pieceId = 42, slot = 2, equip = 9, unlocked = false },
    },
})
assertEq(M.BuildProgressLine(400, "Foo"), "Foo — 0/2 collected — missing: Ring", "dedupe missing labels")

-- ResolveCollectionSetId: direct
installFixture(600, { total = 3, collected = 0, pieces = {} })
assertEq(M.ResolveCollectionSetId(600), 600, "resolve direct")
-- ResolveCollectionSetId: perfected falls back to unperfected
installFixture(500, { total = 0, collected = 0, unperfected = 501, pieces = {} })
installFixture(501, { total = 5, collected = 0, pieces = {} })
assertEq(M.ResolveCollectionSetId(500), 501, "resolve unperfected fallback")
-- ResolveCollectionSetId: neither -> nil
installFixture(700, { total = 0, collected = 0, unperfected = 0, pieces = {} })
assertEq(M.ResolveCollectionSetId(700), nil, "resolve none -> nil")

print("ALL PASS")

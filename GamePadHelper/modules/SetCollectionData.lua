-- Pure data/formatting helpers for the set-collection container tooltip.
-- No event or UI dependencies at load time, so it can be unit-tested headless
-- (see tests/SetCollectionData_test.lua). All ESO API access is via globals.

local GPH_SetCollection = {}
_G["GPH_SetCollection"] = GPH_SetCollection

-- If setId has no item-set collection but is a perfected set, fall back to its
-- unperfected set id. Returns the setId whose collection should be queried, or
-- nil if neither has a collection.
function GPH_SetCollection.ResolveCollectionSetId(setId)
    if not setId or setId <= 0 then return nil end
    if GetNumItemSetCollectionPieces(setId) > 0 then
        return setId
    end
    local unperfected = GetItemSetUnperfectedSetId(setId)
    if unperfected and unperfected > 0 and GetNumItemSetCollectionPieces(unperfected) > 0 then
        return unperfected
    end
    return nil
end

-- Ordered, de-duplicated list of localized slot labels for the pieces of setId
-- that are NOT yet unlocked.
function GPH_SetCollection.GetMissingSlotLabels(setId)
    local labels = {}
    local seen = {}
    local total = GetNumItemSetCollectionPieces(setId)
    for i = 1, total do
        local pieceId, slot = GetItemSetCollectionPieceInfo(setId, i)
        if pieceId and not IsItemSetCollectionSlotUnlocked(setId, slot) then
            local link = GetItemSetCollectionPieceItemLink(pieceId, LINK_STYLE_DEFAULT, ITEM_TRAIT_TYPE_NONE)
            local equipType = link and GetItemLinkEquipType(link)
            local label = equipType and GetString("SI_EQUIPTYPE", equipType)
            if label and label ~= "" and not seen[label] then
                seen[label] = true
                labels[#labels + 1] = label
            end
        end
    end
    return labels
end

-- Builds the tooltip line, e.g. "Vicecanon of Venom — 4/9 collected — missing: Head, Hands".
-- Returns nil if the set has no collection (total <= 0).
function GPH_SetCollection.BuildProgressLine(setId, setName)
    local total = GetNumItemSetCollectionPieces(setId)
    if not total or total <= 0 then return nil end
    local collected = GetNumItemSetCollectionSlotsUnlocked(setId)
    local line = string.format("%s — %d/%d %s",
        setName, collected, total, GetString(SI_GPH_TOOLTIP_SET_COLLECTION_COLLECTED))
    if collected < total then
        local labels = GPH_SetCollection.GetMissingSlotLabels(setId)
        if #labels > 0 then
            line = line .. string.format(" — %s: %s",
                GetString(SI_GPH_TOOLTIP_SET_COLLECTION_MISSING), table.concat(labels, ", "))
        end
    end
    return line
end

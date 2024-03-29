Ext.Require("Server/FullPartyDialoguesUtil.lua")

local mod = {}
mod.passive = "FULLPARTYDIALOGUES_PRIVATE_PASSIVE"
mod.status = "FULLPARTYDIALOGUES_PRIVATE_STATUS"

local party = {}
local dialog = {}
dialog.moment = {}

function addPassive(character_guid)
    if Osi.HasPassive(character_guid, mod.passive) == 0 then
        Osi.AddPassive(character_guid, mod.passive)
    end
end

function removePassive(character_guid)
    if Osi.HasPassive(character_guid, mod.passive) == 1 then
        Osi.RemovePassive(character_guid, mod.passive)
    end
    if Osi.HasActiveStatus(character_guid, mod.status) == 1 then
        Osi.RemoveStatus(character_guid, mod.status)
    end
end

Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(_, _)
    dialog.moment.found = false
    local partyMembers = Osi.DB_PartyMembers:Get(nil)
    for _, partyMember in pairs(partyMembers) do
        table.insert(party, partyMember[1])
        addPassive(partyMember[1])
    end
    dbg("Mod activated successfully!")
end)

Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(character_guid)
    table.insert(party, character_guid)
    addPassive(character_guid)
end)

Ext.Osiris.RegisterListener("CharacterLeftParty", 1, "before", function(character_guid)
    removePassive(character_guid)
    removeValueFromTable(party, character_guid)
end)

Ext.Osiris.RegisterListener("DialogStarted", 2, "before", function(dialog_guid, _)
    dialog.guid = tostring(dialog_guid)
    local startedDialog = Osi.DB_StartedDialog:Get(dialog.guid, nil, nil, nil, nil, nil, nil)
    for _, guid in pairs(startedDialog[1]) do
        if Osi.IsPlayer(guid) == 1 then
            if Osi.IsControlled(guid) == 1 then
                dialog.speaker = tostring(guid)
                break
            end
        else
            dialog.npc = tostring(guid);
        end
    end

    if Osi.HasActiveStatus(dialog.speaker, mod.status) == 1 then
        return
    end

    if Osi.QRY_OM_FindValidOriginMoment(dialog.guid, dialog.npc, dialog.speaker) == true then
        local doubleOriginMoment = Osi.DB_DoubleOriginMoment:Get(dialog.guid, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil)
        if doubleOriginMoment[1] ~= nil then
            dialog.tag = doubleOriginMoment[1][2]
            dialog.moment.guid = doubleOriginMoment[1][5]
            for _, member in ipairs(party) do
                if Osi.IsTagged(member, dialog.tag) == 1 then
                    dialog.moment.origin = member
                    dialog.moment.found = true
                    dbg("Found origin moment " .. dialog.moment.guid)
                    Osi.PROC_ForceStopDialog(dialog.speaker)
                    return
                end
            end
            dbg("No party member with tag " .. dialog.tag)
        end
    end
end)

Ext.Osiris.RegisterListener("DialogStarted", 2, "after", function(dialog_guid, dialog_id)
    if Osi.HasActiveStatus(dialog.speaker, mod.status) == 1 then
        return
    end

    for _, member in ipairs(party) do
        dbg("Adding party member " .. member)
        Osi.PROC_DialogAddSpeakingActor(dialog_id, member)
    end
end)

Ext.Osiris.RegisterListener("DialogEnded", 2, "after", function(dialog_guid, _)
    if dialog.moment.found == false then
        return
    else
        dbg("Playing origin moment " .. dialog.moment.guid)
        dialog.moment.found = false
    end

    if Osi.QRY_PlayOriginMoment(dialog.guid, dialog.npc, dialog.speaker) == false then
        if Osi.PROC_ExecuteOriginMoment(
            dialog.guid,
            dialog.moment.guid,
            dialog.tag,
            "NULL_00000000-0000-0000-0000-000000000000",
            dialog.moment.origin,
            "NULL_00000000-0000-0000-0000-000000000000",
            dialog.speaker,
            dialog.npc,
            "COM_7075ec1a-70ad-bd25-3111-0a955cf07585",
            dialog.speaker) == false then
                dbg("Couldn't execute origin moment " .. dialog.moment.guid)
                return
            end
    end
    dbg("Executed origin moment " .. dialog.moment.guid)
end)

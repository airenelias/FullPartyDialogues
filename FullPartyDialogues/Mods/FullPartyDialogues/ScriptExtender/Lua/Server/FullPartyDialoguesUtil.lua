function dbg(msg)
    _P("FullPartyDialogues: " .. msg)
end

function removeValueFromTable(tbl, val)
    for i, v in ipairs (tbl) do 
        if (v == val) then
            table.remove(tbl, i)
            return
        end
    end
end

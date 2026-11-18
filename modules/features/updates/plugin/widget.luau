-- Package changes between the running system and main's, written by the infra-update service.
local dir = "~/.cache/infra-update/"

function update()
  noctalia.setUpdateInterval(60000)
  local count = tonumber(noctalia.readFile(dir .. "count") or "")
  if not count or count == 0 then
    barWidget.setVisible(false)
    return
  end
  barWidget.setVisible(true)
  barWidget.setGlyph("package")
  barWidget.setText(tostring(count))
  local lines = {}
  for line in (noctalia.readFile(dir .. "diff") or ""):gmatch("[^\n]+") do
    if #lines == 30 then
      table.insert(lines, "…")
      break
    end
    table.insert(lines, line)
  end
  barWidget.setTooltip(table.concat(lines, "\n"))
end

function onClick()
  noctalia.runInTerminal(
    "less -F " .. dir .. "diff; printf 'Update now? [y/N] '; read a; [ \"$a\" = y ] && "
      .. "cd ~/.config/infra && git pull --ff-only && sudo nixos-rebuild switch --flake . "
      .. "&& systemctl --user start infra-update; echo; echo 'Enter to close'; read _"
  )
end

function onRightClick()
  noctalia.runAsync("systemctl --user start --no-block infra-update")
end

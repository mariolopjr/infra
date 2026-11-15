-- Ported from Ghostty keybinds

-- splits
rex.bind("ctrl+h", "pane.focus.left")
rex.bind("ctrl+j", "pane.focus.down")
rex.bind("ctrl+k", "pane.focus.up")
rex.bind("ctrl+l", "pane.focus.right")
rex.bind("alt+h", "pane.resize", { direction = "left" })
rex.bind("alt+j", "pane.resize", { direction = "down" })
rex.bind("alt+k", "pane.resize", { direction = "up" })
rex.bind("alt+l", "pane.resize", { direction = "right" })
rex.bind("ctrl+-", "pane.split", { direction = "down" })
rex.bind("cmd+alt+enter", "pane.split.auto")

rex.bind("cmd+shift+p", "client.palette.toggle")
rex.bind("cmd+n", "client.window.new")
rex.bind("cmd+shift+t", "client.tab.rename")
rex.bind("cmd+r", "client.config.reload")
rex.bind("cmd+shift+r", "session.rename")

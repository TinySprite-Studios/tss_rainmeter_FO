return {
  title = {
    line1 = "B.O.L.T",
    line2 = "BUNKER TEC // Employee: Josh Sayer",
  },

  tabs = {
    { id = "STAT",  label = "[STAT]",  root = "STAT_ROOT",  status = "STAT // SYSTEM STATUS ONLINE" },
    { id = "DATA",  label = "[DATA]",  root = "DATA_ROOT",  status = "DATA // FILE INDEX" },
    { id = "INV",   label = "[INV]",   root = "INV_ROOT",   status = "INV // APPLICATION INDEX" },
    { id = "RADIO", label = "[RADIO]", root = "RADIO_ROOT", status = "RADIO // MEDIA LINKS" },
    { id = "SET",   label = "[SET]",   root = "SET_ROOT",   status = "SET // SKIN SETTINGS" },
  },

  menus = {
    STAT_ROOT = {
      { type = "none", text = "CPU Usage: [MeasureCPUClamped:0]%", show_if_var = "StatShowCPU", show_if_value = "1" },
      { type = "none", text = "RAM Usage: [MeasureRAMClamped:0]%", show_if_var = "StatShowRAM", show_if_value = "1" },
      { type = "none", text = "C: Used: [MeasureDiskCUsedClamped:0]%", show_if_var = "StatShowDiskC", show_if_value = "1" },
      { type = "none", text = "G: Used: [MeasureDiskGUsedClamped:0]%", show_if_var = "StatShowDiskG", show_if_value = "1" },
      { type = "none", text = "Net Test Down: [MeasureNetTestDownText] Mbps", show_if_var = "StatShowNetTest", show_if_value = "1" },
      { type = "none", text = "Net Test Up: [MeasureNetTestUpText] Mbps", show_if_var = "StatShowNetTest", show_if_value = "1" },
      { type = "none", text = "Uptime: [MeasureUptimeText]", show_if_var = "StatShowUptime", show_if_value = "1" },
    },

    DATA_ROOT = {
      { type = "add_entry", text = "Add Folder", mode = "folder", menu = "DATA_ROOT", status = "DATA // ADD FOLDER" },
      { type = "add_entry", text = "Add Submenu", mode = "submenu", menu = "DATA_ROOT", status = "DATA // ADD SUBMENU" },
      { type = "submenu", text = "FiveM Folder", menu = "DATA_FIVEM", status = "DATA // FIVEM FOLDER" },
      { type = "submenu", text = "System Resources", menu = "DATA_SYS", status = "DATA // SYSTEM RESOURCES" },
    },

    DATA_FIVEM = {
      { type = "add_entry", text = "Add Folder", mode = "folder", menu = "DATA_FIVEM", status = "DATA // ADD FOLDER" },
      { type = "add_entry", text = "Add Program/Shortcut", mode = "program", menu = "DATA_FIVEM", status = "DATA // ADD PROGRAM" },
      { type = "add_entry", text = "Add Submenu", mode = "submenu", menu = "DATA_FIVEM", status = "DATA // ADD SUBMENU" },
      { type = "submenu", text = "Back", menu = "DATA_ROOT", status = "DATA // FILE INDEX" },
    },

    DATA_SYS = {
      { type = "add_entry", text = "Add Folder", mode = "folder", menu = "DATA_SYS", status = "DATA // ADD FOLDER" },
      { type = "add_entry", text = "Add Program/Shortcut", mode = "program", menu = "DATA_SYS", status = "DATA // ADD PROGRAM" },
      { type = "add_entry", text = "Add Submenu", mode = "submenu", menu = "DATA_SYS", status = "DATA // ADD SUBMENU" },
      { type = "submenu", text = "Back", menu = "DATA_ROOT", status = "DATA // FILE INDEX" },
    },

    INV_ROOT = {
      { type = "add_entry", text = "Add Folder", mode = "folder", menu = "INV_ROOT", status = "INV // ADD FOLDER" },
      { type = "add_entry", text = "Add Program/Shortcut", mode = "program", menu = "INV_ROOT", status = "INV // ADD PROGRAM" },
      { type = "add_entry", text = "Add Submenu", mode = "submenu", menu = "INV_ROOT", status = "INV // ADD SUBMENU" },
      { type = "submenu", text = "Programs", menu = "INV_PROGRAMS", status = "INV // PROGRAMS" },
      { type = "submenu", text = "Games", menu = "INV_GAMES", status = "INV // GAMES" },
    },

    INV_PROGRAMS = {
      { type = "add_entry", text = "Add Folder", mode = "folder", menu = "INV_PROGRAMS", status = "INV // ADD FOLDER" },
      { type = "add_entry", text = "Add Program/Shortcut", mode = "program", menu = "INV_PROGRAMS", status = "INV // ADD PROGRAM" },
      { type = "add_entry", text = "Add Submenu", mode = "submenu", menu = "INV_PROGRAMS", status = "INV // ADD SUBMENU" },
      { type = "submenu", text = "Back", menu = "INV_ROOT", status = "INV // APPLICATION INDEX" },
    },

    INV_GAMES = {
      { type = "add_entry", text = "Add Folder", mode = "folder", menu = "INV_GAMES", status = "INV // ADD FOLDER" },
      { type = "add_entry", text = "Add Program/Shortcut", mode = "program", menu = "INV_GAMES", status = "INV // ADD PROGRAM" },
      { type = "add_entry", text = "Add Submenu", mode = "submenu", menu = "INV_GAMES", status = "INV // ADD SUBMENU" },
      { type = "submenu", text = "Back", menu = "INV_ROOT", status = "INV // APPLICATION INDEX" },
    },

    RADIO_ROOT = {
      { type = "add_entry", text = "Add Folder", mode = "folder", menu = "RADIO_ROOT", status = "RADIO // ADD FOLDER" },
      { type = "add_entry", text = "Add Web Link", mode = "link", menu = "RADIO_ROOT", status = "RADIO // ADD LINK" },
      { type = "add_entry", text = "Add Submenu", mode = "submenu", menu = "RADIO_ROOT", status = "RADIO // ADD SUBMENU" },
    },

    SET_ROOT = {
      { type = "toggle_edit", text = "Edit Mode", status = "SET // TOGGLE EDIT MODE" },
      { type = "submenu", text = "STATS", menu = "SET_STATS", status = "SET // STATS" },
      { type = "submenu", text = "CUSTOMISATION", menu = "SET_CUSTOMISATION", status = "SET // CUSTOMISATION" },
      { type = "reload_config", text = "Reload Config", status = "SET // RELOADED CONFIG" },
      { type = "launch", text = "Recycle Bin", target = "shell:RecycleBinFolder", status = "SET // OPEN RECYCLE BIN" },
      { type = "edit_name", text = "Edit Employee Name", status = "SET // EDIT EMPLOYEE NAME" },
      { type = "refresh_app", text = "Refresh Rainmeter", status = "SET // REFRESHING RAINMETER" },
    },

    SET_STATS = {
      { type = "toggle_var", text = "CPU Usage", var = "StatShowCPU", status = "SET // TOGGLE CPU STAT" },
      { type = "toggle_var", text = "RAM Usage", var = "StatShowRAM", status = "SET // TOGGLE RAM STAT" },
      { type = "toggle_var", text = "Disk C Usage", var = "StatShowDiskC", status = "SET // TOGGLE DISK C STAT" },
      { type = "toggle_var", text = "Disk G Usage", var = "StatShowDiskG", status = "SET // TOGGLE DISK G STAT" },
      { type = "toggle_var", text = "Network Test Results", var = "StatShowNetTest", status = "SET // TOGGLE NET TEST RESULTS" },
      { type = "run_network_test", text = "Test Network", status = "SET // RUNNING NETWORK TEST" },
      { type = "toggle_var", text = "Uptime", var = "StatShowUptime", status = "SET // TOGGLE UPTIME STAT" },
      { type = "submenu", text = "Back", menu = "SET_ROOT", status = "SET // SKIN SETTINGS" },
    },

    SET_CUSTOMISATION = {
      { type = "toggle_scanlines", text = "Enable Scanlines", status = "SET // TOGGLE SCANLINES" },
      { type = "toggle_sounds", text = "Enable Sounds", status = "SET // TOGGLE SOUNDS" },
      {
        type = "writes",
        text = "UI Colour: Terminal Green",
        status = "SET // COLOUR TERMINAL GREEN",
        refresh = "skin",
        writes = {
          { section = "Variables", key = "TextColor", value = "0,255,0,255", file = "#@#Variables.inc" },
          { section = "Variables", key = "AccentColor", value = "95,255,95,255", file = "#@#Variables.inc" },
          { section = "Variables", key = "HoverColor", value = "255,140,0,255", file = "#@#Variables.inc" },
          { section = "Variables", key = "DeleteColor", value = "255,64,64,255", file = "#@#Variables.inc" },
        },
      },
      {
        type = "writes",
        text = "UI Colour: Amber CRT",
        status = "SET // COLOUR AMBER CRT",
        refresh = "skin",
        writes = {
          { section = "Variables", key = "TextColor", value = "255,191,0,255", file = "#@#Variables.inc" },
          { section = "Variables", key = "AccentColor", value = "255,220,120,255", file = "#@#Variables.inc" },
          { section = "Variables", key = "HoverColor", value = "255,140,0,255", file = "#@#Variables.inc" },
          { section = "Variables", key = "DeleteColor", value = "255,64,64,255", file = "#@#Variables.inc" },
        },
      },
      {
        type = "writes",
        text = "UI Colour: Ice Blue",
        status = "SET // COLOUR ICE BLUE",
        refresh = "skin",
        writes = {
          { section = "Variables", key = "TextColor", value = "110,220,255,255", file = "#@#Variables.inc" },
          { section = "Variables", key = "AccentColor", value = "180,245,255,255", file = "#@#Variables.inc" },
          { section = "Variables", key = "HoverColor", value = "255,140,0,255", file = "#@#Variables.inc" },
          { section = "Variables", key = "DeleteColor", value = "255,64,64,255", file = "#@#Variables.inc" },
        },
      },
      {
        type = "writes",
        text = "UI Colour: White Phosphor",
        status = "SET // COLOUR WHITE PHOSPHOR",
        refresh = "skin",
        writes = {
          { section = "Variables", key = "TextColor", value = "235,255,235,255", file = "#@#Variables.inc" },
          { section = "Variables", key = "AccentColor", value = "255,255,255,255", file = "#@#Variables.inc" },
          { section = "Variables", key = "HoverColor", value = "255,140,0,255", file = "#@#Variables.inc" },
          { section = "Variables", key = "DeleteColor", value = "255,64,64,255", file = "#@#Variables.inc" },
        },
      },
      { type = "submenu", text = "Back", menu = "SET_ROOT", status = "SET // SKIN SETTINGS" },
    },
  }
}

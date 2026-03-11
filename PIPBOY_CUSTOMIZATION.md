# B.O.L.T Skin Customization Guide (Lua Config + In-UI Add)

Core files:
- `Skins/tss_rainmeter_FO/tss_rainmeter_FO.ini` (minimal shell)
- `Skins/tss_rainmeter_FO/@resources/Config/Config.lua` (base tabs/menus/settings)
- `Skins/tss_rainmeter_FO/@resources/Config/UserItems.lua` (items you add in UI)
- `Skins/tss_rainmeter_FO/@resources/Scripts/PipBoyMenu.lua` (menu engine)

## In-UI Add system
You now have add options directly in menus:
- DATA: `Add Folder` (+ in submenus also `Add Program/Shortcut`)
- INV: `Add Folder`, `Add Program/Shortcut`
- RADIO: `Add Folder`, `Add Web Link`

`SET > Edit Mode` controls menu editing:
- `OFF`: normal mode (launch items when clicked, hide add controls)
- `ON`: shows add controls and turns user launch entries into delete actions (`[DEL]`)

When you add items:
- A native overlay appears above the terminal (no external PowerShell dialog)
- Enter display name and target path / URL
- New item is saved to `UserItems.lua`
- Lua merges those entries into the current menu

No manual path typing required.

## Direct config editing
If you prefer manual edits:
- Edit `Config.lua` for base menu definitions
- Edit `UserItems.lua` for added items

The launchable DATA / INV / RADIO entries now live in `UserItems.lua`.

## Item types in config
- `none`
- `submenu`
- `launch`
- `add_entry`
- `reload_config`
- `writes`
- `open_variables`
- `refresh_app`

## Reload
- Use `SET > Reload Config`, or refresh the skin in Rainmeter.

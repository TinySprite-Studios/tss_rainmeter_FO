return {
  menus = {
    ['INV_ROOT_USR_LOOK'] = {
      { type = 'submenu', text = 'Back', status = 'BACK', menu = 'INV_ROOT' },
    },
    ['INV_ROOT'] = {
      { type = 'launch', text = 'Documents', target = 'C:\\Users\\josh sayer\\Documents', status = 'OPEN Documents' },
    },
    ['INV_ROOT_USR_PEA'] = {
      { type = 'submenu', text = 'Back', status = 'BACK', menu = 'INV_ROOT' },
    },
    ['INV_GAMES'] = {
      { type = 'launch', text = 'qbcore (server)', target = 'G:\\FiveM Drive\\servers\\qbcore\\qbcore.bat', status = 'INV // LAUNCH qbcore' },
      { type = 'launch', text = 'sixties (server)', target = 'G:\\FiveM Drive\\servers\\sixties\\sixties.bat', status = 'INV // LAUNCH sixties' },
      { type = 'launch', text = 'zombie_dev (server)', target = 'G:\\FiveM Drive\\servers\\zombies\\zombie_dev.bat', status = 'INV // LAUNCH zombie_dev' },
      { type = 'launch', text = 'FiveM', target = 'C:\\Users\\josh sayer\\AppData\\Local\\FiveM\\FiveM.exe', status = 'INV // LAUNCH FiveM' },
    },
    ['DATA_FIVEM'] = {
      { type = 'launch', text = 'CodeWalker', target = 'C:\\Users\\josh sayer\\Documents\\CodeWalker30_dev48\\CodeWalker.exe', status = 'DATA // OPENING CodeWalker' },
      { type = 'launch', text = 'CodeWalker RPF Explorer', target = 'C:\\Users\\josh sayer\\Documents\\CodeWalker30_dev48\\CodeWalker RPF Explorer.exe', status = 'DATA // OPENING CodeWalker RPF Explorer' },
      { type = 'launch', text = 'FiveM', target = 'C:\\Users\\josh sayer\\AppData\\Local\\FiveM\\FiveM.exe', status = 'DATA // OPENING FiveM' },
      { type = 'launch', text = 'OpenIV', target = 'C:\\Users\\josh sayer\\AppData\\Local\\New Technology Studio\\Apps\\OpenIV\\OpenIV.exe', status = 'DATA // OPENING OpenIV' },
      { type = 'launch', text = 'FiveM Drive', target = 'G:\\FiveM Drive', status = 'DATA // OPENING FiveM Drive' },
    },
    ['DATA_ROOT'] = {
      { type = 'launch', text = 'Open FiveM Drive Folder', target = 'G:\\FiveM Drive', status = 'DATA // OPENING FiveM Drive' },
      { type = 'launch', text = 'Open SystemResources Folder', target = 'C:\\Users\\josh sayer\\Desktop\\SystemResources', status = 'DATA // OPENING SystemResources' },
      { type = 'launch', text = 'Music', target = 'C:\\Users\\josh sayer\\Music', status = 'OPEN Music' },
      { type = 'launch', text = 'Videos', target = 'C:\\Users\\josh sayer\\Videos', status = 'OPEN Videos' },
      { type = 'submenu', text = 'Melt', status = 'OPEN Melt', menu = 'DATA_ROOT_USR_MELT' },
    },
    ['RADIO_ROOT'] = {
      { type = 'launch', text = 'YouTube', target = 'https://youtube.com', status = 'RADIO // OPEN YouTube' },
      { type = 'launch', text = 'Spotify Web', target = 'https://open.spotify.com', status = 'RADIO // OPEN Spotify' },
      { type = 'submenu', text = 'Menu2', status = 'OPEN Menu2', menu = 'RADIO_ROOT_USR_MENU2' },
    },
    ['RADIO_ROOT_USR_MENU2'] = {
      { type = 'submenu', text = 'Back', status = 'BACK', menu = 'RADIO_ROOT' },
    },
    ['INV_PROGRAMS'] = {
      { type = 'launch', text = 'Google Chrome', target = 'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe', status = 'INV // LAUNCH Google Chrome' },
      { type = 'launch', text = 'Steam', target = 'S:\\Steam\\steam.exe', status = 'INV // LAUNCH Steam' },
      { type = 'launch', text = 'FiveM', target = 'C:\\Users\\josh sayer\\AppData\\Local\\FiveM\\FiveM.exe', status = 'INV // LAUNCH FiveM' },
      { type = 'launch', text = 'OpenIV', target = 'C:\\Users\\josh sayer\\AppData\\Local\\New Technology Studio\\Apps\\OpenIV\\OpenIV.exe', status = 'INV // LAUNCH OpenIV' },
      { type = 'launch', text = 'File Explorer', target = 'explorer.exe', status = 'INV // LAUNCH File Explorer' },
      { type = 'launch', text = 'TinySprite', target = 'C:\\Users\\josh sayer\\Pictures\\TinySprite', status = 'OPEN TinySprite' },
      { type = 'launch', text = 'Paint.Net', target = 'C:\\Program Files\\Paint.NET\\paintdotnet.exe', status = 'OPEN Paint.Net' },
    },
    ['DATA_ROOT_USR_MELT'] = {
      { type = 'submenu', text = 'Back', status = 'BACK', menu = 'DATA_ROOT' },
    },
    ['DATA_SYS'] = {
      { type = 'launch', text = 'AI Suite 3', target = 'C:\\Users\\josh sayer\\Desktop\\SystemResources\\AI Suite 3.lnk', status = 'DATA // OPENING AI Suite 3' },
      { type = 'launch', text = 'Armoury Crate', target = 'C:\\Users\\josh sayer\\Desktop\\SystemResources\\Armoury Crate.lnk', status = 'DATA // OPENING Armoury Crate' },
      { type = 'launch', text = 'Aura Creator', target = 'C:\\Users\\josh sayer\\Desktop\\SystemResources\\Aura Creator.lnk', status = 'DATA // OPENING Aura Creator' },
      { type = 'launch', text = 'iCUE', target = 'C:\\Users\\josh sayer\\Desktop\\SystemResources\\iCUE.lnk', status = 'DATA // OPENING iCUE' },
      { type = 'launch', text = 'NVIDIA App', target = 'C:\\Users\\josh sayer\\Desktop\\SystemResources\\NVIDIA App.lnk', status = 'DATA // OPENING NVIDIA App' },
      { type = 'launch', text = 'NVIDIA Control Panel', target = 'C:\\Users\\josh sayer\\Desktop\\SystemResources\\NVIDIA Control Panel.lnk', status = 'DATA // OPENING NVIDIA Control Panel' },
      { type = 'launch', text = 'Razer Synapse', target = 'C:\\Users\\josh sayer\\Desktop\\SystemResources\\Razer Synapse.lnk', status = 'DATA // OPENING Razer Synapse' },
    },
  }
}

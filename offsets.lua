local _, FSH = ...

--[[
You can usualy find the needed offsets in:
http://www.ownedcore.com/forums/world-of-warcraft/world-of-warcraft-bots-programs/wow-memory-editing/

This table allows users to manualy inster the offsets and therefore make it work on any unlocked WoW build
with minimal effort.

  Find the game build with the in-game command:
  /dump select(2, GetBuildInfo())

  [GameBuild] = OFFSET

]]

------------------------------------------------------------------------------------
----------------------------------------X64-----------------------------------------
FSH.X64 = {}
FSH.X64.OBJECT_BOBBING_OFFSET = {
  [22950] = 0x1C4,
  [23171] = 0x1C4
}

FSH.X64.OBJECT_CREATOR_OFFSET = {
  [22950] = 0x030,
  [23171] = 0x030
}

------------------------------------------------------------------------------------
----------------------------------------X86-----------------------------------------
FSH.X86 = {}
FSH.X86.OBJECT_BOBBING_OFFSET = {
  [22950] = 0x0F8,
  [23171] = 0x0F8
}

FSH.X86.OBJECT_CREATOR_OFFSET = {
  [22950] = 0x030,
  [23171] = 0x030
 }

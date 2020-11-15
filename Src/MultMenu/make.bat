call compzx7 resources/Menu.scr
call compzx7 resources/romsetwriter_v1.scr
call asm MultMenu.asm >MultMenu.txt

copy /b MultMenu.mld+512.rom rom.rom
fcut rom.rom 0 80000 0.rom
del rom.rom

type MultMenu.txt

pause 0
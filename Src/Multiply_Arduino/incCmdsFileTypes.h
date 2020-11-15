
//// COMMANDS

// Commands for Arduino
#define CMD_ZX2INO_REQ_ID       0x01    //Ask for Multiply Identification
#define CMD_ZX2INO_REQ_RESET    0x02    //Reset Arduino
#define CMD_ZX2SD_SETZXTYPE     0x03    //Hard type of Spectrum machine: 1=16k, 3=48k, 8=128k

// Commands for SDCARD
#define CMD_ZX2SD_OFWRITE       0x06    //Open File to Write
#define CMD_ZX2SD_OFWRITE_IX    0x07    //Open File to Write by index
#define CMD_ZX2SD_OFREAD        0x08    //Open File to Read
#define CMD_ZX2SD_OFREAD_IX     0x09    //Open File for Read by index

// Change Directory
#define CMD_ZX2SD_CD_ROOT       0x0A    //Go to root of SDCARD
#define CMD_ZX2SD_CD            0x0B    //Change to dir
#define CMD_ZX2SD_CD_IX         0x0C    //Change to dir by index
#define CMD_ZX2SD_GETDIR        0x0D    //Get long name of current dir

// Directory Listing
#define CMD_ZX2SD_LS_RELATIVE   0x0E    //Get list of current dir
#define CMD_ZX2SD_LS_ABSOLUTE   0x0F    //Get list of specific dir (full path)

//Commands for screen file type
#define CMD_ZX2SD_SCR           0x10      //Ask for Screen Data

//Commands for SNAPSHOTS - Request File Contents
#define CMD_ZX2SD_Z80_16K       0x11      //Ask for Data of Z80 16k snapshot
#define CMD_ZX2SD_Z80_48K       0x12      //Ask for Data of Z80 48k snapshot
#define CMD_ZX2SD_Z80_128K      0x13      //Ask for Data of Z80 128k snapshot
#define CMD_ZX2SD_SCR_FROM_Z80  0x14      //Ask for Screen of Z80 file

#define CMD_ZX2SD_SNA_48K       0x16      //Ask for Data of Z80 48k snapshot
#define CMD_ZX2SD_SNA_128K      0x17      //Ask for Data of Z80 128k snapshot
#define CMD_ZX2SD_SCR_FROM_SNA  0x18      //Ask for Screen of SNA file

//Additional information from Entries (Directory/File)
#define CMD_ZX2SD_GETINFO       0x1E      //Ask for 2 bytes of additional data (index of Dir/File)


//Commands for tap/tzx files
#define CMD_ZX2SD_TAP           0x20      //Ask for TAP Data
#define CMD_ZX2SD_TAP2          0x21      //Ask for TAP Data 2
#define CMD_ZX2SD_TAP_ULA       0x22      //Ask for TAP directly to ULA port
#define CMD_ZX2SD_SCRTAP        0x23      //Ask for Screen into a TAP file

#define CMD_ZX2SD_TZX1          0x24      //Ask for TZX Data
#define CMD_ZX2SD_TZX2          0x25      //Ask for TZX Data 2
#define CMD_ZX2SD_TZX_ULA       0x26      //Ask for TAP directly to ULA port

//Commands for binary files
#define CMD_ZX2SD_BINARY_INFO   0x28      //Ask for Bin file CMD_ZX2SD_BINARY_INFO
#define CMD_ZX2SD_BINARY_DATA   0x29      //Ask for Bin file DATA

//Commands for ROMSET
#define CMD_ZX2SD_ROMSETBLK4B   0x30      //Ask for ROMSET block with 4bit
#define CMD_ZX2SD_ROMSETBLKSER  0x31      //Ask for ROMSET block with Serial

// Commands from PC
#define CMD_PC2AR_ROMSET_TUNNEL 0xED      //Ask for Romset through Arduino Serial (tunnel)
#define CMD_PC2AR_ROMSET_TUN2   0xF3      //Ask for Romset through Arduino Serial (tunnel)
#define CMD_PC2AR_BIN_TUNNEL    0xEF      //Ask for Binary file through Arduino Serial (tunnel)

//File Types as per directory listing
//// FILETYPES => FILECONTENTS 4Bit
#define FT_END_DIRECTORY        0x00      //End of directory listing

#define FT_DIRECTORY            0x0C      //Directory entry

#define FT_SCR                  0x10      //Screen (6912 bytes)

#define FT_Z80_16K              0x11      //Z80 for 16k snapshot
#define FT_Z80_48K              0x12      //Z80 for 48k snapshot
#define FT_Z80_128K             0x13      //Z80 for 128k snapshot

#define FT_SNA_48K              0x16      //SNA for 48k snapshot
#define FT_SNA_128K             0x17      //SNA for 128k snapshot

#define FT_TAP                  0x20      //TAP File

#define FT_BINARY               0x28      //BIN File

#define FT_ROMSET               0x30      //Romset (512k)

//// Other
#define ROOTDIR                 "/"

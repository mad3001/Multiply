//Multiply_commands / Types / Constants

//Commands for Arduino
CMD_ZX2INO_REQ_ID			EQU		0x01			//Ask for Multiply Identification
CMD_ZX2INO_REQ_RESET		EQU		0x02			//Reset Arduino
CMD_ZX2SD_SETZXTYPE     	EQU		0x03		    //Hard type of Spectrum machine: 1=16k, 3=48k, 8=128k

//Commands for SDCARD
CMD_ZX2SD_OFWRITE			EQU		0x06			//Open File to Write
CMD_ZX2SD_OFWRITE_IX     	EQU		0x07			//Open File for Write by index
CMD_ZX2SD_OFREAD			EQU		0x08			//Open File to Read
CMD_ZX2SD_OFREAD_IX     	EQU		0x09			//Open File for Read by index

// Change Directory
CMD_ZX2SD_CD_ROOT			EQU		0x0A			//Go to root of SDCARD
CMD_ZX2SD_CD				EQU		0x0B			//Change to dir
CMD_ZX2SD_CD_IX				EQU		0x0C			//Change to dir by index
CMD_ZX2SD_GETDIR        	EQU		0x0D 		    //Get long name of current dir

// Directory Listing
CMD_ZX2SD_LS_RELATIVE		EQU		0x0E			//Get list of current dir
CMD_ZX2SD_LS_ABSOLUTE		EQU		0x0F			//Get list of specific dir (full path)

//Commands for screen file type
CMD_ZX2SD_SCR				EQU		0x10			//Ask for Screen Data

//Commands for SNAPSHOTS - Request File Contents
CMD_ZX2SD_Z80_16K			EQU		0x11			//Ask for Data of Z80 16k snapshot
CMD_ZX2SD_Z80_48K			EQU		0x12			//Ask for Data of Z80 48k snapshot
CMD_ZX2SD_Z80_128K			EQU		0x13			//Ask for Data of Z80 128k snapshot
CMD_ZX2SD_SCR_FROM_Z80		EQU		0x14			//Ask for Screen of Z80 file
CMD_ZX2SD_SNA_48K			EQU		0x16			//Ask for Data of Z80 48k snapshot
CMD_ZX2SD_SNA_128K			EQU		0x17			//Ask for Data of Z80 128k snapshot
CMD_ZX2SD_SCR_FROM_SNA		EQU		0x18			//Ask for Screen of SNA file

//Additional information from Entries (Directory/File)
CMD_ZX2SD_GETINFO			EQU		0x1E			//Ask for 4 bytes of additional data

//Commands for tap/tzx files
CMD_ZX2SD_TAP				EQU		0x20			//Ask for TAP Data
CMD_ZX2SD_TAP2				EQU  	0x21			//Ask for TAP Data 2
CMD_ZX2SD_TAP_ULA			EQU  	0x22			//Ask for TAP directly to ULA port
CMD_ZX2SD_SCRTAP        	EQU		0x23 		    //Ask for Screen into a TAP file

CMD_ZX2SD_TZX				EQU		0x24			//Ask for TZX Data
CMD_ZX2SD_TZX2				EQU  	0x25			//Ask for TZX Data 2
CMD_ZX2SD_TZX_ULA			EQU  	0x26			//Ask for TAP directly to ULA port

//Commands for binary files
CMD_ZX2SD_BINARY_INFO		EQU		0x28			//Ask for Bin file CMD_ZX2SD_BINARY_INFO
CMD_ZX2SD_BINARY_DATA		EQU 	0x29			//Ask for Bin file DATA

//Commands for ROMSET
CMD_ZX2SD_ROMSETBLK4B		EQU		0x30			//Ask for ROMSET block with 4bit
CMD_ZX2SD_ROMSETBLKSER		EQU		0x31			//Ask for ROMSET block with Serial

// Commands from PC
CMD_PC2AR_ROMSET_TUNNEL		EQU		0xED			//Ask for Romset through Arduino Serial (tunnel)
CMD_PC2AR_ROMSET_TUN2		EQU		0xF3			//Ask for Romset through Arduino Serial (tunnel)
CMD_PC2AR_BIN_TUNNEL		EQU		0xEF			//Ask for Binary file through Arduino Serial (tunnel)

//File Types as per directory listing
//// FILETYPES => FILECONTENTS 4Bit
FT_END_DIRECTORY			EQU		0x00			//End of directory listing

FT_DIRECTORY				EQU		0x0C			//Directory entry

FT_SCR						EQU		0x10			//Screen (6912 bytes)

FT_Z80_16K					EQU		0x11			//Z80 for 16k snapshot
FT_Z80_48K					EQU		0x12			//Z80 for 48k snapshot
FT_Z80_128K					EQU		0x13			//Z80 for 128k snapshot
FT_Z80_SCR					EQU		0x14			//Screen of Z80

FT_SNA_48K					EQU		0x16			//SNA for 48k snapshot
FT_SNA_128K					EQU		0x17			//SNA for 128k snapshot
FT_SNA_SCR					EQU		0x18			//Screen of SNA

FT_TAP						EQU		0x20			//TAP File

FT_BINARY					EQU		0x28			//BIN File

FT_ROMSET					EQU		0x30			//Romset (512k)
FT_BASIC					EQU		0x31			//Not a real type, used for return to ZX Basic

//Constants for ASM routines

DANCMD_MULTIPLY	EQU		52							//Dandantor command for Multiply operations
DANDAT_MULTIPLY	EQU		1							//Dandantor data for Multiply command DANCMD_MULTIPLY

SNAP_HEADER		EQU		9							//Used with Commands. 9=Get header of SNA/Z80
SNAP_CHUNK		EQU		10							//Used with Commands. 10=Get Chunk
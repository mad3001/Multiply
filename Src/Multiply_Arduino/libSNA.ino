
  #define SNAHEADSIZE 27
  #define SNABLKSIZE 16384                          //Size of RAM blocks (except RAM5)
  #define CHUNKSIZE 512                             //Size of Chunk (last 512 bytes of RAM5)
  #define POSCHUNK SNAHEADSIZE+SNABLKSIZE-CHUNKSIZE //Begining position in SNA for Chunk (last LENCHUNK bytes of RAM5)
  #define ENDCHUNK SNAHEADSIZE+SNABLKSIZE           //End position in SNA for Chunk (last LENCHUNK bytes of RAM5)

  //-------------------------------------------------------------------------------------------------
  void SendSNA(uint8_t ReqType, uint8_t c, uint8_t *myBuf) {
    unsigned int cnt;
    unsigned long pos;
    //RAMBLOCKS hold array of position in SNA for each RAM block required...
    static uint8_t RAMBLOCKS[8] ; // Array for blocks returned to Spectrum corresponding to 0..7 (spectrum send 1..8) sort is RAM: 5,2,0,1,3,4,6,7
    switch(c) {
      case 9:  
            // Send SNA Header
            SendBlock4bit(0,SNAHEADSIZE,Dly4SNAus);   //27 bytes of header in SNA file
            if (ReqType == CMD_ZX2SD_SNA_128K ) {
              SendBlock4bit(49179,2,Dly4SNAus);//PC value when 128k snapshot
              SendBlock4bit(49181,1,Dly4SNAus);//port #7FFD value when 128k snapshot
              c=myBuf[0]; //value sent as per previous SendBlock4bit (aka port #7FFD)
              c&=7; //c is only the page number (0..7)
            }
            else {
              SendValue4bit(0);//PC value is 0 for 48k SNA, meaning PC is into Stack
              SendValue4bit(0);//PC value is 0 for 48k SNA, meaning PC is into Stack
              SendValue4bit(48);//port #7FFD=#30 if snapshot is 16k or 48k (RAM0/48K ROM and pages locked)
              c=0;  //for 48k upper ram is RAM0
            };
            //Now assign location of corresponding RAM into file as per UPPER RAM PAGED
            // Combinations for this are as follows:
            // Paged RAM0: 0 1 2 3 4 5 6 7    into file it's      RAM:5,2,0,1,3,4,6,7
            // Paged RAM1: 0 1 3 2 4 5 6 7                        RAM:5,2,1,0,3,4,6,7
            // Paged RAM2: 0 1 3 4 5 6 7 8   2nd is repeated RAM2 RAM:5,2,2,0,1,3,4,6,7
            // Paged RAM3: 0 1 3 4 2 5 6 7                        RAM:5,2,3,0,1,4,6,7
            // Paged RAM4: 0 1 3 4 5 2 6 7                        RAM:5,2,4,0,1,3,6,7
            // Paged RAM5: 0 1 3 4 5 6 7 8   2nd is repeated RAM5 RAM:5,2,5,0,1,3,4,6,7
            // Paged RAM6: 0 1 3 4 5 6 2 7                        RAM:5,2,6,0,1,3,4,7
            // Paged RAM7: 0 1 3 4 5 6 7 2                        RAM:5,2,7,0,1,3,6,7
            RAMBLOCKS[0] = 0;                                     //Spectrum ask 1 for RAM5
            RAMBLOCKS[1] = 1;                                     //Spectrum ask 2 for RAM2
            RAMBLOCKS[2] = (c==0) ? 2 : 3;                        //Spectrum ask 3 for RAM0
            RAMBLOCKS[3] = (c==1) ? 2 :((c<1) ? 3 : 4);           //Spectrum ask 4 for RAM1
            RAMBLOCKS[4] = (c==3) ? 2 :((c<2) ? 4 : 5);           //Spectrum ask 5 for RAM3
            RAMBLOCKS[5] = (c==4) ? 2 :(((c<4)&&(c!=2)) ? 5 : 6); //Spectrum ask 6 for RAM4
            RAMBLOCKS[6] = (c==6) ? 2 :(((c<5)&&(c!=2)) ? 6 : 7); //Spectrum ask 7 for RAM6
            RAMBLOCKS[7] = (c==7) ? 2 :(((c!=5)&&(c!=2)) ? 7 : 8);//Spectrum ask 8 for RAM7
            
            SendValue4bit(4);//port #1FFD=#04 for SNA... (sna doesn't have, Z80 have it)
            SendValue4bit((ReqType == CMD_ZX2SD_SNA_128K ) ? 8 : ((ReqType == CMD_ZX2SD_SNA_48K ) ? 3 : 1));//Gametype: 8=128k, 3=48k, 1=16k
            for (cnt=0;cnt<17;cnt++) {
                SendValue4bit(0);  //0 for no AY, no values.... future will send AY regs (sna doesn't have, Z80 have it)
            }
            for (cnt=0;cnt<15;cnt++) {
                SendValue4bit(255);  //15 reserved bytes for future usage, at this moment send 255
            }
            break;
    case 10:  // Send CHUNK and close file... CHUNK is always LENCHUNK last bytes of RAM5
            SendBlock4bit(POSCHUNK,CHUNKSIZE,Dly4SNAus); //Send chunk block
            break;              
    case 1 ... 8:   // Send RAM block
            pos=RAMBLOCKS[c-1]; //Converts 1..8 into 0..7 and use it with RAMBLOCKS
            pos*=16384;
            pos+=SNAHEADSIZE;                   //Position in SNA file for the selected block
            if (RAMBLOCKS[c-1]>2) pos+=4;   //For blocks 4rd to last need to skip 4 bytes for PC (2 bytes), #7FFD(1 byte), TR-DOS(1 byte)
            cnt=((c==1) ? SNABLKSIZE-CHUNKSIZE: SNABLKSIZE);// RAM5 size is less than others
            SendBlock4bit(pos,cnt,Dly4SNAus);     //Send the block
            break;               
    default: break;
  }
 }

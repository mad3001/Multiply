//Own defines and variables specific for Z80 snapshot
#define Z80MAXHEADERSIZE 87

//static uint8_t Z80Version;                            //2 for v1 compressed, 1 for v1 uncompressed, 23 for v2, 54 or 55 for v3
//unsigned long posFile;                                //Position in file for Z80 when Z80 version 1 file
//uint8_t numRepeats;                                   //Number of repetitions pending with compressed file
//uint8_t valueRepeats;                                 //Value for repetitions pending with compressed file
static unsigned long ChunkPos;                        //Position in file for Chunk
static uint8_t ChunknumRepeats;                       //Number of repetitions pending with compressed file
static uint8_t ChunkvalueRepeats;                     //Value for repetitions pending with compressed file
static boolean ChunkCompressed;                       //Holding if Chunk is compressed or not


    
//Routine for processing Z80 snapshot
//-------------------------------------------------------------------------------------------------
void SendZ80(uint8_t ReqType, uint8_t c) {
  const uint8_t Z80_128k_page[8] ={8,5,3,4,6,7,9,10};
  const uint8_t Z802SNAHeader[25] ={10,19,20,17,18,15,16,22,21,4,5,13,14,2,3,23,24,25,26,27,11,1,0,8,9};
//  const uint8_t Z802SNAHeader[25] ={10,19,20,17,18,15,16,21,22,4,5,13,14,2,3,23,24,25,26,27,11,0,1,8,9};
  uint8_t Z80Header[87];              //Maximum size of header from Z80 (version 3 file for +3 snapshot)
  uint8_t page;                       //will hold page number as per z80 snapshot (is different RAM page)
                                      // 16K Uses page 8 (4000-7FFF)
                                      // 48K Uses Page 8 (4000-7FFF)
                                      //          Page 4 (8000-BFFF)
                                      //          Page 5 (C000-FFFF)
                                      // 128K Uses Page 3..10 for RAM 0..7
                                      //Spec 16/48/128 can't use SamRam mode snapshots

  unsigned long pos;                  //position into file
  unsigned int dataCnt;
  uint16_t lenData;                   //Will hold length of data block 0xFFFF for uncompressed 16384 bytes, 0x3xxx for compressed
  uint8_t SNAHeader[64];              //Size of header to trasnfer to spectrum
  uint8_t pageNumber;                 //Number of page into Z80 snapshot (only versions 2 and 3 of Z80 snapshot)
  
  switch(c) {
    case 9:   // Get Z80 Header, convert to SNA Header and Send SNA Header
        numRepeats = 0;                      //Number of repetitions pending with compressed file
        valueRepeats = 0;                    //Value for repetitions pending with compressed file
        ChunkCompressed=false;               //Initialize
        getFileChunk(&myFile, Z80Header, 0,Z80MAXHEADERSIZE);              //Read maximum z80 header (version 3 for +3)
        for (dataCnt=0;dataCnt<25;dataCnt++)
          SNAHeader[dataCnt]=Z80Header[Z802SNAHeader[dataCnt]];        
        SNAHeader[19] = (Z80Header[27]==0) ? 0 : 4 ;    // Bit 2 => 0=DI, 1=EI
        SNAHeader[20] = (Z80Header[11] & 0x7F) | (((Z80Header[12] & 1) == 1) ? 0x80 : 0);      // R Register + Bit 7 of R (from Bit 0 of Z80..byte 12)
        SNAHeader[25] = (Z80Header[29] & 0x03);   // IMx Bits:0 and 1
        SNAHeader[26] = (Z80Header[12] & 0x0E) >> 1 ;// Border colour (Bits 3,2,1 of Z80 byte 12)

        SNAHeader[29] = 0x30;         // Default value for 48k: //#7FFD Port to #30 so it's 48k and locked page changes, also RAM0 in upper RAM zone
        SNAHeader[30] = 0x04;         // Default value for 48k or non +2A/+2B/+3 : //#1FFD Port to #04 so be sure ROM 48k is paged
  //Depends of version of snapshot V1 (PC stored in bytes 6-7 <>0), v2 or v3 (PC stored in bytes 6-7 = 0)
        if ((Z80Header[6]!=0) | (Z80Header[7]!=0)){   //If Z80 PC value into bytes 6-7 <> 0 then it's snapshot version 1
          SNAHeader[27] = Z80Header[6];     // PCl for version 1 (snapshot only 48k)
          SNAHeader[28] = Z80Header[7];     // PCh for version 1 (snapshot only 48k)

          SNAHeader[31] = 3;            //version 1 only is Gametype 3
          Z80Version = (Z80Header[12] & 32) ? 2 : 1;               // 2 for v1 compressed, 1 for v1 uncompressed
        }
        else                    //If Z80 PC value into bytes 6-7 = 0 then it's snapshot version 2 (value 23) or 3 (valur 54 or 55)
        {
          Z80Version = Z80Header[30];       //value of version 23, 54 or 55
          SNAHeader[27] = Z80Header[32];      // PCl
          SNAHeader[28] = Z80Header[33];     // PCh

          switch (Z80Header[30]) {        //Version have differences here as is used as lenght of header: vers2 have 23, vers3 have 54 most times but 55 for +3.
            case 23:              //Version 2 of Z80 sna
              SNAHeader[31] = ((Z80Header[34] < 3) ? 3 : 8);  //GameType (16k/48k/128k) Assign 0-1-2 for 48k (value 3), higher for 128k (value 8).
              break;
            case 55:              //Version 3 of Z80 sna applid to +2A/+2B/+3
              SNAHeader[30] = Z80Header[86];            // For +2A/+2B/+3 assign #1FFD port
              // here no break as we want both SNAHeader[30] and SNAHeader[31] filled when version 55
            case 54:              //Version 3 of Z80 sna for all models except +2A/+2B/+3
              SNAHeader[31] = ((Z80Header[34] < 4) ? 3 : 8);  //GameType (16k/48k/128k) Assign 0-1-2-3 for 48k, higher for 128k
              break;
          }
          if (SNAHeader[31]==8) SNAHeader[29] = Z80Header[35];  //For 128k also assign #7FFD port
          if ((Z80Header[37] & 0x80) && (SNAHeader[31]==3)) SNAHeader[31] = 1; //Bit 7=1 of 37 changes 48k to 16k
        }
        
        //Process AY registers if Z80 snapshot have info (bit 2 of byte 37 of z80 header is 1)
        // Z80Header [38] have last out value port #FFFD
        // Z80Header [39..54] 16 bytes with contents of sound chip regs
        for (c=0;c<18;c++) {
          SNAHeader[32+c] = ((Z80Version>22) ? Z80Header[38+c] : 0);  //17 bytes, value if AY, 0 for no AY
        }
        for (c=49;c<63;c++) {
          SNAHeader[c] = 255;  //14 reserved bytes for future usage, at this moment send 255
        }
        SNAHeader[63] = 255;  //1 reserved bytes for future usage, at this moment send 255
        SendBuf4bit(SNAHeader,64,Dly4Z80us);    //Send header to spectrum
        break;
    case 10:  // Send CHUNK ...CHUNK is always CHUNKSIZE last bytes of RAM5
        if  (ChunkCompressed){
            uncompress(ChunkPos,CHUNKSIZE,ChunknumRepeats,ChunkvalueRepeats,true); //Uncompress sending data to spectrum          
        }
        else
        {
            SendBlock4bit(ChunkPos,CHUNKSIZE,Dly4Z80us);     //Send Chunk not compressed
        }
        break;              
    case 1 ... 8:   // Send RAM block c=1..8 for ram page=0..7
        if (ReqType == FT_Z80_128K ){              //Gametype 1=16k, 3=48k, 8=128k
         page=Z80_128k_page[c-1];
        }
        else    //Here for 16k or 48k snapshot
        {
          page = 8;  //for 16k or 48k, c= 1 => ram #4000 //default value
          if (c==2) page = 4;  //for 48k, c=2 => ram #8000
          if (c==3) page = 5;  //for 48k, c=3 => ram #C000
        }
        if(Z80Version<3){     //HERE VERSION 1 Z80... 1 for uncompressed block, 2 for compressed block
          pos=30;   // for version 1 data starts in position 
          if(Z80Version==2){
             // Bit 5 of byte 12 is 1 for Compressed block
            if(c==1) posFile=pos;                                //Position in file for Z80 when Z80 version 1 file
            dataCnt=((c==1) ? SNABLKSIZE-CHUNKSIZE : SNABLKSIZE);// RAM5 size is less than others
            uncompress(posFile,dataCnt,numRepeats,valueRepeats,true); //Uncompress sending data to spectrum
            if(c==1) {
              ChunkPos=posFile;                                 //Save current file position
              ChunknumRepeats=numRepeats;                       //Save current numRepeats (if any)
              ChunkvalueRepeats=valueRepeats;                   //Save value to repeat (if any)
              ChunkCompressed=true;
              uncompress(posFile,CHUNKSIZE,numRepeats,valueRepeats,false); //Skip chunk to get position in file
            }
          }
          else
          {
            // Bit 5 of byte 12 is 0 for raw block (uncompressed)
            switch(c){
              case 1:
                SendBlock4bit(pos,SNABLKSIZE-CHUNKSIZE,Dly4Z80us);     //Send the block not compressed
                ChunkPos=pos+SNABLKSIZE-CHUNKSIZE;                     //Save current file position
                ChunkCompressed=false;
                break;
              case 2:
                SendBlock4bit(pos+SNABLKSIZE,SNABLKSIZE,Dly4Z80us);     //Send the block not compressed
                break;
              case 3:
                SendBlock4bit(pos+SNABLKSIZE+SNABLKSIZE,SNABLKSIZE,Dly4Z80us);     //Send the block not compressed
                break;
            }
          }
        }
        else                             //PC counter = 0 for version 2 or 3 of Z80 snapshot
        {
          pos=32+Z80Version; // Position in file for 1st block
          do{      //version 2 and 3 uses a block system. Each have 2 bytes info for length and 1 bytes for page number of block
            posFile=pos+3;                //Position where to begin uncompress
            if (myFile.curPosition()!=pos) myFile.seek(pos);
            lenData= (uint16_t) (myFile.read());        //Get Low Byte Length of block
            lenData+= (256* (uint16_t) (myFile.read())); //Length of block
            if (lenData==0xffff){       //Is length=0xFFFF...
              pos += 0x4000;            //...uncompressed block of 16384 bytes
            }
            else
            {
              pos += (unsigned long) lenData; 
            }
            pos += 3;               // Position for next block (or end of file if no more blocks)
            pageNumber=myFile.read();        //Get Page Number
          } while(pageNumber!=page);         //If Page found then exit do while
          //At this moment myFile is located in the begining of Page located
          //  and pos is position after the whole block (position of next block or end of file)
          
          dataCnt=((c==1) ? SNABLKSIZE-CHUNKSIZE : SNABLKSIZE);// RAM5 size is less than others
  
          if (lenData==0xffff){      //Uncompressed block of 16384 bytes
            SendBlock4bit(pos-0x4000,dataCnt,Dly4Z80us);     //Send the block not compressed
            if(c==1) {
                ChunkPos=pos-CHUNKSIZE;                                     //Save current file position
                ChunkCompressed=false;
            }
          }
          else
          {                           //Compressed block of (lenData) bytes
            numRepeats=0;
            valueRepeats=0;

            uncompress(posFile,dataCnt,numRepeats,valueRepeats,true); //Uncompress and send to spectrum
          }
          if(c==1){
            ChunkPos=posFile;                                    //Save current file position
            ChunknumRepeats=numRepeats;                       //Save current numRepeats (if any)
            ChunkvalueRepeats=valueRepeats;                   //Save value to repeat (if any)
            ChunkCompressed=true;
          }

        }        
        break;               
    default: break;
  }
}

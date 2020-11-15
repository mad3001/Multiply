#define SCRSIZE 6912
#define SCR_BLKSIZE 432
#define SNA48KSIZE   49179

static uint8_t Z80Version;                            //2 for v1 compressed, 1 for v1 uncompressed, 23 for v2, 54 or 55 for v3
uint8_t numRepeats;                                   //Number of repetitions pending with compressed file
uint8_t valueRepeats;                                 //Value for repetitions pending with compressed file
static unsigned long posFile;              //Position in file when v2/v3 for pages

//-------------------------------------------------------------------------------------------------
void SendSCR(File *f, uint8_t *b, uint8_t nbloque) {
  unsigned long pos;
  uint16_t b2Read;
  uint16_t cnt;
  if (nbloque==0){   //0=send whole screen
    pos=SCRSIZE;
    while (pos>0) {
        if (pos<BUFRSIZE)
          b2Read = pos;
        else
          b2Read = BUFRSIZE;
          f->read(b,b2Read);
        for (cnt=0;cnt<b2Read;cnt++)
          Send4bit (b[cnt],Dly4SCRus);         
        pos-=b2Read;
    //Clear4bit();
    }
    f->close();
  }       
  else
  {     //non 0 send pieces of SCR_BLKSIZE bytes, 1..nn (nn*SCR_BLKSIZE=6912 bytes)
    f->read(b,SCR_BLKSIZE);
    for (cnt=0;cnt<SCR_BLKSIZE;cnt++){
          Send4bit (b[cnt],Dly4SCRus);         
    }
    //Clear4bit();
    if (nbloque==(uint8_t) (6912/SCR_BLKSIZE)) f->close();
    
  }
}

//-------------------------------------------------------------------------------------------------
void SendSCRSNA(File *f, uint8_t *b, uint8_t nbloque) {
  //unsigned long pos;
  //uint16_t b2Read;
  uint16_t cnt;
  uint8_t i;
  if (nbloque == 1){
    cnt=27;     //default position for Normal (no Shadow) screen
    if (f->size()!=SNA48KSIZE){       // for 128k snapshots
      f->seek(49181);         //Position for #7FFD 
      i=f->read();            //Value of Port #7FFD
      if ((i & 8) && ((i & 7) !=7)){
        cnt = f->size()-16384 ; //Last bank when Shadow and paged ram is not 7
      }
      else if ((i & 8) && ((i & 7) ==7)) cnt = 32795; //If Shadow and ram paged is 7
    }
    f->seek(cnt);
  }
  f->read(b,SCR_BLKSIZE);
  for (cnt=0;cnt<SCR_BLKSIZE;cnt++){
        Send4bit (b[cnt],Dly4SCRus);         
      
  }
  if (nbloque==(uint8_t) (6912/SCR_BLKSIZE)) f->close();
}

//-------------------------------------------------------------------------------------------------
void SendSCRZ80(File *f, uint8_t *b, uint8_t nbloque) {
  unsigned long pos;
  //uint16_t b2Read;
  //uint16_t cnt;
  //uint8_t i;
  uint16_t lenData;                   //Will hold length of data block 0xFFFF for uncompressed 16384 bytes, 0x3xxx for compressed
  uint8_t pageNumber;                 //Number of page into Z80 snapshot (only versions 2 and 3 of Z80 snapshot)
  
  if (nbloque == 1){
      numRepeats=0;
      valueRepeats=0;          
      f->seek(0);
      f->read(b,31);    //Read 1st 31 bytes (0..30)
      if ((b[6]!=0) | (b[7]!=0)) {
        Z80Version = (b[12] & 32) ? 2 : 1;               // 2 for v1 compressed, 1 for v1 uncompressed
        posFile = 30;                                        //Initial pos is 30
      }
      else
      {
          Z80Version = 4;       //4 for v2 or v3 compressed, 3 for v2 or v3 uncompressed
          //for v2,v3 have to locate page 8 (4000-7FFF page 5)
          pos=32+b[30]; // Position in file for 1st block
          do{      //version 2 and 3 uses a block system. Each have 2 bytes info for length and 1 bytes for page number of block
            posFile=pos+3;                //Position where to begin uncompress
            if (f->curPosition()!=pos) f->seek(pos);
            lenData= (uint16_t) (f->read());        //Get Low Byte Length of block
            lenData+= (256* (uint16_t) (f->read())); //Length of block
            if (lenData==0xffff){       //Is length=0xFFFF...
              pos += 0x4000;            //...uncompressed block of 16384 bytes
            }
            else
            {
              pos += (unsigned long) lenData; 
            }
            pos += 3;               // Position for next block (or end of file if no more blocks)
            pageNumber=f->read();        //Get Page Number
          } while(pageNumber!=8);         //If Page found then exit do while, also we're ready for reading the block
          if (lenData==0xffff) Z80Version = 3; //3 for v2 or v3 ucompressed
      }
  }
  switch (Z80Version) {
    case 1:
      // Uncompressed v1 block
      SendBlock4bit(posFile,SCR_BLKSIZE,Dly4Z80us);     //Send the block not compressed
      posFile+= SCR_BLKSIZE;
      break;
    case 2:
      // Compressed v1 block
      uncompress(posFile,SCR_BLKSIZE,numRepeats,valueRepeats,true); //Uncompress sending data of block to spectrum
      break;
    case 3:
      // Uncompressed v2/v3 block
      SendBlock4bit(posFile,SCR_BLKSIZE,Dly4Z80us);     //Send the block not compressed
      posFile+= SCR_BLKSIZE;
      break;
    case 4:
      // Compressed v2/v3 block
      uncompress(posFile,SCR_BLKSIZE,numRepeats,valueRepeats,true); //Uncompress and send to spectrum
      break;
  }

  if (nbloque==(uint8_t) (6912/SCR_BLKSIZE)) f->close();
}

//-------------------------------------------------------------------------------------------------
void SendSCRTAP(File *f, uint8_t *b, uint8_t nbloque) {
  //unsigned long pos;
  //uint16_t b2Read;
  uint16_t cnt;
    //non 0 send pieces of SCR_BLKSIZE bytes, 1..nn (nn*SCR_BLKSIZE=6912 bytes)
    f->read(b,SCR_BLKSIZE);
    for (cnt=0;cnt<SCR_BLKSIZE;cnt++){
          Send4bit (b[cnt],Dly4SCRus);         
    }
    //Clear4bit();
    if (nbloque==(uint8_t) (6912/SCR_BLKSIZE)) f->close();
    
}

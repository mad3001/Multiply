unsigned long TapPosition;
//-------------------------------------------------------------------------------------------------

void  SendTAP(File *f, uint8_t *buf){  //Send next TAP block
uint16_t *TAPLength;
uint8_t *TAPFlag;
//uint16_t *TAPStart;

uint8_t *ZXFlag;
uint16_t *ZXLength;
uint16_t *ZXStart;

uint8_t *TAP5Block;
uint16_t *TAP5Length;
uint16_t *TAP5Start;

uint16_t *ZXSkip;
   
    ZXFlag=buf;                                   //(1)Flag required by ZX
    ZXLength=(uint16_t *) (buf+1);                //(2)Length required by ZX
    ZXStart=(uint16_t *) (buf+3);                 //(2)Start address required by ZX
    
    TAPFlag=(buf+5);                              //(1)Will hold flag from TAP file... It came 1st byte to send
    TAPLength=(uint16_t *) (buf+6);               //(2)Will hold length from TAP file... It came 2nd and 3rd byte to send
    
    TAP5Block=(buf+8);                            //(1)Will hold status that Arduino will send to ZX
    TAP5Length=(uint16_t *) (buf+9);              //(2)Will hold the length that Arduino will send to ZX
    TAP5Start=(uint16_t *) (buf+11);              //(2)Will hold the length that Arduino will send to ZX
        //Take care...TAP5Length,TAP5Start are inside TAP5Block (5 bytes)!!!
    ZXSkip=(uint16_t *) (buf+13);                 //(2)Will hold bytes to skip when sending less bytes that into entry of TAP

    TapPosition = f->curPosition() + 3;           //Will send to spectrum skipping first 3 bytes and 1 char less (will be read in a moment)
    if(TapPosition>f->size())
    {
      f->seek(0);                                 //Loop TAP when arriving end of TAP so it's cicling (required for some multiload games)
      TapPosition=3;
    }

    f->read(TAPLength,2);                         //Reading length of data (length includes Flag and CRC -ZXlength + 2 bytes-)
    *TAPLength -=  2;                             //ZX Length is 2 less than TAP File (discount Flag and checksum)
    *TAPFlag = f->read();                         //Read Flag (will not be sent to spectrum as data)

    if (*TAPFlag!=*ZXFlag)                        //Flag differs so send error and skip this block in TAP
    {
      TAP5Block[0]=0xFF;                          //Status=Error Flag
      *TAP5Length=0;                              //Length=0 (no data to load)
      *TAP5Start=0;                               //Start=0 (no data to load)
      SendBuf4bit(TAP5Block, 5,Dly4Z80us);        //Send Status, Length and Start address to Spectrum
      f->seekCur(1+(*TAPLength));                 //Error flag (0xFF) length will be 0,not send additional data but we have move to next entry in TAP
      return;
    };
    
    *ZXSkip=0;                                    //Initial value of skip is 0 (no skip last bytes)
    if(*ZXLength==*TAPLength)                     //Perfect match for length
    {
      TAP5Block[0]=0x00;                          //Status=OK 
      *TAP5Length=*TAPLength;                     //Length=requested length (same as TAP length)
    }
    else if(*ZXLength<*TAPLength)                 //ZX requiring less length than available in TAP
    {
      TAP5Block[0]=0x01;                          //Status=Requested less length than available
      *TAP5Length=*ZXLength;                      //Length=requested length (will send less byte than available as per TAP length)
      *ZXSkip=(*TAPLength)-(*ZXLength);           //Byte to skip after sending data
    }
    else                                          //ZX requiring more length than available in TAP
    {
      TAP5Block[0]=0x02;                          //Status=Requested more length than available
      *TAP5Length=*TAPLength;                     //Length=TAP length (will send less than requested length)
    }

    *TAP5Start = *ZXStart;
    if(*TAP5Start<0x4000)                         //Starting below #4000, cut part at the beginning
    {
      *TAP5Length = (*TAP5Length) - (0x4000-*TAP5Start);  //Length will be lower as conflict with #0000-#3FFF area
      TapPosition+=(0x4000-*TAP5Start);           //Update new position skipping bytes overlapping rom zone 
      *TAP5Start=0x4000;                          //Fix Start to 0x4000
    }
    
    if((0xFFFF-(*TAP5Length)+1)<(*TAP5Start))        //Check Start+Length does not exceed 0xFFFF (avoid overlap with ROM)
    {
      *ZXSkip=(*TAP5Start)-(0xFFFF-(*TAP5Length)+1);//Bytes exceding 0xFFFF to be discarded at the end of loading
      (*TAP5Length)=(*TAP5Length)-(*ZXSkip);      //Limiting length
    }

    SendBuf4bit(TAP5Block, 5,Dly4Z80us);           //Send Status, Length and Start address to Spectrum
    delayMicroseconds(100);             //Wait a bit to send the data to load
    SendBlock4bit(TapPosition,*TAP5Length, Dly4Z80us);

    if ((*ZXSkip)!=0) f->seekCur(*ZXSkip);        //If have to skip bytes, do it so pointing to next Entry in TAP file      

    f->read();  //Always skip Checksum (not checked)

    //during TAP usage never close file.... only reseting spectrum will ask Arduino go to root and there will be closed  
}

uint8_t SCRposTAP(File *f, uint8_t *buf){     //Get position in TAP where Screen is (if any), return true if found, false if not found
  unsigned long *pos = (unsigned long*) buf;  //will hold position to locate Screen in TAP file
  uint16_t *len = (uint16_t *) buf+4;         //will hold length of block of data into TAP
  uint8_t *flag = (uint8_t *) buf+6;          //will hold flag of block
  uint16_t *Strt = (uint16_t *) buf+7;        //will hold starting address of a block of Bytes into TAP
  *pos=0; //initialize

  while(*pos < f->size() and f->available())
  {
    f->seek(*pos);
    f->read(len,2);                            //Get length of block
    if ((*len)==0x13)                          //Header block, let's check if is data and also beginning in 16384 and length>=6912
    {
      *flag=f->read();                         //Get flag
      if ((*flag)==0x00)                       //0x00 for header (Program, Bytes, etc...)
      {
        *flag=f->read();                       //Get Type of header
        if ((*flag)==0x03)                     //0x03 for Bytes
        f->seekCur(12);                        //Advance 12 bytes arriving to Starting address
        f->read(Strt,2);                       //read starting address
        if((*Strt)==16384)
        {
          f->seekCur(6);                       //Advance until beginning of data for scr
          return 0x01;                         //Screen found into Bytes
        }
      }
    }
    if ((*len)==6914)                          //Length is always 2 more or real length (because flag and crc)
    {
      *flag=f->read();                          //Get flag
      if ((*flag)==0xFF)
      {
        return 0x01;                           //Screen found, position was set to beginning of screen so can be retrieve later-on
      }
    }
    *pos += (unsigned long) *len;              //Length does not include the 2 byte of the own data for length
    *pos += 2;                                 //so add also the 2 byte
  }
  return 0x00;                                 //Screen not found
}

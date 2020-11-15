   #define ROMSETSIZETUN 524336
   #define ROMSETBLKSIZE 32768
   #define INPUTTIMEOUT  4000
   #define NUMBLOCKS 32768/BUFRSIZE // 32K/BUFRSIZE Must be aligned (MOD = 0)
   #define LASTBLOCK 31


//-------------------------------------------------------------------------------------------------
void SendRomsetBlock4b(uint8_t block) {
  long pos;
  uint16_t CRC;
  uint8_t dataCnt;
  uint16_t dataCnt2;
  
  pos=block;
  pos *=ROMSETBLKSIZE;
  CRC=0;
  dataCnt = 0;
  delay(DlyROMSETms); // Wait for Spectrum to be ready
  for (dataCnt=0;dataCnt<NUMBLOCKS;dataCnt++) {
    SendBlock4bit(pos+dataCnt*BUFRSIZE,BUFRSIZE,Dly4ROMSETus);
    for (dataCnt2=0;dataCnt2<BUFRSIZE;dataCnt2++)
      CRC+=myBuf[dataCnt2];
    }
   dataCnt= block+1;
   CRC+=dataCnt;
   Send4bit(dataCnt,Dly4ROMSETus);
   dataCnt=CRC % 256;
   Send4bit(dataCnt,Dly4ROMSETus);
   dataCnt=CRC / 256;
   Send4bit(dataCnt,Dly4ROMSETus);
   if (block == LASTBLOCK) myFile.close();
}


//-------------------------------------------------------------------------------------------------
void RomsetSerialTunnel(uint8_t cmd, bool nodrop){
  unsigned long cnt;
  unsigned long LRtInit;
  uint8_t c;
  
  //Release4bit();
  UCSR0B |= 0x08; // Activate TX
  if (nodrop) Serial.write(cmd);
  cnt=1;
  LRtInit=millis();
  while (cnt< ROMSETSIZETUN && millis()<LRtInit+INPUTTIMEOUT ) {
    if (Serial.available()) {
      c=Serial.read();
      Serial.write(c);
      LRtInit=millis();
      cnt++;
    }
  }
  UCSR0B &= 0xF7; // Deactivate TX
  //Init4bit();
}

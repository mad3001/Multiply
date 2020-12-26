#include <BlockDriver.h>
//#include <FreeStack.h>
#include <MinimumSerial.h>
#include <SdFat.h>
#include <SdFatConfig.h>
#include <sdios.h>
#include <SysCall.h>

const uint8_t MultiplyVersion[8] = { 'M','U','L','T','v','1','.','2' }  ;  //Version 1.1 for command CMD_ZX2INO_REQ_ID
														// Version 1.2 fixed NO SD CARD

//#define PinPower_A7           // A7 for testing, Comment #define for D9 for Multiply+Dan2.x
#define pinPower A7             // Number of pin for testing, not need to comment this line as it's only used with PinPower_A7 is defined


//#include <SdFat.h>
#include "incCmdsFileTypes.h"
#include "incDelayDefs.h"

#define DEFAULT_TIMEOUT 1000   // Default Milliseconds for serial timeouts
#define CS_PIN 10              // CS on Pin 10 (Nano SS)
#define BUFRSIZE 512

#define SCR_BLKSIZE 432       //for loading SCR in "pieces"

#define HW16K 1
#define HW48K  2
#define HW128K  3

SdFat SD;
File myFile; 
File CurDir;
uint8_t myBuf[BUFRSIZE];
bool SdCardOk = false;
bool FileOk = false;
uint8_t HWZX = HW128K;              //Default Hardware spectrum: 1=16k, 2=48k, 3=128k

//-------------------------------------------------------------------------------------------------
void setup() { 

  #ifdef PinPower_A7
    pinMode(pinPower,INPUT);   
  
    #if FASTADC
     // set prescale to 16 so analogRead takes less time
     sbi(ADCSRA,ADPS2) ;
     cbi(ADCSRA,ADPS1) ;
     cbi(ADCSRA,ADPS0) ;
    #endif 
  #endif
  
  DDRB&=0xFD; // PortB bit 1 as input D9
  PORTB&=0xFD; // PortB bit 1 as 0 (no pullup)    
  Serial.begin(57600,SERIAL_8N2);
  UCSR0B &= 0xF7; // Deactivate TX  
  InitJoyPassT();
  if (SD.begin(CS_PIN)) SdCardOk = true;  
  Init4bit();
  CurDir = SD.open(ROOTDIR, O_READ);
}

/*
void debug(uint8_t *b, uint8_t len) {
  uint8_t i;
  UCSR0B |= 0x08; // Activate TX  
  delay(15);
  Serial.println("Dbg>");
  for (i=0;i<len;i++) {
    Serial.print(b[i],HEX);
    Serial.write(' ');
  }
  Serial.println();
  delay(15);
  UCSR0B &= 0xF7; // Deactivate TX
}*/

//-------------------------------------------------------------------------------------------------
void loop() { 
  #define cmdBufSize 8 //64
  uint8_t cmdBuf[cmdBufSize];
  uint16_t *index;
  #ifdef PinPower_A7
    bool test=false;
  #endif
  
  while (!Serial.available()){
    JoyThrough(); 
    #ifdef PinPower_A7
      test=(analogRead(pinPower)<900);
    #endif
  }
  #ifdef PinPower_A7
    if (test) {
  #else
    if ((PINB & 0x02) == 0) {  // Avoid power to pins if spectrum is disconnected
  #endif
      ShutdownPower4bit();     // Reaches here because a power off spectrum is read as a Serial 0x00 data.
      Init4bit(); // Loops internally until power is back on
    } 
  cmdBuf[0]=Serial.read();
  switch (cmdBuf[0]) {
    case CMD_ZX2INO_REQ_ID:
            delay(DlyROMSETms);//DlyANSWERus); //Required
            for(int i=0;i<8;i++) Send4bit(MultiplyVersion[i],DlyANSWERus);
            break;
    case CMD_ZX2SD_SETZXTYPE:
            if (getBuffer_N(myBuf,1)) {
                HWZX = *myBuf ;
            };
            break;     
    case CMD_ZX2SD_OFREAD:       
            if (getBuffer_0(myBuf)) 
              FileOk = (*OpenFile(&myFile,myBuf) == 0x01);     
            break; 
    case CMD_ZX2SD_OFREAD_IX:   
            if (getBuffer_N(myBuf,2)) {
              index=(uint16_t *)(myBuf);
              FileOk = OpenFileIX(&CurDir,&myFile,*index);
            };
            break; 
    case CMD_ZX2SD_CD_ROOT:
            OpenDir(&CurDir, (uint8_t *) ROOTDIR);
            SD.chdir(true);
            break;
    case CMD_ZX2SD_CD:
            if (getBuffer_0(myBuf)) {
              if (OpenDirTmp(myBuf)) {
                OpenDir(&CurDir,myBuf);  
                SD.chdir((char *) myBuf,true); 
              };
            };
            break;
    case CMD_ZX2SD_CD_IX:
            if (getBuffer_N(myBuf,2)) {
              FileOk = OpenDirIX(&CurDir,&myFile,myBuf);
              if (FileOk) SD.chdir((char *)myBuf,true); 
            };
            break; 
    case CMD_ZX2SD_GETDIR:
            //delay(DlyLAUNCHms);   // Wait for Spectrum to be ready <-Not required
            GetDir(&CurDir,myBuf);
            break;    
    case CMD_ZX2SD_LS_RELATIVE:
            //delay(DlyLAUNCHms);   // Wait for Spectrum to be ready <-Not required
            if (getBuffer_N(myBuf,2)) {
              index=(uint16_t *)(myBuf);
              ListDir(&CurDir, SdCardOk, myBuf, index);
            }
            break;
    case CMD_ZX2SD_LS_ABSOLUTE:
            if (getBuffer_0(myBuf)) {
            //delay(DlyLAUNCHms);   // Wait for Spectrum to be ready <-Not required
              ListDirTmp(myBuf);
            };
            break;        
    case CMD_ZX2SD_ROMSETBLK4B:
            if (getBuffer_N(cmdBuf+1,1) && FileOk && SdCardOk)
              SendRomsetBlock4b(cmdBuf[1]-1);          
            break;
    case CMD_ZX2SD_SNA_128K:
    case CMD_ZX2SD_SNA_48K:
            if (getBuffer_N(cmdBuf+1,1)) {
              //delay(DlyLAUNCHms); // Wait for Spectrum to be ready <-Not required
              SendSNA(cmdBuf[0],cmdBuf[1],myBuf);
              if (cmdBuf[1] == 10) myFile.close();
            };
            break;  
    case CMD_ZX2SD_Z80_128K:
    case CMD_ZX2SD_Z80_48K:
    case CMD_ZX2SD_Z80_16K:
             if (getBuffer_N(cmdBuf+1,1)) {
              //delay(DlyLAUNCHms); // Wait for Spectrum to be ready <-Not required
              SendZ80(cmdBuf[0],cmdBuf[1]);
              if (cmdBuf[1] == 10) myFile.close();
            };
            break;         
    case CMD_ZX2SD_SCRTAP:
             if (getBuffer_N(cmdBuf+1,1)) {
              //delay(DlyLAUNCHms); // Wait for Spectrum to be ready <-Not required
              SendSCRTAP(&myFile,myBuf,*(cmdBuf+1));
            };
            break;         
    case CMD_ZX2SD_SCR:
            if (getBuffer_N(cmdBuf+1,1)){   //0=Read whole file, 1..nn=read that piece of SCR_BLKSIZE bytes 
              //delay(DlyLAUNCHms); // Wait for Spectrum to be ready <-Not required
              SendSCR(&myFile,myBuf,*(cmdBuf+1));
            };
            break;
    case CMD_ZX2SD_SCR_FROM_SNA:
            if (getBuffer_N(cmdBuf+1,1)){   //1..nn=read that piece of SCR_BLKSIZE bytes 
              //delay(DlyLAUNCHms); // Wait for Spectrum to be ready <-Not required
              SendSCRSNA(&myFile,myBuf,*(cmdBuf+1));
            };
            break;
    case CMD_ZX2SD_SCR_FROM_Z80:
            if (getBuffer_N(cmdBuf+1,1)){   //1..nn=read that piece of SCR_BLKSIZE bytes 
              //delay(DlyLAUNCHms); // Wait for Spectrum to be ready <-Not required
              SendSCRZ80(&myFile,myBuf,*(cmdBuf+1));
            };
            break;
    case CMD_ZX2SD_GETINFO:
            if (getBuffer_N(myBuf+256,2)) {
             // delay(DlyLAUNCHms); // Wait for Spectrum to be ready <-Not required
              GetMoreInfoIX(&CurDir,&myFile,myBuf+256);
            };
            break;
    case CMD_ZX2SD_TAP:
            if (getBuffer_N(cmdBuf+1,5)) {
              delay(DlyTAPms); // Wait for Spectrum to be ready 
              SendTAP(&myFile,cmdBuf+1);
            };
            break;
    case CMD_PC2AR_ROMSET_TUNNEL:
    case CMD_PC2AR_ROMSET_TUN2:
            RomsetSerialTunnel(cmdBuf[0],true);
            break;
    case CMD_PC2AR_BIN_TUNNEL:
            RomsetSerialTunnel(cmdBuf[0],false);
            break;      
    case 0x00:setup(); break; // This is the recognized command on right dandanator button (hardware transmitted)               
    default:  break;
  } 
 }

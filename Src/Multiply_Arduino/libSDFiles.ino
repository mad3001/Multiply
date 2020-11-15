  #define SUCCESS      0x01
  #define FAIL         0x00
  #define SNA48KSIZE   49179
  #define SNA128KSIZE  131103
  #define SNA128KSIZE2 147487
  #define Z80V1_48KSIZE 49182
  #define SCRSIZE      6912
  #define ROMSETSIZESD  524288
  #define nameMaxS     64


//-------------------------------------------------------------------------------------------------
bool OpenDir(File *Dir, uint8_t *b) {
  if (SD.exists((char *) b)) {
    if (*Dir) Dir->close();
    *Dir = SD.open((char *)b, O_READ); 
    return Dir->isDir();
  }
  else
    return false;
}


//-------------------------------------------------------------------------------------------------
bool OpenDirTmp(uint8_t *b) {
 File tmpDir;
 bool response;
  response = OpenDir(&tmpDir, b);
  tmpDir.close();
  return response;
}

bool OpenDirIX(File *Dir, File *f,uint8_t *buf){
   uint16_t *index;

  index=(uint16_t *)(buf);
  
   if (*f) f->close();
   if (f->open(Dir,*index, O_READ)){  
     f->getName((char *)buf,nameMaxS);
      return OpenDir(Dir,buf);
    }
  else return false;

   
}

//-------------------------------------------------------------------------------------------------
uint8_t* OpenFile(File *f, uint8_t *b) {
  #define off 128
  #define nameoff 256
  b[off] = FAIL;
  if (SD.exists((char *)b)) {
    if (*f) f->close();
    *f=SD.open((char *)b,O_READ);
    f->seek(0);
    if (!f->isDir()) {
      f->getName((char *)b+nameoff,nameMaxS);
      b[off]=SUCCESS;
      SetFileType(b+off+1, b+nameoff, f);
    }
  }
  return b+off;
}


//-------------------------------------------------------------------------------------------------
bool OpenFileIX(File *Dir, File *f, uint16_t ix) {  
  if (*f) f->close();
  if (f->open(Dir,ix, O_READ)){
    if (!f->isDir()) {
      f->seek(0);
      return true;
    }
  }
  return false;
}


//-------------------------------------------------------------------------------------------------
void FileExtension(uint8_t *fname, uint8_t *temp) { 
    strlcpy((char *)temp,(char *)fname+strlen((char *)fname)-4,5);
    strupr((char *)temp);
}


//-------------------------------------------------------------------------------------------------
void getFileChunk(File *f, uint8_t* b, unsigned long startPos, uint16_t dataBytes){ 
   f->seek(startPos);
    f->read(b,dataBytes); 
}


//-------------------------------------------------------------------------------------------------
bool SetFileType(uint8_t *ft, uint8_t *fname, File *f) { 
  unsigned long fsize;
  uint8_t scratch[38];
  uint16_t *TAPLength= (uint16_t *) scratch;    //Reasign 2 bytes of scratch for uint16_t 
  uint8_t *CRC= (scratch+2);                    //Reasign 1 byte of scratch for uint8_t 

  // Discard Linux and Mac hidden files
  if (fname[0] == '.')
    return false;   
  // Check Directory
  if (f->isDir()) {
    *ft = FT_DIRECTORY;
    return  true;
  }
  fsize = f->fileSize();
  FileExtension(fname,scratch); //Take file extension
  // Check SNA
  if (strcmp((char *)scratch, ".SNA")==0) {
    const int iSize=27;
    f->seek(0);
    f->read(scratch,iSize);  //get header data
    for(int i=1;(i<iSize) && (scratch[i-1]==scratch[i]);i++) if (i==(iSize-1)) return false; //if header data all bytes are the same, discard
    if ((fsize == SNA48KSIZE) && (HWZX >=HW48K))
    {
      *ft = FT_SNA_48K;
      return true;
    }
    if ((fsize == SNA128KSIZE || fsize == SNA128KSIZE2) && (HWZX >=HW128K))
    {
      *ft = FT_SNA_128K;
      return true;
    }
  }
  // Check Screen
  if (strcmp((char *)scratch, ".SCR")==0 && fsize==SCRSIZE) {
    *ft = FT_SCR;
    return true;
  }
  // Check Romset
  if (strcmp((char *)scratch, ".ROM")==0 && fsize==ROMSETSIZESD) {
    f->seek(0x3FE0);  //Version field
    f->read(scratch,5);  //get version info (vx.x or vxx.x)
    if ((scratch[0]!='v') || ((scratch[1]<'4') && (scratch[2]=='.')))
    {
      f->seek(0x3FEC); //MLD field
      f->read(scratch,3);  //get MLD chartext (ie Sword of Ianna)
      scratch[3]=0x00; //ender for string
      if (strcmp((char *)scratch, "MLD")==0) return false;
    }
    *ft = FT_ROMSET;
    return true;
  } 
  // Check Z80
  if (strcmp((char *)scratch, ".Z80")==0) {
     f->seek(0);
     f->read(scratch,38);  //get data
     if ((scratch[6]==0) && (scratch[7]==0)) {
        if ((scratch[30]!=23) && (scratch[30]!=54) && (scratch[30]!=55)) return false;  //avoid non valid Z80 files
        if (scratch[30]==23){
          *ft=(scratch[34]< 3) ? FT_Z80_48K : FT_Z80_128K;
        }
        else
        {
          *ft=(scratch[34]< 4) ? FT_Z80_48K : FT_Z80_128K;
        }
        if (*ft==FT_Z80_48K){
            if(scratch[37] & 0x80) *ft=FT_Z80_16K;
        }
        if (((*ft==FT_Z80_48K) && (HWZX <HW48K)) || ((*ft==FT_Z80_128K) && (HWZX <HW128K))) return false;
        
        //f->seek(0); //f->rewind() no funciona.... a saber porqué
        return true;
     }
     else {       //Here for v1 z80 snapshot 
      *ft=FT_Z80_48K;
      if (HWZX <HW48K) return false;
      if (scratch[12] & 0x20)           //Here for v1 z80 compressed
      {
          f->seek(fsize-4);             //Go to end of file where should exists 00 ED ED 00
          f->read(scratch,4);
          //f->seek(0); //f->rewind() no funciona.... a saber porqué
          if ((scratch[0]==0) && (scratch[1]==0xED) && (scratch[2]==0xED) && (scratch[3]==0))   //check file compressed is ended with 00 ED ED 00
            return true;
      }
      else if (fsize==Z80V1_48KSIZE)    //Here for v1 z80 uncompressed
      {
        const int iSize=30;
        f->seek(0);
        f->read(scratch,iSize);  //get header data
        for(int i=1;(i<iSize) && (scratch[i-1]==scratch[i]);i++) if (i==(iSize-1)) return false; //if header data all bytes are the same, discard
        return true;
      }
     }
  }   
  //Check TAP
  if (strcmp((char *)scratch, ".TAP")==0) {
     f->seek(0);
     f->read(scratch,2);  //get "supposed" length of 1st data (usually will be header for PROGRAM file... so it should be short)
     if (f->peek()!=00) return false;
     *CRC=0;
     for(;(*TAPLength)>0;(*TAPLength)--) (*CRC) ^= ((uint8_t) f->read());
     if (*CRC) return false;
     *ft=FT_TAP; 
     return true;
  }
  // Not recognized
  return false;
}

void  GetMoreInfoIX(File *Dir, File *f, uint8_t *buf){  //Get more info for Directory/File as per Index
  uint8_t i;
  uint16_t *index;
  //Next used only for FT_ROMSET
  uint8_t *NumVers;
  uint8_t *NumSubVers;
  uint8_t *DataToSend;
  uint8_t *DataToSend36;

  
  index=(uint16_t *)(buf);
  if (OpenFileIX(Dir,f,*index)){  
    f->getSFN((char *)buf+1);
    if(SetFileType(buf, buf+1, f)){
      switch (*(buf)){
        case FT_Z80_16K:
        case FT_Z80_48K:
        case FT_Z80_128K:                    //Send 3 bytes 
            f->seek(0x0006);                 //PC for check if v1 or v2/v3
           *(buf+2) = f->read();   //byte 6
           *(buf+3) = f->read();   //byte 7
           if((*(buf+2)==0) && *(buf+3)==0){      //Version 2 or 3
              f->seek(0x001E);                 //Version byte for length
             *(buf+2) = f->read(); 
              f->seek(0x0022);                 //Hardware Machine
             *(buf+3) = f->read(); 
              f->seek(0x0025);                 //Bit 7 for Hardware Machine
             *(buf+4) = f->read(); 
              for (i=2;i<5;i++) Send4bit(*(buf+i),Dly4DIRLISTus);
              break;
           }
           else
           {
              for(i=0;i<3;i++) Send4bit(0xFF,Dly4DIRLISTus);          //For no valid use 0xFF
           };
           break;
        case FT_ROMSET:                       //Send 8 bytes for version and 1 for Number of Games in Romset
           NumVers=buf+2;                     //Locating NumVers in pos 2 (1 byte)
           NumSubVers=buf+3;                  //Locating NumVers in pos 3 (1 byte)
           DataToSend=buf+4;                  //Data to send. 1st block is 9 bytes (pos 4 to 12)
           DataToSend[8]=0xFF;                //Default Number Games as not valid 0xFF
           f->seek(0x3FE0);                   //Position for string of version in all versions
           f->read(DataToSend,8);             //Read string for version
           //Version is like vx.x or vxx.x Different versions: v4.x, v5.0, v5.0-v5.2, >=v5.3
           if ((DataToSend[0]!='v') || ((DataToSend[2]!='.') && (DataToSend[3]!='.')))          //neither vx.x nor vxx.x
           {
              DataToSend[0]=0xFF;          //Default mark as not valid 0xFF
           }
           else
           {
             if (DataToSend[2]=='.')
             {
                DataToSend[2]=0x00;         //Change '.' to 0x00
                *NumVers=atoi((char *)(DataToSend+1));     //Convert version text to number
                *NumSubVers=atoi((char *)(DataToSend+3));   //Convert subversion text to number
                DataToSend[2]='.';          //Revert to '.'
             }
             else 
             {
                DataToSend[3]=0x00;         //Change '.' to 0x00
                *NumVers=atoi((char *) (DataToSend+1));     //Convert version text to number
                *NumSubVers=atoi((char *) (DataToSend+4));   //Convert subversion text to number             
                DataToSend[3]='.';               //Revert to '.'
             }
              switch(*NumVers)
              {
                case 4:                        //Version 4.x had num.games in 0x1C84 and it was forced to have 10 games (non compressed)
                  f->seek(0x1C84);
                  DataToSend[8]=f->read();              //Last byte is Number of Games
                  break;                  
                case 5:                       //Version 5.x have num.games in 0xA00 or 0xC00 
                  if (*NumSubVers==0)
                  {     //Version 5.0 could have it in 0xA00 or 0xC00 (if 0xA00=0xFF then it should be in 0xC00)
                    f->seek(0x0A00);
                    if((DataToSend[8]=f->read())==0xFF)
                    {
                      f->seek(0x0C00);
                      DataToSend[8]=f->read();
                    }
                  }
                  else
                  {
                    f->seek(0x0C00);
                    DataToSend[8]=f->read();
                  }
                  break;
                case 6 ... 254:               //Version >=6.0
                   f->seek(0x0E00);                         //Number of Games for versions >=6.0
                   DataToSend[8]=f->read();                 //Last byte is Number of Games
                   break;
                default:
                  break;
             }
           }

           SendBuf4bit(DataToSend,9,Dly4DIRLISTus);
           
           if ((DataToSend[8]==0xFF) || (DataToSend[8]==0x00))   break;    //No valid number of games or 0 games don't send more data

           delay(DlyROMSETms);                          //Little pause prior to begin sending data of games !!! To check timing for non-excesive wait here!!
           DataToSend36=buf+13;                            //Data to send. Other blocks char 13 to 48 (36 bytes)
           for (i=1;i<=DataToSend[8];i++)                  //Valid number of Games: btw 1 and 25
           {
              if(*NumVers > 4)  f->seekCur(31);             //v4 have Gamename inmediatly, >=5.0 have 31 bytes prior to GameName
              if(*NumVers==4)                               //Additional v4 info
              {
                f->read(DataToSend36,33);                  //Reading Gamename (2 bytes)
                DataToSend36[33] = 0;                       //v 4 was uncompressed
                DataToSend36[34] = 3;                      //v 4 was only for 48k GameTypes
                DataToSend36[36] = 0;                       //v 4 had no Hold Screen
                f->seekCur(357);                           //Skip 357 bytes to arrive to next GameName
              }
              else 
              {
                f->read();                                    //Discarding Game Number of each
                f->read(DataToSend36,2);                      //Reading Icon (2 bytes)
                DataToSend36[2]=' ';                          //Insert space btw Icon and game
                f->read(DataToSend36+3,30);                   //Reading GameName (30 bytes)
                f->read();                                //Discard byte 64 (Original Hardware)
                f->read(DataToSend36+33,3);               //Get 3 bytes for: GameCompr, Gametype, ScreenHold
              };
              SendBuf4bit(DataToSend36,36,Dly4DIRLISTus);
              if((*NumVers==5) && (*NumSubVers==0)) f->seekCur(68);  //v5.0 have 68 (Total 136 bytes)
              else if(*NumVers!=4) f->seekCur(63);          // >=5.0 have 63 bytes after (Total 131 bytes)
           };
           Clear4bit();
           break;
        case FT_TAP:
           DataToSend=buf+1;                                //Assing place to store data
           f->seek(4);                                      //Skip header, Flag and Type of Header and go directly to 10 bytes for PROGRAM name
           f->read(DataToSend+1,10);                        //Getting PROGRAM name
                      
           DataToSend[0]=SCRposTAP(f,DataToSend+11);        //byte 0 will be 0x01 if located screen into TAP (block of 6912 bytes)
           
           for (i=1;i<11;i++){
            if((DataToSend[i]<32) || (DataToSend[i]>127)) DataToSend[i]=32; //replace tokens with space
           }
           SendBuf4bit(DataToSend,11,Dly4DIRLISTus);        //Send 11 bytes to zx
           return;  //avoid f->close();  MARIO CHEQUEAR, LO MISMO PODEMOS DEJAR EL FICHERO ABIERTO Y ASI EL PREVIEW NO TIENE QUE VOLVER A ABRIRLO
          break;
        default:
          break;
      }
    } 
    //f->seek(0);
    f->close(); 
  }
}

  #define nameMaxS 64   // Filename as per list
  #define maxChapters 8 // Max number of chapters (8+1=9)
  #define nameLen  30   // Filename cut for sending to spectrum  
  #define msgLen  nameLen+4 // message len per directory entry
  #define maxFLen 256   // Max length of Directory Name (including last 0x00)
  #define locCH0 400    // Location for chapter 0 data within buffer

  #define entriesPerPage 23
  #define pagesPerChapter 11
  #define maxFiles (entriesPerPage*pagesPerChapter)  // Max number of files -1 (value=0..254)
  #define maxTotalFiles ((maxChapters+1)*(maxFiles)) //Maximum of files for all chapters

  #define FakeIndex 0xFFFF //Fake index number for 1st chapter


  #define tChaptersOffset 0x02
  #define tPagesOffset 0x03
  #define tFilesOffset 0x04
  #define indexOffset 0x0A
  #define degraded 0x1C
  #define lowdegrad 0x04
  #define highdegrad 0x08

//-------------------------------------------------------------------------------------------------
void FirstChapterScan(File *Dir, uint8_t *bufp) {
 
  uint16_t fileCnt = 1; //at least will exists 1 entry: FT_DIRECTORY,".."
  uint8_t chCnt = 1;
  uint16_t *dIx;
  uint16_t totIndex=0;
  uint16_t lastIndex=0;  
  uint16_t Sorted=0;
  char nname[76];
  char nname1[32]="";
  char nname2[32]="";
    //1st chapter exist at least with a FT_DIRECTORY and ".." (at least will be an empty directory)
     dIx=(uint16_t *)(bufp+indexOffset); 
     *dIx = FakeIndex; //1st chapter use fake index

    bufp[indexOffset]=0xFF;
    bufp[indexOffset+1]=0xFF;   //Always initalize Chapter 1 with 0xFFFF

    //1st process only Directories
    while (myFile.openNext(Dir, O_READ) && (fileCnt < maxTotalFiles)) {
      if (myFile.isDir() && !myFile.isHidden()){
        myFile.getSFN((char *) bufp+msgLen);
        if (SetFileType(bufp+msgLen, bufp+msgLen+1, &myFile)) {
          lastIndex = myFile.dirIndex();
          if ((fileCnt % maxFiles)==0)
          {
            dIx=(uint16_t *)(bufp+chCnt*2+indexOffset); 
            *dIx = lastIndex  ;
            chCnt++;
          }
          fileCnt++;
          myFile.getName(nname,76);
          totIndex+= (strlen(nname)+12)/13;
          memcpy(nname1,nname,31);              //Copy first 31 char from nname to nname1
          nname1[31]=0x00;                      //Force last byte as 0x00
          if(strcmp(nname1,nname2)<0) Sorted++; //If well sorted (nname1<nname2) then add 1 more
          memcpy(nname2,nname1,32);             //Copy new string as old string
        }
      }
      myFile.close();
    }
    //2nd process only Files
    Dir->rewindDirectory();
    while (myFile.openNext(Dir, O_READ) && (fileCnt < maxTotalFiles)) {
      if (myFile.isFile() && !myFile.isHidden()){
        myFile.getSFN((char *) bufp+msgLen);
        if (SetFileType(bufp+msgLen, bufp+msgLen+1, &myFile)) {
          myFile.getName(nname, 76);
          lastIndex = myFile.dirIndex();
          if ((fileCnt % (maxFiles))==0)
          {
            dIx=(uint16_t *)(bufp+chCnt*2+indexOffset); 
            *dIx = lastIndex  ;
             chCnt++;
          }
          fileCnt++;
          myFile.getName(nname,76);
          totIndex+= (strlen(nname)+12)/13;
          memcpy(nname1,nname,31);              //Copy first 31 char from nname to nname1
          nname1[31]=0x00;                      //Force last byte as 0x00
          if(strcmp(nname1,nname2)<0) Sorted++; //If well sorted (nname1<nname2) then add 1 more
          memcpy(nname2,nname1,32);             //Copy new string as old string
        }
      }
      myFile.close();
    }

    //Calculate degradation 
    totIndex = (1+lastIndex)/(1+totIndex);                //Ratio of degradation  (+1 for avoiding divide by 0)
    if (totIndex > highdegrad ) bufp[degraded] = 0x02;      //2 = too degraded
    else if (totIndex > lowdegrad ) bufp[degraded] = 0x01;  //1 = degraded
    else bufp[degraded] = 0x00;                             //Default is 0 = Not degraded (below ratio 2)

    //Calculate sorted
    Sorted = (fileCnt+1) / (Sorted+1);                    //Ratio of unsorted  (+1 for avoiding divide by 0)
    if (Sorted >highdegrad) bufp[degraded] = 0x02;          //2 = too degraded
    else if ((Sorted >lowdegrad) && (bufp[degraded] == 0x00)) bufp[degraded] = 0x01; //1 = degraded (Ratio >2)


    //Resume Counters for Chapters, Pages and # of files in last chapter
    bufp[tChaptersOffset] = chCnt; // total chapters 1..maxChapters+1
    
    chCnt = 1 + (uint8_t) ((fileCnt-1)/entriesPerPage);
    bufp[tPagesOffset] = chCnt; // Number of pages 1..pagesPerChapter*(maxChapters+1)
    
    chCnt = 1+(uint8_t) ((fileCnt-1) % maxFiles);  //Number of files in last valid chapter (value 1..MaxFiles)
    bufp[tFilesOffset] =  chCnt; // Number of files in last valid chapter (value 1..MaxFiles)
    
  /* only for debug
    bufp[tFilesOffset+1] =  (uint8_t) (fileCnt/256); //
    bufp[tFilesOffset+2] =  (uint8_t) (fileCnt%256); // 
    fileCnt= maxTotalFiles;
    bufp[tFilesOffset+3] =   (uint8_t) (fileCnt/256); //
    bufp[tFilesOffset+4] =  (uint8_t) (fileCnt%256); // 
    fileCnt= maxFiles;
    bufp[tFilesOffset+5] =  (uint8_t) (fileCnt); //
   */

}
 
//-------------------------------------------------------------------------------------------------
void ListDir(File *Dir, bool s, uint8_t *buf, uint16_t *chapterix) { 
  // Wrapper for ListChapter
  uint8_t i;
    memset(buf+locCH0,0x00,msgLen); // set final mark as all 0
    if (s) { // s means the folder actually exists
      if (myFile) myFile.close();
      if ((*chapterix!=0) && (*chapterix!=FakeIndex)) {
        Dir->seekSet(32 * (uint32_t) ((*chapterix)-0)); // Revisar esto !!!! AVISO !!!!
      }
      else {
        Dir->rewindDirectory();
        if (*chapterix==0) {
          FirstChapterScan(Dir, buf+locCH0); //Fill chapters data
        }
      }
      delay(DlyLAUNCHms*2);
      ListChapter(Dir,buf,chapterix);
    }
    else
    {
      delay(DlyLAUNCHms*2);
        if (*chapterix==0) {
          buf[locCH0]=FT_DIRECTORY; //1st item is directory
          buf[locCH0+1]='.'; //1st item is directory
          buf[locCH0+21]='.'; //1st item is directory
        }
      for (i=0;i<msgLen;i++) Send4bit(buf[i+locCH0],Dly4DIRLISTus); // Send last mark of chapter
    //debug(buf+locCH0,msgLen);
      
      memset(buf+locCH0,0x00,msgLen); // set final mark as all 0
          buf[indexOffset+locCH0]=0xFF;
          buf[indexOffset+1+locCH0]=0xFF;   //Always initalize Chapter 1 with 0xFFFF
          buf[tChaptersOffset+locCH0]=1; //1 chapter
          buf[tPagesOffset+locCH0]=1; //1 page
          buf[tFilesOffset+locCH0]=1; //1 file
      delay(DlyLAUNCHms*2);
    }
    for (i=0;i<msgLen;i++) Send4bit(buf[i+locCH0],Dly4DIRLISTus); // Send last mark of chapter
    
}


//-------------------------------------------------------------------------------------------------
void ListChapter(File *Dir, uint8_t *buf, uint16_t *chapterix)  {
  uint8_t i;
  uint16_t fileCnt = 0;
  uint16_t *dIx;
  bool onlyFiles = false;
    if (myFile) myFile.close();
  
    if ((*chapterix!=0) && (*chapterix!=FakeIndex)){
      Dir->seekSet(32 * (uint32_t) ((*chapterix)-0)); // Revisar esto !!!! AVISO !!!!
      myFile.openNext(Dir, O_READ) && (fileCnt < maxFiles);
      onlyFiles=myFile.isFile();
      myFile.close();
    }
    else {
    //1st chapter always have 1st entry as FT_DIRECTORY,".."
      Dir->rewindDirectory();
      memset(buf+255,0x00,msgLen); // set as all 0
      buf[255]=FT_DIRECTORY;
      buf[256]='.';
      buf[257]='.';
      for (i=0;i<msgLen;i++) Send4bit(buf[i+255],Dly4DIRLISTus);
      fileCnt++;
    }

    //1st send only Directories
    if(!onlyFiles){
      while (myFile.openNext(Dir, O_READ) && (fileCnt < maxFiles)) {  
        if (myFile.isDir() && !myFile.isHidden()){
          myFile.getSFN((char *)buf+256); //Short File Name for SetFileType
          if (SetFileType(buf+255, buf+256, &myFile)) {
            myFile.getName((char *)buf+256,nameMaxS);
            buf[256] = toupper(buf[256]);
            for (i=1;i<nameLen;i++) buf[256+i] = tolower(buf[256+i]);
            dIx=(uint16_t *)(buf+256+nameLen+1); 
            *dIx = myFile.dirIndex();
            *(buf+256+nameLen) = 0x00;         //This byte always with 0x00
            for (i=0;i<msgLen;i++) Send4bit(buf[i+255],Dly4DIRLISTus);
            fileCnt++;
          }
        }
        myFile.close();
      }
    }
    //now send only Files (without file extension)
    if ((*chapterix!=0) && (*chapterix!=FakeIndex)){
        Dir->seekSet(32 * (uint32_t) ((*chapterix)-0)); // Revisar esto !!!! AVISO !!!!
    }
    else {
      Dir->rewindDirectory();
    }

    while (myFile.openNext(Dir, O_READ) && (fileCnt < maxFiles)) {    
      if (myFile.isFile()&& !myFile.isHidden()){
        myFile.getSFN((char *)buf+256); //Short File Name for SetFileType
        if (SetFileType(buf+255, buf+256, &myFile)) {
          myFile.getName((char *)buf+256,nameMaxS);
          buf[256] = toupper(buf[256]);
          for (i=1;i<nameLen;i++)  buf[256+i] = tolower(buf[256+i]); 
          i=strlen((char *)buf+256);
          *(buf+256+i-4)=0x00; //remove extension if file have
          *(buf+256+nameLen) = 0x00;         //This byte always with 0x00
          dIx=(uint16_t *)(buf+256+nameLen+1); // ojo por si la aritmética de punteros se hace antes o después del cast.
          *dIx = myFile.dirIndex();      
          // Enviar desde el 255, 30+4 posiciones
          for (i=0;i<nameLen+4;i++) Send4bit(buf[i+255],Dly4DIRLISTus);
         fileCnt++;
        }
      }
      myFile.close();
    }
}

//-------------------------------------------------------------------------------------------------
void ListDirTmp(uint8_t *buf) {
  File tmpDir;
  bool test;
  test = OpenDir(&tmpDir, buf);
  ListDir(&tmpDir, test, myBuf,0x0000); // Always reads first chapter
  tmpDir.close();
}

//-------------------------------------------------------------------------------------------------
void GetDir(File *Dir,uint8_t *buf){
  uint16_t i; //Don't change to uint8_t, maxFLen is 256 so it hangs for loop if changed to uint8_t
  Dir->getName((char *)buf,maxFLen);
  for (i=0;i<maxFLen;i++) Send4bit(buf[i],Dly4DIRLISTus);
}
//repeatValue
// Repeat a value for a number of times or until len is reached
// Value is stored in Buffer if address of Buffer is not 0
// Value is sent to spectrum with 4bit if Buffer is 0
//-------------------------------------------------------------------------------------------------
void repeatValue (uint16_t &actlen, uint16_t len, uint8_t &numRepeats, uint8_t valueRepeats, boolean send4bit){
    while(actlen<len && numRepeats>0){
      if(send4bit) Send4bit(valueRepeats,Dly4Z80us);
      numRepeats--;
      actlen++;
    }   
}


//-------------------------------------------------------------------------------------------------
void uncompress(unsigned long &pos, uint16_t len, uint8_t &numRepeats, uint8_t &valueRepeats, boolean send4bit) {
    uint8_t c;
    uint8_t c2;
    uint16_t actlen;
    if (myFile.curPosition()!=pos) myFile.seek(pos);
    actlen=0;
    if (numRepeats>0) repeatValue(actlen, len, numRepeats,  valueRepeats,send4bit);
    while (actlen<len && myFile.available()){
        c=myFile.read();
        pos++;
        if(c==0xED){
            c2=myFile.read();
            pos++;
            if(c2==0xED){      //2 x ED then it's compressed dataa
                numRepeats=myFile.read();   //num of times to repeat
                valueRepeats=myFile.read();   //value to repeat
                pos+=2;
                repeatValue (actlen, len, numRepeats,  valueRepeats, send4bit);
            }
            else            //It was only 1 x ED, so not compressed
            { //Not ED-ED
                if(send4bit) Send4bit (c,Dly4Z80us);
                actlen++;
                if(actlen<len){     //only send if less than len... so if last byte of this block is ED then only 1 byte is sent
                    if(send4bit) Send4bit (c2,Dly4Z80us);
                    actlen++; 
                }
               else
                    pos--;    //We could not send 2nd byte so pos is 1 less
            }     
        }
        else
        {
            if(send4bit) Send4bit (c,Dly4Z80us);
            actlen++; 
        }
    }
}

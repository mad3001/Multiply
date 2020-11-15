//-------------------------------------------------------------------------------------------------
void Init4bit(){
  #ifdef PinPower_A7
    while (analogRead(pinPower)<900) yield(); // lock until spectrum is powered up.
  #else
    while ((PINB & 0x02) == 0) yield(); // lock until spectrum is powered up.
  #endif
    UCSR0B &= 0xF7; // Deactivate TX
    PORTC |= 0x0F;
    DDRC |=0x0F; // PortC bits 0..3 as Output A0, A1, A2, A3
    PORTD|=0x02;
    DDRD|=0x02; // PortD1 (TX) as output with a default HIGH level
}


//-------------------------------------------------------------------------------------------------
void ShutdownPower4bit(){
   UCSR0B &= 0xF7; // Deactivate TX
   PORTC &= 0xF0;  // PortC bits 0..3 to GND A0, A1, A2, A3
   PORTD &= 0xFD;  // PortD bit 1 to GND (TX) 
   DDRC |= 0x0F;  // Ensure pins are OUTPUT
   DDRD |= 0x02;
}

//-------------------------------------------------------------------------------------------------
void Release4bit(){
   DDRC&= 0xF0; // PortC bits 0..3 as input A0, A1, A2, A3
   DDRD&=0xFD; // PortD bit 1 as input TX 
}

//-------------------------------------------------------------------------------------------------
void Clear4bit(){
    PORTC|=0x0F;
    PORTD|=0x02;
}

//-------------------------------------------------------------------------------------------------
void Send4bit (uint8_t d, uint8_t i) {
  PORTC = (PORTC & 0xF0) | (~((d>>4) & 0x0F));  // first nibble
  PORTD&=0xFD;  
  delayMicroseconds(Dly4NIBBLEus); // Allow Spectrum to process first nibble. Aparently 9us is the minimum
   PORTC = (PORTC & 0xF0) | ((~d) & 0x0F); // Second nibble
   PORTD|=0x02; 
  delayMicroseconds(i);
}


//-------------------------------------------------------------------------------------------------
void SendValue4bit(uint8_t c){
    Send4bit (c,Dly4SINGLEus);
}


//-------------------------------------------------------------------------------------------------
void SendBlock4bit(unsigned long pos, uint16_t len, uint8_t dly){
    uint16_t actlen;
    uint16_t cnt;
    uint16_t b2Read;
    
    myFile.seek(pos);
    actlen=0;
    while (actlen<len) {
        if ((len-actlen)<BUFRSIZE)
          b2Read = (len-actlen);
        else
          b2Read = BUFRSIZE;
        myFile.read(myBuf,b2Read);
        for (cnt=0;cnt<b2Read;cnt++) {
          Send4bit (myBuf[cnt],dly);
        }   
        actlen+=b2Read;
    }
}



//-------------------------------------------------------------------------------------------------
void SendBuf4bit(uint8_t *b, uint16_t len, uint8_t dly){
  uint16_t cnt;
    for (cnt=0;cnt<len;cnt++) {
      Send4bit (b[cnt],dly);
    }     
}

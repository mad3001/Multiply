//-------------------------------------------------------------------------------------------------
boolean getBuffer_0(uint8_t* b) {
#define GB0_TIMEOUT DEFAULT_TIMEOUT
  char c=1;
  unsigned long tAct;
  uint8_t cnt=0;
  tAct=millis();
  while (c!=0 && millis()<tAct+GB0_TIMEOUT){
    yield();
    if (Serial.available()) {
      c = Serial.read();
      b[cnt] = c; 
      cnt++;
      tAct=millis();
    }
  } 
  return (c == 0 ? true : false);
}


//-------------------------------------------------------------------------------------------------
boolean getBuffer_N(uint8_t* b, uint8_t n) {
  #define GBN_TIMEOUT DEFAULT_TIMEOUT
  uint8_t cnt=0;
  unsigned long tAct;
  tAct=millis();
  while (cnt<n && millis()<tAct+GBN_TIMEOUT) {
    if (Serial.available()) {
      b[cnt]=Serial.read();
      cnt++;
      tAct=millis();
    }  
  }
  return (cnt == n ? true : false);
}

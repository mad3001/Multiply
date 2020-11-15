//Common code for Joy Mode. InitJoyPassT will define what kind of Joy is been used

enum : uint8_t {
  Atari = 0,      // Atari or compatible with 1 button (pin 6) or 2 buttons (pin 6 and 9)
  SJS = 1,        // Sinclair Joystick with 1 button, having GND in pin 8 and pin 2
  Megadrive = 2   // Megadrive controller (at this moment only 3 buttons accepted but using only B and C buttons)
} JoyMode=Atari;

void InitJoyPassT(void){

  //1st check Megadrive (more complex)
  pinMode(2,INPUT_PULLUP);  //Will check D2 (db9-passthrough RIGHT)
  pinMode(3,INPUT_PULLUP);  //Will check D3 (db9-passthrough LEFT)
  pinMode(A5,OUTPUT);
  digitalWrite(A5,HIGH);    // Prepare to check Megadrive Joystick, sending +5V through pin 5 of Passthrough
  pinMode(8,OUTPUT);
  digitalWrite(8,LOW);    // Prepare to check Megadrive Joystick, if no megadrive pin 7 of Passthrough will remain as OUTPUT=LOW except for SJS that will be changed later-on to INPUT_PULLUP
  if ((digitalRead(2) ==LOW) && (digitalRead(3) == LOW)){
    JoyMode=Megadrive;
    InitJoyPassTAtari();
  }
  else {    
    //digitalWrite(A5,LOW);    // Remove +5V through A5=pin 5 of Passthrough
    pinMode(4,INPUT_PULLUP); // Pin 2 of SJS have GND connected with Pin 8
    if (digitalRead(4)==LOW){  //If Low then it's an SJS
      JoyMode=SJS;
      InitJoyPassTSJS();
    }
    else
    {
      //JoyMode=Atari;
      InitJoyPassTAtari();
    }
  }
  //debug((uint8_t *) &JoyMode,1);
}
void JoyThrough(void) {
  if (JoyMode==SJS) JoyThroughSJS();
  else JoyThroughAtari();
}

//-------------------------------------------------------------------------------------------------
// code for using Atari and Megadrive 3 buttons Joystick
//-------------------------------------------------------------------------------------------------
void InitJoyPassTAtari(void){
  // D2 to D6 Joystick In (Port D)
//  pinMode(2, INPUT_PULLUP); //D2:00 = PD2 => Joy Pin 4 = Right //not required as was done previously
//  pinMode(3, INPUT_PULLUP); //D3:01 = PD3 => Joy Pin 3 = Left  //not required as was done previously
  pinMode(4, INPUT_PULLUP); //D4:02 = PD4 => Joy Pin 2 = Down
  pinMode(5, INPUT_PULLUP); //D5:03 = PD5 => Joy Pin 1 = Up
  pinMode(6, INPUT_PULLUP); //D6:04 = PD6 => Joy Pin 6 = Fire (Atari) or Button 2 (SMS) or Button C (Megadrive)
  // D8 Joystick In (Port B)
  digitalWrite(8,HIGH); // Atari Joy Pin 7 =+5V so some Joysticks can Power internal chips (ie turbo / autofire)
  // A4 Joystick In (Port C)
  pinMode(A4,INPUT_PULLUP);        //A4:04 = PC4 => Not used in Atari Joy, only for paddles as pot => Joy Pin 9, but used as Button 1(SMS) and button B for Megadrive
  digitalWrite(A5,HIGH);           //A5:05 = PC5 => Not used in Atari Joy, only for paddles as pot => Joy Pin 5. SMS and Megadrive require here +5V
  // Joy Pin 8 connected to GND
}

//-------------------------------------------------------------------------------------------------
//
// Reading Joy through PORTD  : PD6=Fire, PD5=Up, PD4=Down, PD3=Left, PD2=Right.   Pending reading A4 PC4 (2nd Fire) and what to do with it
// and is Converted to PORTC/D: PC3=Fire, PC2=Up, PC1=Down, PC0=Left, PD1=Right.   Pending 2nd fire how should "act", maybe LEFT+RIGHT simultaneusly.. this require changes in ZX ASM
void JoyThroughAtari(void) {
  uint8_t Joy, JoyR, JoyFire2;
  yield();
  JoyFire2 = (PINC & 0x10);  // PC4 gets Fire2 button, 0x00=Fire 2 pressed, 0x10=Fire 2 not pressed
  Joy = (PIND >> 3);  // 76543210 (PIND) => xxxx6543  (6=Fire, 5=Up, 4=Down, 3=Left) so Joy = xxxxFUDL
  //Joy = ~(PIND >> 3);
  if (JoyFire2)  Joy &= 0x0F;        // Isolate 0000FUDL (Fire 2 not pressed)
  else Joy &= 0x0E;                  //Isolate 0000FUD0 (Fire 2 pressed)
  PORTC = ((PORTC & 0xF0) | Joy);        // Bit 3 for DB9 Pin 6=Fire, Bit 2 for DB9 Pin 1=Up, Bit 1 for DB9 Pin 2=Down, Bit 0 for DB9 Pin 3=Left
  //DDRC = Joy;
 // JoyR = PORTB & 0xFD;
  JoyR = (PORTD & 0xFD); //JoyR take all D port except bit 1 (bit 1 is set to 0) so value is  VVVVVV0V (V=old value)
  //JoyR = ~PORTB & 0xFD;
  if (JoyFire2)  JoyR |= (PIND >> 1) & 0x02; //D2=R so PIND >>1 move R to bit 1 (000000R0), after OR it have PORTD and changed bit for Right into bit 1
  //DDRD=JoyR;
  PORTD=JoyR;         // D=VVVVVVRV  (V=old portD value, R=right bit)
  //PORTB = JoyR;
}
//----------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
// code for using SJS Joystick
//-------------------------------------------------------------------------------------------------
void InitJoyPassTSJS(void){
   // D2 to D6 Joystick In
//  pinMode(2, INPUT_PULLUP); //D2:00 = PD2 => Joy Pin 4 = Fire
  pinMode(3, INPUT);        //D3:01 = PD3 => Joy Pin 3 = Not used
  pinMode(4, INPUT);        //D4:02 = PD4 => Joy Pin 2 = GND ¡ojo! lo mismo hay poner OUTPUT y poner a LOW
  //pinMode(4,OUTPUT);
  //digitalWrite(4,LOW);      //Force D4 to GND ?
  pinMode(5, INPUT);        //D5:03 = PD5 => Joy Pin 1 = Not used
  pinMode(6, INPUT_PULLUP); //D6:04 = PD6 => Joy Pin 6 = Right
  // D8 Joystick In (Port B)
  pinMode(8, INPUT_PULLUP); //D8:00 = PB0 => Joy Pin 7 = Left
  // A4 Joystick In (Port C)
  pinMode(A4,INPUT_PULLUP); //A4:04 = PC4 => Joy Pin 9 = Down
  pinMode(A5,INPUT_PULLUP); //A5:05 = PC5 => Joy Pin 5 = Up
 // Joy Pin 8 connected to GND
}

//-------------------------------------------------------------------------------------------------
// Reading Joy through PORTB/C/D: PD2=Fire, PC5=Up, PC4=Down, PB0=Left, PD6=Right.
// and is Converted to PORTC/D  : PC3=Fire, PC2=Up, PC1=Down, PC0=Left //PORTD: PD1=Right.
void JoyThroughSJS(void) {
  uint8_t Joy, JoyR;
  yield();    
  Joy = (PIND << 1) & 0x08;   // PIND=xRxxxFxx => RxxxFxxx, and isolate bit 3 so Joy=0000F000
  Joy |= (PINB & 0x01);       // PINB=xxxxxxxL => 0000000L OR with Joy =>0000F00L
  Joy |= (PINC >> 3) & 0x06;  // PINC=xxUDxxxx => xxxxxUDx, and isolate bits 2,1 so 00000UD0, OR with Joy=>0000FUDL
  Joy |= (PORTC & 0xF0);      // Joy = VVVVFUDL (V=old bit values)
  PORTC = Joy;                // C=VVVVFUDL (C7/C6/C5/C4 as per old values)

  JoyR = PORTD & 0xFD;        // JoyR take all D port except bit 1 (bit 1 is set to 0) so value is  VVVVVV0V (V=old value)
  JoyR |= (PIND >> 5) & 0x02; // D6=R so PIND >>5 move R to bit 1 (000000R0), after OR it have PORTD and changed bit for Right into bit 1
  PORTD = JoyR;               // D=VVVVVVRV  (V=old portD value, R=right bit)

}

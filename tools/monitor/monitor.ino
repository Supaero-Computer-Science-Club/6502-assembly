/**
 * This file allows to monitor a 6502 micor-processor chip.
 * 
 * The 16 address lines and the 8 data lines are connected to the digital I/O ports of the arduino. 2 extra pins are monitored, namely the clock and the read/write pin of the processor.
 * The arduino chip needs to handle enough pins and digital ports, namely 26 of them.
 * One could for example use the Arduino Mega controller.
 */


// some global variable definitions.
// all the address lines are connected to the even ports of the arduino, starting from pin 22.
// all the data lines are connected to the odd ports of the arduino, starting from pin 39
// the clock is on pin 2.
// the read/write signal is on pin 3.
//===================================================================================
const char ADDR[] = {52, 50, 48, 46, 44, 42, 40, 38, 36, 34, 32, 30, 28, 26, 24, 22};  
const char DATA[] = {53, 51, 49, 47, 45, 43, 41, 39};  
#define CLOCK 2  
#define READ_WRITE 3 
//===================================================================================


/*
 * Ran one time at the beginning of the program.
 * Sets the pins up, starts the monitor and does some more application specific stuff.
 */
void setup() {
  for (int n = 0; n < 16; n += 1) {
    pinMode(ADDR[n], INPUT);
  }
  for (int n = 0; n < 8; n += 1) {
    pinMode(DATA[n], INPUT);
  }
  pinMode(CLOCK, INPUT);
  pinMode(READ_WRITE, INPUT);

  // attach an interrupt that trigger the below function everytime the clock of the CPU goes high.
  attachInterrupt(digitalPinToInterrupt(CLOCK), onClock, RISING);
  
  Serial.begin(57600);
}


/*
 * Everytime that the clock of the CPU goes high, this function runs.
 * It reads the address line, the data line and the read/write pin, then prints all the information onto the serial monitor.
 * The format of the print is the following:
 *    ...
 *    1110110000111111   11101010 | ec3f  r ea 
 *    1111111111111100   11101010 | fffc  r ea 
 *    1111111111111101   11101010 | fffd  r ea 
 *    1110101011101010   11101010 | eaea  W ea 
 *    ...
 */
void onClock() {
  char output[15];

  // print the address from ADDR pins in binary and store the result as a decimal integer in address.
  unsigned int address = 0;
  for (int n = 0; n < 16; n += 1) {
    int bit = digitalRead(ADDR[n]) ? 1 : 0;
    Serial.print(bit);
    address = (address << 1) + bit;  // shift the variable to the left and add the bit.
  }
  
  Serial.print("   ");

  // print the data from DATA pins in binary and store the result as a decimal integer in data.
  // go in reverse to use the custom ribbon cable.
  unsigned int data = 0;
  for (int n = 0; n < 8; n += 1) {
    int bit = digitalRead(DATA[n]) ? 1 : 0;
    Serial.print(bit);
    data = (data << 1) + bit;  // shift the variable to the left and add the bit.
  }

  // format the output with the hexadecimal representations of the address and the data, separated by the read/write pin state, either reading (r) or writing (W).
  sprintf(output, " | %04x  %c %02x", address, digitalRead(READ_WRITE) ? 'r' : 'W', data);
  Serial.println(output);  
}


void loop() {
}

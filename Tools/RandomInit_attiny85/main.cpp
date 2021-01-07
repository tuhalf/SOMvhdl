
#include <avr/io.h>
#include <util/delay.h>
#include <Arduino.h>
#include <avr/eeprom.h>
#define	RANDOM_SEED_ADDRESS	0x00
static uint16_t random_number = 0;

static uint16_t lfsr16_next(uint16_t n)
{

	return (n >> 0x01U) ^ (-(n & 0x01U) & 0xB400U);
}


void random_init(uint16_t seed)
{
    random_number = lfsr16_next(eeprom_read_word((uint16_t *)RANDOM_SEED_ADDRESS) ^ seed);
    eeprom_write_word((uint16_t *)RANDOM_SEED_ADDRESS, random_number);
}


uint16_t random1()
{

	return (random_number = lfsr16_next(random_number));
}

void setup(void)
{
	uint16_t number = 0xabcd;

	/* setup */
	DDRB |= _BV(PB0); // set LED pin as OUTPUT
  DDRB |= _BV(PB1); // set LED pin as OUTPUT
  DDRB |= _BV(PB2); // set LED pin as OUTPUT
  DDRB |= _BV(PB3); // set LED pin as OUTPUT
  DDRB |= _BV(PB4); // set LED pin as OUTPUT
  DDRB |= _BV(PB5); // set LED pin as OUTPUT
	random_init(number); // initialize 16 bit seed

	/* loop, simple realization of pseudo random LED blinking */
	while (1) {
    for (int i = 0; i < 6; i++)
    {
      number = random1();
    }
    
		if (number & 0x01) { // odd number
			PORTB |= _BV(PB0);
		} else { // even number
			PORTB &= ~_BV(PB0);
		}
    if (number & 0x02) { // odd number
			PORTB |= _BV(PB1);
		} else { // even number
			PORTB &= ~_BV(PB1);
		}
    if (number & 0x04) { // odd number
			PORTB |= _BV(PB2);
		} else { // even number
			PORTB &= ~_BV(PB2);
		}
    if (number & 0x08) { // odd number
			PORTB |= _BV(PB3);
		} else { // even number
			PORTB &= ~_BV(PB3);
		}
    if (number & 0x10) { // odd number
			PORTB |= _BV(PB4);
		} else { // even number
			PORTB &= ~_BV(PB4);
		}
    if (number & 0x20) { // odd number
			PORTB |= _BV(PB5);
		} else { // even number
			PORTB &= ~_BV(PB5);
		}
	}
}
#define __NOINLINE __attribute__((noinline))
#define __REGPARM  __attribute__((regparm(3)))

void __NOINLINE __REGPARM print(char *str)
{
	while ( *str ) {
		__asm__ __volatile__ ("int  $0x10" : : "a"(0x0E00 | *str), "b"(7));
		str++;
	}
}

void main(void)
{
	print( "Spud Gun launching PotatOS...\r\n(not yet implemented ;)\r\n" );

	asm("cli");	// disable all maskable interrupts
	while (1) { asm("hlt");	}	// Keep halting, ignoring non-maskable interrupts
}

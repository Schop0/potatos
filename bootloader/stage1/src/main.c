void print(char *str)
{
	for ( ; *str; str++)
		__asm__ __volatile__ ("int  $0x10" : : "a"(0x0E00 | *str), "b"(7));
}

void main(void)
{
	print( "Spud Gun launching PotatOS...\r\n(not yet implemented ;)\r\n" );

	asm("cli");	// disable all maskable interrupts
	while (1) { asm("hlt");	}	// Keep halting, ignoring non-maskable interrupts
}

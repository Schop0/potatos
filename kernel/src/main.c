#define VIDEO_MEMORY    0xB8000
#define GRAY_ON_BLACK   0x07

void print(char *str)
{
	char *video_memory = (char *) VIDEO_MEMORY;
	char c;

	while ( c = *str++ ) {
		*video_memory++ = c;
		*video_memory++ = GRAY_ON_BLACK;
	}
}

void halt(void)
{
	asm("cli");
	while (1) {
		asm("hlt");
	}
}

void main(void)
{
	print( "Hello from 32-bit protected mode C code!" );

	halt();
}

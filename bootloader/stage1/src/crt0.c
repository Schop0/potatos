#include "main.h"

/*
 * Our bootloader simply starts executing the first line of code
 * There is no C runtime that calls main() so we do it ourselves
 * Ensure this file is compiled and placed first in your binary!
 */
void _start(void)
{
	main();
}

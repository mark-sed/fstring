#include "fstring.h"
#include <stdio.h>

int main(int argc, char *argv[]){
    char *str = "Hello, how's it going guys";
    fstring *fstr = fstrfromstr(str);
    printf("%p\n%p\n%ld\n'%s'\n", fstr, fstr->alloc_start, fstr->length, fstr->text);
	char *a = fstr->text;
	free(fstr);
	puts(a);
    return 0;
}

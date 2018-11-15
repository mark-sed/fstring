#include "fstring.h"
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]){
    char *str = "Hello, how's it going guys";
    fstring *fstr = fstrfromstr(str);
    printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	fstrappend(fstr, ". This was appended. And made uppercase!");

	fstr_to_upper(fstr, 0, fstrlen(fstr));

	printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	fstrfree(fstr);

	fstrset(fstr, "I changed :) 123456789abcdefghijklmnopqrstuvwxyz");

    printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	fstring *fstr2 = fstrfromstr(str);
	
	printf("FSTR FROM STR: %s -> %s\n", str, fstr2->text);

	char *a = fstrtostr(fstr, 0, 10);

	printf("FSTR TO STR (0: 10) '%s' -> '%s'\n", fstr->text, a);
	
	char *b;

	_fstrtostr_free(b, fstr, 0, 4);
	
	printf("FREE + CONVERT (0, 4): '%s'\n", b);

	free(a);
	free(b);
    return 0;
}

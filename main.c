#include "fstring.h"
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]){
    char *str = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    fstring *fstr = fstrfromstr(str);
    printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	fstrcopy(fstr, 2, "--INJECTED--");
	printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));
	/*unsigned long am = 0;
	char **words = fstrsplit(fstr, ' ', &am);
	for(int i = 0; i < am; i++){
		printf("%02d %s\n", (i+1), words[i]);
	}*/


	//fstrappend(fstr, ". This was appended. And made uppercase. Later lowercase");

	//fstring *fsub = fstrfromstr("CDEFGHIJ");
	//printf("%p: %p: %ld: %ld: '%s'\n", fsub, fsub->alloc_start, fsub->alloc_len, fstrlen(fsub), fstr_get_str(fsub));
	//unsigned long index = _fstr_find_first(fstr, fsub);
	//printf("Found at: %lu\n", index);
	//fstrflip(fstr, 5, fstrlen(fstr)); 
	//printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));
	/*

	fstr_to_upper(fstr, 0, fstrlen(fstr));

	printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	fstr_to_lower(fstr, 0, 10000);

	printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	fstrcapitalize(fstr, 0);
	fstrcapitalize(fstr, 7);
	fstrcapitalize(fstr, 10000);

	printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	fstrfree(fstr);

	fstrset(fstr, "I changed :) 123456789abcdefghijklmnopqrstuvwxyz");

	fstrappend(fstr, ".");

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
	*/
    return 0;
}

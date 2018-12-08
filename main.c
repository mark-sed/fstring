#include "fstring.h"
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]){
    char *str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    fstring *fstr = fstrfromstr(str);
    printf("\nfstrfromstr(%s)\n", str);
    //printf("%s\n", fstr_get_str(fstr));
    printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	//fstrappend(fstr, ". I appended this");

	//printf("\nfstrinsert(fstr, 2, --INJECTED--)\n");
	//fstrinsert(fstr, 2, "--INJECTED--");
	//printf("%s\n", fstr_get_str(fstr));
	//printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	
	//fstrinsert(fstr, 2, "--INJECTED--");
	//printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));
	/*unsigned long am = 0;
	char **words = fstrsplit(fstr, ' ', &am);
	for(int i = 0; i < am; i++){
		printf("%02d %s\n", (i+1), words[i]);
	}*/

	fstring *fsub = fstrfromstr("ijkl");
	printf("%p: %p: %ld: %ld: '%s'\n", fsub, fsub->alloc_start, fsub->alloc_len, fstrlen(fsub), fstr_get_str(fsub));
	unsigned long index = _fstr_find_first(fstr, fsub);
	printf("Found at: %lu\n", index);
	/*
	printf("\nfstrflip(fstr, 5, fstrlen(fstr))\n");
	fstrflip(fstr, 5, fstrlen(fstr)); 
	printf("%s\n", fstr_get_str(fstr));
	//printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	printf("\nfstr_to_upper(fstr, 0, fstrlen(fstr))\n");
	fstr_to_upper(fstr, 0, 10000);
	printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	printf("\nfstr_to_lower(fstr, 0, 10000)\n");
	fstr_to_lower(fstr, 0, 10000);

	printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	printf("\nfstrcapitalize(fstr, 0)\n");
	fstrcapitalize(fstr, 0);
	printf("fstrcapitalize(fstr, 7)\n");
	fstrcapitalize(fstr, 7);
	printf("fstrcapitalize(fstr, 10000)\n");
	fstrcapitalize(fstr, 10000);

	printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	printf("\nfstrset(fstr, \"I changed :) 123456789abcdefghijklmnopqrstuvwxyz\")\n");
	fstrset(fstr, "I changed :) 123456789abcdefghijklmnopqrstuvwxyz");

    printf("%s\n", fstr_get_str(fstr));

	printf("\nfstring *fstr2 = fstrfromstr(str)");
	fstring *fstr2 = fstrfromstr(str);
	printf("%s\n", fstr_get_str(fstr2));
	

	printf("\nFSTR FROM STR: %s -> %s\n", str, fstr2->text);

	printf("\nchar *a = fstrtostr(fstr, 0, 10)\n");
	char *a = fstrtostr(fstr, 0, 10);

	
	printf("FSTR TO STR (0: 10) '%s' -> '%s'\n", fstr->text, a);
	char *b;
	printf("\nchar *b; _fstrtostr_free(b, fstr, 0, 4);\n");
	_fstrtostr_free(b, fstr, 0, 4);
	
	printf("FREE + CONVERT (0, 4): '%s'\n", b);

	printf("\nfstrappend(fstr, %s)\n", ". This was appended.");
	fstrappend(fstr, ". This was appended.");
	printf("%p: %p: %ld: %ld: '%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	printf("\nfstrfree(fstr)\n");
	fstrfree(fstr);

	free(a);
	free(b);
	*/
    return 0;
}

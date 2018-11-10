#include "fstring.h"
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]){
    char *str = "Hello, how's it going guys";
    fstring *fstr = fstrfromstr(str);
    printf("%p\n%p\n%ld\n%ld\n'%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	fstrappend(fstr, ". This was appended xD I added this for loooooooooool upe{}|_^&}se1!");

	fstr_to_upper(fstr, 0, fstrlen(fstr));

	printf("%p\n%p\n%ld\n%ld\n'%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));

	fstrfree(fstr);

	/*fstrset(fstr, "I changed :)AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
    printf("%p\n%p\n%ld\n%ld\n'%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));
	char *a = fstrtostr(fstr, 0, 20);
	fstring *fstr2 = fstrfromstr(str);
	printf("%s\n", fstr2->text);

	printf("'%s'\n", a);

	fstrrealloc(fstr, 3000);
	printf("REALLOCED: %p\n%p\n%ld\n%ld\n'%s'\n", fstr, fstr->alloc_start, fstr->alloc_len, fstrlen(fstr), fstr_get_str(fstr));
	
	char *b;
	_fstrtostr_free(b, fstr, 0, 4);
	printf("'%s'\n", b);

	free(a);
	free(b);*/
    return 0;
}

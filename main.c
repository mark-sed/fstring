#include "fstring.h"
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]){
    char *str = "Hello, how's it going guys";
    fstring *fstr = fstrfromstr(str);
    printf("%p\n%p\n%ld\n'%s'\n", fstr, fstr->alloc_start, fstrlen(fstr), fstr_get_str(fstr));
	char *a = fstrtostr(fstr, 0, 20);

	printf("'%s'\n", a);
	
	fstrfree(fstr);
	free(a);
    return 0;
}

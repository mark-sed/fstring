#ifndef _FSTRING_H_
#define _FSTRING_H_

#include <stdint.h>

typedef struct{
	uint64_t length;    // Actual length of the text without the \0
	uint64_t alloc_len; // Free allocated space after the text
	char *text;		// text (use alloc_start when free and realloc)
	void *alloc_start;  // Tells where the text actually starts (padding for alignmnet)
} fstring;

/**
 * Returns length of a fstring text
 */
#define fstrlen(fstr) (fstr->length)

/**
 * Accesses the string part of the object
 */
#define fstr_get_str(fstr) (fstr->text)

/**
 * Konverze C stringu na FSTring
 */
fstring *fstrfromstr(char *str);

/**
 * Konverze FSTringu na C string
 */
char *fstrtostr(fstring *fstr, unsigned int start, unsigned int end);
#define _fstrtostr(fstr) fstrtostr(fstr, 0, fstr->length)

/**
 * Smaže FSTring (uvolní paměť)
 */
void fstrfree(fstring *fstr);
#define _fstrtostr_free(cstr, fstr, start, end) do{cstr = fstrtostr(fstr, start, end); fstrfree(fstr);}while(0)

/**
 * Rewrites FSTring
 */
void fstrset(fstring *fstr, char *str);
#define _fstrfset(fstr, fstr_src) fstrset(fstr, fstr_get_str(fstr_src))

/**
 * Appends text to the end of fstring
 */
void fstrappend(fstring *fstr, char *str);
#define _fstrappend(fstr, fstr_src) fstrappend(fstr, fstr_get_str(fstr_src))

/**
 * Converts all letters to upper case
 */
void fstr_to_upper(fstring *fstr, unsigned long start, unsigned long end);

/**
 * Converts all letters to lowercase
 */
void fstr_to_lower(fstring *fstr, unsigned long start, unsigned long end);

/**
 * Capitalizes one letter
 */
void fstrcapitalize(fstring *fstr, unsigned long start);
#define _fstrcapitalize(fstr) fstrcapitalize(fstr, 0);


/**
 * Flips fstring
 */
void fstrflip(fstring *fstr, unsigned int start, unsigned int end);

/**
 * Finds first appearance of an fstring in an fstring
 */
// TODO: FINISH
unsigned long fstr_find_first(fstring *fstr, unsigned long start1, unsigned long end1, fstring *subfstr, unsigned long start2, unsigned long end2);
#define _fstr_find_first(fstr, substr) fstr_find_first(fstr, 0, fstrlen(fstr), substr, 0, fstrlen(substr));

/**
 * Splits FSTring by character and saves substring to a newly allocated array of string literals
 * Passed in FSTring will contain the first element (see note why)
 * Once the passed in FSTring is changed the array is changed as well, thus it is better to
 * make a copy of the fstring if you plan on using it later on, but this makes the
 * freeing process lot easier, just call fstrfree and free the returned pointer
 *
 * @Note the substrings will be just pointers into the FSTring in which the separator will be
 * exchanged for \0, thus making it easy for 
 */
char **fstrsplit(fstring *fstr, char separator, unsigned long *amount); // TODO: Finish

/**
 * Copies string into fstring into a certain position
 */
void fstrcopy(fstring *fstr, unsigned long start, char *str);

#ifdef _ALL_DONE

//TODO: ?? void fstr_switch_case(fstring *fstr, unsigned int start, unsigned int end);

/**
 * Nakopíruje string nebo FSTring do druhého FSTringu (posune znaky)
 */
fstrinsert();


/**
 * Vrací kolikrát se substring nachází ve stringu
 */ 
fstrcount();

/**
 * Vyhledá poslední výskyt podřetězce v řetězci
 */
fstr_find_last();
#endif

#endif//_FSTRING_H_

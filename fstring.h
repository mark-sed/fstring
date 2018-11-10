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
#define fstrlen(fstr) fstr->length

/**
 * Accesses the string part of the object
 */
#define fstr_get_str(fstr) fstr->text

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
#define _fstrtostr_free(cstr, fstr, start, end) do{cstr = fstrtostr(fstr, start, end); fstrfree(fstr);}while(0);

/**
 * Rewrites FSTring
 */
void fstrset(fstring *fstr, char *str);
#define _fstrfset(fstr, fstr_src) fstrset(fstr, fstr_get_str(fstr_src)) // TODO: Version for fstring (length doesnt have to be counted)

void fstrrealloc(fstring *fstr, unsigned long new_size);

/**
 * Appends text to the end of fstring
 */
void fstrappend(fstring *fstr, char *str);
#define _fstrappend(fstr, fstr_src) fstrappend(fstr, fstr_get_str(fstr_src));

/**
 * Converts all letters to upper case
 */
void fstr_to_upper(fstring *fstr, unsigned long start, unsigned long end);

#ifdef _ALL_DONE_

/**
 * Převede řetězec na malá písmena
 */
void fstr_to_lower(fstring *fstr, unsigned int start, unsigned int end);

/**
 * Vyhledá první výskyt podřetězce v řetězci
 */
fstr_find_last();

/**
 * Vyhledá poslední výskyt podřetězce v řetězci
 */
fstr_find_last();

/**
 * Převrátí řetězec
 */
void fstrflip(fstring *fstr, unsigned int start, unsigned int end);

/**
 * Nakopíruje string nebo FSTring do druhého FSTringu (posune znaky)
 */
fstrinsert();

/**
 * Nakopíruje string nebo FSTring do druhého FSTringu (přepíše znaky)
 */
fstrcopy();

/**
 * Rozdělí FSTring podle oddělovacího znaku na podřetězce (literály) a ty uloží do pole
 *
 * @note Oddělovací znak je nahrazen koncovou nulou a ukazatel na začátek slova před tímto znakem
 * je uložen do pole, přepsáním je tedy přepsán i samotný FSTring, tato funkce ale má sloužit
 * spíše k analýze slov dle oddělovačů a poté jejich nakopírování
 */
fstrsplit();

/**
 * Zvětší pouze první písmeno
 */
void fstrcapitalize(fstring *fstr, unsigned int start);

/**
 * Vrací kolikrát se substring nachází ve stringu
 */ 
fstrcount();
#endif

#endif//_FSTRING_H_

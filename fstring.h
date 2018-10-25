#ifndef _FSTRING_H_
#define _FSTRING_H_

#include <stdint.h>

typedef struct{
	uint64_t length;
	uint64_t alloc_len;
	char **text;
} fstring;

#define fstrlen //finish

/**
 * Konverze C stringu na FSTring
 */
fstring *fstrfromstr(char *str);

#ifdef _ALL_DONE_
/**
 * Konverze FSTringu na C string
 */
char *fstrtostr(fstring fstr, unsigned int start, unsigned int end);

/**
 * Dynamicky vytvoří nový FSTring
 */ 
fstring *fstrnew(const char*); //Variation with max length

/**
 * Smaže FSTring (uvolní paměť)
 */
void fstrfree(fstring *fstr);

/**
 * Rewrites FSTring
 */
fstring *fstrset();

/**
 * Převede řetězec na velká písmena
 */
fstr_to_upper();

/**
 * Převede řetězec na malá písmena
 */
fstr_to_lower();

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
fstrflip();

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
fstrcapitalize();

/**
 * Vrací kolikrát se substring nachází ve stringu
 */ 
fstrcount();
#endif

#endif//_FSTRING_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

int main(int argc, char *argv[]){

	char *t1 = "HelloTherethisisthetext123456";
	char *t2 = "Thiswasinsertedatthestartoftheappendedtext";
	char *t3 = "FINDME";
	
	char *str = malloc(strlen(t1));
	strcpy(str, t1);

	for(int i = 0; str[i]; i++){
  		str[i] = tolower(str[i]);
	}

	for(unsigned int i = 0; i < 4000; i++){
		str = realloc(str, strlen(str)+strlen(t1));
		strcpy(&str[strlen(str)], t1);
	}

	for(int i = 0; str[i]; i++){
  		str[i] = toupper(str[i]);
	}

	str = realloc(str, strlen(str)+strlen(t2));

	for(int i = 1; i < strlen(str)-1; i++){
		str[strlen(str)-i+strlen(t2)] = str[strlen(str)-i];
	}

	str = realloc(str, strlen(str)+strlen(t3));

	strcpy(&str[strlen(str)], t3);

	//puts(str);

	unsigned long fnd = strstr(str, t3)-str;
	printf("\nFound at: %lu (should be %lu)\n", fnd, strlen(str)-strlen(t3));

	free(str);

	return 0;
}
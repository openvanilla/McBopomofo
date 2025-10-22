#include <string.h>
#include <stdio.h>

int match(const char *s, const char *p, int overlap)
{
    int c = 0, l = strlen(p);

    while (*s != '\0') {
            if (strncmp(s++, p, l)) continue;
            if (!overlap) s += l - 1;
            c++;
    }
    return c;
}

int main ( int argc, char** argv )
{
   int myCount=0;
   char* myQuery=argv[2];
   //fputs (argv[1], stdout);
   //if (0){
   //static const char filename[] = "/Volumes/ramdisk/utf8file";
   char* filename = argv[1];
   FILE *file = fopen ( filename, "r" );
   if ( file != NULL )
   {
      char line [ 600 ]; /* or other suitable maximum line length */

      while ( fgets ( line, sizeof line, file ) != NULL ) /* read a line */
      {
         //fputs ( line, stdout ); /* write the line */
         myCount+=match(line,myQuery,0);
      }
      printf("%s	%d\n",myQuery,myCount);
      fclose ( file );
   }
   else
   {
      perror ( filename ); /* why didn't the file open? */
   }
   //}
   return 0;
}

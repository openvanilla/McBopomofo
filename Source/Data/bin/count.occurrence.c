#include <string.h>
#include <stdio.h>

int main ( int argc, char** argv )
{
   int myCount=0;
   char* myQuery=argv[1];
   //fputs (argv[1], stdout);
   //if (0){
   static const char filename[] = "/Volumes/ramdisk/newTEXT.txt";
   FILE *file = fopen ( filename, "r" );
   if ( file != NULL )
   {
      char line [ 600 ]; /* or other suitable maximum line size */

      while ( fgets ( line, sizeof line, file ) != NULL ) /* read a line */
      {
         //fputs ( line, stdout ); /* write the line */
         myCount+=match(line,myQuery);
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

/* file.txt
This text is the contents of the file named, "file.txt".

It is being used with some example code to demonstrate reading a file line by
line. More interesting things could be done with the output, but I'm trying to
keep this example very simple.
*/

/* my output
This text is the contents of the file named, "file.txt".

It is being used with some example code to demonstrate reading a file line by
line. More interesting things could be done with the output, but I'm trying to
keep this example very simple.
*/

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

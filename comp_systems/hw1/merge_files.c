#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
  // Check for correct usage
  if (argc < 3) {
    printf("Usage: %s file_in_1 file_in_2 [file_out (default:myfile.out)]\n",
           argv[0]);
    return 1;
  }

  // Attempt to open first two input files
  FILE *fp1 = fopen(argv[1], "r");
  FILE *fp2 = fopen(argv[2], "r");
  if (!fp1) {
    printf("%s: No such file or directory\n", argv[1]);
    return 1;
  }
  if (!fp2) {
    printf("%s: No such file or directory\n", argv[2]);
    fclose(fp1);
    return 1;
  }

  // Determine output file name
  char *outFileName = (argc == 4) ? argv[3] : "myfile.out";

  FILE *fp3 = fopen(outFileName, "w");
  if (!fp3) {
    printf("Could not open or create output file %s\n", outFileName);
    fclose(fp1);
    fclose(fp2);
    return 1;
  }

  // Copy contents from first file
  int ch;
  while ((ch = fgetc(fp1)) != EOF) {
    fputc(ch, fp3);
  }

  // Copy contents from second file
  while ((ch = fgetc(fp2)) != EOF) {
    fputc(ch, fp3);
  }

  // Close files
  fclose(fp1);
  fclose(fp2);
  fclose(fp3);

  printf("Merged %s and %s into %s\n", argv[1], argv[2], outFileName);

  return 0;
}

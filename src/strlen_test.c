#include <stdio.h>

extern size_t strlen(const char *str);

int main(void)
{

  const char *string_1 = "pinci";
  const char *string_2 = "hello world!";
  const char *string_3 = "";
  const char *string_4 = "hello my baby, hello my honey, hello my ragtime gal";

  printf("length of string 1: %zu\n", strlen(string_1));
  printf("length of string 2: %zu\n", strlen(string_2));
  printf("length of string 3: %zu\n", strlen(string_3));
  printf("length of string 4: %zu\n", strlen(string_4));

  return 0;

}

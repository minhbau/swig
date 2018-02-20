/* File : funcptr.c */

int do_op(int a, int b, int (*op)(int, int)) {
  return (*op)(a, b);
}

int add(int a, int b) {
  return a + b;
}

int sub(int a, int b) {
  return a - b;
}

int mul(int a, int b) {
  return a * b;
}

int (*funcvar)(int, int) = add;
/* vim: set ts=2 sw=2 sts=2 tw=129 : */
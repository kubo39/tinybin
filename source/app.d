import syscall : syscall, WRITE;

void main()
{
  immutable(char)[7] hello = "Hello!\n";
  size_t stdout = 1;
  syscall(WRITE, stdout, cast(size_t) hello.ptr, 7);
}

import syscall : syscall, WRITE;

void main()
{
  auto hello = "Hello!\n";
  size_t stdout = 1;
  syscall(WRITE, stdout, cast(size_t) hello.ptr, hello.length);
}

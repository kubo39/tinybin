@system:

void write(size_t p, size_t len)
{
  synchronized asm
  {
    mov RAX, 1;    // WRITE
    mov RDI, 1;    // STDOUT
    mov RSI, p[RBP];
    mov RDX, len[RBP];
    syscall;
  }
}


void main()
{
  immutable(char)[7] hello = "Hello!\n";
  write(cast(size_t) hello.ptr, 7);
}

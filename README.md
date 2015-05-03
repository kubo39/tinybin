# tinybin

## 実行環境

```
$ uname -srvp
Linux 3.13.0-49-generic #83-Ubuntu SMP Fri Apr 10 20:11:33 UTC 2015 x86_64
$ cat /proc/cpuinfo | grep 'model name'
model name      : Intel(R) Core(TM) i5-4200U CPU @ 1.60GHz
model name      : Intel(R) Core(TM) i5-4200U CPU @ 1.60GHz
model name      : Intel(R) Core(TM) i5-4200U CPU @ 1.60GHz
model name      : Intel(R) Core(TM) i5-4200U CPU @ 1.60GHz
```

## やったこと

### 1. デフォルト

```d
import std.stdio;

void main()
{
  "Hello!".writeln;
}
```

```
$ dub build
```

```
$ ls -l tinybin
-rwxrwxr-x 1 kubo39 kubo39 1584546  5月  2 16:31 tinybin
```


### 2. -releaseオプション

```
$dub build --build=release
```

```
$ ls -l tinybin
-rwxrwxr-x 1 kubo39 kubo39 700884  5月  2 16:35 tinybin
```

### 3. stdioをやめる

```
$ git clone git://github.com/kubo39/syscall.d
$ dub add-local syscall.d ~master
```

`dub.json` の dependencies に syscall.d を追加する.


```
{
	"name": "tinybin",
	"description": "A minimal D application.",
	"copyright": "Copyright © 2015, kubo39",
	"authors": ["kubo39"],
	"dependencies": {
        "syscall.d": {"version": "~master", "path": "../syscall.d"}
	}
}
```

`app.d` を syscall.d を使ったコードに変更

```d
import syscall : syscall, WRITE;

void main()
{
  auto hello = "Hello!\n";
  size_t stdout = 1;
  syscall(WRITE, stdout, cast(size_t) hello.ptr, hello.length);
}
```

`dub build --build=release` でビルド.

```
$ ls -l tinybin
-rwxrwxr-x 1 kubo39 kubo39 429067  5月  2 16:56 tinybin
```


### 4. string型から固定長にする

```d
import syscall : syscall, WRITE;

void main()
{
  immutable(char)[7] hello = "Hello!\n";
  size_t stdout = 1;
  syscall(WRITE, stdout, cast(size_t) hello.ptr, 7);
}
```

`dub build --build=release` でビルド.

```
$ ls -l tinybin
-rwxrwxr-x 1 kubo39 kubo39 429037  5月  2 17:02 tinybin
```

### 5. 生成したバイナリにstripをかける

```
$ strip tinybin
$ wc -c < tinybin
285536
```

### 6. dd使ってsection headerを削る

`readelf -h tinybin` でセクションヘッダの開始位置を調べる.

```
$ dd if=tinybin of=tinybin_nosectionhdr count=283487 bs=1
$ chmod +x tinybin_nosectionhdr
$ wc -c < tinybin_nosectionhdr
283487
```

### 7. dub路線に見切りをつけてlink周りをいじる

`syscall.d` の syscall 呼び出し部分を直接コードに書く.

```d
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
```

こういう `build.sh` を用意.

```
#!/bin/bash

set -e

for d in dmd; do
    which $d >/dev/null || (echo "Can't find $d, needed to build"; exit 1)
done

dmd | head -1
echo

set -x

dmd -c -noboundscheck -release source/app.d
gcc app.o -o tinybin -s -m64 -L/usr/lib/x86_64-linux-gnu -Xlinker -l:libphobos2.a -lpthread
```

ビルドする.

```
$ ./build.sh
DMD64 D Compiler v2.067.1

+ dmd -c -noboundscheck -release source/app.d
+ gcc app.o -o tinybin -s -m64 -L/usr/lib/x86_64-linux-gnu -Xlinker -l:libphobos2.a -lpthread
$ ./tinybin
Hello!
$ wc -c < tinybin
170848
```

6 のとこででやったように dd 使って削る.

```
$ dd if=tinybin of=tinybin_nosectionhdr count=168799 bs=1
$ chmod +x tinybin_nosectionhdr
$ ./tinybin_nosectionhdr
Hello!
$ wc -c < tinybin_nosectionhdr
168799
```

### 8. synchronizedを外してcritical sectionのオーバヘッドを削減

この程度のプログラムで特にチェックする必要はなさそう.

```d
@system:

void write(size_t p, size_t len)
{
  asm
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
```

ビルドする.

```
$ wc -c < tinybin
170760
$ dd if=tinybin of=tinybin_nosectionhdr count=168711 bs=1
$ chmod +x tinybin_nosectionhdr
$ wc -c < tinybin_nosectionhdr
168711
$ ./tinybin_nosectionhdr
Hello!
```

実行もできてる.

### 9. さよなら _Dmain && _d_run_main

```d
@system:

extern(C)
{
  void write(size_t p, size_t len)
  {
    asm
    {
      mov RAX, 1;      // WRITE
      mov RDI, 1;      // STDOUT
      mov RSI, p[RBP];
      mov RDX, len[RBP];
      syscall;
    }
  }

  int main()
  {
    immutable(char)[7] buf = "Hello!\n";
    write(cast(size_t)buf.ptr, 7);
    return 0;
  }
}
```

```
$ ./tinybin
Hello!
$ wc -c < tinybin
134872
$ dd if=tinybin of=tinybin_nosectionhdr count=132887 bs=1
$ wc -c < tinybin_nosectionhdr
132887
```

### 10. エントリポイントをmainに差し替えて、不要なsectionを削除

リンカのオプションに `-e main -Xlinker --gc-section` 追加.

```
#!/bin/bash

set -e

for d in dmd; do
    which $d >/dev/null || (echo "Can't find $d, needed to build"; exit 1)
done

dmd | head -1
echo

set -x

dmd -c -noboundscheck -release source/app.d
gcc app.o -o tinybin -e main -s -Xlinker --gc-section -l:libphobos2.a -lpthread
```

`exit(2)` 呼び出しを追加. (segv対策)

```d
@system:

extern(C)
{
  void write(size_t p, size_t len)
  {
    asm
    {
      mov RAX, 1;      // WRITE
      mov RDI, 1;      // STDOUT
      mov RSI, p[RBP];
      mov RDX, len[RBP];
      syscall;
    }
  }

  void exit()
  {
    asm{
      mov RAX, 60;  // EIXT
      mov RDI, 0;
      syscall;
    }
  }

  int main()
  {
    immutable(char)[7] buf = "Hello!\n";
    write(cast(size_t)buf.ptr, 7);
    exit();
    return 0;
  }
}
```

ビルド.

```
$ ./build.sh
DMD64 D Compiler v2.067.1

+ dmd -c -noboundscheck -release source/app.d
+ gcc app.o -o tinybin -e main -s -Xlinker --gc-section -l:libphobos2.a -lpthread
$ ./tinybin
Hello!
$ wc -c < tinybin
77352
```

さらにsection headerを削った場合.

```
$ dd if=tinybin of=tinybin_nosectionhdr count=75495 bs=1
$ ./tinybin_nosectionhdr
Hello!
$ wc -c < tinybin_nosectionhdr
75495
```


### 11. エントリポイントを _Dmain に差し替えてコードを修正

```d
@system:

void write(size_t p, size_t len)
{
  asm
  {
    mov RAX, 1;  // WRITE
    mov RDI, 1;  // STDOUT
    mov RSI, p[RBP];
    mov RDX, len[RBP];
    syscall;
  }
}

void exit()
{
  asm
  {
    mov RAX, 60;  // EXIT
    mov RDI, 0;
    syscall;
  }
}


void main()
{
  immutable(char)[7] buf = "Hello!\n";
  write(cast(size_t) buf.ptr, 7);
  exit();
}
```

エントリポイントを差し替えてビルド.

```
 $ ./build.sh
 DMD64 D Compiler v2.067.1

+ dmd -c -noboundscheck -release source/app.d
+ gcc app.o -o tinybin -e _Dmain -s -Xlinker --gc-section -l:libphobos2.a -lpthread
$ ./tinybin
Hello!
$ wc -c < tinybin
77336
```

dd版.

```
$ dd if=tinybin of=tinybin_nosectionhdr count=75479 bs=1
$ wc -c < tinybin_nosectionhdr
75479
```

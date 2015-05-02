# tinybin

## 1. デフォルト

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


## 2. -releaseオプション

```
$dub build --build=release
```

```
$ ls -l tinybin
-rwxrwxr-x 1 kubo39 kubo39 700884  5月  2 16:35 tinybin
```

## 3. stdioをやめる

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


## 4. string型から固定長にする

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

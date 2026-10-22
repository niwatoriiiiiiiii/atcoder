# グリッド

## 文字列グリッド

### 空白区切りパターン

```txt
A B C
D E F
```

```rust
input! {
    h: usize,
    w: usize,
    grid: [[char; w]; h], // H行 W列 Vec<Vec<char>>
}

let val = grid[0][0];
```

### 連結パターン

```txt
ABC
DEF
```

`String` は可変長 UTF-8 なせいで `s[i]` でアクセスできない。
`s.chars().nth(i)` は $O(N)$ だから使わない。

AtCoderでは入力は基本的に英数字なので `Bytes` を使う。

```rust
input! {
    n: usize,
    s: [Bytes; n], // n行受け取る Vec<Vec<u8>>
}

// アクセスは s[i][j] で出来る
let val = s[0][0];

// 中身がu8なので判定はバイトで比較することに注意する
if val == b'A' {}
```

## 数値グリッド

### 空白区切りパターン

```txt
1 2 3
4 5 6
```

```rust
input! {
    h: usize,
    w: usize,
    grid: [[i64; w]; h], // H行 W列 Vec<Vec<i64>>
}

// アクセスは grid[i][j] で出来る
let val = grid[0][0];
```

## 連結パターン

```txt
123
456
```

```rust
input! {
    n: usize,
    s: [Bytes; n], // n行受け取る Vec<Vec<u8>>
}

// s[i][j] は u8 なので、b'0' を引くと 0〜9 の数値になる
let val = (s[0][0] - b'0') as usize;

// または最初から 0〜9 の usize の2次元配列に変換しておく
let a: Vec<Vec<usize>> = s
    .into_iter()
    .map(|row| row.into_iter().map(|b| (b - b'0') as usize).collect())
    .collect();

// またはそのまま比較する（0/1のみの場合など）
if s[0][0] == b'1' {}
```

//! Repository: https://github.com/niwatoriiiiiiiii/atcoder
//! Template: https://github.com/niwatoriiiiiiiii/atcoder/blob/master/template.rs

// ----- Imports -----
#[allow(unused_imports)]
use ac_library::*;
#[allow(unused_imports)]
use itertools::Itertools;
#[allow(unused_imports)]
use proconio::{
    fastout, input,
    marker::{Bytes, Chars, Usize1},
};
#[allow(unused_imports)]
use rustc_hash::{FxHashMap, FxHashSet};
#[allow(unused_imports)]
use std::cmp::{Reverse, max, min};
#[allow(unused_imports)]
use std::collections::{BTreeMap, BTreeSet, BinaryHeap, VecDeque};
#[allow(unused_imports)]
use superslice::Ext;

// ----- Constants -----
#[allow(dead_code)]
const INF: i64 = 1 << 60;
#[allow(dead_code)]
const DIRS4: [(isize, isize); 4] = [(-1, 0), (1, 0), (0, -1), (0, 1)];
#[allow(dead_code)]
const DIRS8: [(isize, isize); 8] = [
    (-1, -1),
    (-1, 0),
    (-1, 1),
    (0, -1),
    (0, 1),
    (1, -1),
    (1, 0),
    (1, 1),
];

// ----- Macros & Utilities -----
#[cfg(not(debug_assertions))]
#[allow(unused_macros)]
macro_rules! dbg {
    ($($x:tt)*) => {};
}

#[allow(unused_macros)]
macro_rules! chmin {
    ($target:expr, $value:expr) => {{
        let val = $value;
        if $target > val {
            $target = val;
            true
        } else {
            false
        }
    }};
}

#[allow(unused_macros)]
macro_rules! chmax {
    ($target:expr, $value:expr) => {{
        let val = $value;
        if $target < val {
            $target = val;
            true
        } else {
            false
        }
    }};
}

#[allow(dead_code)]
fn yes() {
    println!("Yes");
}

#[allow(dead_code)]
fn no() {
    println!("No");
}

// ----- Main -----
#[fastout]
fn main() {
    input! {
        s1: String,
        s2: String,
    }

    let s = s1 + &s2;

    #[allow(clippy::iter_nth_zero)]
    #[allow(clippy::if_same_then_else)]
    if s.chars().nth(0) == Some('A') && s.chars().nth(3) == Some('D') {
        no();
    } else if s.chars().nth(1) == Some('A') && s.chars().nth(2) == Some('D') {
        no();
    } else if s.chars().nth(2) == Some('A') && s.chars().nth(1) == Some('D') {
        no();
    } else if s.chars().nth(3) == Some('A') && s.chars().nth(0) == Some('D') {
        no();
    } else {
        yes();
    }
}

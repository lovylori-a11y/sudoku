import Foundation

/// 可重現的偽亂數產生器，逐位元復刻 PWA（index.html）的 `mulberry32`。
///
/// 對照 JS：
/// ```js
/// function mulberry32(seed){let a=seed>>>0;return function(){a|=0;a=a+0x6D2B79F5|0;
///   let t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};}
/// ```
/// JS 只用到 `>>>`（邏輯右移）與 `Math.imul`（32 位元乘法低位）→ 全程以 `UInt32`
/// 溢位運算（`&+`、`&*`）即可位元對齊，`>>` 對 UInt32 就是邏輯右移。
public struct Mulberry32 {
    private var a: UInt32

    /// - Parameter seed: 對應 JS 的 `seed>>>0`（無號 32 位元）。
    public init(seed: UInt32) {
        self.a = seed
    }

    /// 回傳除以 2^32 前的原始整數 `(t ^ t>>>14) >>> 0`。用於 bit-for-bit 比對。
    public mutating func nextUInt() -> UInt32 {
        a = a &+ 0x6D2B79F5
        var t = (a ^ (a >> 15)) &* (a | 1)
        t = (t &+ ((t ^ (t >> 7)) &* (t | 61))) ^ t
        return t ^ (t >> 14)
    }

    /// 對應 JS `rng()`：回傳 [0, 1) 的 Double。
    public mutating func next() -> Double {
        return Double(nextUInt()) / 4294967296.0
    }

    /// 對應 JS `Math.floor(rng()*bound)`：回傳 [0, bound) 的整數。
    public mutating func int(upperBound bound: Int) -> Int {
        return Int((next() * Double(bound)).rounded(.down))
    }
}

/// 對應 JS `shuffle(arr,rng)`：Fisher–Yates，rng 消耗順序與 JS 完全一致
/// （i 從尾到 1，j = floor(rng()*(i+1)) 後交換）。
@inlinable
public func seededShuffle<T>(_ arr: inout [T], using rng: inout Mulberry32) {
    var i = arr.count - 1
    while i > 0 {
        let j = rng.int(upperBound: i + 1)
        arr.swapAt(i, j)
        i -= 1
    }
}

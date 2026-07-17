import Foundation

/// 盤面幾何常數，對應 PWA 的 `UNITS` / `PEERS` / `_bit` / `_pc`。
enum SudokuGeometry {
    /// 27 個「單元」= 9 列 + 9 行 + 9 宮，順序與 JS 一致：
    /// index 0..8 = 列（rows），9..17 = 行（cols），18..26 = 宮（boxes）。
    /// 這個順序被 humanSolve 的技巧掃描直接依賴，不能改。
    static let units: [[Int]] = {
        var u: [[Int]] = []
        // rows
        for r in 0..<9 {
            var a: [Int] = []
            for c in 0..<9 { a.append(r * 9 + c) }
            u.append(a)
        }
        // columns
        for c in 0..<9 {
            var a: [Int] = []
            for r in 0..<9 { a.append(r * 9 + c) }
            u.append(a)
        }
        // boxes
        for br in 0..<3 {
            for bc in 0..<3 {
                var a: [Int] = []
                for i in 0..<3 {
                    for j in 0..<3 { a.append((br * 3 + i) * 9 + (bc * 3 + j)) }
                }
                u.append(a)
            }
        }
        return u
    }()

    /// 每格的 20 個同行/列/宮夥伴格（不含自己）。對應 JS `PEERS`。
    static let peers: [[Int]] = {
        var p: [[Int]] = []
        for pos in 0..<81 {
            var s = Set<Int>()
            let r = pos / 9, c = pos % 9
            let br = (r / 3) * 3, bc = (c / 3) * 3
            for i in 0..<9 {
                s.insert(r * 9 + i)
                s.insert(i * 9 + c)
            }
            for i in 0..<3 {
                for j in 0..<3 { s.insert((br + i) * 9 + (bc + j)) }
            }
            s.remove(pos)
            p.append(Array(s))
        }
        return p
    }()
}

/// 對應 JS `_bit(n)=1<<(n-1)`：數字 n(1..9) → 候選位元遮罩。
@inlinable
func bitMask(_ n: Int) -> Int { 1 << (n - 1) }

/// 對應 JS `_pc(m)`：計算遮罩內設定的位元數（候選數量）。
@inlinable
func popCount(_ m: Int) -> Int { m.nonzeroBitCount }

/// 單一位元遮罩 → 其代表的數字（1..9）。取代 JS 的 `Math.log2(mask)+1`，用整數運算更精確。
@inlinable
func onlyBitNumber(_ mask: Int) -> Int { mask.trailingZeroBitCount + 1 }

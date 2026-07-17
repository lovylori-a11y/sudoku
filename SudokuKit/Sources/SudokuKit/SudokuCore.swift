import Foundation

/// 數獨核心引擎：合法性檢查、回溯完整解、唯一解計數。
/// 逐段對應 PWA `valid` / `solveFull` / `countSolutions`。
/// 盤面一律用長度 81 的 `[Int]`（0 = 空格），列優先（row-major）。
enum SudokuCore {

    /// 對應 JS `valid(b,pos,n)`：在 pos 放 n 是否不違反行/列/宮。
    @inlinable
    static func isValid(_ b: [Int], _ pos: Int, _ n: Int) -> Bool {
        let r = pos / 9, c = pos % 9
        for i in 0..<9 {
            if b[r * 9 + i] == n { return false }
            if b[i * 9 + c] == n { return false }
        }
        let br = (r / 3) * 3, bc = (c / 3) * 3
        for i in 0..<3 {
            for j in 0..<3 {
                if b[(br + i) * 9 + (bc + j)] == n { return false }
            }
        }
        return true
    }

    /// 對應 JS `solveFull(b,rng)`：以隨機數字順序回溯填滿盤面，產生一個完整解。
    /// rng 消耗順序與 JS 一致（每個空格 shuffle 一次 [1...9]）。
    static func solveFull(_ b: inout [Int], using rng: inout Mulberry32) -> Bool {
        guard let pos = b.firstIndex(of: 0) else { return true }
        var nums = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        seededShuffle(&nums, using: &rng)
        for n in nums {
            if isValid(b, pos, n) {
                b[pos] = n
                if solveFull(&b, using: &rng) { return true }
                b[pos] = 0
            }
        }
        return false
    }

    /// 對應 JS `countSolutions(b,limit)`：用 MRV（最少候選格優先）數解，最多數到 limit。
    /// 會就地修改再還原 `b`；呼叫端請傳副本。
    static func countSolutions(_ b: inout [Int], limit: Int) -> Int {
        var best = -1
        var bestC: [Int] = []
        for p in 0..<81 {
            if b[p] != 0 { continue }
            var cand: [Int] = []
            for n in 1...9 where isValid(b, p, n) { cand.append(n) }
            if cand.isEmpty { return 0 }
            if cand.count == 1 {
                b[p] = cand[0]
                let r = countSolutions(&b, limit: limit)
                b[p] = 0
                return r
            }
            if best == -1 || cand.count < bestC.count {
                best = p
                bestC = cand
            }
        }
        if best == -1 { return 1 } // 全填滿
        var count = 0
        for n in bestC {
            b[best] = n
            count += countSolutions(&b, limit: limit)
            b[best] = 0
            if count >= limit { break }
        }
        return count
    }

    /// 便利版：不改動呼叫端的盤面。
    static func countSolutions(_ b: [Int], limit: Int) -> Int {
        var copy = b
        return countSolutions(&copy, limit: limit)
    }
}

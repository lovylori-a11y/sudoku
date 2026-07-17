import Foundation

/// 一題生成結果。
public struct GeneratedPuzzle: Sendable {
    /// 難度。
    public let difficulty: Difficulty
    /// 產生此題的 seed。
    public let seed: UInt32
    /// 題面（長度 81，0 = 空格）。
    public let puzzle: [Int]
    /// 唯一正解（長度 81）。
    public let solution: [Int]

    /// 提示數（非空格數）。
    public var clueCount: Int { puzzle.reduce(0) { $0 + ($1 != 0 ? 1 : 0) } }

    public init(difficulty: Difficulty, seed: UInt32, puzzle: [Int], solution: [Int]) {
        self.difficulty = difficulty
        self.seed = seed
        self.puzzle = puzzle
        self.solution = solution
    }
}

/// 題目產生器，對外 API。
public enum SudokuGenerator {

    /// 對應 PWA `levelSeed(di,lv)`：由 難度索引＋關卡編號 算出可重現的 seed（FNV 風格雜湊）。
    /// 逐位元復刻，確保原生版與 PWA 的「第 N 關」是同一題。
    public static func levelSeed(difficultyIndex di: Int, level lv: Int) -> UInt32 {
        var h: UInt32 = 2166136261 ^ UInt32(truncatingIfNeeded: di)
        h = (h ^ UInt32(truncatingIfNeeded: lv)) &* 16777619
        h = (h ^ UInt32(truncatingIfNeeded: lv >> 8)) &* 16777619
        h = (h ^ UInt32(truncatingIfNeeded: lv >> 16)) &* 16777619
        return h
    }

    /// 對應 PWA `generate(di,seedNum)`：先解出一個完整解，再依難度的 tier/floor
    /// 逐格嘗試挖空——只有「仍是唯一解」**且**「該 tier 技巧範圍內純邏輯可解」才真的挖掉。
    /// - Parameters:
    ///   - difficulty: 難度。
    ///   - seed: 可重現的亂數種子。
    public static func generate(difficulty: Difficulty, seed: UInt32) -> GeneratedPuzzle {
        var rng = Mulberry32(seed: seed)

        var solution = [Int](repeating: 0, count: 81)
        _ = SudokuCore.solveFull(&solution, using: &rng)

        var puzzle = solution
        let tier = difficulty.tier
        let floor = difficulty.floor

        var order = Array(0..<81)
        seededShuffle(&order, using: &rng)

        var clues = 81
        for pos in order {
            if clues <= floor { break }
            let bak = puzzle[pos]
            if bak == 0 { continue }
            puzzle[pos] = 0
            let uniqueSolution = SudokuCore.countSolutions(puzzle, limit: 2) == 1
            // 唯一解 且 純邏輯（該難度技巧範圍內）可解，才真的挖掉
            if !uniqueSolution || !HumanSolver.solve(puzzle, tier: tier, recordTrace: false).solved {
                puzzle[pos] = bak
            } else {
                clues -= 1
            }
        }
        return GeneratedPuzzle(difficulty: difficulty, seed: seed, puzzle: puzzle, solution: solution)
    }

    /// 便利版：直接由 難度＋關卡編號 產生「闖關模式」的固定題目
    /// （seed 走 `levelSeed`，與 PWA 的第 N 關一致）。
    public static func levelPuzzle(difficulty: Difficulty, level: Int) -> GeneratedPuzzle {
        let seed = levelSeed(difficultyIndex: difficulty.rawValue, level: level)
        return generate(difficulty: difficulty, seed: seed)
    }
}

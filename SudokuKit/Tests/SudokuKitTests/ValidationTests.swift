import XCTest
@testable import SudokuKit

/// 200 題品質驗證：對照 PWA 的三條保證（2026-07-17 commit 967155d 起全難度 tier:1）——
/// 唯一解、0 題需要「單元素以外的技巧」（掃描可解、隨時有一格填得出）、掃描解＝正解。
final class ValidationTests: XCTestCase {

    /// 四難度 × 各 50 關 = 200 題，逐題驗證所有性質。
    func test200PuzzlesQuality() {
        let levelsPerDifficulty = 50
        var total = 0

        for diff in Difficulty.allCases {
            for lv in 1...levelsPerDifficulty {
                total += 1
                let g = SudokuGenerator.levelPuzzle(difficulty: diff, level: lv)
                let where_ = "\(diff.key) 第 \(lv) 關"

                // 1) 正解為完整合法解
                XCTAssertTrue(SudokuCheck.isCompleteValid(g.solution), "\(where_)：正解不是完整合法盤面")

                // 2) 題面提示與正解一致
                XCTAssertTrue(SudokuCheck.puzzleMatchesSolution(g.puzzle, g.solution),
                    "\(where_)：題面提示與正解不符")

                // 3) 唯一解
                XCTAssertEqual(SudokuCore.countSolutions(g.puzzle, limit: 2), 1,
                    "\(where_)：非唯一解")

                // 4) 全難度 tier 1：只用單元素（掃描）就能解開、不試誤，且掃描解＝正解
                //    （＝0 題需要單元素以外的技巧，「隨時有一格靠掃描填得出」的保證）
                let r = HumanSolver.solve(g.puzzle, tier: diff.tier, recordTrace: false)
                XCTAssertTrue(r.solved, "\(where_)：單元素技巧內無法解開（違反掃描可解保證）")
                XCTAssertEqual(r.values, g.solution, "\(where_)：掃描解與正解不一致")

                // 5) 提示數不低於 floor（產生器 clues<=floor 就停）
                XCTAssertGreaterThanOrEqual(g.clueCount, diff.floor, "\(where_)：提示數 \(g.clueCount) 低於 floor \(diff.floor)")
                XCTAssertLessThanOrEqual(g.clueCount, 81, "\(where_)：提示數異常")
            }
        }
        XCTAssertEqual(total, 200)
    }

    /// 提示數落點符合各難度預期（防止難度曲線回歸）。
    func testClueCountsPerDifficulty() {
        // 各難度取樣 30 關看提示數分佈（967155d：簡單46/中等38/困難30/專家25-27）
        let expected: [Difficulty: (min: Int, max: Int)] = [
            .easy: (46, 46),
            .medium: (38, 38),
            .hard: (30, 30),
            .expert: (25, 27),
        ]
        for diff in Difficulty.allCases {
            let range = expected[diff]!
            for lv in 1...30 {
                let g = SudokuGenerator.levelPuzzle(difficulty: diff, level: lv)
                XCTAssertGreaterThanOrEqual(g.clueCount, range.min, "\(diff.key) 第 \(lv) 關提示數過低")
                XCTAssertLessThanOrEqual(g.clueCount, range.max, "\(diff.key) 第 \(lv) 關提示數過高")
            }
        }
    }

    /// 效能量測：生成一批題目的平均耗時（Swift 不應顯著慢於 JS 版）。
    /// 註：只有 release 建置的數字有意義；debug 未最佳化會慢數十倍，故硬性斷言只在 release 生效。
    func testGenerationPerformance() {
        // 專家（最慢）lv 1..20
        _ = SudokuGenerator.levelPuzzle(difficulty: .expert, level: 1) // warm
        let count = 20
        var start = Date()
        for lv in 1...count { _ = SudokuGenerator.levelPuzzle(difficulty: .expert, level: lv) }
        let expertMs = Date().timeIntervalSince(start) / Double(count) * 1000.0
        print(String(format: "⏱ 專家難度生成平均 %.2f ms/題（%d 題）", expertMs, count))

        // 全難度混合 各 20 關
        var pairs: [(Difficulty, Int)] = []
        for d in Difficulty.allCases { for lv in 1...20 { pairs.append((d, lv)) } }
        start = Date()
        for (d, lv) in pairs { _ = SudokuGenerator.levelPuzzle(difficulty: d, level: lv) }
        let allMs = Date().timeIntervalSince(start) / Double(pairs.count) * 1000.0
        print(String(format: "⏱ 全難度混合生成平均 %.2f ms/題（%d 題）", allMs, pairs.count))

        #if !DEBUG
        // release：專家單題應在幾十毫秒內（JS 版同 workload 約 32ms；留 10 倍餘裕擋退化）
        XCTAssertLessThan(expertMs, 100, "release 生成效能異常退化")
        #endif
    }
}

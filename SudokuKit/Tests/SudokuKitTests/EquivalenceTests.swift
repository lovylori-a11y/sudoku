import XCTest
@testable import SudokuKit

/// 端到端等價：同一個 seed，Swift 版產生的題目與 JS 版逐格相同。
/// 這是最強的整體驗證——題目是 RNG＋shuffle＋solveFull＋countSolutions＋humanSolve
/// 全鏈路的乘積，逐格相同即代表整條移植鏈與 JS 對齊。
final class EquivalenceTests: XCTestCase {

    /// 闖關模式：四難度 × 關卡 1..10，共 40 題與 JS 版逐格比對。
    func testLevelPuzzlesMatchJS() {
        for f in JSFixtures.shared.levelPuzzles {
            let diff = Difficulty(rawValue: f.di)!
            // seed 本身要與 JS 一致
            let seed = SudokuGenerator.levelSeed(difficultyIndex: f.di, level: f.lv)
            XCTAssertEqual(seed, f.seed, "\(diff.key) 第 \(f.lv) 關 seed 不符")

            let g = SudokuGenerator.generate(difficulty: diff, seed: seed)
            XCTAssertEqual(g.puzzle, f.puzzle,
                "\(diff.key) 第 \(f.lv) 關題面與 JS 不符")
            XCTAssertEqual(g.solution, f.solution,
                "\(diff.key) 第 \(f.lv) 關正解與 JS 不符")
            XCTAssertEqual(g.clueCount, f.clues,
                "\(diff.key) 第 \(f.lv) 關提示數與 JS 不符")
        }
    }

    /// 無限模式：四難度 × 固定 seed 抽樣，共 20 題與 JS 版逐格比對。
    func testInfinitePuzzlesMatchJS() {
        for f in JSFixtures.shared.infinitePuzzles {
            let diff = Difficulty(rawValue: f.di)!
            let g = SudokuGenerator.generate(difficulty: diff, seed: f.seed)
            XCTAssertEqual(g.puzzle, f.puzzle,
                "\(diff.key) seed=\(f.seed) 題面與 JS 不符")
            XCTAssertEqual(g.solution, f.solution,
                "\(diff.key) seed=\(f.seed) 正解與 JS 不符")
            XCTAssertEqual(g.clueCount, f.clues,
                "\(diff.key) seed=\(f.seed) 提示數與 JS 不符")
        }
    }
}

import Foundation
import XCTest
@testable import SudokuKit

/// 對照 JS 版真實輸出的 fixture（由 tools/gen-fixtures.js 產生）。
struct JSFixtures: Decodable {
    struct DiffMeta: Decodable { let key: String; let tier: Int; let floor: Int }
    struct RNGTest: Decodable { let seed: UInt32; let uints: [UInt32]; let doubles: [Double] }
    struct LevelSeedTest: Decodable { let di: Int; let lv: Int; let seed: UInt32 }
    struct LevelPuzzle: Decodable {
        let di: Int; let lv: Int; let seed: UInt32
        let puzzle: [Int]; let solution: [Int]; let clues: Int
    }
    struct InfinitePuzzle: Decodable {
        let di: Int; let seed: UInt32
        let puzzle: [Int]; let solution: [Int]; let clues: Int
    }

    let diffs: [DiffMeta]
    let rngTests: [RNGTest]
    let levelSeedTests: [LevelSeedTest]
    let levelPuzzles: [LevelPuzzle]
    let infinitePuzzles: [InfinitePuzzle]

    static let shared: JSFixtures = load()

    private static func load() -> JSFixtures {
        let bundle = Bundle.module
        let candidates: [URL?] = [
            bundle.url(forResource: "js-fixtures", withExtension: "json", subdirectory: "Fixtures"),
            bundle.url(forResource: "js-fixtures", withExtension: "json"),
        ]
        guard let url = candidates.compactMap({ $0 }).first else {
            fatalError("找不到 js-fixtures.json 資源（Bundle.module）")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(JSFixtures.self, from: data)
        } catch {
            fatalError("解析 js-fixtures.json 失敗：\(error)")
        }
    }
}

// MARK: - 盤面驗證輔助

enum SudokuCheck {
    /// 盤面是否為完整合法解（每列/行/宮都含 1..9）。
    static func isCompleteValid(_ board: [Int]) -> Bool {
        guard board.count == 81 else { return false }
        for unit in SudokuGeometry.units {
            var seen = Set<Int>()
            for p in unit {
                let v = board[p]
                if v < 1 || v > 9 { return false }
                seen.insert(v)
            }
            if seen.count != 9 { return false }
        }
        return true
    }

    /// 題面的每個提示格是否與正解一致、空格為 0。
    static func puzzleMatchesSolution(_ puzzle: [Int], _ solution: [Int]) -> Bool {
        guard puzzle.count == 81, solution.count == 81 else { return false }
        for i in 0..<81 {
            if puzzle[i] != 0 && puzzle[i] != solution[i] { return false }
        }
        return true
    }
}

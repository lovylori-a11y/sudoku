import XCTest
@testable import SudokuKit

/// 推理步驟軌跡（教學框內容來源）的正確性與可序列化驗證。
final class ReasoningTraceTests: XCTestCase {

    /// 軌跡的 place 步驟恰好覆蓋所有空格、每步填的都是正解、無重複——證明「認真推理、不試誤」。
    func testTracePlacementsAreCorrectAndComplete() {
        for diff in Difficulty.allCases {
            for lv in 1...20 {
                let g = SudokuGenerator.levelPuzzle(difficulty: diff, level: lv)
                let r = HumanSolver.solve(g.puzzle, tier: diff.tier, recordTrace: true)
                let where_ = "\(diff.key) 第 \(lv) 關"

                XCTAssertTrue(r.solved, "\(where_)：未解開")
                XCTAssertEqual(r.values, g.solution, "\(where_)：解答不符")

                let emptyCells = Set((0..<81).filter { g.puzzle[$0] == 0 })
                var placed = Set<Int>()
                for step in r.steps where step.action == .place {
                    guard let cell = step.targetCells.first, let value = step.value else {
                        XCTFail("\(where_)：place 步驟缺少格子或數字"); continue
                    }
                    XCTAssertEqual(step.targetCells.count, 1, "\(where_)：place 應只填一格")
                    XCTAssertEqual(value, g.solution[cell], "\(where_)：第 \(step.ordinal) 步填了非正解數字（等於猜測）")
                    XCTAssertFalse(placed.contains(cell), "\(where_)：格子 \(cell) 被填兩次")
                    placed.insert(cell)
                }
                XCTAssertEqual(placed, emptyCells, "\(where_)：place 步驟沒有恰好覆蓋所有空格")
            }
        }
    }

    /// tier 1 難度的軌跡只能出現單元素技巧；不得混入 tier 2 技巧。
    func testTierRestrictionInTrace() {
        let tier1Only: Set<ReasoningStep.Technique> = [.nakedSingle, .hiddenSingle]
        for diff in [Difficulty.easy, .medium] {
            for lv in 1...20 {
                let g = SudokuGenerator.levelPuzzle(difficulty: diff, level: lv)
                let r = HumanSolver.solve(g.puzzle, tier: diff.tier, recordTrace: true)
                for step in r.steps {
                    XCTAssertTrue(tier1Only.contains(step.technique),
                        "\(diff.key) 第 \(lv) 關出現了 tier 2 技巧 \(step.technique)")
                }
            }
        }
    }

    /// 步驟欄位健全：ordinal 遞增、focus/target 在盤面範圍內、eliminate 有被刪候選。
    func testStepFieldsWellFormed() {
        let g = SudokuGenerator.levelPuzzle(difficulty: .expert, level: 7)
        let r = HumanSolver.solve(g.puzzle, tier: g.difficulty.tier, recordTrace: true)
        XCTAssertFalse(r.steps.isEmpty)
        for (idx, step) in r.steps.enumerated() {
            XCTAssertEqual(step.ordinal, idx + 1, "ordinal 應從 1 連續遞增")
            XCTAssertFalse(step.explanation.isEmpty, "說明不可為空")
            for c in step.focusCells + step.targetCells {
                XCTAssertTrue((0..<81).contains(c), "格子索引越界：\(c)")
            }
            for n in step.candidateNumbers {
                XCTAssertTrue((1...9).contains(n), "候選數字越界：\(n)")
            }
            switch step.action {
            case .place:
                XCTAssertNotNil(step.value, "place 需有 value")
            case .eliminate:
                XCTAssertNil(step.value, "eliminate 不應有 value")
                XCTAssertFalse(step.targetCells.isEmpty, "eliminate 需有被影響的格子")
            }
        }
    }

    /// ReasoningStep 可序列化（Codable round-trip 不失真）。
    func testTraceIsCodable() throws {
        let g = SudokuGenerator.levelPuzzle(difficulty: .hard, level: 3)
        let r = HumanSolver.solve(g.puzzle, tier: g.difficulty.tier, recordTrace: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(r.steps)
        let decoded = try JSONDecoder().decode([ReasoningStep].self, from: data)
        XCTAssertEqual(decoded, r.steps, "Codable round-trip 後不一致")
        XCTAssertGreaterThan(data.count, 0)
    }

    /// 印出一段真實軌跡樣本，示範教學框可拿到的資料（開發用，永遠通過）。
    func testPrintSampleTraceForDocs() throws {
        let g = SudokuGenerator.levelPuzzle(difficulty: .expert, level: 7)
        let r = HumanSolver.solve(g.puzzle, tier: g.difficulty.tier, recordTrace: true)
        print("── 樣本軌跡（expert 第 7 關，共 \(r.steps.count) 步）前 4 步 ──")
        for step in r.steps.prefix(4) {
            let cellDesc = step.targetCells.map { "(\($0/9),\($0%9))" }.joined(separator: ",")
            print("  #\(step.ordinal) [\(step.technique.displayName)] → \(cellDesc)  \(step.explanation)")
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        if let first = r.steps.first {
            let json = String(data: try encoder.encode(first), encoding: .utf8)!
            print("── 單一 ReasoningStep 的 JSON 序列化 ──\n\(json)")
        }
        XCTAssertFalse(r.steps.isEmpty)
    }

    /// tier 2 進階技巧確實被使用並記入軌跡（掃 50 關專家題，至少要出現一次）。
    func testAdvancedTechniquesAreExercised() {
        let advanced: Set<ReasoningStep.Technique> = [.pointing, .claiming, .nakedPair, .nakedTriple, .hiddenPair]
        var seen = Set<ReasoningStep.Technique>()
        for lv in 1...50 {
            let g = SudokuGenerator.levelPuzzle(difficulty: .expert, level: lv)
            let r = HumanSolver.solve(g.puzzle, tier: g.difficulty.tier, recordTrace: true)
            for step in r.steps where advanced.contains(step.technique) {
                seen.insert(step.technique)
            }
        }
        XCTAssertFalse(seen.isEmpty, "50 關專家題中沒有任何進階技巧被使用，humanSolve 進階分支可能失效")
        print("🧠 專家題用到的進階技巧：\(seen.map { $0.displayName }.sorted().joined(separator: "、"))")
    }
}

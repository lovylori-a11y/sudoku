import XCTest
@testable import SudokuKit

/// 亂數與 seed：逐位元復刻 JS 版的驗證。
final class RNGTests: XCTestCase {

    /// Mulberry32 的原始整數輸出（除以 2^32 前）逐一與 JS 版比對。
    func testMulberry32RawUIntsMatchJS() {
        for t in JSFixtures.shared.rngTests {
            var rng = Mulberry32(seed: t.seed)
            for (k, expected) in t.uints.enumerated() {
                let got = rng.nextUInt()
                XCTAssertEqual(got, expected,
                    "seed=\(t.seed) 第 \(k) 個 nextUInt 不符：Swift=\(got) JS=\(expected)")
            }
        }
    }

    /// rng() 的 Double 輸出（2^32 為 2 的次方，除法無誤差）應與 JS 完全相等。
    func testMulberry32DoublesMatchJS() {
        for t in JSFixtures.shared.rngTests {
            var rng = Mulberry32(seed: t.seed)
            for (k, expected) in t.doubles.enumerated() {
                let got = rng.next()
                XCTAssertEqual(got, expected, accuracy: 0,
                    "seed=\(t.seed) 第 \(k) 個 next() 不符：Swift=\(got) JS=\(expected)")
            }
        }
    }

    /// levelSeed(di,lv) 與 JS 版逐一相符。
    func testLevelSeedMatchesJS() {
        for t in JSFixtures.shared.levelSeedTests {
            let got = SudokuGenerator.levelSeed(difficultyIndex: t.di, level: t.lv)
            XCTAssertEqual(got, t.seed,
                "levelSeed(di=\(t.di), lv=\(t.lv)) 不符：Swift=\(got) JS=\(t.seed)")
        }
    }

    /// 難度的 tier / floor 與 JS DIFFS 一致。
    func testDifficultyMetaMatchesJS() {
        let diffs = JSFixtures.shared.diffs
        XCTAssertEqual(diffs.count, Difficulty.allCases.count)
        for (i, d) in Difficulty.allCases.enumerated() {
            XCTAssertEqual(d.key, diffs[i].key)
            XCTAssertEqual(d.tier, diffs[i].tier, "\(d.key) tier 不符")
            XCTAssertEqual(d.floor, diffs[i].floor, "\(d.key) floor 不符")
        }
    }
}

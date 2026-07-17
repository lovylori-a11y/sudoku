import Foundation

/// 人類技巧解題器：**只用人會用的推理，全程不試誤（no guessing）**。
/// 逐段對應 PWA 的 `humanSolve(puzzle,tier)`——控制流程刻意 1:1 復刻，
/// 因為 `generate` 只看它回傳的布林值決定「這格能不能挖掉」，任何流程差異都可能讓
/// 產生的題目與 JS 版不一致。
///
/// tier 1 = 只用單元素（唯一候選 / 隱藏唯一）；
/// tier 2 = 再加 區塊排除（指向 / 宣告）＋ 裸數對 / 裸數三 ＋ 隱數對。
///
/// `recordTrace` 為 true 時額外輸出可序列化的 `ReasoningStep` 軌跡（教學框用）；
/// 生成題目時走 `recordTrace: false` 快路徑，不配置額外記憶體、與 JS 效能對齊。
public enum HumanSolver {

    /// - Parameters:
    ///   - puzzle: 長度 81 的盤面（0 = 空格）。
    ///   - tier: 允許的最高技巧層級（見 `Difficulty.tier`）。
    ///   - recordTrace: 是否收集推理步驟軌跡。
    public static func solve(_ puzzle: [Int], tier: Int, recordTrace: Bool = true) -> HumanSolveResult {
        var val = puzzle
        var cand = [Int](repeating: 0, count: 81)
        for p in 0..<81 where val[p] == 0 {
            var m = 0
            for n in 1...9 where SudokuCore.isValid(val, p, n) { m |= bitMask(n) }
            cand[p] = m
        }

        var steps: [ReasoningStep] = []
        var ordinal = 0

        func cellName(_ idx: Int) -> String { "第\(idx / 9 + 1)列第\(idx % 9 + 1)行" }
        func numbersInMask(_ m: Int) -> [Int] { (1...9).filter { (m & bitMask($0)) != 0 } }

        func place(_ p: Int, _ n: Int) {
            val[p] = n
            cand[p] = 0
            let mask = bitMask(n)
            for q in SudokuGeometry.peers[p] { cand[q] &= ~mask }
        }

        var prog = true
        while prog {
            prog = false

            // ---- A) 唯一候選（naked single）：某空格只剩一個候選數 ----
            for p in 0..<81 where val[p] == 0 && popCount(cand[p]) == 1 {
                let n = onlyBitNumber(cand[p])
                if recordTrace {
                    ordinal += 1
                    steps.append(ReasoningStep(
                        ordinal: ordinal, technique: .nakedSingle, action: .place,
                        unit: nil, focusCells: [p], targetCells: [p], value: n, candidateNumbers: [n],
                        explanation: "\(cellName(p))只剩 \(n) 一個候選——1 到 9 其他數字都被同列、同行或同宮用掉了，所以這格一定是 \(n)。"))
                }
                place(p, n)
                prog = true
            }
            if prog { continue }

            // ---- B) 隱藏唯一（hidden single）：某單元裡某數字只放得下一格 ----
            for (ui, u) in SudokuGeometry.units.enumerated() {
                for n in 1...9 {
                    let b = bitMask(n)
                    var w = -1, c = 0
                    for p in u where val[p] == 0 && (cand[p] & b) != 0 { w = p; c += 1 }
                    if c == 1 {
                        if recordTrace {
                            ordinal += 1
                            let unit = UnitRef.fromUnitIndex(ui)
                            steps.append(ReasoningStep(
                                ordinal: ordinal, technique: .hiddenSingle, action: .place,
                                unit: unit, focusCells: u, targetCells: [w], value: n, candidateNumbers: [n],
                                explanation: "看\(unit.displayName)：數字 \(n) 在這個單元裡只有 \(cellName(w)) 放得下，其他格都被擋掉，所以 \(n) 一定填這裡。"))
                        }
                        place(w, n)
                        prog = true
                    }
                }
            }
            if prog { continue }

            if tier < 2 { break }

            // ---- C) 區塊排除・指向（pointing）：宮內某數只落同一列/行 → 清該列/行宮外 ----
            for bi in 18..<27 {
                let box = SudokuGeometry.units[bi]
                for n in 1...9 {
                    let b = bitMask(n)
                    let cs = box.filter { val[$0] == 0 && (cand[$0] & b) != 0 }
                    if cs.count < 2 { continue }
                    let rs = Set(cs.map { $0 / 9 })
                    let cols = Set(cs.map { $0 % 9 })
                    if rs.count == 1 {
                        let r = rs.first!
                        var removed: [Int] = []
                        for c in 0..<9 {
                            let q = r * 9 + c
                            if !box.contains(q) && (cand[q] & b) != 0 {
                                cand[q] &= ~b
                                prog = true
                                if recordTrace { removed.append(q) }
                            }
                        }
                        if recordTrace && !removed.isEmpty {
                            ordinal += 1
                            steps.append(ReasoningStep(
                                ordinal: ordinal, technique: .pointing, action: .eliminate,
                                unit: UnitRef(kind: .box, index: bi - 18), focusCells: cs, targetCells: removed,
                                value: nil, candidateNumbers: [n],
                                explanation: "第 \(bi - 18 + 1) 宮裡，數字 \(n) 只可能落在第 \(r + 1) 列 → 這條列上、宮以外的格子就都不能是 \(n) 了。"))
                        }
                    }
                    if cols.count == 1 {
                        let c = cols.first!
                        var removed: [Int] = []
                        for r in 0..<9 {
                            let q = r * 9 + c
                            if !box.contains(q) && (cand[q] & b) != 0 {
                                cand[q] &= ~b
                                prog = true
                                if recordTrace { removed.append(q) }
                            }
                        }
                        if recordTrace && !removed.isEmpty {
                            ordinal += 1
                            steps.append(ReasoningStep(
                                ordinal: ordinal, technique: .pointing, action: .eliminate,
                                unit: UnitRef(kind: .box, index: bi - 18), focusCells: cs, targetCells: removed,
                                value: nil, candidateNumbers: [n],
                                explanation: "第 \(bi - 18 + 1) 宮裡，數字 \(n) 只可能落在第 \(c + 1) 行 → 這條行上、宮以外的格子就都不能是 \(n) 了。"))
                        }
                    }
                }
            }
            if prog { continue }

            // ---- D) 區塊排除・宣告（claiming）：列/行內某數只落同一宮 → 清該宮其餘 ----
            for ui in 0..<18 {
                let u = SudokuGeometry.units[ui]
                for n in 1...9 {
                    let b = bitMask(n)
                    let cs = u.filter { val[$0] == 0 && (cand[$0] & b) != 0 }
                    if cs.count < 2 { continue }
                    let bx = Set(cs.map { p -> Int in
                        let r = p / 9, c = p % 9
                        return (r / 3) * 3 + (c / 3)
                    })
                    if bx.count == 1 {
                        let boxIndex = bx.first!
                        let box = SudokuGeometry.units[18 + boxIndex]
                        var removed: [Int] = []
                        for q in box where !u.contains(q) && val[q] == 0 && (cand[q] & b) != 0 {
                            cand[q] &= ~b
                            prog = true
                            if recordTrace { removed.append(q) }
                        }
                        if recordTrace && !removed.isEmpty {
                            ordinal += 1
                            let unit = UnitRef.fromUnitIndex(ui)
                            steps.append(ReasoningStep(
                                ordinal: ordinal, technique: .claiming, action: .eliminate,
                                unit: unit, focusCells: cs, targetCells: removed,
                                value: nil, candidateNumbers: [n],
                                explanation: "看\(unit.displayName)：數字 \(n) 只可能落在第 \(boxIndex + 1) 宮 → 這個宮裡、\(unit.displayName)以外的格子就都不能是 \(n) 了。"))
                        }
                    }
                }
            }
            if prog { continue }

            // ---- E) 裸數對 / 裸數三（naked pair / triple）----
            for (ui, u) in SudokuGeometry.units.enumerated() {
                let em = u.filter { val[$0] == 0 }
                // 裸數對
                var i = 0
                while i < em.count && !prog {
                    for j in (i + 1)..<em.count {
                        let m = cand[em[i]] | cand[em[j]]
                        if popCount(cand[em[i]]) <= 2 && popCount(cand[em[j]]) <= 2 && popCount(m) == 2 {
                            var removed: [Int] = []
                            for p in em where p != em[i] && p != em[j] && (cand[p] & m) != 0 {
                                cand[p] &= ~m
                                prog = true
                                if recordTrace { removed.append(p) }
                            }
                            if recordTrace && !removed.isEmpty {
                                ordinal += 1
                                let unit = UnitRef.fromUnitIndex(ui)
                                let ds = numbersInMask(m)
                                steps.append(ReasoningStep(
                                    ordinal: ordinal, technique: .nakedPair, action: .eliminate,
                                    unit: unit, focusCells: [em[i], em[j]], targetCells: removed,
                                    value: nil, candidateNumbers: ds,
                                    explanation: "看\(unit.displayName)：\(cellName(em[i]))和\(cellName(em[j]))的候選都只剩 \(ds[0])、\(ds[1]) → 這兩個數字被這兩格鎖住，同單元其他格不能再用 \(ds[0]) 或 \(ds[1])。"))
                            }
                        }
                    }
                    i += 1
                }
                if prog { break }
                // 裸數三
                var i2 = 0
                while i2 < em.count && !prog {
                    for j in (i2 + 1)..<em.count {
                        for k in (j + 1)..<em.count {
                            let m = cand[em[i2]] | cand[em[j]] | cand[em[k]]
                            if popCount(m) == 3 {
                                var removed: [Int] = []
                                for p in em where p != em[i2] && p != em[j] && p != em[k] && (cand[p] & m) != 0 {
                                    cand[p] &= ~m
                                    prog = true
                                    if recordTrace { removed.append(p) }
                                }
                                if recordTrace && !removed.isEmpty {
                                    ordinal += 1
                                    let unit = UnitRef.fromUnitIndex(ui)
                                    let ds = numbersInMask(m)
                                    steps.append(ReasoningStep(
                                        ordinal: ordinal, technique: .nakedTriple, action: .eliminate,
                                        unit: unit, focusCells: [em[i2], em[j], em[k]], targetCells: removed,
                                        value: nil, candidateNumbers: ds,
                                        explanation: "看\(unit.displayName)：\(cellName(em[i2]))、\(cellName(em[j]))、\(cellName(em[k]))三格的候選合起來只有 \(ds[0])、\(ds[1])、\(ds[2]) → 這三個數字被這三格鎖住，同單元其他格不能再用。"))
                                }
                            }
                        }
                    }
                    i2 += 1
                }
                if prog { break }
            }
            if prog { continue }

            // ---- F) 隱數對（hidden pair）：某單元裡兩個數字只出現在同兩格 ----
            for (ui, u) in SudokuGeometry.units.enumerated() {
                var a = 1
                while a <= 9 && !prog {
                    for bb in stride(from: a + 1, through: 9, by: 1) {
                        let ba = bitMask(a), b2 = bitMask(bb)
                        let ca = u.filter { val[$0] == 0 && (cand[$0] & ba) != 0 }
                        let cb = u.filter { val[$0] == 0 && (cand[$0] & b2) != 0 }
                        if ca.count == 2 && cb.count == 2 && ca[0] == cb[0] && ca[1] == cb[1] {
                            let keep = ba | b2
                            var changed: [Int] = []
                            for p in ca where (cand[p] & ~keep) != 0 {
                                cand[p] &= keep
                                prog = true
                                if recordTrace { changed.append(p) }
                            }
                            if recordTrace && !changed.isEmpty {
                                ordinal += 1
                                let unit = UnitRef.fromUnitIndex(ui)
                                steps.append(ReasoningStep(
                                    ordinal: ordinal, technique: .hiddenPair, action: .eliminate,
                                    unit: unit, focusCells: ca, targetCells: changed,
                                    value: nil, candidateNumbers: [a, bb],
                                    explanation: "看\(unit.displayName)：數字 \(a) 和 \(bb) 都只出現在\(cellName(ca[0]))和\(cellName(ca[1]))這兩格 → 這兩格必定是 \(a) 和 \(bb)，格內其他候選可以刪掉。"))
                            }
                        }
                    }
                    a += 1
                }
                if prog { break }
            }
        }

        return HumanSolveResult(solved: val.allSatisfy { $0 != 0 }, values: val, steps: steps)
    }
}

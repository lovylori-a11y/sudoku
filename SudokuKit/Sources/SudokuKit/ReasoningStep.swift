import Foundation

/// 指向一個「單元」（列 / 行 / 宮），供教學框標示推理範圍。
public struct UnitRef: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case row      // 橫列
        case column   // 直行
        case box      // 3×3 宮
    }
    /// 單元種類。
    public let kind: Kind
    /// 該種類內的序號，0-based（列/行/宮各 0..8）。
    public let index: Int

    public init(kind: Kind, index: Int) {
        self.kind = kind
        self.index = index
    }

    /// 由 `SudokuGeometry.units` 的索引（0..26）建立。
    static func fromUnitIndex(_ ui: Int) -> UnitRef {
        if ui < 9 { return UnitRef(kind: .row, index: ui) }
        if ui < 18 { return UnitRef(kind: .column, index: ui - 9) }
        return UnitRef(kind: .box, index: ui - 18)
    }

    /// 中文描述（1-based），如「第 3 列」「第 5 行」「第 1 宮」。
    public var displayName: String {
        switch kind {
        case .row: return "第 \(index + 1) 列"
        case .column: return "第 \(index + 1) 行"
        case .box: return "第 \(index + 1) 宮"
        }
    }
}

/// 一步人類推理的完整軌跡。**可序列化（Codable）**，是未來「教學框」的內容來源：
/// 每一步告訴玩家「看哪裡（focusCells）、用什麼技巧（technique）、為什麼（explanation）」，
/// 但**永不代填**——`value` 只提供給引擎，是否揭露由教學框決定。
public struct ReasoningStep: Codable, Equatable, Sendable {

    /// 人類數獨技巧（不含任何試誤）。
    public enum Technique: String, Codable, Sendable {
        case nakedSingle   // 唯一候選（單元素）
        case hiddenSingle  // 隱藏唯一（單元素）
        case pointing      // 區塊排除（宮內指向行/列）
        case claiming      // 區塊排除（行/列指向宮）
        case nakedPair     // 裸數對
        case nakedTriple   // 裸數三
        case hiddenPair    // 隱數對

        /// 中文技巧名。
        public var displayName: String {
            switch self {
            case .nakedSingle: return "唯一候選"
            case .hiddenSingle: return "隱藏唯一"
            case .pointing: return "區塊排除（指向）"
            case .claiming: return "區塊排除（宣告）"
            case .nakedPair: return "裸數對"
            case .nakedTriple: return "裸數三"
            case .hiddenPair: return "隱數對"
            }
        }
    }

    /// 這一步是「填入一個數字」還是「刪掉候選數」。
    public enum Action: String, Codable, Sendable {
        case place      // 確定填入 value
        case eliminate  // 刪除候選（縮小範圍，尚未確定填哪格）
    }

    /// 第幾步（1-based）。
    public let ordinal: Int
    /// 使用的技巧。
    public let technique: Technique
    /// 動作類型。
    public let action: Action
    /// 推理所在的單元（列/行/宮）；唯一候選是單格推理，為 nil。
    public let unit: UnitRef?
    /// 「看哪裡」——教學框要引導玩家觀察的格子（0..80，row = idx/9、col = idx%9）。
    public let focusCells: [Int]
    /// 這一步實際改動的格子（place：被填的那格；eliminate：被刪候選的格子）。
    public let targetCells: [Int]
    /// place 時要填入的數字；eliminate 時為 nil。
    public let value: Int?
    /// 這一步牽涉的候選數字（數對/數三的組合數字，或被刪掉的候選數）。
    public let candidateNumbers: [Int]
    /// 繁中說明：看哪裡＋為什麼。
    public let explanation: String

    public init(ordinal: Int,
                technique: Technique,
                action: Action,
                unit: UnitRef?,
                focusCells: [Int],
                targetCells: [Int],
                value: Int?,
                candidateNumbers: [Int],
                explanation: String) {
        self.ordinal = ordinal
        self.technique = technique
        self.action = action
        self.unit = unit
        self.focusCells = focusCells
        self.targetCells = targetCells
        self.value = value
        self.candidateNumbers = candidateNumbers
        self.explanation = explanation
    }
}

/// humanSolve 的結果：是否純邏輯解開、最終盤面、以及推理軌跡。
public struct HumanSolveResult: Sendable {
    /// 是否在該 tier 技巧範圍內、不試誤地完全解開。
    public let solved: Bool
    /// 解題器推得的最終盤面（solved 為 true 時即為正解）。
    public let values: [Int]
    /// 推理步驟軌跡（recordTrace 為 false 時為空陣列）。
    public let steps: [ReasoningStep]
}

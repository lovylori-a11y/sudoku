import Foundation

/// 四個難度。對應 PWA 的 `DIFFS`：
/// ```js
/// const DIFFS=[
///   {key:'easy',   name:'簡單', tier:1, floor:44 ...},
///   {key:'medium', name:'中等', tier:1, floor:34 ...},
///   {key:'hard',   name:'困難', tier:2, floor:30 ...},
///   {key:'expert', name:'專家', tier:2, floor:24 ...},
/// ];
/// ```
/// - `tier`：允許用到的最高階人類技巧（1 = 只單元素；2 = 再加區塊排除／數對數三／隱數對）。
/// - `floor`：挖到剩幾格提示就停。
public enum Difficulty: Int, CaseIterable, Codable, Sendable {
    case easy = 0
    case medium = 1
    case hard = 2
    case expert = 3

    /// 對應 JS `DIFFS[di].key`。
    public var key: String {
        switch self {
        case .easy: return "easy"
        case .medium: return "medium"
        case .hard: return "hard"
        case .expert: return "expert"
        }
    }

    /// 中文顯示名（對應 JS `DIFFS[di].name`）。
    public var displayName: String {
        switch self {
        case .easy: return "簡單"
        case .medium: return "中等"
        case .hard: return "困難"
        case .expert: return "專家"
        }
    }

    /// 允許用到的最高技巧層級（對應 JS `DIFFS[di].tier`）。
    public var tier: Int {
        switch self {
        case .easy, .medium: return 1
        case .hard, .expert: return 2
        }
    }

    /// 提示數下限（對應 JS `DIFFS[di].floor`）。
    public var floor: Int {
        switch self {
        case .easy: return 44
        case .medium: return 34
        case .hard: return 30
        case .expert: return 24
        }
    }
}

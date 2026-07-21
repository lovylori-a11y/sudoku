import Foundation

/// 四個難度。對應 PWA 的 `DIFFS`（2026-07-17 commit 967155d 起）：
/// ```js
/// const DIFFS=[
///   {key:'easy',   name:'簡單', tier:1, floor:46 ...},
///   {key:'medium', name:'中等', tier:1, floor:38 ...},
///   {key:'hard',   name:'困難', tier:1, floor:30 ...},
///   {key:'expert', name:'專家', tier:1, floor:25 ...},
/// ];
/// ```
/// - `tier`：允許用到的最高階人類技巧。**全難度 tier:1** = 只用「單元素」
///   （naked/hidden single）即可解——保證「隨時都有一格能靠掃描填出來」，
///   永遠不會卡到要抓數三/隱數對；難度只由空格多寡決定（Lori 2026-07-17 專家第 10 關
///   卡死的第一手回饋修正，見該 commit 訊息）。tier 2 技巧仍保留在 `HumanSolver`
///   （生成不用，未來教練層拿它們當「更快的捷徑」教學內容）。
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

    /// 允許用到的最高技巧層級（對應 JS `DIFFS[di].tier`）。全難度 1 = 只單元素。
    public var tier: Int { 1 }

    /// 提示數下限（對應 JS `DIFFS[di].floor`）。
    public var floor: Int {
        switch self {
        case .easy: return 46
        case .medium: return 38
        case .hard: return 30
        case .expert: return 25
        }
    }
}

import Foundation

enum Constants {
    struct SeedTag: Equatable {
        let name: String
        let color: String
        let icon: String
    }

    static let seedTags: [SeedTag] = [
        .init(name: "聊天记录", color: "#4A90D9", icon: "bubble.left.and.bubble.right"),
        .init(name: "文章/阅读", color: "#27AE60", icon: "book"),
        .init(name: "产品/UI", color: "#9B59B6", icon: "app.badge"),
        .init(name: "代码/技术", color: "#E67E22", icon: "chevron.left.forwardslash.chevron.right"),
        .init(name: "购物/订单", color: "#E74C3C", icon: "cart"),
        .init(name: "工作/会议", color: "#3498DB", icon: "briefcase"),
        .init(name: "学习/课堂", color: "#1ABC9C", icon: "graduationcap"),
        .init(name: "社交媒体", color: "#F39C12", icon: "person.2"),
        .init(name: "其他", color: "#95A5A6", icon: "tag")
    ]

    static let kimiSystemPrompt = "你是一个截图内容分析助手。你的任务是分析 OCR 识别出的截图文字内容，生成结构化笔记。请严格按照 JSON 格式输出。"

    static func kimiUserPrompt(ocrText: String) -> String {
        """
        请分析以下截图 OCR 文本，生成结构化笔记。

        OCR 原文：
        ---
        \(ocrText)
        ---

        请返回以下 JSON 格式（不要包含任何其他内容）：
        {
          "title": "15字以内的标题",
          "summary": "3-5句话的内容摘要",
          "tags": ["标签1", "标签2"],
          "entities": {
            "people": ["识别到的人名"],
            "dates": ["识别到的日期"],
            "amounts": ["识别到的金额"],
            "links": ["识别到的链接"]
          },
          "content_type": "chat|article|product|code|shopping|work|study|social|other"
        }
        """
    }
}

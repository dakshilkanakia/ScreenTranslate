import os

enum Log {
    static let capture = Logger(subsystem: "com.dakshil.ScreenTranslate", category: "capture")
    static let ocr = Logger(subsystem: "com.dakshil.ScreenTranslate", category: "ocr")
    static let translate = Logger(subsystem: "com.dakshil.ScreenTranslate", category: "translate")
    static let intent = Logger(subsystem: "com.dakshil.ScreenTranslate", category: "intent")
}

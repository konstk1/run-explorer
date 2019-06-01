import Cocoa

var str = "Hello, playground"
let dict = ["id": "1234"]

extension String {
    func toInt() -> Int? {
        return Int(self)
    }
    
    func toBool() -> Bool? {
        return Bool(self)
    }
}

let id = dict["id"]?.toInt()
"true".toInt()
"true".toBool()

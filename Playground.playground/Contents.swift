import Cocoa

func persistPurchase(identifier: String) -> [UInt8] {
    let date = Date()
    let dateFormatter = ISO8601DateFormatter()

    let uuid = getSystemUUID()!

    var encrypted = [UInt8]()
    let serialBuf = [UInt8](uuid.utf8)
    let dataBuf = [UInt8]("\(dateFormatter.string(from: date))".utf8)

    print(serialBuf.count)
    print(dataBuf.count)

    for d in dataBuf.enumerated() {
        encrypted.append(d.element ^ serialBuf[d.offset % serialBuf.count])
    }

    print(date)
    print(encrypted)
    return encrypted
}

func decodePurchase(identifier: String) {
    let uuid = getSystemUUID()!

    var encrypted = persistPurchase(identifier: "test")

    let serialBuf = [UInt8](uuid.utf8)
    var decrypted = [UInt8]()

    for d in encrypted.enumerated() {
        decrypted.append(d.element ^ serialBuf[d.offset % serialBuf.count])
    }

    let dateStr = String(bytes: decrypted, encoding: .utf8)
    print(dateStr)
    let dateFormatter = ISO8601DateFormatter()
    let date = dateFormatter.date(from:dateStr!)
    print(date)
}

func getSystemUUID() -> String? {
    let dev = IOServiceMatching("IOPlatformExpertDevice")
    let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, dev)
    let serialNumberObject = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)
    IOObjectRelease(platformExpert)
    let ser: CFTypeRef = serialNumberObject?.takeUnretainedValue() as CFTypeRef
    if let result = ser as? String {
        return result
    }
    return nil
}

//persistPurchase(identifier: "test.purchase")
decodePurchase(identifier: "test.purchase")

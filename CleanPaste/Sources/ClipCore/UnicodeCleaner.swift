public enum UnicodeCleaner {
    public static func clean(_ text: String) -> String {
        var output = String.UnicodeScalarView()
        output.reserveCapacity(text.unicodeScalars.count)

        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x00A0, 0x202F, 0x2007, 0x2009, 0x200A:
                output.append(" ")
            case 0x200B, 0x200C, 0x2060, 0xFEFF:
                continue
            default:
                output.append(scalar)
            }
        }

        return String(output)
    }
}

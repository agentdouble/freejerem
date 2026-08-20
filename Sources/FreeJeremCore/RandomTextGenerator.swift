public struct RandomTextGenerator: Sendable {
    public static let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
    private static let vowels = Array("aeiouy")
    private static let consonants = Array("bcdfghjklmnpqrstvwxz")
    private var startsSentence = true

    public init() {}

    public func nextCharacter() -> Character {
        Self.alphabet.randomElement() ?? "a"
    }

    public static func character(at index: Int) -> Character {
        alphabet[index % alphabet.count]
    }

    public mutating func nextBurst(maxCharacters: Int) -> String {
        guard maxCharacters > 0 else { return "" }
        var result = ""

        while result.count < maxCharacters {
            var word = randomWord()
            if startsSentence {
                word = word.prefix(1).uppercased() + word.dropFirst()
                startsSentence = false
            }

            let separator = result.isEmpty ? "" : " "
            guard result.count + separator.count + word.count <= maxCharacters else { break }
            result += separator + word

            if result.count < maxCharacters - 1, Int.random(in: 0..<9) == 0 {
                result += [".", ",", ";"].randomElement() ?? "."
                if result.last == "." {
                    startsSentence = true
                    if result.count < maxCharacters - 1, Bool.random() {
                        result += "\n"
                    }
                }
            }
        }

        if result.isEmpty {
            result = String(randomWord().prefix(maxCharacters))
        }
        return result
    }

    private func randomWord() -> String {
        let length = Int.random(in: 2...9)
        let startsWithVowel = Bool.random()
        return String((0..<length).map { index in
            let useVowel = (index.isMultiple(of: 2) == startsWithVowel)
            return useVowel
                ? Self.vowels.randomElement() ?? "a"
                : Self.consonants.randomElement() ?? "b"
        })
    }
}

//
//  MorseCode.swift
//  Whatch
//

import Foundation

/// Turns text into the tap pattern the Watch plays.
///
/// A pattern is a string of `.` (dot), `-` (dash), a space between letters and `/` between words.
enum MorseCode {
    static let table: [Character: String] = [
        "A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".", "F": "..-.", "G": "--.", "H": "....",
        "I": "..", "J": ".---", "K": "-.-", "L": ".-..", "M": "--", "N": "-.", "O": "---", "P": ".--.",
        "Q": "--.-", "R": ".-.", "S": "...", "T": "-", "U": "..-", "V": "...-", "W": ".--", "X": "-..-",
        "Y": "-.--", "Z": "--..",
        "0": "-----", "1": ".----", "2": "..---", "3": "...--", "4": "....-",
        "5": ".....", "6": "-....", "7": "--...", "8": "---..", "9": "----.",
    ]

    /// Longest pattern the Watch will play.
    static let limit = 80

    /// Encodes letters and digits; anything else is skipped.
    static func pattern(for text: String) -> String {
        text.uppercased()
            .split(whereSeparator: \.isWhitespace)
            .map { word in word.compactMap { table[$0] }.joined(separator: " ") }
            .filter { !$0.isEmpty }
            .joined(separator: "/")
    }

    /// Drops anything that is not part of a pattern and caps its length.
    static func sanitized(_ pattern: String) -> String {
        String(pattern.filter { ".-/ ".contains($0) }.prefix(limit))
    }

    /// The pattern with typographic dots and dashes, for showing on screen.
    static func display(_ pattern: String) -> String {
        pattern.map { symbol -> String in
            switch symbol {
            case ".": "·"
            case "-": "—"
            case "/": "  /  "
            default: " "
            }
        }.joined()
    }
}

import Foundation
import CommonCrypto

// QQ音乐歌词提供器（本地魔改版专用回落来源）
// 流程：搜索歌曲 → 下载 QRC 逐字歌词 → 解密 → 解析为 Sapphire 的 LyricLine
// 说明：QQ音乐歌词接口为社区公开的非官方接口，可能随官方调整而失效。
//      仅在 LRCLIB 查不到歌词时作为回落使用。

final class QQMusicLyricsProvider {
    static let shared = QQMusicLyricsProvider()

    private static let searchURL = "https://c.y.qq.com/soso/fcgi-bin/client_search_cp"
    private static let lyricURL = "https://c.y.qq.com/lyric/fcgi/fcg_query_lyric_download.fcg"
    private static let qrc3DESKey = "!@#)(*$%123ZXC!@!@#)(NHL" // 社区公开的 QRC 解密密钥

    private var baseHeaders: [String: String] {
        [
            "Referer": "https://y.qq.com/",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
        ]
    }

    // MARK: - 入口

    func fetchSyncedLyrics(
        for title: String,
        artist: String,
        album: String,
        duration: TimeInterval?
    ) async -> LyricsFetchOutcome {
        guard let songMid = await searchSongMid(title: title, artist: artist, duration: duration) else {
            LyricsLog.info("QQMusic: no matching song for '\(title)' / '\(artist)'")
            return .notFound
        }
        guard let lyricPayload = await downloadLyric(songMid: songMid) else {
            LyricsLog.info("QQMusic: no lyric payload for songmid \(songMid)")
            return .notFound
        }
        guard let text = Self.decodeLyricPayload(lyricPayload) else {
            LyricsLog.error("QQMusic: lyric decode failed for songmid \(songMid)")
            return .notFound
        }
        let lines = Self.parseLyrics(text)
        guard !lines.isEmpty else {
            LyricsLog.info("QQMusic: lyric parsed empty for songmid \(songMid)")
            return .notFound
        }
        LyricsLog.info("QQMusic: parsed \(lines.count) lines for '\(title)' (songmid \(songMid))")
        return .found(lines)
    }

    // MARK: - 搜索歌曲

    private struct SearchEnvelope {
        struct Payload {
            struct Song {
                struct Item: Decodable {
                    let songmid: String
                    let songname: String
                    let interval: Int
                    struct Singer: Decodable { let name: String }
                    let singer: [Singer]
                }
                let list: [Item]
            }
            let song: Song
        }
        let payload: Payload
    }

    private func searchSongMid(title: String, artist: String, duration: TimeInterval?) async -> String? {
        var components = URLComponents(string: Self.searchURL)!
        components.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "n", value: "10"),
            URLQueryItem(name: "platform", value: "yqq"),
            URLQueryItem(name: "w", value: "\(title) \(artist)")
        ]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url, timeoutInterval: 10)
        for (key, value) in baseHeaders { request.setValue(value, forHTTPHeaderField: key) }

        let data: Data
        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard (200...299).contains(status) else {
                LyricsLog.error("QQMusic search '\(title)': HTTP \(status)")
                return nil
            }
            data = Data(await bytes.reduce(into: [UInt8]()) { $0.append($1) })
        } catch {
            LyricsLog.error("QQMusic search '\(title)' failed: \(error.localizedDescription)")
            return nil
        }

        struct SearchResult: Decodable {
            struct Payload: Decodable {
                struct Song: Decodable {
                    struct Item: Decodable {
                        let songmid: String
                        let songname: String
                        let interval: Int
                        struct Singer: Decodable { let name: String }
                        let singer: [Singer]
                    }
                    let list: [Item]
                }
                let song: Song
            }
            let code: Int
            let data: Payload?
        }

        guard let result = try? JSONDecoder().decode(SearchResult.self, from: data),
              let items = result.data?.song.list, !items.isEmpty else {
            LyricsLog.info("QQMusic search '\(title)': empty result")
            return nil
        }

        // 按时长接近度选最佳匹配；没有时长信息时取第一个
        let best: SearchResult.Payload.Song.Item
        if let duration {
            let ranked = items.sorted {
                abs(Double($0.interval) - duration) < abs(Double($1.interval) - duration)
            }
            best = ranked.first ?? items[0]
            let gap = abs(Double(best.interval) - duration)
            guard gap <= 5 else {
                LyricsLog.info("QQMusic search '\(title)': best match off by \(gap)s, rejecting")
                return nil
            }
        } else {
            best = items[0]
        }
        LyricsLog.info("QQMusic search '\(title)': matched '\(best.songname)' (songmid \(best.songmid))")
        return best.songmid
    }

    // MARK: - 下载歌词

    private func downloadLyric(songMid: String) async -> String? {
        var components = URLComponents(string: Self.lyricURL)!
        components.queryItems = [
            URLQueryItem(name: "csrf_mid", value: "0"),
            URLQueryItem(name: "csrf_uin", value: "0"),
            URLQueryItem(name: "g_tk", value: "5381"),
            URLQueryItem(name: "loginUin", value: "0"),
            URLQueryItem(name: "hostUin", value: "0"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "inCharset", value: "utf8"),
            URLQueryItem(name: "outCharset", value: "utf-8"),
            URLQueryItem(name: "notice", value: "0"),
            URLQueryItem(name: "platform", value: "yqq.json"),
            URLQueryItem(name: "needNewCode", value: "0"),
            URLQueryItem(name: "cid", value: "205360772"),
            URLQueryItem(name: "reqtype", value: "2"),
            URLQueryItem(name: "songmid", value: songMid),
            URLQueryItem(name: "songtype", value: "0")
        ]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url, timeoutInterval: 10)
        for (key, value) in baseHeaders { request.setValue(value, forHTTPHeaderField: key) }

        let data: Data
        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard (200...299).contains(status) else {
                LyricsLog.error("QQMusic lyric \(songMid): HTTP \(status)")
                return nil
            }
            data = Data(await bytes.reduce(into: [UInt8]()) { $0.append($1) })
        } catch {
            LyricsLog.error("QQMusic lyric \(songMid) failed: \(error.localizedDescription)")
            return nil
        }

        guard let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let payload = object["lyric"] as? String, !payload.isEmpty else {
            LyricsLog.info("QQMusic lyric \(songMid): response missing lyric field")
            return nil
        }
        return payload
    }

    // MARK: - 解码（base64 → [hex] → 3DES 解密 → QRC/LRC 文本）

    static func decodeLyricPayload(_ base64: String) -> String? {
        guard let decoded = Data(base64Encoded: base64, options: [.ignoreUnknownCharacters]) else {
            return nil
        }
        // 变体一：base64 解出来是 hex 字符串，需要再转字节后 3DES 解密（标准 QRC 流程）
        if let hexString = String(data: decoded, encoding: .utf8),
           hexString.count > 16, hexString.count % 2 == 0,
           hexString.allSatisfy({ $0.isHexDigit }) {
            guard let encrypted = Self.hexDecoded(hexString),
                  let decrypted = Self.decrypt3DES(encrypted) else { return nil }
            return decrypted
        }
        // 变体二：base64 直接解出可读歌词文本（LRC 或明文 QRC）
        if let text = String(data: decoded, encoding: .utf8),
           text.contains("["), text.contains("]") {
            return text
        }
        return nil
    }

    private static func hexDecoded(_ hex: String) -> Data? {
        var bytes = [UInt8]()
        bytes.reserveCapacity(hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
            guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        return Data(bytes)
    }

    private static func decrypt3DES(_ data: Data) -> String? {
        let key = Array(qrc3DESKey.utf8)
        guard key.count == kCCKeySize3DES else { return nil }
        guard data.count % 8 == 0, !data.isEmpty else { return nil }
        var output = [UInt8](repeating: 0, count: data.count + kCCBlockSizeDES)
        var outputMoved = 0
        let status = data.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) -> CCCryptorStatus in
            CCCrypt(
                CCOperation(kCCDecrypt),
                CCAlgorithm(kCCAlgorithmDES),
                CCOptions(kCCOptionECBMode),
                key, key.count,
                nil,
                rawBuffer.baseAddress, data.count,
                &output, output.count,
                &outputMoved
            )
        }
        guard status == kCCSuccess, outputMoved > 0 else { return nil }
        var result = Data(output[0..<outputMoved])
        while let last = result.last, last == 0 { result.removeLast() }
        return String(data: result, encoding: .utf8)
    }

    // MARK: - 解析 QRC / LRC

    static func parseLyrics(_ text: String) -> [LyricLine] {
        if text.contains("]<(") || text.range(of: #"\[\d+,\d+\]"#, options: .regularExpression) != nil {
            return parseQRC(text)
        }
        return parseLRC(text)
    }

    private static func parseQRC(_ qrc: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        let tokenRegex = try? NSRegularExpression(pattern: #"\((\d+),(\d+),(\d+)\)([^(]*)"#)
        for rawLine in qrc.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("["), let bracketEnd = line.firstIndex(of: "]") else { continue }
            let inner = line[line.index(after: line.startIndex)..<bracketEnd]
            let parts = inner.split(separator: ",")
            guard parts.count == 2,
                  let startMs = Double(parts[0]),
                  let durationMs = Double(parts[1]) else { continue }
            let rest = String(line[line.index(after: bracketEnd)...])

            var words: [LyricWord] = []
            var plain: [String] = []
            var background: [LyricWord] = []
            if let regex = tokenRegex {
                let range = NSRange(rest.startIndex..., in: rest)
                regex.enumerateMatches(in: rest, range: range) { match, _, _ in
                    guard let match,
                          let startRange = Range(match.range(at: 1), in: rest),
                          let durationRange = Range(match.range(at: 2), in: rest),
                          let flagRange = Range(match.range(at: 3), in: rest),
                          let wordRange = Range(match.range(at: 4), in: rest),
                          let start = Double(rest[startRange]),
                          let wordDuration = Double(rest[durationRange]),
                          let flag = Int(rest[flagRange]) else { return }
                    let wordText = String(rest[wordRange])
                    guard !wordText.isEmpty, wordDuration >= 0 else { return }
                    let word = LyricWord(
                        text: wordText,
                        timestamp: start / 1000,
                        endTimestamp: (start + wordDuration) / 1000
                    )
                    if flag == 1 {
                        background.append(word)
                    } else {
                        words.append(word)
                        plain.append(wordText)
                    }
                }
            }

            let joined = plain.joined().trimmingCharacters(in: .whitespaces)
            guard !joined.isEmpty else { continue }
            lines.append(
                LyricLine(
                    text: joined,
                    timestamp: startMs / 1000,
                    endTimestamp: (startMs + durationMs) / 1000,
                    words: words,
                    background: background
                )
            )
        }
        return lines.sorted { $0.timestamp < $1.timestamp }
    }

    private static func parseLRC(_ lrc: String) -> [LyricLine] {
        // 简易 LRC 解析：[mm:ss.xx]歌词
        let pattern = #"\[(\d+):(\d+(?:\.\d+)?)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        var lines: [LyricLine] = []
        for rawLine in lrc.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            let matches = regex.matches(in: line, range: NSRange(line.startIndex..., in: line))
            guard let lastMatch = matches.last else { continue }
            guard let m1 = Range(lastMatch.range(at: 1), in: line),
                  let m2 = Range(lastMatch.range(at: 2), in: line),
                  let minutes = Double(line[m1]),
                  let seconds = Double(line[m2]) else { continue }
            let textStart = line.index(after: lastMatch.range.upperBound)
            let text = String(line[textStart...]).trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { continue }
            let timestamp = minutes * 60 + seconds
            lines.append(LyricLine(text: text, timestamp: timestamp))
        }
        return lines.sorted { $0.timestamp < $1.timestamp }
    }
}

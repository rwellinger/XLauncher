//
//  Copyright (c) 2026 Jeremie Corbier
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//


import CryptoKit
import Foundation
import zlib

/// File checksums for the updater backends, computed in fixed-size chunks so a
/// multi-gigabyte texture or model never has to be loaded into memory at once.
enum FileChecksum {
    /// Large enough that the per-read overhead disappears, small enough to stay
    /// out of the way of everything else running at the same time.
    static let chunkSize = 1 << 20

    /// Lowercase hex MD5 of the file, or `nil` if it cannot be read.
    static func md5Hex(of fileURL: URL) -> String? {
        var hasher = Insecure.MD5()
        let completed = forEachChunk(of: fileURL) { hasher.update(data: $0) }
        guard completed else { return nil }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    /// CRC32 (zlib polynomial) of the file, or `nil` if it cannot be read.
    static func crc32(of fileURL: URL) -> UInt32? {
        var crc = zlib.crc32(0, nil, 0)
        let completed = forEachChunk(of: fileURL) { chunk in
            crc = chunk.withUnsafeBytes { buffer in
                zlib.crc32(crc, buffer.bindMemory(to: Bytef.self).baseAddress, uInt(buffer.count))
            }
        }
        guard completed else { return nil }
        return UInt32(crc)
    }

    /// Feeds the file to `body` chunk by chunk. Returns `false` if the file
    /// cannot be opened or a read fails part way, so a truncated read is never
    /// mistaken for a valid checksum.
    private static func forEachChunk(of fileURL: URL, _ body: (Data) -> Void) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: fileURL) else { return false }
        defer { try? handle.close() }

        while true {
            // Each chunk is bridged from Foundation; without the pool they would
            // pile up until the whole file has been read.
            let finished: Bool? = autoreleasepool {
                do {
                    guard let data = try handle.read(upToCount: chunkSize), !data.isEmpty else { return true }
                    body(data)
                    return nil
                } catch {
                    return false
                }
            }
            if let finished { return finished }
        }
    }
}

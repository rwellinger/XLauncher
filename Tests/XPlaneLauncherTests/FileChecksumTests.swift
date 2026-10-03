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
import XCTest
import zlib
@testable import XPlaneLauncher

final class FileChecksumTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileChecksumTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    private func write(_ data: Data, named name: String) throws -> URL {
        let url = tempDir.appendingPathComponent(name)
        try data.write(to: url)
        return url
    }

    func testKnownVectors() throws {
        let url = try write(Data("abc".utf8), named: "abc.txt")
        XCTAssertEqual(FileChecksum.md5Hex(of: url), "900150983cd24fb0d6963f7d28e17f72")
        XCTAssertEqual(FileChecksum.crc32(of: url), 0x352441C2)
    }

    func testEmptyFile() throws {
        let url = try write(Data(), named: "empty")
        XCTAssertEqual(FileChecksum.md5Hex(of: url), "d41d8cd98f00b204e9800998ecf8427e")
        XCTAssertEqual(FileChecksum.crc32(of: url), 0)
    }

    func testMultiChunkFileMatchesOneShot() throws {
        // Not a multiple of the chunk size, so the last read is partial.
        let size = FileChecksum.chunkSize * 2 + 12_345
        let data = Data((0..<size).map { UInt8(truncatingIfNeeded: $0 &* 31 &+ 7) })
        let url = try write(data, named: "large.bin")

        let expectedCRC = data.withUnsafeBytes { buffer in
            UInt32(zlib.crc32(0, buffer.bindMemory(to: Bytef.self).baseAddress, uInt(buffer.count)))
        }
        XCTAssertEqual(FileChecksum.crc32(of: url), expectedCRC)

        let expectedMD5 = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(FileChecksum.md5Hex(of: url), expectedMD5)
    }

    func testMissingFileYieldsNil() {
        let url = tempDir.appendingPathComponent("does-not-exist")
        XCTAssertNil(FileChecksum.md5Hex(of: url))
        XCTAssertNil(FileChecksum.crc32(of: url))
    }
}

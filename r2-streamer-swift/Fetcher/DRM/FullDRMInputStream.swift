//
//  FullDRMInputStream.swift
//  r2-streamer-swift
//
//  Created by Mickaël Menu on 04.07.19.
//
//  Copyright 2019 Readium Foundation. All rights reserved.
//  Use of this source code is governed by a BSD-style license which is detailed
//  in the LICENSE file present in the project repository where this source code is maintained.
//

import Foundation
import R2Shared


/// A DRM input stream that read, decrypt and cache the full resource before reading requested range.
/// Can be used when it's impossible to map a read range (byte range request) to the encrypted resource, for example when the resources is deflated before encryption.
final class FullDRMInputStream: DRMInputStream {

    enum Error: Swift.Error {
        case emptyDecryptedData
        case readOutOfRange
        case readFailed
        case decryptionFailed
        case inflateFailed
    }
    
    private let isDeflated: Bool
    
    init(stream: SeekableInputStream, link: Link, license: DRMLicense, originalLength: Int, isDeflated: Bool) {
        self.isDeflated = isDeflated
        super.init(stream: stream, link: link, license: license, originalLength: originalLength)
    }
    
    /// Full decrypted data cache.
    private lazy var data: Data? = {
        // Read data from the stream
        var data: Data
        do {
            let bufferSize = Int(stream.length)
            var buffer = Array<UInt8>(repeating: 0, count: bufferSize)
            stream.open()
            try stream.seek(offset: 0, whence: .startOfFile)
            let numberOfBytesRead = (stream as InputStream).read(&buffer, maxLength: bufferSize)
            data = Data(bytes: buffer, count: numberOfBytesRead)
            stream.close()
        } catch {
            fail(with: Error.readFailed)
            return nil
        }
        
        do {
            guard let decryptedData = try license.decipher(data) else {
                fail(with: Error.emptyDecryptedData)
                return nil
            }
            data = decryptedData
        } catch {
            fail(with: Error.decryptionFailed)
            return nil
        }
        
        // If the ressource was compressed using deflate, inflate it.
        if isDeflated {
            // Remove padding from data
            let padding = Int(data[data.count - 1])
            data = data.subdata(in: Range(uncheckedBounds: (0, data.count - padding)))
    
            guard let inflatedData = data.inflate() else {
                fail(with: Error.inflateFailed)
                return nil
            }
            data = inflatedData
        }
        
        return data
    }()
    
    override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        guard hasBytesAvailable else {
            return 0
        }
        guard offset + UInt64(len) <= length else {
            fail(with: Error.readOutOfRange)
            log(.error, "\(link.href): Decryption read out of range")
            return -1
        }
        guard let data = data else {
            return -1
        }

        let readSize = (len > Int(length - offset) ? Int(length - offset) : len)
        let start = data.index(0, offsetBy: Int(offset))
        let end = data.index(start, offsetBy: readSize)
        let range = Range(uncheckedBounds: (start, end))
        
        data.copyBytes(to: buffer, from: range)
        _offset += UInt64(readSize)
        if _offset >= length {
            _streamStatus = .atEnd
        }
        return readSize
    }
    
}

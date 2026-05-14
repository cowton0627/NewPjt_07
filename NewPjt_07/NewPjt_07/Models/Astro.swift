//
//  Astro.swift
//  NewPjt_07
//

import Foundation

struct Astro: Codable {
    var title: String?
    var url: URL?
    let hdurl: String?

    /// hdurl 可能含未編碼字元，先做 URL 安全編碼再轉 URL
    var durl: URL? {
        guard let hdurl = hdurl,
              let encoded = hdurl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: encoded)
    }

    var date: Date?
    var copyright: String?
    var description: String?
}

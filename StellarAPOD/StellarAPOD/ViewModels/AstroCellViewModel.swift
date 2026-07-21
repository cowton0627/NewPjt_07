//
//  AstroCellViewModel.swift
//  StellarAPOD
//
//  單一 cell 的顯示資料。
//  cell 收到的是已準備好的字串與 URL，不做格式化。
//

import Foundation

final class AstroCellViewModel {
    let title: String?
    let imageURL: URL?

    init(astro: Astro) {
        self.title = astro.title
        self.imageURL = astro.url
    }
}

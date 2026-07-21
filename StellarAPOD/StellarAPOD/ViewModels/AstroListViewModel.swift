//
//  AstroListViewModel.swift
//  StellarAPOD
//
//  整頁的 [Astro] 狀態 + fetch + binding。
//  View 只透過 numberOfItems / cellViewModel(at:) / astro(at:) 取資料，
//  不直接碰 model 陣列、不知道 Service 存在。
//

import Foundation

final class AstroListViewModel {

    private(set) var astros: [Astro] = []

    /// View 在 viewDidLoad 註冊；資料更新時主線程回呼
    var onAstrosUpdated: (() -> Void)?
    var onError: ((String) -> Void)?

    var numberOfItems: Int { astros.count }

    func astro(at index: Int) -> Astro { astros[index] }

    func cellViewModel(at index: Int) -> AstroCellViewModel {
        AstroCellViewModel(astro: astros[index])
    }

    func fetch() {
        AstroService.shared.fetchAstros { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let list):
                self.astros = list
                self.onAstrosUpdated?()
            case .failure(let error):
                self.onError?(error.localizedDescription)
            }
        }
    }
}

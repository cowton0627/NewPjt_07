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

    enum State {
        case idle
        case loading
        case loaded
        case empty
        case failed(String)
    }

    private(set) var astros: [Astro] = []
    private var allAstros: [Astro] = []
    private let service: AstroServicing

    init(service: AstroServicing = AstroService.shared) {
        self.service = service
    }

    /// View 在 viewDidLoad 註冊；資料更新時主線程回呼
    var onStateChange: ((State) -> Void)?

    var numberOfItems: Int { astros.count }

    func astro(at index: Int) -> Astro { astros[index] }

    func cellViewModel(at index: Int) -> AstroCellViewModel {
        AstroCellViewModel(astro: astros[index])
    }

    func search(query: String?) {
        let term = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !term.isEmpty else {
            astros = allAstros
            onStateChange?(astros.isEmpty ? .empty : .loaded)
            return
        }
        astros = allAstros.filter { astro in
            [astro.title, astro.description, astro.copyright]
                .compactMap { $0 }
                .contains { $0.localizedCaseInsensitiveContains(term) }
        }
        onStateChange?(astros.isEmpty ? .empty : .loaded)
    }

    func fetch() {
        onStateChange?(.loading)
        service.fetchAstros { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let list):
                self.allAstros = list.sorted {
                    ($0.date ?? .distantPast) > ($1.date ?? .distantPast)
                }
                self.astros = self.allAstros
                self.onStateChange?(self.astros.isEmpty ? .empty : .loaded)
            case .failure(let error):
                self.onStateChange?(.failed(error.localizedDescription))
            }
        }
    }
}

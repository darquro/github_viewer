//
//  SearchUseCase.swift
//  GitHubViewer
//
//  Created by Kuroda, Yuki | Yuki | ECID on 2021/10/31.
//

import Foundation
import Combine

protocol SearchUseCaseProtocol {
    func fetch(keyword: String) -> AnyPublisher<[CardViewEntity], Error>
}

final class SearchUseCase: SearchUseCaseProtocol {

    private let searchRepository: GitHubSearchRepositoryProtocol = GitHubSearchRepository()

    func fetch(keyword: String) -> AnyPublisher<[CardViewEntity], Error> {
        searchRepository.fetch(keyword: keyword)
            .map {
                $0.items.map { item in
                    CardViewEntity(imageURL: item.owner.avatarUrl,
                                   title: item.name,
                                   subTitle: item.owner.login,
                                   language: item.language,
                                   star: item.stargazersCount,
                                   description: item.description,
                                   url: item.htmlUrl)
                }
            }
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}

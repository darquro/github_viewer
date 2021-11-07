//
//  HomeView.swift
//  GitHubViewer
//
//  Created by Kuroda, Yuki | Yuki | ECID on 2021/10/24.
//

import SwiftUI
import Combine
import ViewComponents
import WebContent

public struct HomeView<ViewModel: HomeViewModelProtocol>: View {

    @ObservedObject var viewModel: ViewModel

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.output.state == .initialzed {
                    Spacer()
                } else if viewModel.output.state == .error {
                    ErrorView()
                } else {
                    LazyVStack {
                        ForEach(viewModel.output.items.indices, id: \.self) { index in
                            let item = viewModel.output.items[index]
                            NavigationLink(destination:
                                            WebContentView(url: item.url)
                                            .navigationBarTitle(item.title, displayMode: .inline),
                                           isActive: $viewModel.output.items[index].isNavigationPushing) {
                                BigCardView(item: $viewModel.output.items[index])
                                    .onTapGesture(perform: {
                                        viewModel.input.onTappedCardView.send(index)
                                    })
                            }
                        }
                    }
                    .padding([.leading, .trailing], 8)
                }
            }
            .padding(.top, 1) // ScrollViewをpullするとカクつく事象のworkaround。ただしNavigationBarがScroll量に応じて小さくならない。
            .refreshable(onValueChanged: { refreshControl in
                viewModel.input.onRefresh.send({
                    refreshControl.endRefreshing()
                })
            })
            .overlay(
                VStack {
                    if viewModel.output.state == .dataLoading {
                        DataLoadingView()
                    }
                }
            )
            .navigationBarTitle("Home")
            .onLoad(perform: {                
                viewModel.input.onLoad.send()
            })
            .alert(isPresented: $viewModel.output.isAlertShowing) {
                Alert(title: Text("Error"),
                      message: Text("Please retry."))
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {

    @StateObject static var viewModel: ViewModelMock = .init()

    static var previews: some View {
        Group {
            HomeView(viewModel: viewModel.state(.initialzed))
                .previewDisplayName(HomeViewModelState.initialzed.rawValue)
            HomeView(viewModel: viewModel.state(.dataLoading))
                .previewDisplayName(HomeViewModelState.dataLoading.rawValue)
            HomeView(viewModel: viewModel.state(.dataFeched))
                .previewDisplayName(HomeViewModelState.dataFeched.rawValue)
            HomeView(viewModel: viewModel.state(.error))
                .previewDisplayName(HomeViewModelState.error.rawValue)
        }
    }

    final class ViewModelMock: HomeViewModelProtocol {
        let input: Input = .init()
        var binding: Binding = .init()
        var output: Output = .init()

        final class Input: HomeViewModelInput {
            var onLoad: PassthroughSubject<Void, Never> = .init()
            var onTappedCardView: PassthroughSubject<Int, Never> = .init()
            var onRefresh: PassthroughSubject<onRefreshCompletion, Never> = .init()
        }
        final class Binding: HomeViewModelBinding {}
        final class Output: HomeViewModelOutput {
            var state: HomeViewModelState = .initialzed
            var items: [CardViewEntity] = []
            var isAlertShowing: Bool = false

        }

        func state(_ state: HomeViewModelState) -> Self {
            output.state = state
            switch state {
            case .initialzed:
                break
            case .dataLoading:
                break
            case .dataFeched:
                let entity = CardViewEntity(imageURL: .init(string: "https://avatars.githubusercontent.com/u/10639145?s=200&v=4")!,
                                            title: "swift",
                                            subTitle: "apple",
                                            language: "Swift",
                                            star: 1000,
                                            description: "The Swift Programming Language",
                                            url: .init(string: "https://github.com/apple/swift")!)

                output.items = [CardViewEntity](repeating: entity, count: 3)
            case .error:
                output.isAlertShowing = true
                break
            }
            return self
        }
    }
}
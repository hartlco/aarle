//
//  ArchiveViewStore.swift
//  Aarle
//
//  Created by Martin Hartl on 18.04.22.
//

import Foundation
import ViewStore
import Types

typealias ArchiveViewStore = ViewStore<ArchiveState, ArchiveAction, ArchiveEnvironment>

struct ArchiveState {
    var archiveLinks: [ArchiveLink]
}

enum ArchiveAction {
    case archiveLink(link: Link)
}

struct ArchiveEnvironment {
    let archiveService: ArchiveService
}

let archiveReducer: ReduceFunction<ArchiveState, ArchiveAction, ArchiveEnvironment> = { _, action, env, handler in
    switch action {
    case let .archiveLink(link):
        do {
            try await env.archiveService.archive(link: link)
            let newLinks = env.archiveService.archiveLinks
            handler.handle(
                .change {
                    $0.archiveLinks = newLinks
                }
            )
        } catch {
            print(error)
        }
    }
}

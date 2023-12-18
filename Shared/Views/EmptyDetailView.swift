//
//  EmptyDetailView.swift
//  Aarle
//
//  Created by Martin Hartl on 18.12.23.
//

import SwiftUI

struct EmptyDetailView: View {
    @Environment(OverallAppState.self) private var overallAppState

    var body: some View {
        VStack {
            Spacer()
            Button(action: {
                overallAppState.navigationState.showsAddView = true
            }, label: {
                Label("Add a link", systemImage: "plus.circle.fill")
            })
            Spacer()
        }
    }
}

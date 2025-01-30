//
//  ProgressView.swift
//  workout-tracker
//
//  Created by Rory Wood on 29/01/2025.
//

import SwiftUI

struct ProgressView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Progress Tab")
                    .font(.title)
                    .padding()
            }
            .navigationTitle("Progress")
        }
    }
}

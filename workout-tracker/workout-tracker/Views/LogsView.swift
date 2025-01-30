//
//  LogsView.swift
//  workout-tracker
//
//  Created by Rory Wood on 29/01/2025.
//

import SwiftUI

struct LogsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Logs Tab")
                    .font(.title)
                    .padding()
            }
            .navigationTitle("Logs")
        }
    }
}

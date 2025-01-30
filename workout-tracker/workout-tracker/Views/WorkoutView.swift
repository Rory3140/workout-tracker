//
//  WorkoutView.swift
//  workout-tracker
//
//  Created by Rory Wood on 29/01/2025.
//

import SwiftUI

struct WorkoutView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Workout Tab")
                    .font(.title)
                    .padding()
            }
            .navigationTitle("Workout")
        }
    }
}

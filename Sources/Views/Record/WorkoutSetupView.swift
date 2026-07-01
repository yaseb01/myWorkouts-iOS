import SwiftUI

struct WorkoutSetupView: View {
    @Environment(WorkoutRecorder.self) private var recorder

    var body: some View {
        List {
            Section("Sport Type") {
                Text("Running")
                    .accessibilityLabel("Selected sport type: Running")
            }

            Section("Options") {
                Toggle("GPS Recording", isOn: .constant(true))
                    .accessibilityLabel("GPS recording toggle")
                Toggle("Heart Rate Sensor", isOn: .constant(false))
                    .accessibilityLabel("Heart rate sensor toggle")
            }

            Section {
                Button("Start Workout") {
                    recorder.start()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Start workout")
                .accessibilityHint("Begins recording a new workout")
            }
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutSetupView()
            .navigationTitle("Record")
    }
}

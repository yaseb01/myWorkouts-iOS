import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \SportType.name) private var sportTypes: [SportType]
    @Query(sort: \HeartRateZone.zoneNumber) private var hrZones: [HeartRateZone]

    @State private var showEditProfile = false
    @State private var showEditSportTypes = false
    @State private var showEditHRZones = false

    @ObservedObject private var languageManager = AppLanguageManager.shared

    private var profile: UserProfile? {
        profiles.first
    }

    var body: some View {
        List {
            Section("Settings.Goals".localized()) {
                NavigationLink {
                    GoalView()
                } label: {
                    Label("Settings.PersonalGoals".localized(), systemImage: "target")
                }
            }

            Section("Settings.BiologicalData".localized()) {
                if let profile = profile {
                    LabeledContent("Settings.Gender".localized(), value: profile.gender?.rawValue.capitalized ?? "Not.set".localized())
                    LabeledContent("Settings.BirthDate".localized(), value: profile.birthDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not.set".localized())
                    LabeledContent("Settings.Weight".localized(), value: profile.weight.map { "\(Int($0)) kg" } ?? "Not.set".localized())
                    LabeledContent("Settings.Height".localized(), value: profile.height.map { "\(Int($0)) cm" } ?? "Not.set".localized())
                    LabeledContent("Settings.VO2Max".localized(), value: profile.vo2max.map { String(format: "%.1f", $0) } ?? "Not.set".localized())
                } else {
                    Text("Settings.NoProfile".localized())
                        .foregroundStyle(.secondary)
                }
                Button("Edit".localized()) { showEditProfile = true }
                    .foregroundStyle(.green)
            }

            Section("Settings.Units".localized()) {
                if let profile = profile {
                    Picker("Settings.UnitSystem".localized(), selection: Binding(
                        get: { profile.unitSystem },
                        set: { profile.unitSystem = $0; try? modelContext.save() }
                    )) {
                        Text("Settings.Metric".localized()).tag(UnitSystem.metric)
                        Text("Settings.Imperial".localized()).tag(UnitSystem.imperial)
                    }
                }
            }

            Section("Settings.Language".localized()) {
                Picker("Settings.Language".localized(), selection: $languageManager.currentLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
            }

            Section("Settings.HeartRateZones".localized()) {
                Button { showEditHRZones = true } label: {
                    Label("Settings.ManageZones".localized(), systemImage: "waveform.path.ecg")
                }
                .foregroundStyle(.green)
            }

            Section("Settings.WorkoutTypes".localized()) {
                Button { showEditSportTypes = true } label: {
                    Label("Settings.ManageTypes".localized(), systemImage: "figure.run")
                }
                .foregroundStyle(.green)
            }

            Section("Settings.Info".localized()) {
                LabeledContent("Settings.Version".localized(), value: "1.0")
                Link(destination: URL(string: "https://www.myworkouts.org/privacy")!) {
                    Label("Settings.PrivacyPolicy".localized(), systemImage: "lock.shield")
                }
                Link(destination: URL(string: "https://www.myworkouts.org/terms-of-use")!) {
                    Label("Settings.TermsOfUse".localized(), systemImage: "doc.text")
                }
                Link(destination: URL(string: "mailto:info@myworkouts.org")!) {
                    Label("Settings.SendFeedback".localized(), systemImage: "envelope")
                }
                Link(destination: URL(string: "https://www.myworkouts.org")!) {
                    Label("Settings.Website".localized(), systemImage: "globe")
                }
            }
        }
        .navigationTitle("Settings".localized())
        .sheet(isPresented: $showEditProfile) { EditProfileView(profile: profile) }
        .sheet(isPresented: $showEditSportTypes) { EditSportTypesView() }
        .sheet(isPresented: $showEditHRZones) { EditHRZonesView() }
    }
}

// MARK: - Edit HR Zones (matching Android screenshot)

struct EditHRZonesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HeartRateZone.zoneNumber) private var hrZones: [HeartRateZone]

    @State private var showAddZone = false
    @State private var editingZone: HeartRateZone?
    @State private var newMinHR: Double = 100
    @State private var newMaxHR: Double = 180
    @State private var newName = ""
    @State private var newDescription = ""

    var body: some View {
        List {
            // Full Range summary
            if let first = hrZones.first, let last = hrZones.last {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(.systemGray3))
                        .frame(width: 52, height: 52)
                        .overlay {
                            Text("*")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(first.minHR) - \(last.maxHR)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.white)
                        Text("Full Range (HR rest ... HR max)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("0% - 100%")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
                .padding(.vertical, 4)
            }

            // Individual zones
            ForEach(hrZones) { zone in
                Button {
                    editingZone = zone
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(zoneColor(for: zone.zoneNumber))
                            .frame(width: 52, height: 52)
                            .overlay {
                                Text(zone.abbreviation)
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(zone.minHR) - \(zone.maxHR)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.white)
                            Text(zone.zoneDescription.isEmpty ? zone.name : zone.zoneDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(Int(zone.minPercentage))% - \(Int(zone.maxPercentage))%")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete(perform: deleteZones)

            Button { showAddZone = true } label: {
                Label("Add Zone", systemImage: "plus")
            }
        }
        .navigationTitle("Heart Rate Zones")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $showAddZone) {
            AddZoneSheet(minHR: $newMinHR, maxHR: $newMaxHR, name: $newName, description: $newDescription) {
                let zone = HeartRateZone(
                    name: newName.isEmpty ? "Zone \(hrZones.count + 1)" : newName,
                    zoneDescription: newDescription,
                    minHR: Int(newMinHR),
                    maxHR: Int(newMaxHR),
                    zoneNumber: hrZones.count,
                    minPercentage: 0,
                    maxPercentage: 100
                )
                modelContext.insert(zone)
                try? modelContext.save()
                newName = ""
                newDescription = ""
                newMinHR = 100
                newMaxHR = 180
                showAddZone = false
            }
        }
        .sheet(item: $editingZone) { zone in
            EditZoneSheet(zone: zone)
        }
    }

    private func deleteZones(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(hrZones[index])
        }
        try? modelContext.save()
    }

    private func zoneColor(for zone: Int) -> Color {
        switch zone {
        case 0: return Color(.systemGray3)
        case 1: return Color(red: 0.7, green: 0.5, blue: 0.8)
        case 2: return Color(red: 0.6, green: 0.3, blue: 0.8)
        case 3: return Color(red: 0.5, green: 0.2, blue: 0.9)
        case 4: return Color(red: 0.4, green: 0.1, blue: 0.95)
        case 5: return Color(red: 0.3, green: 0.05, blue: 1.0)
        default: return .gray
        }
    }
}

// MARK: - Add Zone Sheet

struct AddZoneSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var minHR: Double
    @Binding var maxHR: Double
    @Binding var name: String
    @Binding var description: String
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Zone Name") {
                    TextField("Name", text: $name)
                    TextField("Description (e.g., Easy / Recovery)", text: $description)
                }
                Section("Heart Rate Range") {
                    HStack {
                        Text("Min HR")
                        Spacer()
                        TextField("bpm", value: $minHR, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("bpm").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Max HR")
                        Spacer()
                        TextField("bpm", value: $maxHR, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("bpm").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Add Zone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave() }
                        .disabled(minHR >= maxHR)
                }
            }
        }
    }
}

// MARK: - Edit Zone Sheet

struct EditZoneSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let zone: HeartRateZone

    @State private var minHR: Double = 0
    @State private var maxHR: Double = 0
    @State private var name: String = ""
    @State private var zoneDescription: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Zone Info") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $zoneDescription)
                    HStack {
                        Text("Zone Number")
                        Spacer()
                        Text("\(zone.zoneNumber)")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Heart Rate Range") {
                    HStack {
                        Text("Min HR")
                        Spacer()
                        TextField("bpm", value: $minHR, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("bpm").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Max HR")
                        Spacer()
                        TextField("bpm", value: $maxHR, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("bpm").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Zone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        zone.name = name
                        zone.zoneDescription = zoneDescription
                        zone.minHR = Int(minHR)
                        zone.maxHR = Int(maxHR)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                minHR = Double(zone.minHR)
                maxHR = Double(zone.maxHR)
                name = zone.name
                zoneDescription = zone.zoneDescription
            }
        }
    }
}

// MARK: - Edit Sport Types (matching Android screenshot)

struct EditSportTypesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SportType.name) private var sportTypes: [SportType]

    @State private var showAddSport = false
    @State private var editingSport: SportType?
    @State private var newName = ""
    @State private var newAbbr = ""
    @State private var newColor = "#007AFF"

    private let colorOptions = [
        "#007AFF", "#34C759", "#FF9500", "#FF3B30", "#AF52DE",
        "#5856D6", "#FF2D55", "#00C7BE", "#30B0C7", "#8E8E93",
        "#FFD60A", "#64D2FF", "#BF5AF2", "#FF453A", "#32D74B"
    ]

    var body: some View {
        List {
            ForEach(sportTypes) { sport in
                Button {
                    editingSport = sport
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: sport.color) ?? .blue)
                            .frame(width: 44, height: 44)
                            .overlay {
                                Text(sport.abbreviation)
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }

                        Text(sport.name)
                            .foregroundStyle(.white)

                        Spacer()

                        Button {
                            sport.isFavorite.toggle()
                            try? modelContext.save()
                        } label: {
                            Image(systemName: sport.isFavorite ? "star.fill" : "star")
                                .foregroundStyle(sport.isFavorite ? .yellow : Color(.systemGray3))
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .onDelete(perform: deleteSports)
        }
        .navigationTitle("Workout Types")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSport = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $showAddSport) {
            AddSportSheet(name: $newName, abbr: $newAbbr, color: $newColor, colorOptions: colorOptions) {
                let sport = SportType(
                    name: newName,
                    abbreviation: newAbbr.isEmpty ? String(newName.prefix(3)).uppercased() : newAbbr,
                    color: newColor
                )
                modelContext.insert(sport)
                try? modelContext.save()
                newName = ""
                newAbbr = ""
                newColor = "#007AFF"
                showAddSport = false
            }
        }
        .sheet(item: $editingSport) { sport in
            EditSportSheet(sport: sport)
        }
    }

    private func deleteSports(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sportTypes[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Add Sport Sheet

struct AddSportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    @Binding var abbr: String
    @Binding var color: String
    let colorOptions: [String]
    let onSave: () -> Void

    @State private var selectedColor: String = "#007AFF"

    var body: some View {
        NavigationStack {
            Form {
                Section("Sport Info") {
                    TextField("Name (e.g., Indoor Cycling)", text: $name)
                    TextField("Abbreviation (e.g., IC)", text: $abbr)
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if selectedColor == hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = hex
                                    color = hex
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Add Sport Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear { selectedColor = color }
        }
    }
}

// MARK: - Edit Sport Sheet

struct EditSportSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let sport: SportType

    @State private var name = ""
    @State private var abbr = ""
    @State private var selectedColor = ""

    let colorOptions = [
        "#007AFF", "#34C759", "#FF9500", "#FF3B30", "#AF52DE",
        "#5856D6", "#FF2D55", "#00C7BE", "#30B0C7", "#8E8E93",
        "#FFD60A", "#64D2FF", "#BF5AF2", "#FF453A", "#32D74B"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Sport Info") {
                    TextField("Name", text: $name)
                    TextField("Abbreviation", text: $abbr)
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if selectedColor == hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { selectedColor = hex }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Edit Sport Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        sport.name = name
                        sport.abbreviation = abbr
                        sport.color = selectedColor
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = sport.name
                abbr = sport.abbreviation
                selectedColor = sport.color
            }
        }
    }
}

// MARK: - Edit Profile

struct EditProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile?

    @State private var gender: Gender = .preferNotToSay
    @State private var birthDate = Date(timeIntervalSince1970: 0)
    @State private var weight: Double = 70
    @State private var height: Double = 175
    @State private var vo2max: Double = 0

    var body: some View {
        Form {
            Section("Personal Information") {
                Picker("Gender", selection: $gender) {
                    ForEach(Gender.allCases, id: \.self) { g in
                        Text(g.rawValue.capitalized).tag(g)
                    }
                }
                DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
            }
            Section("Measurements") {
                HStack {
                    Text("Weight"); Spacer()
                    TextField("kg", value: $weight, format: .number)
                        .multilineTextAlignment(.trailing).frame(width: 80)
                    Text("kg").foregroundStyle(.secondary)
                }
                HStack {
                    Text("Height"); Spacer()
                    TextField("cm", value: $height, format: .number)
                        .multilineTextAlignment(.trailing).frame(width: 80)
                    Text("cm").foregroundStyle(.secondary)
                }
                HStack {
                    Text("VO2 Max"); Spacer()
                    TextField("ml/kg/min", value: $vo2max, format: .number)
                        .multilineTextAlignment(.trailing).frame(width: 80)
                    Text("ml/kg/min").foregroundStyle(.secondary)
                }
            }
            Section {
                Button("Save") {
                    if let profile = profile {
                        profile.gender = gender
                        profile.birthDate = birthDate
                        profile.weight = weight
                        profile.height = height
                        profile.vo2max = vo2max > 0 ? vo2max : nil
                    } else {
                        let new = UserProfile(gender: gender, birthDate: birthDate,
                                              weight: weight, height: height,
                                              vo2max: vo2max > 0 ? vo2max : nil)
                        modelContext.insert(new)
                    }
                    try? modelContext.save()
                    dismiss()
                }
                .font(.headline).frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let p = profile {
                gender = p.gender ?? .preferNotToSay
                birthDate = p.birthDate ?? Date(timeIntervalSince1970: 0)
                weight = p.weight ?? 70
                height = p.height ?? 175
                vo2max = p.vo2max ?? 0
            }
        }
    }
}

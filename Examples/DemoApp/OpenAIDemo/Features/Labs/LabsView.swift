import SwiftUI

struct LabsView: View {
  var body: some View {
    NavigationStack {
      List {
        NavigationLink(value: LabDestination.tools) {
          Label("Function tools", systemImage: "wrench.and.screwdriver")
        }
        NavigationLink(value: LabDestination.guided) {
          Label("Guided generation", systemImage: "curlybraces")
        }
        NavigationLink(value: LabDestination.profiles) {
          Label("Dynamic profiles", systemImage: "person.2.badge.gearshape")
        }
        NavigationLink(value: LabDestination.architecture) {
          Label("Architecture", systemImage: "point.3.connected.trianglepath.dotted")
        }
      }
      .navigationTitle("Labs")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(for: LabDestination.self) {
        switch $0 {
        case .tools:
          ToolsLabView()
        case .guided:
          GuidedLabView()
        case .profiles:
          ProfilesLabView()
        case .architecture:
          ArchitectureView()
        }
      }
    }
  }
}

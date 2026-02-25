import SwiftUI

struct JobManagementView: View {
    @ObservedObject var viewModel: TimerViewModel
    let startJob: (Job) -> Void

    @State private var newJobDescription: String = ""
    @State private var filterText: String = ""
    @State private var jobSelection = Set<Int64>()
    @State private var showDeleteConfirmation = false

    private var selectedJob: Job? {
        guard let id = jobSelection.first else { return nil }
        return filteredJobs.first { $0.id == id }
    }

    private var filteredJobs: [Job] {
        if filterText.isBlank {
            return viewModel.jobs
        }
        return viewModel.jobs.filter { job in
            job.description.localizedCaseInsensitiveContains(filterText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Jobs")
                    .font(.headline)
                Spacer()
#if os(macOS)
                MacSearchField(text: $filterText, prompt: "Filter")
                    .frame(width: 220)
#else
                TextField("Filter", text: $filterText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
#endif
            }

            HStack {
                TextField("Add job description", text: $newJobDescription)
                Button("Add") {
                    let trimmed = newJobDescription.trimmed()
                    guard !trimmed.isEmpty else { return }
                    viewModel.addJob(description: trimmed)
                    newJobDescription = ""
                }
                .disabled(newJobDescription.isBlank)
            }

            Table(filteredJobs, selection: $jobSelection) {
                TableColumn("Description") { job in
                    Text(job.description)
                }
            }
            .frame(height: 160)

            HStack {
                Button("Start Job") {
                    if let job = selectedJob {
                        startJob(job)
                    }
                }
                .disabled(selectedJob == nil)

                Button("Remove Job") {
                    if selectedJob != nil {
                        showDeleteConfirmation = true
                    }
                }
                .disabled(selectedJob == nil)
            }
        }
        .onChange(of: viewModel.selectedJobID) { newValue in
            if let newValue {
                jobSelection = [newValue]
            } else {
                jobSelection.removeAll()
            }
        }
        .onChange(of: jobSelection) { newSelection in
            viewModel.selectedJobID = newSelection.first
        }
        .alert("Delete Job",
               isPresented: $showDeleteConfirmation,
               presenting: selectedJob) { job in
            Button("Delete", role: .destructive) {
                viewModel.deleteSelectedJob()
            }
        } message: { job in
            Text("Are you sure you want to delete job '\(job.description)'?")
        }
    }
}

#if os(macOS)
import AppKit

private struct MacSearchField: NSViewRepresentable {
    @Binding var text: String
    var prompt: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.placeholderString = prompt
        field.target = context.coordinator
        field.action = #selector(Coordinator.textChanged(_:))
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSSearchFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        @objc func textChanged(_ sender: NSSearchField) {
            text = sender.stringValue
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSSearchField else { return }
            text = field.stringValue
        }
    }
}
#endif

import SwiftUI

struct JobManagementView: View {
    @ObservedObject var viewModel: TimerViewModel
    let startJob: (Job) -> Void

    @State private var newJobDescription: String = ""
    @State private var jobSelection = Set<Int64>()
    @State private var showDeleteConfirmation = false

    private var selectedJob: Job? {
        guard let id = jobSelection.first else { return nil }
        return viewModel.jobs.first { $0.id == id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Jobs")
                .font(.headline)

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

            Table(viewModel.jobs, selection: $jobSelection) {
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

import SwiftUI

struct JobManagementView: View {
    @ObservedObject var viewModel: TimerViewModel
    let startJob: (Job) -> Void

    @State private var newJobDescription: String = ""
    @State private var jobSelection: Int64?

    private var selectedJob: Job? {
        guard let id = jobSelection else { return nil }
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

            List(viewModel.jobs, id: \.id) { job in
                HStack {
                    Text(job.description)
                    Spacer()
                    if jobSelection == job.id {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    jobSelection = job.id
                    viewModel.selectedJobID = job.id
                }
            }
            .frame(height: 160)

            HStack {
                Button("Start Job") {
                    if let job = selectedJob {
                        startJob(job)
                    }
                }
                .disabled(selectedJob?.description.isBlank ?? true)

                Button("Remove Job") {
                    viewModel.deleteSelectedJob()
                }
                .disabled(selectedJob == nil)
            }
        }
        .onChange(of: viewModel.selectedJobID) { newValue in
            jobSelection = newValue
        }
    }
}

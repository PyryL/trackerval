//
//  MotionSurveyListView.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 20.9.2024.
//

import SwiftUI

struct MotionSurveyListView: View {
    private let repository = MotionSurveyRepository()
    private let phoneConnection = PhoneConnectionManager()

    @State var files: [MotionSurveyRepository.RepositoryFile] = []
    @State var ongoingExport: URL? = nil
    @State var alertTitle: String? = nil

    // TODO: toolbar item to remove all files

    private func export(url: URL) {
        guard ongoingExport == nil else {
            return
        }

        ongoingExport = url

        phoneConnection.sendFile(url: url) { error in
            if let error {
                print("failed to send file to phone", error)
                alertTitle = "Failed to transfer the file"
            }

            ongoingExport = nil
        }
    }

    var body: some View {
        List {
            ForEach(files, id: \.self) { file in
                Button {
                    export(url: file.url)
                } label: {
                    listItem(file: file)
                }
            }
        }
        .navigationTitle("Motion survey")
        .alert(alertTitle ?? "", isPresented: Binding(
            get: { alertTitle != nil },
            set: { alertTitle = $0 ? alertTitle : nil }
        )) {
            Button("OK") { }
        }
        .onAppear {
            do {
                files = try repository.listFiles()
            } catch {
                print("failed to load motion survey files", error)
            }
        }
    }

    private func listItem(file: MotionSurveyRepository.RepositoryFile) -> some View {
        HStack {
            VStack(alignment: .leading) {
                if let date = file.date {
                    Text(date, format: .dateTime)
                        .font(.headline)
                } else {
                    Text("???")
                        .font(.headline)
                }

                if let fileSize = file.fileSize {
                    Text(ByteCountFormatter().string(fromByteCount: Int64(fileSize)))
                        .font(.subheadline)
                } else {
                    Text("???")
                        .font(.subheadline)
                }
            }

            Spacer(minLength: 0)

            if ongoingExport == file.url {
                ProgressView()
                    .progressViewStyle(.circular)
                    .fixedSize(horizontal: true, vertical: true)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MotionSurveyListView(files: [
            .init(date: .now.addingTimeInterval(-60*60), fileSize: 123456, url: URL(string: "/path/to/file.json")!),
        ])
    }
}

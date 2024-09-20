//
//  MotionSurveyListView.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 20.9.2024.
//

import SwiftUI

struct MotionSurveyListView: View {
    private let repository = MotionSurveyRepository()

    @State var files: [MotionSurveyRepository.RepositoryFile] = []

    // TODO: toolbar item to remove all files

    // TODO: function to export a certain file

    var body: some View {
        List {
            ForEach(files, id: \.self) { file in
                listItem(file: file)
            }
        }
        .navigationTitle("Motion survey")
        .onAppear {
            do {
                files = try repository.listFiles()
            } catch {
                print("failed to load motion survey files", error)
            }
        }
    }

    private func listItem(file: MotionSurveyRepository.RepositoryFile) -> some View {
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
    }
}

#Preview {
    NavigationStack {
        MotionSurveyListView(files: [
            .init(date: .now.addingTimeInterval(-60*60), fileSize: 123456),
        ])
    }
}

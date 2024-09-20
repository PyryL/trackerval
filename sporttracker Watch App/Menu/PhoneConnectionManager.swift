//
//  PhoneConnectionManager.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 20.9.2024.
//

import WatchConnectivity

class PhoneConnectionManager: NSObject, WCSessionDelegate {
    override init() {
        super.init()
        session.delegate = self
        session.activate()
    }

    private let session = WCSession.default

    private var fileTransferCallbacks: [UUID : (Error?) -> ()] = [:]

    func sendFile(url: URL, callback: @escaping (Error?) -> ()) {
        guard session.isReachable, session.activationState == .activated else {
            callback(WCError(.notReachable))
            return
        }

        let transferId = UUID()

        fileTransferCallbacks[transferId] = callback

        session.transferFile(url, metadata: ["transferId": transferId.uuidString])
    }

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: (any Error)?) {
        // this will not be called because of a bug in Apple's software
        // see https://forums.developer.apple.com/forums/thread/751623
        // using workaround of sending a message back from iOS after successful transfer

        print("file transfer finished", fileTransfer.file.metadata as Any, error as Any)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // workaround
        if let transferIdString = message["receivedFile"] as? String,
           let transferId = UUID(uuidString: transferIdString) {

            guard let callback = fileTransferCallbacks.removeValue(forKey: transferId) else {
                print("did not find callback for received file transfer", transferId)
                return
            }

            callback(nil)

            // another bug in Apple's software
            // see https://forums.developer.apple.com/forums/thread/751623?answerId=792532022#792532022
            session.outstandingFileTransfers.forEach {
                if $0.progress.isFinished {
                    $0.cancel()
                }
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        //
    }
}

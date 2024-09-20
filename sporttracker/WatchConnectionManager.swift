//
//  WatchConnectionManager.swift
//  sporttracker
//
//  Created by Pyry Lahtinen on 20.9.2024.
//

import WatchConnectivity

class WatchConnectionManager: NSObject, WCSessionDelegate {
    override init() {
        super.init()
        session.delegate = self
        session.activate()
    }

    private let session = WCSession.default

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard let transferIdString = file.metadata?["transferId"] as? String,
              let transferId = UUID(uuidString: transferIdString) else {

            print("received file without transfer id")
            return
        }

        // TODO: handle received file
        print("airdrop file at", file.fileURL.absoluteString)

        // workaround (see PhoneConnectionManager)
        session.sendMessage(["receivedFile": transferId.uuidString], replyHandler: nil) { error in
            print("failed to send file transfer reply", error)
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        //
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        //
    }

    func sessionDidDeactivate(_ session: WCSession) {
        //
    }
}

//
//  MultipeerManager.swift
//  ClickSync
//
//  Created by George Casartelli on 18/12/2025.
//

//
//  MultipeerManager.swift
//  Network Test
//
//  Created by George Casartelli on 18/12/2025.
//

import MultipeerConnectivity
import SwiftUI

enum DeviceRole {
    case master
    case client
    case none
}


class MultipeerManager: NSObject, ObservableObject {
    @Published var receivedWord: String = "Waiting for a word..." // when this changes screen will update
    @Published var connectedPeers: [String] = []
    @Published var role: DeviceRole = .none
    
    @Published var lastAction: String?
    
    private let myPeerID: MCPeerID // nametag
    private var session: MCSession! // conversation channel where devices talk - opens the phone line
    
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    
    private let serviceType = "word-share"
    
    override init() {
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name) // sets displayname to device settings name
        super.init()
        
        self.session = MCSession(peer: myPeerID, // this is me, tells session who we are
                                 securityIdentity: nil, // certificate based encryption, unneeded
                                 encryptionPreference: .none)
        session.delegate = self
        
        // create advertiser -> broadcasts im  here msg
        
        self.advertiser = MCNearbyServiceAdvertiser(peer:myPeerID,
                                                    discoveryInfo: nil,
                                                    serviceType: serviceType)
        advertiser.delegate = self
        
        //create browser to look for others
        self.browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser.delegate = self
    }
    
    func startAsMaster() {
        role = .master
        advertiser.startAdvertisingPeer()
        print("Started as Master - advertising")
    }
    
    func startAsClient() {
        role = .client
        browser.startBrowsingForPeers()
        print("Started as Client - browsing")
    }
    
    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        role = .none
        connectedPeers = []
    }
    
    func send(word: String) {
        guard !session.connectedPeers.isEmpty else {
            print("No one is connected!")
            return
        }
        
        if let data = word.data(using: .utf8) { // convert to utf8 and send
            try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
            print("Sent word: \(word)")
        }
    }
    
    func sendCommand(_ cmd: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: cmd, options: [])
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            print("Sent command: \(cmd)")
        } catch {
            print("Failed to send cmd: \(cmd)")
        }
    }
}

extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
       // connection state changes handles here
        print("Peer \(peerID.displayName) changed state: \(state.rawValue)")
        
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers.map { $0.displayName }
        }
    }
    
    // didReceive data gets called when someone sends info
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // this is message receiving
        
        // here we convert data back to a string and update received word
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            guard let command = json as? [String: Any] else {
                print("Received JSON but not a dictionary")
                return
            }
            
            print("Received command: \(command)")
            
            guard let action = command["action"] as? String else {
                print("Command has no action")
                return
            }
            guard let sender = command["sender"] as? String else {
                print("Command has no sender")
                return
            }
            
            print("Action is \(action)")
            print("Sender is \(sender)")
            
            if sender == "master" {
                DispatchQueue.main.async {
                    self.lastAction = action
                }
            }
            
            
            
        } catch {
            print("Failed to decode JSON: \(error)")
        }
    }
    
    //idk what these are for
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // someone has found us!
        print("Received invitation from \(peerID.displayName)")
        invitationHandler(true, session)// when someone sends invite, we auto accept with this line
    }
}


extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10) // if we detect someone we invite them to session
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
    }
}




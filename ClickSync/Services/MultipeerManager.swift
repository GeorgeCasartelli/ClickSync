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
//import SwiftUI
import Combine
import Foundation



class MultipeerManager: NSObject, ObservableObject {

    @Published var connectedPeers: [String] = []
    @Published var role: DeviceRole = .none

    @Published var lastCommand: NetworkCommand?
    
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
    
    
    func sendCommand(_ cmd: NetworkCommand) {
        print("In send command")
        guard !session.connectedPeers.isEmpty else { return }
        print("At do catch")
        do {
            let data = try JSONEncoder().encode(cmd)
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
    // MARK: Receive
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // this is message receiving
        
        // here we convert data back to a string and update received word
        
        do {
            let command = try JSONDecoder().decode(NetworkCommand.self, from: data)
            DispatchQueue.main.async {
                self.lastCommand = command
            }
            print("Received command from \(peerID.displayName): \(command)")
        } catch {
            print("Failed to decode NetworkCommand from \(peerID.displayName): \(error)")
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




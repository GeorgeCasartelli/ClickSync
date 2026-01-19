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

import Combine
import Foundation

// manages peer to peer connectivity using Apples MultipeerConnectivity framework
/// Responsibilities:
/// - Advertise/browse for nearby devices
/// - Establish an MCSession and track connected peers
/// - Send/receive `NetworkCommand` messages encoded as JSON

class MultipeerManager: NSObject, ObservableObject {
    // MARK: -Observed by Swiftui
    // Displaynames of currently connected peers
    @Published var connectedPeers: [String] = []
    // master, client or none
    @Published var role: DeviceRole = .none
    // most recent command
    @Published var lastCommand: NetworkCommand?
    
    // MARK: - Multipeer internalls
    private let myPeerID: MCPeerID // nametag/identity on network
    private var session: MCSession! // active session used for send/receive data to peers

    //either searches or advertises
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    // should be renamed to "click-sync"
    private let serviceType = "clicksync"
    
    override init() {
        // device name as displayname (functionality for custom names soon)
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name) // sets displayname to device settings name
        super.init()
        // no encryption on the session currently as it is much simpler
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
    // MARK: - ROLE CONTROL

    // start advertising as master device others can discover
    func startAsMaster() {
        role = .master
        advertiser.startAdvertisingPeer()
        print("Started as Master - advertising")
    }
    // start  browsing as client
    func startAsClient() {
        role = .client
        browser.startBrowsingForPeers()
        print("Started as Client - browsing")
    }
    // stop advertising/browsing and disconnect
    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        role = .none
        connectedPeers = []
    }
    
    // MARK: - MESSAGING

    /// Sencds cmd to all peers
    /// cmds encoded as json
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

// MARK: - MCSessionDelegate (connection state + receiving data)

extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
       // connection state changes handles here
        print("Peer \(peerID.displayName) changed state: \(state.rawValue)")
        
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers.map { $0.displayName }
        }
    }
    
    // didReceive data gets called when someone sends info and data received
    // decode json into "network cmd" and publish it to app
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
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
    
    //not used in clicksync but required
    // MARK: - UNused MCSessionDelegate Requirements
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
// MARK: - Advertiser delegate
extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // someone has found us! this gets called when we are invited to session
        // current setup is auto accept
        print("Received invitation from \(peerID.displayName)")
        invitationHandler(true, session)// when someone sends invite, we auto accept with this line
    }
}

// MARK: - Browser delegate
extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    // called when peer advertising same serviceType discovered
    // auto invite behaviour atm
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10) // if we detect someone we invite them to session
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
    }
}




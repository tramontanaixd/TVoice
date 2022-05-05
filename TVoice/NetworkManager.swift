//
//  NetworkManager.swift
//  TVoice
//
//  Created by pier on 2/13/22.
//

import Foundation
import Telegraph
import Network


class NetworkManager : NSObject{
    
    static let shared = NetworkManager()
    
    public var delegate:ServerWebSocketDelegate?;
    private var server:Server?;
    var port:Int = 8072;
    private var clientsConnected:[WebSocket] = [];
    
    private override init() {
        super.init();
        delegate = nil;
    }
    
    public func setupServer(_newPort:Int,_newDelegate:ServerWebSocketDelegate)
    {
        port = _newPort;
        server = Server();
        do{
            try server?.start(port: port);
        }
        catch let exception{
            print(exception);
        }
        print("server started on port:\(port)");
        delegate = _newDelegate;
        server?.webSocketDelegate = _newDelegate;
    }
    
    public func broadcast(message:String)
    {
        for (socket) in clientsConnected
        {
            socket.send(text: message);
        }
    }
    public func broadcast(dict:[String:String])
    {
        do{
            let rawData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted);
            for (socket) in clientsConnected{
                socket.send(data: rawData);
            }
        }
        catch let e{
            print(e);
        }
    }
    public func addClient(socket:WebSocket)
    {
        clientsConnected.append(socket);
    }
    public func removeClient(socket:WebSocket)
    {
        if clientsConnected.contains(where: { WebSocket in
            
            return WebSocket.localEndpoint == socket.localEndpoint;
        }) {
            var index = 0;
            for (oldSocket) in clientsConnected{
                if(oldSocket.localEndpoint == socket.localEndpoint)
                {
                    
                    break;
                }
                index = index+1;
            }
            clientsConnected.remove(at: index);
            
        
        }
        
        
    }
}


enum Network: String {
    case wifi = "en0"
    case cellular = "pdp_ip0"
    //... case ipv4 = "ipv4"
    //... case ipv6 = "ipv6"
}

func getAddress(for network: Network) -> String? {
    var address: String?

    // Get list of all interfaces on the local machine:
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0 else { return nil }
    guard let firstAddr = ifaddr else { return nil }

    // For each interface ...
    for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let interface = ifptr.pointee

        // Check for IPv4 or IPv6 interface:
        let addrFamily = interface.ifa_addr.pointee.sa_family
        if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

            // Check interface name:
            let name = String(cString: interface.ifa_name)
            if name == network.rawValue {

                // Convert interface address to a human readable string:
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                address = String(cString: hostname)
            }
        }
    }
    freeifaddrs(ifaddr)

    return address
}

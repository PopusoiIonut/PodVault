import Foundation

class EthereumRPCService {
    static let shared = EthereumRPCService()
    
    enum RPCError: Error {
        case invalidURL
        case invalidResponse
        case parsingError
    }
    
    /// Queries the public Ethereum node for the balance of a public address.
    /// Returns the balance in Ether (ETH).
    func fetchEthBalance(for address: String) async throws -> Double {
        guard let url = URL(string: "https://cloudflare-eth.com") else {
            throw RPCError.invalidURL
        }
        
        let parameters: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_getBalance",
            "params": [address, "latest"],
            "id": 1
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw RPCError.invalidResponse
        }
        
        guard let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let resultHex = jsonResult["result"] as? String else {
            throw RPCError.parsingError
        }
        
        // Convert hexadecimal Wei value to Double
        let cleanHex = resultHex.hasPrefix("0x") ? String(resultHex.dropFirst(2)) : resultHex
        let balanceInWei = parseHexToDouble(cleanHex)
        
        // 1 ETH = 10^18 Wei
        let balanceInEth = balanceInWei / 1_000_000_000_000_000_000.0
        return balanceInEth
    }
    
    private func parseHexToDouble(_ hexString: String) -> Double {
        var val: Double = 0.0
        let hex = hexString.lowercased()
        for char in hex {
            let charVal: Double
            if let digit = char.wholeNumberValue {
                charVal = Double(digit)
            } else if char >= "a" && char <= "f" {
                charVal = Double(char.asciiValue! - 87) // a = 97, 97 - 87 = 10
            } else {
                continue
            }
            val = val * 16.0 + charVal
        }
        return val
    }
}

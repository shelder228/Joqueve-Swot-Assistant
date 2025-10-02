import Foundation

class GeminiAPI: ObservableObject {
    private let textAPIKey = "AIzaSyAMRfrt-9Y0Jk6cCQZ9VKOWscVW751-izI"
    private let textEndpoint = "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent"
    private let imageEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-preview-image-generation:generateContent"
    
    func generateSWOTAnalysis(strengths: String, weaknesses: String, opportunities: String, threats: String) async throws -> String {
        let prompt = """
        Create a comprehensive SWOT analysis with the following structure:
        
        INPUT DATA:
        Strengths: \(strengths)
        Weaknesses: \(weaknesses)
        Opportunities: \(opportunities)
        Threats: \(threats)
        
        REQUIRED OUTPUT FORMAT:
        
        ## SWOT Analysis
        
        ### STRENGTHS
        - [List each strength as a bullet point]
        - [Include brief explanation for each]
        
        ### WEAKNESSES
        - [List each weakness as a bullet point]
        - [Include brief explanation for each]
        
        ### OPPORTUNITIES
        - [List each opportunity as a bullet point]
        - [Include brief explanation for each]
        
        ### THREATS
        - [List each threat as a bullet point]
        - [Include brief explanation for each]
        
        ### Strategic Recommendations
        - [Provide 3-5 actionable recommendations]
        - [Focus on leveraging strengths and opportunities]
        - [Address weaknesses and threats]
        
        ### Summary
        - [Brief 2-3 sentence summary of key findings]
        - [Main strategic focus areas]
        
        Please ensure each section is clearly marked with ### and use bullet points for easy reading.
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 2048
            ]
        ]
        
        guard let url = URL(string: "\(textEndpoint)?key=\(textAPIKey)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Volqairo-SWOT-Assistant/1.0.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("Making request to Gemini API with URL: \(url)")
            print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
            print("Request body size: \(request.httpBody?.count ?? 0) bytes")
        } catch {
            print("Failed to encode request body: \(error)")
            throw APIError.encodingError
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("Response status code: \(httpResponse.statusCode)")
            print("Response headers: \(httpResponse.allHeaderFields)")
            print("Response data size: \(data.count) bytes")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString.prefix(500))...")
            }
            
            // Handle different HTTP status codes
            switch httpResponse.statusCode {
            case 200:
                break
            case 400:
                throw APIError.serverError(400)
            case 401:
                throw APIError.invalidAPIKey
            case 403:
                throw APIError.serverError(403)
            case 429:
                throw APIError.rateLimitExceeded
            case 500...599:
                throw APIError.serverError(httpResponse.statusCode)
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            // Check if response is empty
            guard !data.isEmpty else {
                throw APIError.emptyResponse
            }
            
            // Parse JSON response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw APIError.malformedResponse
            }
            
            // Check for API errors in response
            if let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("API Error in response: \(message)")
                if message.contains("quota") {
                    throw APIError.quotaExceeded
                } else if message.contains("rate") {
                    throw APIError.rateLimitExceeded
                } else {
                    throw APIError.malformedResponse
                }
            }
            
            // Extract text content
            guard let candidates = json["candidates"] as? [[String: Any]],
                  !candidates.isEmpty else {
                throw APIError.parsingError
            }
            
            let firstCandidate = candidates[0]
            guard let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  !parts.isEmpty else {
                throw APIError.parsingError
            }
            
            let firstPart = parts[0]
            guard let text = firstPart["text"] as? String,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw APIError.emptyResponse
            }
            
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
            
        } catch let error as APIError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw APIError.noInternetConnection
            case .timedOut:
                throw APIError.timeout
            case .dataNotAllowed:
                throw APIError.noInternetConnection
            default:
                throw APIError.networkError(error)
            }
        } catch {
            throw APIError.networkError(error)
        }
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case encodingError
    case networkError(Error)
    case invalidResponse
    case serverError(Int)
    case parsingError
    case rateLimitExceeded
    case quotaExceeded
    case invalidAPIKey
    case requestTooLarge
    case timeout
    case noInternetConnection
    case emptyResponse
    case malformedResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .encodingError:
            return "Failed to encode request data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            switch code {
            case 400:
                return "Bad request - please check your input"
            case 401:
                return "Unauthorized - API key may be invalid"
            case 403:
                return "Forbidden - access denied"
            case 429:
                return "Rate limit exceeded - please try again later"
            case 500:
                return "Server error - please try again"
            default:
                return "Server error with code: \(code)"
            }
        case .parsingError:
            return "Failed to parse API response"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please wait before making another request."
        case .quotaExceeded:
            return "API quota exceeded. Please check your usage limits."
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .requestTooLarge:
            return "Request too large. Please reduce the input size."
        case .timeout:
            return "Request timed out. Please check your internet connection."
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        case .emptyResponse:
            return "Empty response from server"
        case .malformedResponse:
            return "Malformed response from server"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .rateLimitExceeded, .quotaExceeded:
            return "Please wait a few minutes before trying again."
        case .noInternetConnection, .timeout:
            return "Check your internet connection and try again."
        case .invalidAPIKey:
            return "Please contact support to verify your API configuration."
        case .requestTooLarge:
            return "Try reducing the amount of text in your input fields."
        default:
            return "Please try again. If the problem persists, contact support."
        }
    }
}

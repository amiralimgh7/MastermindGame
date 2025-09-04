import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - API Models
struct CreateGameResponse: Codable {
    let game_id: String
}

struct GuessRequest: Codable {
    let game_id: String
    let guess: String
}

struct GuessResponse: Codable {
    let black: Int
    let white: Int
}

struct ErrorResponse: Codable {
    let error: String
}

// MARK: - Mastermind API
actor MastermindAPI {
    let baseURL = "https://mastermind.darkube.app"

    func createGame() async throws -> String {
        guard let url = URL(string: "\(baseURL)/game") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CreateGameResponse.self, from: data)
        return response.game_id
    }

    func makeGuess(gameID: String, guess: String) async throws -> GuessResponse {
        guard let url = URL(string: "\(baseURL)/guess") else {
            throw URLError(.badURL)
        }

        let body = GuessRequest(game_id: gameID, guess: guess)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)

        if let guessResp = try? JSONDecoder().decode(GuessResponse.self, from: data) {
            return guessResp
        }
        if let errResp = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            throw NSError(domain: "MastermindAPI", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: errResp.error])
        }
        throw NSError(domain: "MastermindAPI", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Unexpected response"])
    }

    func deleteGame(gameID: String) async {
        guard let url = URL(string: "\(baseURL)/game/\(gameID)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
                print("🗑️ Game deleted from server.")
            } else {
                print("⚠️ Could not delete game (maybe already deleted).")
            }
        } catch {
            print("⚠️ Error deleting game: \(error.localizedDescription)")
        }
    }
}

// MARK: - Run Game
@main
struct MastermindApp {
    static func main() async {
        let api = MastermindAPI()

        do {
            print("🎮 Welcome to Mastermind!")
            print("Digits are between 1–6, length = 4. Type 'exit' anytime to quit.\n")

            let gameID = try await api.createGame()
            print("✅ Game started with ID: \(gameID)\n")

            while true {
                print("Enter your guess: ", terminator: "")
                guard let input = readLine(), !input.isEmpty else { continue }
                if input.lowercased() == "exit" {
                    await api.deleteGame(gameID: gameID)
                    print("👋 Bye!")
                    break
                }

                do {
                    let result = try await api.makeGuess(gameID: gameID, guess: input)
                    print("Result → Black: \(result.black), White: \(result.white)")
                    if result.black == 4 {
                        print("🎉 You win!")
                        await api.deleteGame(gameID: gameID)
                        break
                    }
                } catch {
                    print("❌ Error: \(error.localizedDescription)")
                }
            }
        } catch {
            print("❌ Failed to start game: \(error.localizedDescription)")
        }
    }
}

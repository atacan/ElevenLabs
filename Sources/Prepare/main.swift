import Foundation

func downloadOpenAPI(toFolder folderUrl: URL) async throws {
    let openapiRemoteUrl = URL(string: "https://api.elevenlabs.io/openapi.json")!
    let content = try String(contentsOf: openapiRemoteUrl)
    // Save yaml files to folderUrl
    try content.write(to: folderUrl.appendingPathComponent("original.json"), atomically: true, encoding: .utf8)
    try content.write(to: folderUrl.appendingPathComponent("openapi.json"), atomically: true, encoding: .utf8)
    print("Downloaded OpenAPI files to \(folderUrl.path)")
}

let currentFile = URL(fileURLWithPath: #filePath)
let projectRoot =
    currentFile
    .deletingLastPathComponent()  // Remove 'main.swift'
    .deletingLastPathComponent()  // Remove 'Prepare'
    .deletingLastPathComponent()  // Remove 'Sources'

try await downloadOpenAPI(toFolder: projectRoot.appendingPathComponent("assets"))
// Generate code
try runCommand("make generate-openapi", workingDirectory: projectRoot.path)

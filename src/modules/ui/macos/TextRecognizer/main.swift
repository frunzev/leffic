import AppKit
import Vision

let expectedArgumentCount = 3
let standardOutputTarget = "stdout"
let usageExitCode: Int32 = 2
let failureExitCode: Int32 = 1

func fail(_ message: String, exitCode: Int32) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(exitCode)
}

func loadedImage(at path: String) -> CGImage {
    guard let image = NSImage(contentsOfFile: path) else {
        fail("Could not read the image at \(path)", exitCode: failureExitCode)
    }

    guard let cgImage = image.cgImage(
        forProposedRect: nil,
        context: nil,
        hints: nil
    ) else {
        fail("Could not decode the image at \(path)", exitCode: failureExitCode)
    }

    return cgImage
}

func recognizedLines(in image: CGImage) -> [String] {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    let handler = VNImageRequestHandler(cgImage: image)

    do {
        try handler.perform([request])
    } catch {
        fail("Text recognition failed: \(error)", exitCode: failureExitCode)
    }

    let observations = request.results ?? []
    var lines: [String] = []

    for observation in observations {
        if let candidate = observation.topCandidates(1).first {
            lines.append(candidate.string)
        }
    }

    return lines
}

let arguments = CommandLine.arguments

if arguments.count != expectedArgumentCount
    || arguments[2] != standardOutputTarget {
    fail("Usage: leffic-text-recognizer <image> stdout", exitCode: usageExitCode)
}

let image = loadedImage(at: arguments[1])
let lines = recognizedLines(in: image)

print(lines.joined(separator: "\n"))

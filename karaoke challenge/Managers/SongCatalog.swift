import Foundation

enum SongCatalogError: LocalizedError {
    case manifestMissing
    case invalidData

    var errorDescription: String? {
        switch self {
        case .manifestMissing:
            return "Could not find songs_manifest.json in the app bundle."
        case .invalidData:
            return "songs_manifest.json is not valid."
        }
    }
}

final class SongCatalog {
    func loadSongs() throws -> [Song] {
        guard let url = Bundle.main.url(forResource: "songs_manifest", withExtension: "json") else {
            throw SongCatalogError.manifestMissing
        }

        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode([Song].self, from: data)
        } catch {
            throw SongCatalogError.invalidData
        }
    }
}

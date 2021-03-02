/*
See LICENSE folder for this sample’s licensing information.
*/

import Foundation
import Combine
import ComposableArchitecture

final class ScrumData {

    enum Error: Swift.Error, Equatable {
        case couldntFindDocumentsDirectory
        case failedToDecodeScrumData
        case couldntSaveScrums
    }

    let global: DispatchQueue
    let fileManager: FileManager

    private var documentsFolder: URL {
        do {
            return try fileManager.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: false)
        } catch {
            fatalError("Can't find documents directory.")
        }
    }
    private var fileURL: URL {
        return documentsFolder.appendingPathComponent("scrums.data")
    }

    init(global: DispatchQueue, fileManager: FileManager) {
        self.global = global
        self.fileManager = fileManager
    }

    func load() -> Effect<[DailyScrum], Error> {
        Effect.run { [weak self] subscriber in
            self?.global.async { [weak self] in
                guard let outfile = self?.fileURL else { return }
                guard let data = try? Data(contentsOf: outfile) else {
                    #if DEBUG
                        subscriber.send(DailyScrum.data)
                    #endif
                    return
                }
                guard let dailyScrums = try? JSONDecoder().decode([DailyScrum].self, from: data) else {
                    subscriber.send(completion: .failure(.failedToDecodeScrumData))
                    return
                }

                subscriber.send(dailyScrums)
            }

            return AnyCancellable {}
        }
    }
    func save(scrums: [DailyScrum]) -> Effect<Always, Error> {
        Effect.run { [weak self] subscriber in
            self?.global.async { [weak self] in
                guard let data = try? JSONEncoder().encode(scrums) else { fatalError("Error encoding data") }
                do {
                    guard let file = self?.fileURL else { return }
                    try data.write(to: file)
                    subscriber.send(.always)
                } catch {
                    subscriber.send(completion: .failure(.couldntSaveScrums))
                }
            }

            return AnyCancellable {}
        }
    }
}

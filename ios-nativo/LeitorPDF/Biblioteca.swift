import Foundation

/// Guarda os PDFs importados na pasta Documentos do app e lembra onde a leitura parou.
@MainActor
final class Biblioteca: ObservableObject {
    @Published private(set) var arquivos: [URL] = []

    private let pasta = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    init() { recarregar() }

    func recarregar() {
        let itens = (try? FileManager.default.contentsOfDirectory(
            at: pasta, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        arquivos = itens
            .filter { $0.pathExtension.lowercased() == "pdf" }
            .sorted { $0.lastPathComponent.localizedCompare($1.lastPathComponent) == .orderedAscending }
    }

    func importar(_ origem: URL) throws {
        let acessou = origem.startAccessingSecurityScopedResource()
        defer { if acessou { origem.stopAccessingSecurityScopedResource() } }

        var destino = pasta.appendingPathComponent(origem.lastPathComponent)
        var n = 2
        while FileManager.default.fileExists(atPath: destino.path) {
            let nome = origem.deletingPathExtension().lastPathComponent
            destino = pasta.appendingPathComponent("\(nome) (\(n)).pdf")
            n += 1
        }
        try FileManager.default.copyItem(at: origem, to: destino)
        recarregar()
    }

    func apagar(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
        UserDefaults.standard.removeObject(forKey: Self.chavePosicao(url))
        recarregar()
    }

    static func chavePosicao(_ url: URL) -> String { "posicao.\(url.lastPathComponent)" }

    static func posicaoSalva(_ url: URL) -> Int {
        UserDefaults.standard.integer(forKey: chavePosicao(url))
    }

    static func salvarPosicao(_ indice: Int, de url: URL) {
        UserDefaults.standard.set(indice, forKey: chavePosicao(url))
    }
}

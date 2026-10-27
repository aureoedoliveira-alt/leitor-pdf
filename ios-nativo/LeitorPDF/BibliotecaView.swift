import SwiftUI
import UniformTypeIdentifiers

struct BibliotecaView: View {
    @StateObject private var biblioteca = Biblioteca()
    @State private var importando = false
    @State private var erro: String?

    var body: some View {
        NavigationStack {
            Group {
                if biblioteca.arquivos.isEmpty {
                    ContentUnavailableView(
                        "Nenhum PDF ainda",
                        systemImage: "doc.text",
                        description: Text("Toque em + para importar um PDF do app Arquivos.")
                    )
                } else {
                    List {
                        ForEach(biblioteca.arquivos, id: \.self) { url in
                            NavigationLink(value: url) {
                                Label(url.deletingPathExtension().lastPathComponent,
                                      systemImage: "doc.richtext")
                            }
                        }
                        .onDelete { indices in
                            indices.map { biblioteca.arquivos[$0] }.forEach(biblioteca.apagar)
                        }
                    }
                }
            }
            .navigationTitle("Biblioteca")
            .navigationDestination(for: URL.self) { LeitorView(url: $0) }
            .toolbar {
                Button { importando = true } label: { Image(systemName: "plus") }
            }
            .fileImporter(isPresented: $importando,
                          allowedContentTypes: [.pdf],
                          allowsMultipleSelection: true) { resultado in
                do {
                    for url in try resultado.get() { try biblioteca.importar(url) }
                } catch {
                    self.erro = error.localizedDescription
                }
            }
            .alert("Não foi possível importar", isPresented: .constant(erro != nil)) {
                Button("OK") { erro = nil }
            } message: {
                Text(erro ?? "")
            }
        }
    }
}

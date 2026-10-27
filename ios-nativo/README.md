# Leitor PDF — app iOS que lê PDFs em voz alta

App próprio, no estilo do Speechify, para importar PDFs e ouvi-los com voz natural no iPhone.

## O plano

### Arquitetura

- **SwiftUI** para as telas (biblioteca e leitor).
- **PDFKit** (da Apple) para mostrar o PDF e extrair o texto de cada página.
- **NaturalLanguage** para quebrar o texto em frases. O app lê frase por frase e destaca em amarelo a frase que está sendo lida.
- **AVSpeechSynthesizer** para a voz. Usa as vozes que já vêm no iPhone, sem internet e sem custo.
- Áudio em segundo plano: a leitura continua com a tela bloqueada, e dá para pausar e pular frases pela tela bloqueada ou pelos fones.

### As vozes: de graça primeiro, nuvem depois (opcional)

**Fase 1 (este MVP): vozes do próprio iPhone, custo zero.**
O iOS tem vozes "Premium" e "Melhoradas" em português (por exemplo Luciana e Felipe) que soam bem menos robóticas que a voz padrão. Elas precisam ser baixadas uma vez no aparelho:

> Ajustes › Acessibilidade › Leitura e Fala (em iOS antigos: Conteúdo Falado) › Vozes › Português (Brasil) › escolha a voz e baixe a versão **Premium** ou **Melhorada**.

O app escolhe sozinho a melhor voz instalada, e você pode trocar no ícone de voz no canto superior.

**Fase 2 (se quiser algo mais próximo do Speechify): TTS na nuvem.**
O app envia o texto para um serviço de voz neural e toca o áudio. Preços aproximados por 1 milhão de caracteres (um livro de 300 páginas tem cerca de 600 mil caracteres). Confira os valores atuais antes de contratar:

| Serviço | Preço aprox. / 1M caracteres | Livro de 300 págs. | Observação |
|---|---|---|---|
| Google Cloud TTS (Neural2/WaveNet) | ~US$ 16 | ~US$ 10 | tem cota gratuita mensal |
| Microsoft Azure (Neural) | ~US$ 15 | ~US$ 9 | 500 mil caracteres grátis por mês |
| Amazon Polly (Neural) | ~US$ 16 | ~US$ 10 | cota grátis no 1º ano |
| OpenAI TTS | ~US$ 15 | ~US$ 9 | vozes muito naturais |
| ElevenLabs | bem mais caro | — | melhor qualidade, assinatura mensal |

Para uso pessoal, a cota gratuita do Azure ou do Google costuma cobrir alguns livros por mês. O custo real fica baixo porque o áudio pode ser guardado no aparelho depois de gerado, e você só paga uma vez por livro.

### O que você precisa

1. **Um Mac com Xcode** (grátis na App Store). O iOS só compila no macOS. Se não tiver Mac, as saídas são alugar um Mac na nuvem (MacinCloud e similares, alguns dólares por mês) ou usar um Mac emprestado só para instalar.
2. **Conta Apple**:
   - Com o Apple ID comum (grátis) já dá para instalar no seu iPhone pelo cabo, mas o app expira a cada 7 dias e precisa ser reinstalado pelo Xcode.
   - Com o **Apple Developer Program (US$ 99 por ano)** o app fica instalado por 1 ano, dá para usar o TestFlight e, se quiser, publicar na App Store.
3. **iPhone com iOS 17 ou mais novo.**
4. **Um repositório no GitHub** (opcional, mas recomendado) para guardar o código e as próximas versões.

### Próximos passos depois do MVP

- OCR para PDFs escaneados (framework Vision da Apple, também gratuito).
- Tocar numa frase do PDF para começar a ler dali.
- Pular cabeçalhos, rodapés e números de página.
- Vozes na nuvem (fase 2), com cache do áudio no aparelho.
- Suporte a EPUB e a textos colados.

## O que o MVP já faz

- Importa PDFs do app Arquivos (iCloud Drive, Downloads, etc.).
- Mostra o PDF e lê em voz alta, destacando a frase atual e virando a página sozinho.
- Play/pausa, voltar e avançar frase, velocidade de 0,6x a 1,3x.
- Escolha de voz, com as Premium no topo da lista.
- Lembra onde parou em cada PDF.
- Continua lendo com a tela bloqueada, com controles na tela bloqueada e nos fones.
- Botão "Ler a partir da pág. X" quando você rola o PDF para outra página.

## Como rodar no seu iPhone

### Opção A: com XcodeGen (mais rápido)

No Terminal do Mac, dentro desta pasta:

```bash
brew install xcodegen   # só na primeira vez (precisa do Homebrew: https://brew.sh)
xcodegen generate
open LeitorPDF.xcodeproj
```

### Opção B: sem instalar nada além do Xcode

1. Xcode › File › New › Project › iOS › App. Nome: `LeitorPDF`, Interface: SwiftUI, Language: Swift.
2. Apague o `ContentView.swift` e o arquivo `...App.swift` que o Xcode criou.
3. Arraste os arquivos da pasta `LeitorPDF/` deste projeto para dentro do projeto no Xcode (marque "Copy items if needed").
4. Clique no projeto › target LeitorPDF › **Signing & Capabilities** › **+ Capability** › **Background Modes** › marque **Audio, AirPlay, and Picture in Picture**.
5. Em **General**, coloque o *Minimum Deployments* em iOS 17.0.

### Instalar

1. Conecte o iPhone no Mac pelo cabo e escolha o iPhone no topo do Xcode.
2. Em **Signing & Capabilities**, marque *Automatically manage signing* e escolha seu Apple ID em *Team*. Troque `com.seunome` por algo seu, sem acento (ex.: `com.aureo.leitorpdf`).
3. Clique em ▶︎ (Run).
4. Na primeira vez, no iPhone: Ajustes › Geral › VPN e Gerenciamento de Dispositivos › confie no seu certificado de desenvolvedor. Em iOS 16 ou mais novo, ative também o **Modo de Desenvolvedor** em Ajustes › Privacidade e Segurança.

## Arquivos

| Arquivo | Para que serve |
|---|---|
| `LeitorPDFApp.swift` | Ponto de entrada; configura o áudio para tocar em segundo plano |
| `Biblioteca.swift` | Guarda os PDFs importados e a posição de leitura de cada um |
| `BibliotecaView.swift` | Tela inicial com a lista de PDFs e o botão de importar |
| `LeitorView.swift` | Tela de leitura com o PDF, os controles e o menu de vozes |
| `PDFKitView.swift` | Mostra o PDF e destaca a frase que está sendo lida |
| `LeitorDeVoz.swift` | O motor de leitura: extrai frases, fala, avança e controla a tela bloqueada |

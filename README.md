# Leitor PDF em Voz

Leitor de PDF em voz alta que roda no navegador do iPhone, no estilo do Speechify.

**Abrir:** https://aureoedoliveira-alt.github.io/leitor-pdf/

No Safari do iPhone, toque em Compartilhar › **Adicionar à Tela de Início** para ele virar um ícone como um app.

## O que faz

- Importa PDFs do iPhone e guarda tudo só no aparelho.
- Lê em voz alta frase por frase, destacando a frase atual. Toque em qualquer frase para ler a partir dela.
- Velocidade de 0,6x a 2x e lembra onde você parou em cada PDF.
- Duas fontes de voz:
  - **Vozes do aparelho** (grátis, sem internet). O Safari só libera a voz principal de cada idioma, como Luciana e Joana.
  - **Vozes neurais da Microsoft** (Azure, pela internet), bem mais naturais. O plano grátis F0 dá 500 mil caracteres por mês. Com elas a leitura continua com a tela bloqueada.

## Como ligar as vozes da Microsoft

1. Crie uma conta em https://azure.microsoft.com/free (pede cartão para confirmar identidade, mas o plano F0 não cobra).
2. No portal (https://portal.azure.com), crie um recurso **Speech service** (Serviço de Fala). Em *Pricing tier* escolha **Free F0**. Em *Region*, **Brazil South**.
3. Abra o recurso › **Keys and Endpoint**. Copie a **KEY 1** e a **Location/Region**.
4. No leitor, toque em **Vozes**, cole a chave e a região e toque em **Salvar e testar**.

A chave fica guardada só no navegador do seu aparelho. Ela não vai para este repositório.

## Pastas

- `index.html`: o leitor inteiro (uma página só).
- `ios-nativo/`: versão em app nativo (SwiftUI), para o dia em que houver um Mac. Veja `ios-nativo/README.md`.

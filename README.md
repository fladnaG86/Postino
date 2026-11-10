# Postino

App per la barra dei menu di macOS che riassume le mail di Microsoft Outlook e prepara bozze di
risposta usando un LLM locale (llama.cpp, Ollama, LM Studio) o qualsiasi endpoint compatibile con
l'API OpenAI.

Postino non entra dentro Outlook: gli parla da fuori tramite AppleScript. Legge la mail selezionata,
la manda al modello e, per le risposte, apre una bozza in Outlook con il testo già scritto sopra la
mail citata. **Non invia mai nulla da sola**: l'invio resta a te.

## Uso

1. Seleziona una mail in Outlook.
2. `⌃⌥S` per il riassunto, `⌃⌥R` per la risposta (oppure dal menu dell'icona a busta).
3. Per la risposta puoi scrivere indicazioni facoltative ("accetta e proponi giovedì"), correggere
   il testo generato e poi premere **Apri bozza in Outlook**.

Al primo uso macOS chiede il permesso di controllare Microsoft Outlook: va concesso.

## Requisiti

- macOS 14 o successivo, toolchain Swift (Xcode o Command Line Tools)
- Microsoft Outlook per Mac con supporto AppleScript attivo
- Un server LLM compatibile OpenAI, ad esempio llama.cpp su `http://127.0.0.1:8001/v1`

## Compilazione

```bash
swift test              # test unitari
./build.sh              # crea dist/Postino.app (firma ad-hoc)
./build.sh --install    # copia anche in /Applications
```

## Impostazioni

Dal menu → **Impostazioni…**: endpoint, modello, chiave API (salvata nel Portachiavi), rispondi a
tutti, preferenze personali su tono e firma, limite di caratteri della mail inviati al modello.

Con un endpoint locale il testo delle mail non lascia il Mac. Con un endpoint remoto sì.

## Limiti

- Funziona finché Outlook espone AppleScript: Microsoft lo ha ridotto nel "nuovo Outlook" e potrebbe
  toglierlo.
- La firma è ad-hoc: dopo una ricompilazione macOS può richiedere di nuovo il permesso Automazione.
- Non si avvia al login: aggiungila a mano in Impostazioni di Sistema → Generali → Elementi login.

Progetto indipendente, non affiliato a Microsoft. Outlook è un marchio di Microsoft Corporation.

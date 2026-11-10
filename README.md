# Postino

**English** · [Italiano](#italiano)

A macOS menu bar app that summarizes your Microsoft Outlook mail and writes reply drafts for you,
using an AI model running on your own Mac (llama.cpp, Ollama, LM Studio) or any OpenAI-compatible
API.

## How it works, in plain words

Think of Postino as an assistant sitting next to Outlook, not inside it.

1. **You pick a mail** in Outlook, as you always do.
2. **You press a shortcut.** Postino asks Outlook: "which mail is selected? Give me sender, subject
   and text." Outlook answers, the same way it answers any AppleScript automation.
3. **Postino hands the text to the AI model** and asks for a summary or a reply.
4. **The answer appears in a small window** next to Outlook, written word by word as the model
   produces it.
5. **For a reply**, you can fix the text, then press one button: Postino asks Outlook to create a
   reply draft and puts the text in it, above the quoted mail.
6. **You read it and press Send yourself.** Postino never sends anything.

```
Outlook  ⇄  Postino  ⇄  AI model (on your Mac, or a web API)
```

If the model runs on your Mac, your mail never leaves the computer. If you point Postino to a
remote API, the text of the mail is sent to that service.

Nothing is installed into Outlook and Outlook itself is not modified.

## Usage

1. Select a mail in Outlook.
2. `⌃⌥S` for a summary, `⌃⌥R` for a reply (or use the envelope icon in the menu bar).
3. For a reply you can type optional directions ("accept and propose Thursday"), edit the generated
   text, then press **Apri bozza in Outlook** (open draft in Outlook).

On first use macOS asks permission to let Postino control Microsoft Outlook: allow it.

The interface is currently in Italian. Summaries are written in Italian; replies are written in the
language of the mail you received.

## Quick install

Download `Postino.zip` from the [Releases](https://github.com/fladnaG86/Postino/releases) page,
unzip it and move `Postino.app` to `/Applications`. The app is built for Apple Silicon and is ad-hoc
signed (not notarized), so Gatekeeper blocks it on first launch. To unblock it:

```bash
xattr -dr com.apple.quarantine /Applications/Postino.app
```

## Requirements

- macOS 14 or later
- Microsoft Outlook for Mac with AppleScript support
- An OpenAI-compatible model server, for example llama.cpp at `http://127.0.0.1:8001/v1`
- To build from source: a Swift toolchain (Xcode or Command Line Tools)

## Build

```bash
swift test              # unit tests
./build.sh              # creates dist/Postino.app (ad-hoc signed)
./build.sh --install    # also copies it to /Applications
```

## Settings

Menu → **Impostazioni…**: endpoint, model name, API key (stored in the Keychain), reply-all,
personal preferences for tone and signature, maximum number of mail characters sent to the model.

## Limits

- It works as long as Outlook exposes AppleScript. Microsoft has reduced it in the "new Outlook" and
  may remove it.
- The signature is ad-hoc: after a rebuild macOS may ask for the Automation permission again.
- It does not start at login: add it yourself in System Settings → General → Login Items.

## License

MIT, see [LICENSE](LICENSE).

Independent project, not affiliated with Microsoft. Outlook is a trademark of Microsoft Corporation.

---

<a name="italiano"></a>

# Postino (Italiano)

App per la barra dei menu di macOS che riassume le mail di Microsoft Outlook e scrive per te le
bozze di risposta, usando un modello di intelligenza artificiale che gira sul tuo Mac (llama.cpp,
Ollama, LM Studio) oppure qualsiasi API compatibile con OpenAI.

## Come funziona, in parole semplici

Pensa a Postino come a un assistente seduto accanto a Outlook, non dentro.

1. **Scegli una mail** in Outlook, come fai sempre.
2. **Premi una scorciatoia.** Postino chiede a Outlook: "quale mail è selezionata? Dammi mittente,
   oggetto e testo." Outlook risponde, come fa con qualsiasi automazione AppleScript.
3. **Postino passa il testo al modello** e gli chiede un riassunto o una risposta.
4. **La risposta compare in una finestrella** accanto a Outlook, scritta parola per parola mentre il
   modello la produce.
5. **Per una risposta** puoi correggere il testo e poi premere un pulsante: Postino chiede a Outlook
   di creare una bozza di risposta e ci mette dentro il testo, sopra la mail citata.
6. **La leggi e premi Invia tu.** Postino non invia mai nulla.

```
Outlook  ⇄  Postino  ⇄  Modello IA (sul tuo Mac, oppure un'API web)
```

Se il modello gira sul tuo Mac, le mail non escono dal computer. Se indichi a Postino un'API remota,
il testo della mail viene inviato a quel servizio.

Non viene installato nulla dentro Outlook e Outlook non viene modificato.

## Uso

1. Seleziona una mail in Outlook.
2. `⌃⌥S` per il riassunto, `⌃⌥R` per la risposta (oppure dal menu dell'icona a busta).
3. Per la risposta puoi scrivere indicazioni facoltative ("accetta e proponi giovedì"), correggere
   il testo generato e poi premere **Apri bozza in Outlook**.

Al primo uso macOS chiede il permesso di controllare Microsoft Outlook: va concesso.

I riassunti sono in italiano; le risposte nella lingua della mail ricevuta.

## Installazione rapida

Scarica `Postino.zip` dalla pagina [Releases](https://github.com/fladnaG86/Postino/releases),
decomprimi e sposta `Postino.app` in `/Applications`. L'app è per Apple Silicon e ha firma ad-hoc
(non notarizzata), quindi al primo avvio Gatekeeper la blocca. Per sbloccarla:

```bash
xattr -dr com.apple.quarantine /Applications/Postino.app
```

## Requisiti

- macOS 14 o successivo
- Microsoft Outlook per Mac con supporto AppleScript
- Un server di modelli compatibile OpenAI, ad esempio llama.cpp su `http://127.0.0.1:8001/v1`
- Per compilare dai sorgenti: toolchain Swift (Xcode o Command Line Tools)

## Compilazione

```bash
swift test              # test unitari
./build.sh              # crea dist/Postino.app (firma ad-hoc)
./build.sh --install    # copia anche in /Applications
```

## Impostazioni

Dal menu → **Impostazioni…**: endpoint, modello, chiave API (salvata nel Portachiavi), rispondi a
tutti, preferenze personali su tono e firma, limite di caratteri della mail inviati al modello.

## Limiti

- Funziona finché Outlook espone AppleScript: Microsoft lo ha ridotto nel "nuovo Outlook" e potrebbe
  toglierlo.
- La firma è ad-hoc: dopo una ricompilazione macOS può richiedere di nuovo il permesso Automazione.
- Non si avvia al login: aggiungila a mano in Impostazioni di Sistema → Generali → Elementi login.

## Licenza

MIT, vedi [LICENSE](LICENSE).

Progetto indipendente, non affiliato a Microsoft. Outlook è un marchio di Microsoft Corporation.

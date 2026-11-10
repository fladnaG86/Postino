import XCTest
@testable import PostinoCore

final class TextToolsTests: XCTestCase {
    func testAppleScriptLiteralEscapesQuotesAndBackslashes() {
        XCTAssertEqual(TextTools.appleScriptLiteral(#"a "b" \c"#), #""a \"b\" \\c""#)
    }

    func testHtmlFromPlainEscapesAndBreaksLines() {
        XCTAssertEqual(TextTools.htmlFromPlain("a<b>&\r\nc"), "<div>a&lt;b&gt;&amp;<br>c</div><br>")
    }

    func testInsertAfterBodyTag() {
        let html = "<html><BODY class=\"x\"><p>old</p></body></html>"
        XCTAssertEqual(TextTools.insertIntoBody(html: html, fragment: "NEW"),
                       "<html><BODY class=\"x\">NEW<p>old</p></body></html>")
    }

    func testInsertPrependsWithoutBody() {
        XCTAssertEqual(TextTools.insertIntoBody(html: "<p>old</p>", fragment: "NEW"), "NEW<p>old</p>")
    }

    func testTruncate() {
        XCTAssertEqual(TextTools.truncate("abc", limit: 10), "abc")
        XCTAssertTrue(TextTools.truncate("abcdef", limit: 3).hasPrefix("abc\n["))
    }

    func testStripThinking() {
        XCTAssertEqual(TextTools.stripThinking("<think>x</think>\nciao"), "ciao")
        XCTAssertEqual(TextTools.stripThinking("ciao <think>in corso"), "ciao")
    }

    func testDeltaFromSSE() {
        XCTAssertEqual(TextTools.deltaFromSSE(line: #"data: {"choices":[{"delta":{"content":"ci"}}]}"#), "ci")
        XCTAssertNil(TextTools.deltaFromSSE(line: "data: [DONE]"))
        XCTAssertNil(TextTools.deltaFromSSE(line: #"data: {"choices":[{"delta":{"role":"assistant"}}]}"#))
        XCTAssertNil(TextTools.deltaFromSSE(line: ": keepalive"))
    }

    func testChatCompletionsURL() {
        XCTAssertEqual(TextTools.chatCompletionsURL(base: "http://127.0.0.1:8001/v1/")?.absoluteString,
                       "http://127.0.0.1:8001/v1/chat/completions")
        XCTAssertEqual(TextTools.chatCompletionsURL(base: "https://x.y/v1/chat/completions")?.absoluteString,
                       "https://x.y/v1/chat/completions")
    }

    func testReplyPromptCarriesInstructionsAndTruncates() {
        let mail = Mail(id: 1, subject: "S", senderName: "N", senderAddress: "a@b.c",
                        body: String(repeating: "x", count: 50))
        let msgs = Prompts.reply(mail: mail, instructions: " accetta ", limit: 10, personal: "firma M.", lang: .it)
        XCTAssertEqual(msgs.count, 2)
        XCTAssertTrue(msgs[0].content.contains("firma M."))
        XCTAssertTrue(msgs[1].content.contains("Indicazioni per la risposta: accetta"))
        XCTAssertTrue(msgs[1].content.contains("troncato"))
    }

    func testPromptsInEnglish() {
        let mail = Mail(id: 1, subject: "S", senderName: "N", senderAddress: "a@b.c",
                        body: String(repeating: "x", count: 50))
        let reply = Prompts.reply(mail: mail, instructions: "accept", limit: 10, personal: "sign M.", lang: .en)
        XCTAssertTrue(reply[0].content.contains("User preferences: sign M."))
        XCTAssertTrue(reply[1].content.contains("Directions for the reply: accept"))
        XCTAssertTrue(reply[1].content.contains("From: N <a@b.c>"))
        XCTAssertTrue(reply[1].content.contains("text truncated"))
        let summary = Prompts.summary(mail: mail, limit: 100, personal: "", lang: .en)
        XCTAssertTrue(summary[0].content.contains("Answer in English"))
        XCTAssertFalse(summary[0].content.contains("italiano"))
        XCTAssertTrue(Prompts.summary(mail: mail, limit: 100, personal: "", lang: .it)[0].content.contains("italiano"))
    }

    func testLanguageFromSystemPreference() {
        XCTAssertEqual(Lang.from(preferred: ["it-IT", "en-US"]), .it)
        XCTAssertEqual(Lang.from(preferred: ["de-DE", "it-IT"]), .en)
        XCTAssertEqual(Lang.from(preferred: []), .en)
        XCTAssertEqual(tr("a", "b", lang: .en), "a")
        XCTAssertEqual(tr("a", "b", lang: .it), "b")
    }
}

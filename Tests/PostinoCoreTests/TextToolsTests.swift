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
        let msgs = Prompts.reply(mail: mail, instructions: " accetta ", limit: 10, personal: "firma M.")
        XCTAssertEqual(msgs.count, 2)
        XCTAssertTrue(msgs[0].content.contains("firma M."))
        XCTAssertTrue(msgs[1].content.contains("Indicazioni per la risposta: accetta"))
        XCTAssertTrue(msgs[1].content.contains("troncato"))
    }
}

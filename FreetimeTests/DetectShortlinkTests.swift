//
//  DetectShortlinkTests.swift
//  FreetimeTests
//
//  Created by B_Litwin on 7/22/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//
import XCTest
@testable import Freetime
import StyledTextKit

class DetectShortlinkTests: XCTestCase {
    // Test the String method detectAndHandleCustomRegex()

    func setupBuilder(with text: String) -> StyledTextString {
        let builder = StyledTextBuilder(text: "")
        text.detectAndHandleCustomRegex(
            owner: "rnystrom",
            repo: "GitHawk",
            builder: builder
        )
        return builder.build()
    }

    func checkForIssueLink(_ styledTexts: [StyledText]) -> [(linkText: String, issueNumber: Int)] {
        // scanning for a styledText unit that has been formatted with blue font and
        // contains an Issue MarkdownAttribute
        var links = [(linkText: String, issueNumber: Int)]()
        for styledText in styledTexts {
            let style = styledText.style
            guard style.attributes[.foregroundColor] != nil,
                style.attributes[MarkdownAttribute.issue] != nil else { continue }
            let correctTextColor = style.attributes[.foregroundColor] as! UIColor == Styles.Colors.Blue.medium.color
            if correctTextColor {
                if case let .text(text) = styledText.storage {
                    let issueModel = style.attributes[MarkdownAttribute.issue] as! IssueDetailsModel
                    let issueNumber = issueModel.number
                    links.append((text, issueNumber))
                }
            }
        }
        return links
    }

    func test_positiveMatches() {
        // test 4 things:
        // 1) for positive text match
        // 2) that the correct text is blue/linked (eg the parentheses aren't blue also)
        // 3) that the MarkdownIssue is linked correctly with an issue number
        // 4) that the string displayed after reformatting == the original string

        var testString = "#1234"
        var builder: StyledTextString = setupBuilder(with: testString)
        var containsLink = checkForIssueLink(builder.styledTexts)[0]
        XCTAssertEqual(containsLink.linkText, "#1234")
        XCTAssertEqual(containsLink.issueNumber, 1234)
        XCTAssertEqual(builder.allText, testString)

        testString = "with a space preceding #1235"
        builder = setupBuilder(with: testString)
        containsLink = checkForIssueLink(builder.styledTexts)[0]
        XCTAssertEqual(containsLink.linkText, "#1235")
        XCTAssertEqual(containsLink.issueNumber, 1235)
        XCTAssertEqual(builder.allText, testString)

        testString = "with a newline preceding \n#345"
        builder = setupBuilder(with: testString)
        containsLink = checkForIssueLink(builder.styledTexts)[0]
        XCTAssertEqual(containsLink.linkText, "#345")
        XCTAssertEqual(containsLink.issueNumber, 345)
        XCTAssertEqual(builder.allText, testString)

        testString =
        """
        #345
        newLine
        """

        builder = setupBuilder(with: testString)
        containsLink = checkForIssueLink(builder.styledTexts)[0]
        XCTAssertEqual(containsLink.linkText, "#345")
        XCTAssertEqual(containsLink.issueNumber, 345)
        XCTAssertEqual(builder.allText, testString)

        testString = "embedded in parentheses (#1900)"
        builder = setupBuilder(with: testString)
        containsLink = checkForIssueLink(builder.styledTexts)[0]
        XCTAssertEqual(containsLink.linkText, "#1900")
        XCTAssertEqual(containsLink.issueNumber, 1900)
        XCTAssertEqual(builder.allText, testString)

        testString = "with owner and repo preceding rnystrom/githawk#4321"
        builder = setupBuilder(with: testString)
        containsLink = checkForIssueLink(builder.styledTexts)[0]
        XCTAssertEqual(containsLink.linkText, "rnystrom/githawk#4321")
        XCTAssertEqual(containsLink.issueNumber, 4321)
        XCTAssertEqual(builder.allText, testString)

        testString = "Fixes (#1"
        builder = setupBuilder(with: testString)
        containsLink = checkForIssueLink(builder.styledTexts)[0]
        XCTAssertEqual(containsLink.linkText, "#1")
        XCTAssertEqual(containsLink.issueNumber, 1)
        XCTAssertEqual(builder.allText, testString)

        testString = "Fixes #12)"
        builder = setupBuilder(with: testString)
        containsLink = checkForIssueLink(builder.styledTexts)[0]
        XCTAssertEqual(containsLink.linkText, "#12")
        XCTAssertEqual(containsLink.issueNumber, 12)
        XCTAssertEqual(builder.allText, testString)

        testString = "Fixes(#432)"
        builder = setupBuilder(with: testString)
        containsLink = checkForIssueLink(builder.styledTexts)[0]
        XCTAssertEqual(containsLink.linkText, "#432")
        XCTAssertEqual(containsLink.issueNumber, 432)
        XCTAssertEqual(builder.allText, testString)

        testString = "!#4 yada yada"
        builder = setupBuilder(with: testString)
        containsLink = checkForIssueLink(builder.styledTexts)[0]
        XCTAssertEqual(containsLink.linkText, "#4")
        XCTAssertEqual(containsLink.issueNumber, 4)
        XCTAssertEqual(builder.allText, testString)

        // dash in repository name
        testString = "Unibeautify/unibeautify-cli#115"
        builder = setupBuilder(with: testString)
        containsLink = checkForIssueLink(builder.styledTexts)[0]
        XCTAssertEqual(containsLink.linkText, "Unibeautify/unibeautify-cli#115")
        XCTAssertEqual(containsLink.issueNumber, 115)
        XCTAssertEqual(builder.allText, testString)

        //leading underscore
        testString = "_#115"
        builder = setupBuilder(with: testString)
        containsLink = checkForIssueLink(builder.styledTexts)[0]
        XCTAssertEqual(containsLink.linkText, "#115")
        XCTAssertEqual(containsLink.issueNumber, 115)
        XCTAssertEqual(builder.allText, testString)

        //trailing underscore
        testString = "#115_"
        builder = setupBuilder(with: testString)
        containsLink = checkForIssueLink(builder.styledTexts)[0]
        XCTAssertEqual(containsLink.linkText, "#115")
        XCTAssertEqual(containsLink.issueNumber, 115)
        XCTAssertEqual(builder.allText, testString)
    }

    func test_ConsecutivePositiveMatches() {
        let testString = "#100 #150 #200"
        let builder = setupBuilder(with: testString)
        let links = checkForIssueLink(builder.styledTexts)

        XCTAssertEqual(links[0].issueNumber, 100)
        XCTAssertEqual(links[0].linkText, "#100")

        XCTAssertEqual(links[1].issueNumber, 150)
        XCTAssertEqual(links[1].linkText, "#150")

        XCTAssertEqual(links[2].issueNumber, 200)
        XCTAssertEqual(links[2].linkText, "#200")
    }

    func test_negativeMatches() {
        var builder = setupBuilder(with: "!1234")
        var containsLink = checkForIssueLink(builder.styledTexts)
        XCTAssertEqual(containsLink.count, 0)

        builder = setupBuilder(with: "imo the best pr so far is prob # 1906")
        containsLink = checkForIssueLink(builder.styledTexts)
        XCTAssertEqual(containsLink.count, 0)

        builder = setupBuilder(with: "#123F")
        containsLink = checkForIssueLink(builder.styledTexts)
        XCTAssertEqual(containsLink.count, 0)

        builder = setupBuilder(with: "f#123")
        containsLink = checkForIssueLink(builder.styledTexts)
        XCTAssertEqual(containsLink.count, 0)

        // format should be f/f/#123
        builder = setupBuilder(with: "f/#123")
        containsLink = checkForIssueLink(builder.styledTexts)
        XCTAssertEqual(containsLink.count, 0)

        builder = setupBuilder(with: "1#1")
        containsLink = checkForIssueLink(builder.styledTexts)
        XCTAssertEqual(containsLink.count, 0)
    }
}

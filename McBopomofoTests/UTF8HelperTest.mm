#import <XCTest/XCTest.h>
#import "UTF8Helper.h"

@interface UTF8HelperTest : XCTestCase

@end

@implementation UTF8HelperTest


- (void)testGetCodePoint1 {
    std::string s = "一二三四";
    std::string r = McBopomofo::GetCodePoint(s, 2);
    XCTAssertTrue(r == "三");
}

- (void)testGetCodePoint2 {
    std::string s = "ABCD";
    std::string r = McBopomofo::GetCodePoint(s, 2);
    XCTAssertTrue(r == "C");
}

- (void)testGetCodePoint3 {
    std::string s = "11🌳1";
    std::string r = McBopomofo::GetCodePoint(s, 2);
    XCTAssertTrue(r == "🌳");
}

- (void)testGetCodePoint4 {
    std::string s = "🌳🌳1🌳";
    std::string r = McBopomofo::GetCodePoint(s, 2);
    XCTAssertTrue(r == "1");
}

@end

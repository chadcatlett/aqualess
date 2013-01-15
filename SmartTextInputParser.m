//
// SmartTextInputParser.m
//
// AquaLess - a less-compatible text pager for Mac OS X
// Copyright (c) 2003 Christoph Pfisterer
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//

#import "SmartTextInputParser.h"
#import "PagerDocument.h"
#import "FontHelper.h"

typedef enum {
    CodeReset,
    CodeBright,
    CodeFaint,
    CodeItalic,
    CodeUnderline,
    CodeSlowBlink,
    CodeRapidBlink,
    CodeInverted,
    CodeConceal,
    CodeCrossedOut,
    CodeFontDefault,
    CodeFontAlternate1,
    CodeFontAlternate2,
    CodeFontAlternate3,
    CodeFontAlternate4,
    CodeFontAlternate5,
    CodeFontAlternate6,
    CodeFontAlternate7,
    CodeFontAlternate8,
    CodeFontAlternate9,
    CodeFraktur,
    CodeBoldOff,
    CodeNormalColorOrIntensity,
    CodeItalicOff,
    CodeUnderlineOff,
    CodeBlinkOff,
    CodeReserved,
    CodeInvertedOff,
    CodeReveal,
    CodeCrossedOutOff,
    CodeTextBlack,
    CodeTextRed,
    CodeTextGreen,
    CodeTextYellow,
    CodeTextBlue,
    CodeTextMagenta,
    CodeTextCyan,
    CodeTextWhite,
    CodeTextXterm,
    CodeTextDefault,
    CodeBackgroundBlack,
    CodeBackgroundRed,
    CodeBackgroundGreen,
    CodeBackgroundYellow,
    CodeBackgroundBlue,
    CodeBackgroundMagenta,
    CodeBackgroundCyan,
    CodeBackgroundWhite,
    CodeBackgroundXterm,
    CodeBackgroundDefault,
    CodeReserved2,
    CodeFramed,
    CodeEncircled,
    CodeOverlined,
    CodeFramedOrEncircledOff,
    CodeOverlinedOff,
} ANSICode;

@implementation SmartTextInputParser

+ (int)priority
{
  return 2;
}

+ (NSString *)name
{
  return @"Text";
}

+ (BOOL)canReadData:(NSData *)partialData
{
  return YES;
}

unsigned getCodeColor(unsigned color)
{
    switch (color) {
    case 0:
        return FontColorBlack;
    case 1:
        return FontColorRed;
    case 2:
        return FontColorGreen;
    case 3:
        return FontColorYellow;
    case 4:
        return FontColorBlue;
    case 5:
        return FontColorMagenta;
    case 6:
        return FontColorCyan;
    case 7:
        return FontColorWhite;
    default:
        return FontColorDefault;
    }
}

- (void)parseData:(NSData *)data fromOffset:(unsigned)startOffset toOffset:(unsigned)endOffset
{
    // parser state
    unsigned offset, state = 0, x = 0;
    unsigned akkuStyle = FontStyleNone, lastStyle = FontStyleNone;
    unsigned terminalStyle = FontStyleNone;
    unsigned terminalStack[16];
    unsigned terminalCount = 0;
    ANSICode terminalCode = CodeReset;
    unichar c, lastC = 0;
    NSMutableString *akku = [NSMutableString string];

    /*
     state == 0: clean
     state == 1: lastC/lastStyle contains the previous printable character, not yet processed
     state == 2: lastC/lastStyle contains the previous printable character, which was followed by a backspace

     In all states, akku may contain chars, which use akkuStyle as their style. Styles:
     0: not set yet, akku is empty
     1: normalAttr
     2: boldAttr
     3: underlineAttr
     4: boldUnderlineAttr
     [invertedAttr doesn't occur]
     */

#define CommitCharWithStyle(thechar,thestyle) do { \
        if (akkuStyle && akkuStyle != (thestyle)) { \
            [self addString:akku withAttributes:fontHelperAttr(akkuStyle)]; \
            [akku setString:@""]; \
        } \
        [akku appendString:[NSString stringWithCharacters:&(thechar) length:1]]; \
        x++; \
        akkuStyle = (thestyle); \
    } while(0)
#define CommitFully() do { \
        [self addString:akku withAttributes:fontHelperAttr(akkuStyle)]; \
        [akku setString:@""]; \
        akkuStyle = FontStyleNone; \
    } while(0);

    for (offset = startOffset; offset < endOffset; offset++) {
        c = ((const unsigned char *)[data bytes])[offset];

        if (state == 3) {
            // inside an escape sequence (or after a single escape)
            if (lastC == 27 && c == '[') {
                // it's a real escape sequence
                terminalCode = CodeReset;
                // state is unchanged
            } else if (lastC == 27) {
                // it's just a stray ESC, put it in the output now
                [self addString:@"ESC"
                      withAttributes:fontHelperAttr(FontStyleInverted)];
                lastStyle = FontStyleNone;
                state = 1;
            } else if (c >= '0' && c <= '9') {
                terminalCode *= 10;
                terminalCode += c - '0';
            } else if (c == ';') {
                // number separator
                terminalCode = CodeReset;
            } else if (c == 'm') {
                // set attributes
                if (terminalCode == CodeReset) {
                    // remove last attribute
                    if (terminalCount > 0)
                        terminalStyle = terminalStack[--terminalCount];
                } else if (terminalCount < 16) {
                    terminalStack[terminalCount++] = terminalStyle;
                    if (terminalCode == CodeBright) {
                        // bold on
                        terminalStyle = (terminalStyle & ~FontStyleFaint) |
                            FontStyleBold;
                    } else if (terminalCode == CodeFaint) {
                        // faint on
                        terminalStyle = (terminalStyle & ~FontStyleBold) |
                            FontStyleFaint;
                    } else if (terminalCode == CodeItalic) {
                        // italic on
                        terminalStyle |= FontStyleItalic;
                    } else if (terminalCode == CodeUnderline) {
                        // underline on
                        terminalStyle |= FontStyleUnderline;
                    } else if (terminalCode == CodeSlowBlink) {
                        // slow blink -- ignored
                    } else if (terminalCode == CodeRapidBlink) {
                        // rapid blink -- ignored
                    } else if (terminalCode == CodeInverted) {
                        // inverted on
                        terminalStyle |= FontStyleInverted;
                    } else if (terminalCode == CodeConceal) {
                        // conceal -- ignored
                    } else if (terminalCode == CodeCrossedOut) {
                        // crossedOut -- ignored
                    } else if (terminalCode >= CodeFontDefault &&
                               terminalCode <= CodeFontAlternate9)
                    {
                        // font specifier -- ignored
                    } else if (terminalCode == CodeFraktur) {
                        // Fraktur -- ignored
                    } else if (terminalCode == CodeBoldOff) {
                        // bold off
                        terminalStyle &= ~FontStyleBold;
                    } else if (terminalCode == CodeNormalColorOrIntensity) {
                        // bold/faint off
                        terminalStyle &= ~(FontStyleBold|FontStyleFaint);
                    } else if (terminalCode == CodeItalicOff) {
                        // italic off
                        terminalStyle &= ~FontStyleItalic;
                    } else if (terminalCode == CodeUnderlineOff) {
                        // underline off
                        terminalStyle &= ~FontStyleUnderline;
                    } else if (terminalCode == CodeBlinkOff) {
                        // blink off -- ignored
                    } else if (terminalCode == CodeInvertedOff) {
                        // inverted off
                        terminalStyle &= ~FontStyleInverted;
                    } else if (terminalCode == CodeReveal) {
                        // reveal -- ignored
                    } else if (terminalCode == CodeCrossedOutOff) {
                        // crossed-out off -- ignored
                    } else if (terminalCode >= CodeTextBlack &&
                               terminalCode <= CodeTextDefault)
                    {
                        terminalStyle = (terminalStyle & 0xff00ffff) |
                            (getCodeColor(terminalCode - CodeTextBlack) << 16);
                    } else if (terminalCode >= CodeBackgroundBlack &&
                               terminalCode <= CodeBackgroundDefault) {
                        terminalStyle = (terminalStyle & 0x00ffffff) |
                            (getCodeColor(terminalCode - CodeBackgroundBlack)
                             << 24);
                    }
                }
                state = 0;
            } else {
                state = 0;
            }
            lastC = c;

        } else if (c == NSBackspaceCharacter) {
            // backspace, used to denote overstriking
            if (state == 1)
                state = 2;
            // lastC is not touched -- important!

        } else if (c < 32 || (c >= 127 && c < 128+32)) {
            // non-printable character

            if (state == 1) {
                // commit pending character
                if (terminalStyle != FontStyleNone)
                    lastStyle = terminalStyle;
                CommitCharWithStyle(lastC, lastStyle);
            } // NOTE: in state 2, we assume that the backspace removed the pending char
            state = 0;

            // now process the non-printable
            if (c == NSTabCharacter) {
                // add spaces instead
                lastC = ' ';  // for temp purposes, overwritten later by c
                CommitCharWithStyle(lastC, FontStyleNone);
                for (; x % 8; x++)
                    [akku appendString:[NSString stringWithCharacters:&lastC length:1]];
            } else if (c == NSCarriageReturnCharacter) {
                // set checkpoint _before_ the line break
                CommitFully();
                [self setCheckpoint:offset];

                lastC = '\n';  // for temp purposes, overwritten later by c
                CommitCharWithStyle(lastC, FontStyleNone);
                x = 0;
            } else if (c == NSNewlineCharacter) {
                if (lastC != NSCarriageReturnCharacter) {
                    // set checkpoint _before_ the line break
                    CommitFully();
                    [self setCheckpoint:offset];

                    lastC = '\n';  // for temp purposes, overwritten later by c
                    CommitCharWithStyle(lastC, FontStyleNone);
                    x = 0;
                }
            } else if (c == 27) {
                // escape, scan what comes after it
                CommitFully();
                state = 3;
            } else {
                // print control char in inverse face
                CommitFully();
                if (c < 32) {  // control sequence
                    [self addString:[NSString stringWithFormat:@"^%c", (int)c ^ 64]
                          withAttributes:fontHelperAttr(FontStyleInverted)];
                } else {  // hex
                    [self addString:[NSString stringWithFormat:@"<%X>", (int)c]
                          withAttributes:fontHelperAttr(FontStyleInverted)];
                }
            }
            lastC = c;

        } else {
            // printable character

            if (state == 2) {
                // compute overstrike of c with lastC
                if (c == lastC) {
                    if (c == '_') {
                        // underscore - bs - underscore: is this bold or underline?
                        // -> guess from context
                        if ((akkuStyle & FontStyleUnderline) ==
                            FontStyleUnderline)
                        {
                            lastStyle |= FontStyleUnderline;
                        } else {
                            lastStyle |= FontStyleBold;
                        }
                    } else {
                        // bold
                        lastStyle |= FontStyleBold;
                    }
                    // lastC is unmodified
                } else if (c == '_') {
                    // underline, lastC is the real char
                    lastStyle |= FontStyleUnderline;
                    // lastC is unmodified
                } else if (lastC == '_') {
                    // underline, c is the real char
                    lastStyle |= FontStyleUnderline;
                    lastC = c;
                } else {
                    // replace
                    lastStyle &= ~(FontStyleBold|FontStyleUnderline);
                    lastC = c;
                }
                state = 1;

            } else if (state == 1) {
                // normal case, add lastC to akku, move this one to lastC
                if (terminalStyle != 0)
                    lastStyle = terminalStyle;
                CommitCharWithStyle(lastC, lastStyle);
                lastStyle = FontStyleNone;
                lastC = c;
                // state is unmodified

            } else {
                // clean state, just push this char into lastC
                lastStyle = FontStyleNone;
                lastC = c;
                state = 1;
            }

        }
    }
    if (state == 1) {
        // commit pending character
        CommitCharWithStyle(lastC, lastStyle);
    } // NOTE: in state 2, we assume that the backspace removed the pending char
    CommitFully();

    // remove the trailing newline if present
    [self chomp];
}

@end

//
// FontHelper.m
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

#import "FontHelper.h"

static BOOL fontInited = NO;
static NSFontManager *mgr;

static NSSize fontCellSize;

static NSFont *normalFont;
static NSFont *boldFont;
static NSFont *italicFont;
static NSFont *boldItalicFont;

static NSColor *normalForeground;
static NSColor *normalBackground;

static NSMutableParagraphStyle *ps;

static NSMutableDictionary *styles;

/*
static NSMutableDictionary *createColor(NSFont *font, NSColor *fgColor,
                                        NSColor *bgColor,
                                        NSMutableParagraphStyle *ps)
{
    NSMutableDictionary *dict = [[NSMutableDictionary dictionary] retain];
    [dict setObject:normalFont forKey:NSFontAttributeName];
    [dict setObject:fgColor forKey:NSForegroundColorAttributeName];
    [dict setObject:bgColor forKey:NSBackgroundColorAttributeName];
    [dict setObject:ps forKey:NSParagraphStyleAttributeName];
    return dict;
}
*/

static void initFonts()
{
    if (fontInited)
        return;

    // get the fonts
    mgr = [NSFontManager sharedFontManager];
    normalFont = [[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"normalTextFont"]] retain];

    // get colors from prefs
    normalForeground = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"normalTextColor"]];
    normalBackground = [NSColor whiteColor];
    //NSColor *boldColor = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"boldTextColor"]];

    // paragraph style
    ps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [ps setLineBreakMode:NSLineBreakByCharWrapping];

    // set up style dictionary
    styles = [[NSMutableDictionary dictionary] retain];

    // get character size for normal font
    fontCellSize.height = [normalFont defaultLineHeightForFont];
    fontCellSize.width = [normalFont maximumAdvancement].width;
    if (fontCellSize.width < 1)
        fontCellSize.width = 8;

    fontInited = YES;
}


void reinitFonts()
{
    if (!fontInited)
        return;

    [normalFont autorelease];
    if (boldFont) [boldFont autorelease];
    if (italicFont) [italicFont autorelease];
    if (boldItalicFont) [boldItalicFont autorelease];

    for (id key in styles) {
        NSDictionary *style = [styles objectForKey:key];
        [style release];
    }
    [styles release];

    fontInited = NO;
}

NSSize fontHelperCellSize()
{
    initFonts();
    return fontCellSize;
}

NSFont *getFont(unsigned style)
{
    initFonts();

    if ((style & FontStyleBold) == FontStyleBold) {
        if ((style & FontStyleItalic) == FontStyleItalic) {
            if (!boldItalicFont) {
                unsigned mask = NSBoldFontMask | NSItalicFontMask;
                boldItalicFont = [[mgr convertFont:normalFont
                                       toHaveTrait:mask] retain];
            }
            return boldItalicFont;
        } else {
            if (!boldFont) {
                boldFont = [[mgr convertFont:normalFont
                                 toHaveTrait:NSBoldFontMask] retain];
            }
            return boldFont;
        }
    } else if ((style & FontStyleItalic) == FontStyleItalic) {
        if (!italicFont) {
            italicFont = [[mgr convertFont:normalFont
                               toHaveTrait:NSItalicFontMask] retain];
        }
        return italicFont;
    }

    return normalFont;
}

NSColor *getColor(unsigned color, NSColor *defaultColor)
{
    if (color == FontColorBlack) {
        return [NSColor blackColor];
    } else if (color == FontColorRed) {
        return [NSColor redColor];
    } else if (color == FontColorGreen) {
        return [NSColor greenColor];
    } else if (color == FontColorYellow) {
        return [NSColor yellowColor];
    } else if (color == FontColorBlue) {
        return [NSColor blueColor];
    } else if (color == FontColorMagenta) {
        return [NSColor magentaColor];
    } else if (color == FontColorCyan) {
        return [NSColor cyanColor];
    } else if (color == FontColorWhite) {
        return [NSColor whiteColor];
    } else {
        return defaultColor;
    }
}

NSDictionary *fontHelperAttr(unsigned style)
{
    initFonts();

    NSNumber *key = [NSNumber numberWithUnsignedInteger:style];
    NSMutableDictionary *thisStyle;

    thisStyle = [styles objectForKey:key];
    if (!thisStyle) {
        NSFont *font = getFont(style & 0xffff);
        NSColor *fgColor = getColor((style >> 16) & 0xff, normalForeground);
        NSColor *bgColor = getColor((style >> 24) & 0xff, normalBackground);

        if ((style & FontStyleInverted) == FontStyleInverted) {
            NSColor *tmp = fgColor;
            fgColor = bgColor;
            bgColor = tmp;
        }

        thisStyle = [[NSMutableDictionary dictionary] retain];
        [thisStyle setObject:font forKey:NSFontAttributeName];
        [thisStyle setObject:fgColor forKey:NSForegroundColorAttributeName];
        [thisStyle setObject:bgColor forKey:NSBackgroundColorAttributeName];
        [thisStyle setObject:ps forKey:NSParagraphStyleAttributeName];

        [styles setObject:thisStyle forKey:key];
    }

    return thisStyle;
}

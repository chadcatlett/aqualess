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
static NSSize fontCellSize;
static NSFont *normalFont;
static NSFont *boldFont;
static NSMutableDictionary *normalAttr;
static NSMutableDictionary *boldAttr;
static NSMutableDictionary *underlineAttr;
static NSMutableDictionary *invertedAttr;

static void initFonts()
{
  if (fontInited)
    return;

  // get the fonts
  NSFontManager *mgr = [NSFontManager sharedFontManager];
  normalFont = [[mgr fontWithFamily:@"Monaco"
                             traits:NSUnboldFontMask|NSUnitalicFontMask
                             weight:5
                               size:10] retain];
  boldFont   = [[mgr fontWithFamily:@"Monaco"
                             traits:NSBoldFontMask|NSUnitalicFontMask
                             weight:9
                               size:10] retain];

  // paragraph style
  NSMutableParagraphStyle *ps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  [ps setLineBreakMode:NSLineBreakByCharWrapping];

  // set up attribute dictionaries
  normalAttr = [[NSMutableDictionary dictionary] retain];
  [normalAttr setObject:normalFont forKey:NSFontAttributeName];
  [normalAttr setObject:ps forKey:NSParagraphStyleAttributeName];

  boldAttr = [[NSMutableDictionary dictionary] retain];
  [boldAttr setObject:boldFont forKey:NSFontAttributeName];
  if (normalFont == boldFont)  // no separate bold font available, use color instead for now
    [boldAttr setObject:[NSColor blueColor] forKey:NSForegroundColorAttributeName];
  [boldAttr setObject:ps forKey:NSParagraphStyleAttributeName];

  underlineAttr = [[NSMutableDictionary dictionary] retain];
  [underlineAttr setObject:normalFont forKey:NSFontAttributeName];
  [underlineAttr setObject:[NSNumber numberWithInt:NSSingleUnderlineStyle]
                    forKey:NSUnderlineStyleAttributeName];
  [underlineAttr setObject:ps forKey:NSParagraphStyleAttributeName];

  invertedAttr = [[NSMutableDictionary dictionary] retain];
  [invertedAttr setObject:normalFont forKey:NSFontAttributeName];
  [invertedAttr setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
  [invertedAttr setObject:[NSColor blackColor] forKey:NSBackgroundColorAttributeName];
  // [NSColor cyanColor] [NSColor blackColor] [NSColor whiteColor]
  [invertedAttr setObject:ps forKey:NSParagraphStyleAttributeName];

  // get character size for normal font
  fontCellSize.height = [normalFont defaultLineHeightForFont];
  fontCellSize.width = [normalFont maximumAdvancement].width;
  if (fontCellSize.width < 1)
    fontCellSize.width = 8;

  fontInited = YES;
}


#define FontStylePlain (1)
#define FontStyleBold (2)
#define FontStyleUnderline (3)
#define FontStyleInverted (4)

NSSize fontHelperCellSize()
{
  initFonts();
  return fontCellSize;
}

NSFont *fontHelperFont(int style)
{
  initFonts();

  switch (style)
  {
  case FontStyleBold:
    return boldFont;
  case FontStylePlain:
  case FontStyleUnderline:
  case FontStyleInverted:
  default:
    return normalFont;
  }
}

NSDictionary *fontHelperAttr(int style)
{
  initFonts();

  switch (style)
  {
  case FontStyleBold:
    return boldAttr;
  case FontStyleUnderline:
    return underlineAttr;
  case FontStyleInverted:
    return invertedAttr;
  case FontStylePlain:
  default:
    return normalAttr;
  }
}

//
// FontHelper.h
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

typedef enum {
    FontStyleNone = 0x00,
    FontStyleBold = 0x01,
    FontStyleFaint = 0x02,
    FontStyleItalic = 0x04,
    FontStyleUnderline = 0x08,
    FontStyleInverted = 0x10,
} FontStyleBit;

typedef enum {
    // note that this does not match the order of the colors in ANSICode
    // so that Default == 0
    FontColorDefault,
    FontColorBlack,
    FontColorRed,
    FontColorGreen,
    FontColorYellow,
    FontColorBlue,
    FontColorMagenta,
    FontColorCyan,
    FontColorWhite,
    FontColorXTerm,
} FontColorType;

void reinitFonts();

NSSize fontHelperCellSize();
NSDictionary *fontHelperAttr(unsigned style);

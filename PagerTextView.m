//
// PagerTextView.m
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

#import "PagerTextView.h"

@implementation PagerTextView

// keyboard handling

- (void)keyDown:(NSEvent *)theEvent
{
  BOOL handled = NO;

  NSString *keys = [theEvent charactersIgnoringModifiers];
  if ([keys length] > 0) {
    int c = [keys characterAtIndex:0];

    handled = YES;
    switch (c)
    {
    case NSDownArrowFunctionKey:
    case 13:
    case 10:
    case 'e':
    case 'j':
      [self scrollLines:1];
      break;
    case NSUpArrowFunctionKey:
    case 'y':
    case 'p':
    case 'k':
      [self scrollLines:-1];
      break;
    case 32:
    case NSPageDownFunctionKey:
    case 'f':
    case 'z':
    case 'v':
      [self scrollPages:1];
      break;
    case NSPageUpFunctionKey:
    case 'b':
    case 'w':
      [self scrollPages:-1];
      break;
    case 'd':
      [self scrollPages:0.5];
      break;
    case 'u':
      [self scrollPages:-0.5];
      break;
    case NSHomeFunctionKey:
    case 'g':
    case '<':
      [self scrollPoint:NSMakePoint(0, 0)];
      break;
    case NSEndFunctionKey:
    case 'G':
    case '>':
      [self scrollPoint:NSMakePoint(0, [self bounds].size.height)];
      break;
    case 'q':
      [[self window] performClose:self];
      break;
    default:
      handled = NO;
      break;
    }
  }

  if (!handled)
    [super keyDown:theEvent];
}

- (void)scrollBy:(NSPoint)offset
{
  NSScrollView *scrollView = [self enclosingScrollView];
  if (scrollView == nil)
    return;
  NSClipView *clipView = [scrollView contentView];

  NSPoint scrollTo = [clipView bounds].origin;
  scrollTo.x += offset.x;
  if ([clipView isFlipped])
    scrollTo.y += offset.y;
  else
    scrollTo.y -= offset.y;
  scrollTo = [clipView constrainScrollPoint:scrollTo];
  [clipView scrollToPoint:scrollTo];
  [scrollView reflectScrolledClipView:clipView];
}

- (void)scrollLines:(int)lines
{
  NSScrollView *scrollView = [self enclosingScrollView];
  if (scrollView == nil)
    return;

  [self scrollBy:NSMakePoint(0, lines * [scrollView verticalLineScroll])];
}

- (void)scrollPages:(float)pages
{
  NSScrollView *scrollView = [self enclosingScrollView];
  if (scrollView == nil)
    return;
  NSClipView *clipView = [scrollView contentView];

  int lineHeight = [scrollView verticalLineScroll];
  int linesPerPage = [clipView bounds].size.height / lineHeight - 1;
  [self scrollBy:NSMakePoint(0, floor(pages * linesPerPage + 0.5) * lineHeight)];
}

@end

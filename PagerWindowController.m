//
// PagerWindowController.m
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

#import "PagerWindowController.h"
#import "PagerDocument.h"
#import "PagerTextView.h"
#import "FindPanelController.h"
#import "FontHelper.h"


@implementation PagerWindowController

// init

- (id)init
{
  if (self = [super initWithWindowNibName:@"PagerDocument"]) {
    [self setShouldCloseDocument:YES];
    findPanel = nil;
    lastPattern = nil;
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if (findPanel != nil)
    [findPanel release];
  if (lastPattern != nil)
    [lastPattern release];

  [super dealloc];
}

// post-init

- (void)windowDidLoad
{
  [super windowDidLoad];

  // replace text view from nib with custom subclass (didn't work in Interface Builder...)
  NSRect tvFrame = [display frame];
  tvFrame.origin.x = 0;  // pointless inside a clipview...
  tvFrame.origin.y = 0;
  display = [[[PagerTextView alloc] initWithFrame:tvFrame] autorelease];
  [display setEditable:NO];
  [display setSelectable:YES];
  [display setRichText:YES];
  [[display layoutManager] replaceTextStorage:[self storage]];
  [scroller setDocumentView:display];

  // scroll and resize by full character cells
  NSSize cell = fontHelperCellSize();
  [scroller setVerticalLineScroll:cell.height];
  [scroller setVerticalPageScroll:cell.height];  // page scrolls keep one line
  [scroller setHorizontalLineScroll:cell.width];
  [scroller setHorizontalPageScroll:cell.width];  // page scrolls keep one line
  [[self window] setResizeIncrements:cell];

  /*
  // add space at top and bottom, like in Terminal
  NSSize inset = [display textContainerInset];
  inset.height += 3;
  [display setTextContainerInset:inset];
  */

  // fill formats popup
  [formatPopup removeAllItems];
  int i;
  NSArray *allFormats = [PagerDocument allFormats];
  for (i = 0; i < [allFormats count]; i++) {
    Class format = [allFormats objectAtIndex:i];
    [formatPopup addItemWithTitle:[format name]];
  }

  // observe the document for changes in status
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateStatus:)
                                               name:StatusChangedNotification
                                             object:[self document]];

  // update the status line
  [self updateStatus:nil];

  // set up keyboard event routing
  [[self window] setInitialFirstResponder:display];
}

// access

- (NSTextStorage *)storage
{
  return [[self document] storage];
}

// status display

- (void)updateStatus:(NSNotification *)notification
{
  [status setStringValue:[[self document] statusLine]];

  Class currentFormat = [[self document] currentFormat];
  if (currentFormat != nil)
    [formatPopup selectItemWithTitle:[currentFormat name]];
}

// format selection

- (IBAction)changeFormat:(id)sender
{
  NSString *formatName = [formatPopup titleOfSelectedItem];
  Class currentFormat = [[self document] currentFormat];
  if (currentFormat != nil)
    if ([formatName isEqual:[currentFormat name]])
      return;  // no change

  int i;
  NSArray *allFormats = [PagerDocument allFormats];
  for (i = 0; i < [allFormats count]; i++) {
    Class format = [allFormats objectAtIndex:i];
    if ([formatName isEqual:[format name]]) {
      [[self document] setCurrentFormat:format];
      break;
    }
  }
}

// find panel actions

- (FindPanelController *)findPanel;
{
  if (findPanel == nil) {
    findPanel = [[FindPanelController alloc] initWithController:self];
  }
  return findPanel;
}

- (IBAction)showFindPanel:(id)sender
{
  [[self findPanel] runOnWindow:[self window]];
}
// TODO: variants of this specifying the search direction

- (IBAction)findAgainForwards:(id)sender
{
  if (lastPattern == nil || [lastPattern length] == 0) {
    NSBeep();
    return;
  }

  lastDirection = NO;
  [self findPattern:lastPattern direction:lastDirection];
}

- (IBAction)findAgainBackwards:(id)sender
{
  if (lastPattern == nil || [lastPattern length] == 0) {
    NSBeep();
    return;
  }

  lastDirection = YES;
  [self findPattern:lastPattern direction:lastDirection];
}

- (IBAction)findAgainSameDirection:(id)sender
{
  if (lastPattern == nil || [lastPattern length] == 0) {
    NSBeep();
    return;
  }

  [self findPattern:lastPattern direction:lastDirection];
}

- (IBAction)findAgainOtherDirection:(id)sender
{
  if (lastPattern == nil || [lastPattern length] == 0) {
    NSBeep();
    return;
  }

  [self findPattern:lastPattern direction:!lastDirection];
}

- (void)findPanelDidEndWithPattern:(NSString *)pattern direction:(BOOL)back
{
  if (lastPattern != nil)
    [lastPattern autorelease];
  lastPattern = [pattern retain];
  lastDirection = back;

  [self findPattern:lastPattern direction:lastDirection];
}

// low-level search

- (void)findPattern:(NSString *)pattern direction:(BOOL)back
{
  NSString *haystack = [[self storage] mutableString];
  unsigned options = NSCaseInsensitiveSearch;
  NSRange searchRange, range;
  NSRange selectedRange = [display selectedRange];

  if (!back) {
    if (selectedRange.length == 0)
      searchRange.location = 0;
    else
      searchRange.location = NSMaxRange(selectedRange);
    searchRange.length = [haystack length] - searchRange.location;
    range = [haystack rangeOfString:pattern options:options range:searchRange];
  } else {
    options |= NSBackwardsSearch;
    searchRange.location = 0;
    if (selectedRange.length == 0)
      searchRange.length = [haystack length];
    else
      searchRange.length = selectedRange.location;
    range = [haystack rangeOfString:pattern options:options range:searchRange];
  }

  if (range.length) {
    [display setSelectedRange:range];
    [display scrollRangeToVisible:range];
    [self updateStatus:nil];
  } else {
    NSBeep();
    [status setStringValue:@"Pattern not found."];
  }
}

@end

//
// FindPanelController.m
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

#import "FindPanelController.h"
#import "PagerWindowController.h"


@implementation FindPanelController

// init

- (id)initWithController:(PagerWindowController *)winC
{
  if (self = [super initWithWindowNibName:@"FindPanel"]) {
    parentController = winC;
  }
  return self;
}

- (void)dealloc
{
  //[[NSNotificationCenter defaultCenter] removeObserver:self];

  [super dealloc];
}

// action

- (IBAction)dismissOk:(id)sender
{
  [NSApp endSheet:[self window] returnCode:NSOKButton];
}

- (IBAction)dismissCancel:(id)sender
{
  [NSApp endSheet:[self window] returnCode:NSCancelButton];
}

// sheet starting

- (void)runOnWindow:(NSWindow *)parentWindow
{
  [NSApp beginSheet:[self window]
     modalForWindow:parentWindow
      modalDelegate:self
     didEndSelector:@selector(findDidEnd:returnCode:contextInfo:)
        contextInfo:nil];
}

// sheet termination

- (void)findDidEnd:(NSWindow *)sheet
        returnCode:(int)returnCode
       contextInfo:(void *)contextInfo
{
  if (returnCode == NSOKButton) {
    NSString *pattern = [patternControl stringValue];

    NSLog(@"pattern: '%@'", pattern);
    /*
    NSString *iText = [textControl stringValue];
    NSDecimalNumber *iNetto = [nettoControl objectValue];
    */

    [parentController findPattern:pattern fromPosition:0 backwards:NO];
  }

  [sheet orderOut:self];
}

@end

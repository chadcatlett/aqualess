//
// ReadmeWindowController.m
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

#import "ReadmeWindowController.h"
#import "MyDocumentController.h"


@implementation ReadmeWindowController

// init

- (id)initWithReadmeName:(NSString *)fileName controller:(MyDocumentController *)docC
{
  if (self = [super initWithWindowNibName:@"ReadmeWindow"]) {

    readmeName = [fileName retain];
    controller = docC;  // not retained by design

    [controller registerReadmeWindow:readmeName withController:self];

  }
  return self;
}

- (void)dealloc
{
  [controller unregisterReadmeWindow:readmeName];  // just to be sure
  [readmeName release];

  [super dealloc];
}

// post-init

- (void)windowDidLoad
{
  [super windowDidLoad];

  NSString *fullPath = [[NSBundle mainBundle] pathForResource:readmeName ofType:@"rtf"];
  [display readRTFDFromFile:fullPath];

  [[self window] setTitle:readmeName];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
  [[self retain] autorelease];  // make sure we're still around for a short time
  [controller unregisterReadmeWindow:readmeName];
}

@end

//
// MyDocumentController.h
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

#import <Cocoa/Cocoa.h>
#import "AquaLess_Protocol.h"

@class ReadmeWindowController;


@interface MyDocumentController : NSDocumentController <AquaLess>
{
  int nextPipeId;
  NSMutableDictionary *pipes;
  NSMutableDictionary *readmeWindows;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

- (oneway void)openFileWithPath:(NSString *)filePath;
- (int)openPipe;
- (int)openPipeWithTitle:(NSString *)title;
- (oneway void)addData:(NSData *)data toPipe:(int)pipeid;

- (void)removeDocument:(NSDocument *)document;

- (void)registerReadmeWindow:(NSString *)readmeName
              withController:(ReadmeWindowController *)controller;
- (void)unregisterReadmeWindow:(NSString *)readmeName;
- (void)openReadmeWindow:(NSString *)readmeName;

- (IBAction)newShell:(id)sender;

- (IBAction)showReadme:(id)sender;
- (IBAction)showLicense:(id)sender;

@end

//
// MyDocumentController.m
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

#import "MyDocumentController.h"
#import "PagerDocument.h"
#import "ReadmeWindowController.h"
#import "ToolInstaller.h"


@implementation MyDocumentController

- (id)init
{
  self = [super init];
  if (self) {

    nextPipeId = 0;
    pipes = [[NSMutableDictionary dictionary] retain];
    readmeWindows = [[NSMutableDictionary dictionary] retain];

  }
  return self;
}

- (void)dealloc
{
  [pipes release];
  [readmeWindows release];

  [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  // register server for the command line tool
  NSConnection *conn = [NSConnection defaultConnection];
  [conn setRootObject:self];
  if ([conn registerName:@"AquaLess1"] == NO) {
    NSRunAlertPanel(@"Server Registration Failed",
                    @"The AquaLess application failed to register its communication port with the system. The command line tool will not be able to contact the application.",
                    @"OK", nil, nil);
  }

  // check for installation of command line tool
  checkAndInstallTool();
}

- (oneway void)openFileWithPath:(NSString *)filePath
{
  // bring us to the front
  [NSApp activateIgnoringOtherApps:YES];

  // open the file
  [self openDocumentWithContentsOfFile:filePath display:YES];
}

- (int)openPipe
{
  // bring us to the front
  [NSApp activateIgnoringOtherApps:YES];

  // make new document without file association
  PagerDocument *pipeDoc = [self openUntitledDocumentOfType:@"Text File" display:YES];
  if (pipeDoc == nil)
    return -1;

  // register an id and return it
  int pipeId = nextPipeId++;
  [pipes setObject:pipeDoc forKey:[NSNumber numberWithInt:pipeId]];
  return pipeId;
}

- (oneway void)addData:(NSData *)data toPipe:(int)pipeId
{
  // find the document by id
  PagerDocument *pipeDoc = [pipes objectForKey:[NSNumber numberWithInt:pipeId]];
  if (pipeDoc == nil)
    return;

  // hand the data on
  [pipeDoc addData:data];
}

- (void)removeDocument:(NSDocument *)document
{
  // remove from pipes dict
  [pipes removeObjectsForKeys:[pipes allKeysForObject:document]];

  // call through
  [super removeDocument:document];
}

- (IBAction)newShell:(id)sender
{
  static NSAppleScript *terminalScript = nil;

  if (terminalScript == nil) {
    NSString *source = @"tell application \"Terminal\"\n  activate\n  do script \"\"\nend tell";
    terminalScript = [[NSAppleScript alloc] initWithSource:source];
  }

  NSDictionary *errorInfo;
  NSAppleEventDescriptor *result = [terminalScript executeAndReturnError:&errorInfo];

  if (result == nil) {
    NSRunAlertPanel(@"Communication Failed",
                    @"AppleScript communication with the Terminal application failed.",
                    @"OK", nil, nil);
  }
}

- (void)registerReadmeWindow:(NSString *)readmeName
              withController:(ReadmeWindowController *)controller
{
  [readmeWindows setObject:controller forKey:readmeName];
}

- (void)unregisterReadmeWindow:(NSString *)readmeName
{
  [readmeWindows removeObjectForKey:readmeName];
}

- (IBAction)showReadme:(id)sender
{
  [self openReadmeWindow:@"ReadMe"];
}

- (IBAction)showLicense:(id)sender
{
  [self openReadmeWindow:@"License"];
}

- (void)openReadmeWindow:(NSString *)readmeName
{
  ReadmeWindowController *wc = [readmeWindows objectForKey:readmeName];
  if (wc == nil)
    wc = [[[ReadmeWindowController alloc] initWithReadmeName:readmeName controller:self] autorelease];
  [[wc window] makeKeyAndOrderFront:nil];
}

@end

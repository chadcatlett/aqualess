//
// aless.m
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

#include <unistd.h>

#import "AquaLess_Protocol.h"

#define BUFSIZE (8192)


const char *progname;
int exitcode = 0;
NSDistantObject <AquaLess> *appProxy = nil;


void usage()
{
  fprintf(stderr, "Usage: <command> | %s\n", progname);
  fprintf(stderr, "       %s <file>...\n", progname);
  exitcode = 1;
}

void connectToApp()
{
  int tries;
  for (tries = 0; tries < 10; tries++) {
    appProxy = [NSConnection rootProxyForConnectionWithRegisteredName:@"AquaLess1"
                                                                 host:nil];
    if (appProxy)
      break;

    if (tries == 0) {
      fprintf(stderr, "%s: Launching AquaLess application\n", progname);
      if (![[NSWorkspace sharedWorkspace] launchApplication:@"AquaLess"]) {
        fprintf(stderr, "%s: Failed to launch AquaLess application\n", progname);
        exitcode = 1;
        return;
      }
    }
    sleep(1);
  }
  if (appProxy == nil) {
    fprintf(stderr, "%s: Failed to connect to AquaLess application\n", progname);
    exitcode = 1;
    return;
  }

  [appProxy setProtocolForProxy:@protocol(AquaLess)];
}

void openFiles(NSArray *files)
{
  // tell the app about each file
  int i;
  for (i = 0; i < [files count]; i++) {
    NSString *fileName = [files objectAtIndex:i];
    [appProxy openFileWithPath:fileName];
  }
}

void doPipe()
{
  int pipeId;
  ssize_t got;
  char buf[BUFSIZE];

  pipeId = [appProxy openPipe];
  if (pipeId < 0) {
    fprintf(stderr, "%s: Error while talking to the AquaLess application\n", progname);
    exitcode = 1;
    return;
  }

  // TODO: use NSFileHandle and a NSRunLoop instead of this mess

  for (;;) {
    got = read(0, buf, BUFSIZE);

    if (got < 0) {
      if (errno == EAGAIN || errno == EINTR)
        continue;
      fprintf(stderr, "%s: Standard input: %s\n", progname, strerror(errno));
      exitcode = 1;
      break;
    } else if (got == 0) {
      break;
    } else {
      NSData *data = [[NSData alloc] initWithBytesNoCopy:buf length:(unsigned)got freeWhenDone:NO];
      [appProxy addData:data toPipe:pipeId];
      [data release];
    }
  }
}

int main(int argc, const char *argv[])
{
  // get program name (for future extension)
  progname = rindex(argv[0], '/');
  if (progname)
    progname++;
  else
    progname = argv[0];

  // entering ObjC land, wrap with an auto-release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // parse command line
  int i;
  NSMutableArray *files = [NSMutableArray array];
  for (i = 1; i < argc; i++) {
    NSString *spec = [NSString stringWithCString:argv[i]];
    if (![spec isAbsolutePath]) {
      spec = [[[NSFileManager defaultManager]
        currentDirectoryPath] stringByAppendingPathComponent:spec];
    }
    [files addObject:spec];
  }

  if ([files count] > 0) {
    // we were invoked with some files
    connectToApp();
    if (exitcode == 0)
      openFiles(files);

  } else {
    // we were invoked without files, i.e. read from stdin
    if (isatty(0))  // don't read from a terminal, only redirections
      usage();

    if (exitcode == 0)
      connectToApp();
    if (exitcode == 0)
      doPipe();
  }

  [pool release];
  return exitcode;
}

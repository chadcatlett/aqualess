//
// PagerDocument.m
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

#import "PagerDocument.h"
#import "PagerWindowController.h"

#import "SmartTextInputParser.h"
#import "RawTextInputParser.h"
#import "HexdumpInputParser.h"

NSString *StatusChangedNotification = @"Pager Status Changed Notification";


@implementation PagerDocument

- (id)init
{
  self = [super init];
  if (self) {

    isFile = NO;

    data = [[NSMutableData alloc] init];
    if (data == nil) {
      [self release];
      return nil;
    }

    storage = [[NSTextStorage alloc] init];
    if (storage == nil) {
      [data release];
      [self release];
      return nil;
    }

    applicableFormats = nil;
    parser = nil;

  }
  return self;
}

- (void)dealloc
{
  [storage release];
  [data release];
  if (applicableFormats != nil)
    [applicableFormats release];
  if (parser != nil)
    [parser release];

  [super dealloc];
}

// window title

- (NSString *)displayName
{
  if (isFile)
    return [super displayName];
  else
    return @"Standard Input";
}

// nib loading stuff

- (void)makeWindowControllers
{
  PagerWindowController *controller = [[PagerWindowController allocWithZone:
    [self zone]] init];
  [self addWindowController:controller];
  [controller release];
}

// file read and write

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
  // saving is not implemented
  return nil;
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
  isFile = YES;

  // start over completely
  [[storage mutableString] setString:@""];
  [data setLength:0];
  // even forget detected formats, leading to parser re-creation
  if (applicableFormats != nil) {
    [applicableFormats release];
    applicableFormats = nil;
  }

  // get the whole file and add it
  // TODO: instead, use NSFileHandle and async reading in chunks
  NSData *newData = [NSData dataWithContentsOfFile:fileName];
  [self addData:newData];

  return YES;
}

// data access

- (NSData *)data
{
  return data;
}

- (NSTextStorage *)storage
{
  return storage;
}

- (void)addData:(NSData *)newData
{
  // add to storage
  [data appendData:newData];

  if (applicableFormats == nil) {
    // first chunk: detect formats, create a parser, automatically consume all present data
    [self detectFormats];
  } else if (parser != nil) {
    // following chunks: notify the parser to resume from its last checkpoint
    [parser newData];
  }
  // if applicableFormats is present, but parser is not, then no format matched

  [[NSNotificationCenter defaultCenter] postNotificationName:StatusChangedNotification
                                                      object:self];
}

- (NSString *)statusLine
{
  NSMutableString *s = [NSMutableString string];

  unsigned len = [[self data] length];
  if (len < 1000) {
    [s appendFormat:@"%u bytes", len];
  } else {
    [s appendFormat:@"%u KB (%u bytes)", (len + 511) >> 10, len];
  }

  return s;
}

// parsing

+ (NSArray *)allFormats
{
  static NSArray *formats = nil;

  if (formats == nil) {
    NSMutableArray *a = [NSMutableArray array];

    // order here determines order in the popup menu
    [a addObject:[SmartTextInputParser class]];
    [a addObject:[RawTextInputParser class]];
    [a addObject:[HexdumpInputParser class]];

    formats = [a retain];
  }

  return formats;
}

- (NSArray *)applicableFormats
{
  return applicableFormats;
}

- (void)detectFormats
{
  // get list of known formats
  NSArray *formats = [PagerDocument allFormats];

  // filter those that apply
  NSMutableArray *a = [NSMutableArray array];
  unsigned i;
  int bestPriority = -1;
  Class bestFormat = nil;
  for (i = 0; i < [formats count]; i++) {
    Class format = [formats objectAtIndex:i];
    if ([format canReadData:[self data]]) {
      [a addObject:format];
      if (bestPriority < [format priority]) {
        bestPriority = [format priority];
        bestFormat = format;
      }
    }
  }
  applicableFormats = [a retain];

  // create a parser for the best choice
  [self setCurrentFormat:bestFormat];
}

- (Class)currentFormat
{
  if (parser != nil)
    return [parser class];
  return nil;
}

- (void)setCurrentFormat:(Class)format
{
  // kill old parser if present
  if (parser != nil) {
    if ([parser class] == format)
      return;  // no change
    [parser release];
    parser = nil;
  }

  // empty text storage before starting over
  [storage beginEditing];
  [[storage mutableString] setString:@""];
  [storage endEditing];

  // create new parser if format exists
  if (format != nil) {
    parser = [[format alloc] initWithDocument:self];
    // NOTE: the creation automatically invokes the parser on the present data
  }

  // update status line and format menu
  [[NSNotificationCenter defaultCenter] postNotificationName:StatusChangedNotification
                                                      object:self];
}

@end

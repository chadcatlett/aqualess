//
// PagerWindowController.h
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

@class FindPanelController;


@interface PagerWindowController : NSWindowController
{
  IBOutlet id display;
  IBOutlet id scroller;
  IBOutlet id status;
  IBOutlet id formatPopup;

  FindPanelController *findPanel;

  NSString *lastPattern;
  BOOL lastDirection;
}

- (NSTextStorage *)storage;

- (void)updateStatus:(NSNotification *)notification;

- (IBAction)changeFormat:(id)sender;

- (FindPanelController *)findPanel;

- (IBAction)showFindPanel:(id)sender;
- (IBAction)findAgainForwards:(id)sender;
- (IBAction)findAgainBackwards:(id)sender;
- (IBAction)findAgainSameDirection:(id)sender;
- (IBAction)findAgainOtherDirection:(id)sender;

- (void)findPanelDidEndWithPattern:(NSString *)pattern direction:(BOOL)back;

- (void)findPattern:(NSString *)pattern direction:(BOOL)back;

@end

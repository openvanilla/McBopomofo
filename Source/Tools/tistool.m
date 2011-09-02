//
// tistool.m
//
// Copyright (c) 2010-2011 Lukhnos D. Liu (lukhnos at lukhnos dot org)
// 
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#import "OVInputSourceHelper.h"

static void PrintUsage();

int main(int argc, char **argv)
{
	// we'll let the OS clean up this pool for us
	[NSAutoreleasePool new];
	
	if (argc < 2) {
		PrintUsage();
		return 1;
	}
	
	int opt;
	while ((opt = getopt(argc, argv, "lr:e:d:s:")) != -1) {
		switch (opt) {
			case 'l':
			{
				for (id source in [OVInputSourceHelper allInstalledInputSources]) {
					if (TISGetInputSourceProperty((TISInputSourceRef)source, kTISPropertyInputSourceType) != kTISTypeKeyboardInputMode) {					
						printf("%s\n", [(id)TISGetInputSourceProperty((TISInputSourceRef)source, kTISPropertyInputSourceID) UTF8String]);
					}
				}
				break;
			}
				
			case 'r':
			{
				NSURL *bundle = [NSURL fileURLWithPath:[NSString stringWithUTF8String:optarg]];
				if (bundle) {
					BOOL status = [OVInputSourceHelper registerInputSource:bundle];
					NSLog(@"register input source at: %@, result: %d", [bundle absoluteString], status);
				}
				break;
			}
				
				
			case 'e':
			{
				TISInputSourceRef inputSource = [OVInputSourceHelper inputSourceForInputSourceID:[NSString stringWithUTF8String:optarg]];
				if (!inputSource) {
					NSLog(@"Cannot find input source: %s", optarg);
					return 1;
				}
				
				BOOL status = [OVInputSourceHelper enableInputSource:inputSource];
				NSLog(@"Enable input source: %s, result: %d", optarg, status);
				return status;
			}

			case 'd':
			{
				TISInputSourceRef inputSource = [OVInputSourceHelper inputSourceForInputSourceID:[NSString stringWithUTF8String:optarg]];
				if (!inputSource) {
					NSLog(@"Cannot find input source: %s", optarg);
					return 1;
				}
				
				BOOL status = [OVInputSourceHelper disableInputSource:inputSource];
				NSLog(@"Disable input source: %s, result: %d", optarg, status);
				return status;
			}

			case 's':
			{
				TISInputSourceRef inputSource = [OVInputSourceHelper inputSourceForInputSourceID:[NSString stringWithUTF8String:optarg]];
				if (!inputSource) {
					NSLog(@"Cannot find input source: %s", optarg);
					return 1;
				}
				
				BOOL status = [OVInputSourceHelper inputSourceEnabled:inputSource];
				NSLog(@"Input source: %s, enabled: %@", optarg, (status ? @"yes" : @"no"));
				return 0;
			}
			default:
				PrintUsage();
				return 1;
		}
	}
	
	return 0;
}

static void PrintUsage()
{
	fprintf(stderr, "usage: tistool [options]\n"
			"options:\n"
			"    -l              list all input sources\n"
			"    -r <path>       register an input source\n"
			"    -e <id>         enable an input source\n"
			"    -d <id>         disable an input source\n"
			"    -s <id>         check if an input source is enabled\n\n"
			"<id> is an input source id, a few examples:\n"
			"    com.apple.inputmethod.Kotoeri (Apple's Japanese input method)\n"
			"    com.apple.CharacterPaletteIM (Keyboard/Character Viewer palettes)\n"
			"    com.apple.keylayout.German (German keyboard layout)\n"
			"\n"
	        "<path> must be a bundle in one of the directories:\n"
			"    ~/Library/Input Methods/\n"
			"    /Library/Input Methods/\n"
			"    ~/Library/Keyboard Layouts/\n"			
			"    /Library/Keyboard Layouts/\n"
			"\n"
			);
}

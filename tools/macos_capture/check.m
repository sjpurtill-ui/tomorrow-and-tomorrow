#import <AppKit/AppKit.h>
#include <dlfcn.h>
#include <stdio.h>

int main(void) {
    // Refuse to create even the canary window unless the guard is loaded first.
    int (*loaded)(void) = dlsym(RTLD_DEFAULT, "tt_capture_guard_loaded");
    if (!loaded || !loaded()) { fprintf(stderr, "TT_CAPTURE_CANARY_NO_GUARD\n"); return 2; }
    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 64, 64)
            styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
        window.releasedWhenClosed = NO;
        [window orderFront:nil]; [window makeKeyAndOrderFront:nil];
        [window orderFrontRegardless]; [window makeKeyWindow]; [window makeMainWindow];
        [window orderWindow:NSWindowAbove relativeTo:0];
        [NSApp activate];
        BOOL passed = !window.visible && !window.keyWindow && !window.mainWindow &&
            !NSApp.active && NSApp.activationPolicy == NSApplicationActivationPolicyProhibited;
        fprintf(stderr, "TT_CAPTURE_CANARY %s visible=%d active=%d policy=%ld\n",
            passed ? "PASS" : "FAIL", window.visible, NSApp.active, (long)NSApp.activationPolicy);
        [window close]; [window release];
        return passed ? 0 : 3;
    }
}

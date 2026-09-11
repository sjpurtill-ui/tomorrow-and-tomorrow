#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// Inject only into the private capture process. No installed app is modified.
static int loaded = 0;
static unsigned long blocked = 0;
static IMP original_policy;
static IMP original_order;

static void deny_action(id self, SEL cmd, id sender) { blocked++; }
static void deny_simple(id self, SEL cmd) { blocked++; }
static void deny_flag(id self, SEL cmd, BOOL flag) { blocked++; }
static BOOL deny_bool(id self, SEL cmd) { return NO; }
static BOOL deny_activation(id self, SEL cmd, NSApplicationActivationOptions options) { blocked++; return NO; }
static BOOL force_background(id self, SEL cmd, NSApplicationActivationPolicy policy) {
    return ((BOOL (*)(id, SEL, NSApplicationActivationPolicy))original_policy)(self, cmd, NSApplicationActivationPolicyProhibited);
}
static void deny_order(id self, SEL cmd, NSWindowOrderingMode place, NSInteger relative) {
    if (place == NSWindowOut) {
        ((void (*)(id, SEL, NSWindowOrderingMode, NSInteger))original_order)(self, cmd, place, relative);
    } else {
        blocked++;
    }
}
static IMP replace(Class cls, const char *name, IMP replacement) {
    Method method = class_getInstanceMethod(cls, sel_registerName(name));
    if (!method) { fprintf(stderr, "TT_CAPTURE_GUARD_MISSING %s\n", name); _exit(91); }
    return method_setImplementation(method, replacement);
}

int tt_capture_guard_loaded(void) { return loaded; }

__attribute__((constructor)) static void install(void) {
    const char *owner = getenv("TT_CAPTURE_OWNER");
    const char *program = getprogname();
    if (!owner || strcmp(owner, "canopy-transition") ||
        (strcmp(program, "GodotCanopyProbe") && strcmp(program, "CanopyGuardCheck"))) {
        fprintf(stderr, "TT_CAPTURE_GUARD_WRONG_PROCESS\n"); _exit(92);
    }
    Class win = objc_getClass("NSWindow");
    Class app = objc_getClass("NSApplication");
    original_order = replace(win, "orderWindow:relativeTo:", (IMP)deny_order);
    for (const char **name = (const char *[]){"orderFront:", "orderBack:", "makeKeyAndOrderFront:", "miniaturize:", "deminiaturize:", NULL}; *name; name++)
        replace(win, *name, (IMP)deny_action);
    for (const char **name = (const char *[]){"orderFrontRegardless", "makeKeyWindow", "makeMainWindow", NULL}; *name; name++)
        replace(win, *name, (IMP)deny_simple);
    replace(win, "canBecomeKeyWindow", (IMP)deny_bool);
    replace(win, "canBecomeMainWindow", (IMP)deny_bool);
    Method visible = class_getInstanceMethod(win, sel_registerName("setIsVisible:"));
    if (visible) method_setImplementation(visible, (IMP)deny_flag);
    original_policy = replace(app, "setActivationPolicy:", (IMP)force_background);
    replace(app, "activateIgnoringOtherApps:", (IMP)deny_flag);
    replace(app, "activate", (IMP)deny_simple);
    replace(app, "unhide:", (IMP)deny_action);
    replace(app, "unhideWithoutActivation", (IMP)deny_simple);
    replace(objc_getClass("NSRunningApplication"), "activateWithOptions:", (IMP)deny_activation);
    loaded = 1;
    fprintf(stderr, "TT_CAPTURE_GUARD_READY %s\n", program);
    fflush(stderr);
}

__attribute__((destructor)) static void report(void) {
    if (loaded) fprintf(stderr, "TT_CAPTURE_GUARD_STATS blocked=%lu\n", blocked);
}

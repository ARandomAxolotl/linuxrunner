// Host unit test for app/LinuxRunner/PointerPolicy.h.
//   cc -I app/LinuxRunner tests/linuxrunner/input/pointer_policy_test.c -o /tmp/pp && /tmp/pp
#include "PointerPolicy.h"
#include <stdio.h>
static int fails;
#define CHECK(name, cond) do { if (cond) printf("PASS %s\n", name); else { printf("FAIL %s\n", name); fails++; } } while (0)
int main(void) {
    LRPointerEnvironment none = {0}, iphone_at = {.assistive_touch = true, .gc_mouse = true},
        iphone_at_no_gc = {.assistive_touch = true}, gc_only = {.gc_mouse = true},
        ipad = {.gc_mouse = true, .indirect_pointer = true, .hover = true};
    CHECK("no mouse: touch gestures", !lr_pointer_mode(none));
    CHECK("forced pointer mode", lr_pointer_mode((LRPointerEnvironment){.mode = LR_MOUSE_MODE_POINTER}));
    CHECK("forced touch mode wins over mouse", !lr_pointer_mode((LRPointerEnvironment){.mode = LR_MOUSE_MODE_TOUCH, .gc_mouse = true}));
    CHECK("AssistiveTouch: pointer mode", lr_pointer_mode(iphone_at) && lr_pointer_mode(iphone_at_no_gc));
    CHECK("AssistiveTouch: GCMouse motion ignored (absolute touch positions)", !lr_pointer_use_gc_motion(iphone_at));
    CHECK("AssistiveTouch: left from touch, not GCMouse", !lr_pointer_use_gc_button(iphone_at, LR_POINTER_LEFT));
    CHECK("AssistiveTouch: right and middle from GCMouse", lr_pointer_use_gc_button(iphone_at, LR_POINTER_RIGHT) && lr_pointer_use_gc_button(iphone_at, LR_POINTER_MIDDLE));
    CHECK("AssistiveTouch without GCMouse: no GCMouse buttons", !lr_pointer_use_gc_button(iphone_at_no_gc, LR_POINTER_RIGHT));
    CHECK("GCMouse only: motion and all buttons", lr_pointer_use_gc_motion(gc_only) && lr_pointer_use_gc_button(gc_only, LR_POINTER_LEFT) && lr_pointer_use_gc_button(gc_only, LR_POINTER_RIGHT));
    CHECK("iPad pointer: UIKit only (no double clicks)", !lr_pointer_use_gc_motion(ipad) && !lr_pointer_use_gc_button(ipad, LR_POINTER_LEFT) && !lr_pointer_use_gc_button(ipad, LR_POINTER_RIGHT));
    CHECK("secondary mask is right button", lr_pointer_touch_button(true) == 4 && lr_pointer_touch_button(false) == 1);
    CHECK("UIKit wheel ignored right after GCMouse wheel", !lr_pointer_use_uikit_wheel(10.1, 10.0) && lr_pointer_use_uikit_wheel(10.5, 10.0));
    printf("POINTER_POLICY_TEST %s failures=%d\n", fails ? "FAIL" : "PASS", fails);
    return fails != 0;
}

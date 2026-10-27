#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static id dummy_nil(id self, SEL _cmd, ...) {
    return nil;
}

static NSInteger dummy_not_found(id self, SEL _cmd, ...) {
    return -1;
}

static double dummy_zero(id self, SEL _cmd, ...) {
    return 0.0;
}

__attribute__((constructor))
static void patch_appkit_divider(void) {
    Class root = [NSObject class];

    // * 修复新版 AppKit 在加载老旧 NIB 时的私有分割线方法缺失崩溃
    class_addMethod(root, sel_registerName("_leadingItemAtDividerIndex:"), (IMP)dummy_nil, "@@:q");
    class_addMethod(root, sel_registerName("_trailingItemAtDividerIndex:"), (IMP)dummy_nil, "@@:q");
    class_addMethod(root, sel_registerName("_splitViewItemAtDividerIndex:"), (IMP)dummy_nil, "@@:q");
    class_addMethod(root, sel_registerName("_dividerIndexForSplitViewItem:"), (IMP)dummy_not_found, "q@:@");
    class_addMethod(root, sel_registerName("sidebarDividerPosition"), (IMP)dummy_zero, "d@:");
    class_addMethod(root, sel_registerName("inspectorDividerPosition"), (IMP)dummy_zero, "d@:");
}

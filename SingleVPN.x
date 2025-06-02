#import <HBLog.h>
#import <dlfcn.h>
#import "Common.h"
#import "UIColor+.h"

#define IsNetworkTypeText(text) ( \
    [text isEqualToString:@"G"] || [text isEqualToString:@"3G"] || \
    [text isEqualToString:@"4G"] || [text isEqualToString:@"5G"] || \
    [text isEqualToString:@"LTE"])

#define decision (_isEnabledReversed ? !_isVPNEnabled : _isVPNEnabled)

static BOOL _isEnabled = NO;
static BOOL _isVPNEnabled = NO;
static BOOL _isEnabledReversed = NO;
static BOOL _isDisableAnimation = NO;
static UIColor *_darkReplacementColor = nil;
static UIColor *_lightReplacementColor = nil;
static VPNConnectionStore *_vpnStore = nil;

static UIColor *svpnColorWithHexString(NSString *hexString) {
    if (!hexString) {
        return nil;
    }
    return [UIColor svpn_colorWithExternalRepresentation:hexString];
}

static UIColor *svpnColorWithTextColor(UIColor *textColor) {
    return [textColor svpn_isDarkColor] ? _lightReplacementColor : _darkReplacementColor;
}

static void ReloadPrefs() {
    static NSUserDefaults *prefs = nil;
    if (!prefs) {
        prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.82flex.singlevpnprefs"];
    }

    NSDictionary *settings = [prefs dictionaryRepresentation];
    _isEnabled = settings[@"IsEnabled"] ? [settings[@"IsEnabled"] boolValue] : YES;
    _isEnabledReversed = settings[@"IsEnabledReversed"] ? [settings[@"IsEnabledReversed"] boolValue] : NO;
    _isDisableAnimation = settings[@"IsDisableAnimation"] ? [settings[@"IsDisableAnimation"] boolValue] : NO;

    _lightReplacementColor = svpnColorWithHexString(settings[@"ForegroundColorLight"]) ?: [UIColor colorWithRed:0.19607843137254902 green:0.7803921568627451 blue:0.34901960784313724 alpha:1];
    _darkReplacementColor = svpnColorWithHexString(settings[@"ForegroundColorDark"]) ?: [UIColor colorWithRed:0.17254901960784313 green:0.8156862745098039 blue:0.3411764705882353 alpha:1];
}

static BOOL checkVPNStatus(void) {
    BOOL status = NO;
    unsigned long long currentGrade = [_vpnStore currentOnlyConnectionGrade];
    VPNConnection *vpn = [_vpnStore currentConnectionWithGrade:currentGrade];
    if (!vpn) return status;
    if ([vpn status] == 3) status = YES;
    return status;
}

%group SingleVPN

%hook _UIStatusBarWifiItem

- (id)applyUpdate:(_UIStatusBarItemUpdate *)update toDisplayItem:(_UIStatusBarDisplayItem *)displayItem {
    _isVPNEnabled = checkVPNStatus();

    id result = %orig;

    UIColor *originalColor = update.styleAttributes.textColor;
    UIColor *newColor = nil;

    if (decision) newColor = svpnColorWithTextColor(originalColor);

    if (!newColor) { newColor = update.styleAttributes.imageTintColor ?: originalColor; }

    for (_UIStatusBarDisplayItem *item in self.displayItems.allValues) {
        %orig(update, item);

        if (item.view == self.networkIconView && [item.view isKindOfClass:%c(_UIStatusBarImageView)]) {
            _UIStatusBarImageView *imageView = (_UIStatusBarImageView *)item.view;
            [imageView setTintColor:newColor];
        }
    }

    return result;
}

- (UIColor *)_fillColorForUpdate:(_UIStatusBarItemUpdate *)update entry:(_UIStatusBarDataWifiEntry *)entry {
    return decision ? svpnColorWithTextColor(update.styleAttributes.textColor) : %orig;
}

%end

%hook _UIStatusBarCellularItem

- (id)applyUpdate:(_UIStatusBarItemUpdate *)update toDisplayItem:(_UIStatusBarDisplayItem *)displayItem {
    _isVPNEnabled = checkVPNStatus();

    id result = %orig;

    UIColor *originalColor = update.styleAttributes.textColor;
    UIColor *newColor = nil;

    if (decision) newColor = svpnColorWithTextColor(originalColor);

    if (!newColor) { newColor = originalColor; }

    for (_UIStatusBarDisplayItem *item in self.displayItems.allValues) {
        _UIStatusBarStringView *stringView = nil;

        if ([item.view isKindOfClass:%c(_UIStatusBarCellularNetworkTypeView)]) {
            stringView = ((_UIStatusBarCellularNetworkTypeView *)item.view).stringView;
        } else if ([item.view isKindOfClass:%c(_UIStatusBarStringView)]) {
            stringView = (_UIStatusBarStringView *)item.view;
        }

        if (IsNetworkTypeText(stringView.text)) {
            [stringView setTextColor:newColor];
        } else {
            [stringView setTextColor:originalColor];
        }
    }

    return result;
}

%end


%hook _UIStatusBarStringView

- (void)applyStyleAttributes:(_UIStatusBarStyleAttributes *)styleAttrs {
    %orig;

    if (decision && IsNetworkTypeText(self.text)) {
        [self setTextColor:svpnColorWithTextColor(styleAttrs.textColor)];
    }
}

%end

%end // SingleVPN

%group gDisableAnimation
%hook _UIStatusBarData
-(_UIStatusBarDataEntry *)vpnEntry{
    _UIStatusBarDataEntry *ret = %orig;
    ret.enabled = NO;
    return ret;
}
%end
%end


%ctor {
    ReloadPrefs();
    if (!_isEnabled) {
        return;
    }

    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(), 
        NULL, 
        (CFNotificationCallback)ReloadPrefs, 
        CFSTR("com.82flex.singlevpnprefs/saved"), 
        NULL, 
        CFNotificationSuspensionBehaviorCoalesce
    );

    if (_isDisableAnimation) %init(gDisableAnimation)

    NSString *bundlePath = @"/System/Library/PreferenceBundles/VPNPreferences.bundle";
    if(![[NSBundle bundleWithPath:bundlePath] load]){
        void *handle = dlopen([bundlePath UTF8String], RTLD_LAZY);
        if (!handle) return;
    }

    _vpnStore = [NSClassFromString(@"VPNConnectionStore") sharedInstance];
    if (_vpnStore) %init(SingleVPN);
}
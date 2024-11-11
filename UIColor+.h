#import <UIKit/UIKit.h>

@interface UIColor (SingleVPN)

+ (nullable instancetype)svpn_colorWithExternalRepresentation:(NSString *_Nonnull)externalRepresentation;
- (NSString *_Nonnull)svpn_externalRepresentation;
- (BOOL)svpn_isDarkColor;

@end
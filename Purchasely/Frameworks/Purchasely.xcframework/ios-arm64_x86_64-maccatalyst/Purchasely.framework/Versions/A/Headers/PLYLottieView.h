//
//  PLYLottieView.h
//  Purchasely-iOS
//
//  Created by Jean-François GRANG on 03/08/2021.
//

#ifndef PLYLottieView_h
#define PLYLottieView_h

#import <UIKit/UIKit.h>

@protocol LottieBridgeProtocol <NSObject>
- (UIView * _Nullable) view;
- (void)loop:(BOOL)loop;
- (void)fill:(BOOL)fill;
- (void)play;
- (void)pause;
- (void)stop;
@end

@interface PLYLottieView : UIView

- (void)configureWithURL:(NSURL * _Nonnull)url;

@property(nonatomic, retain) NSObject<LottieBridgeProtocol>  * _Nullable bridge;
@property(nonatomic, retain) UIView  * _Nullable lottieView;

@end

#endif /* PLYLottieView_h */

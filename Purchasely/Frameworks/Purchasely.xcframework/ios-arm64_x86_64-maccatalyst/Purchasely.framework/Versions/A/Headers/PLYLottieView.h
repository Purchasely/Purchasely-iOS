//
//  PLYLottieView.h
//  Purchasely-iOS
//
//  Created by Jean-François GRANG on 03/08/2021.
//

#ifndef PLYLottieView_h
#define PLYLottieView_h

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

@end

#endif /* PLYLottieView_h */

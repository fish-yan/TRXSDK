#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^TRXSDKGRPCDataCompletion)(NSData *_Nullable responseData, NSError *_Nullable error);

NS_SWIFT_NAME(TRXSDKGRPCClient)
@interface TRXSDKGRPCClient : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithHost:(NSString *)host NS_DESIGNATED_INITIALIZER;

- (void)getAccountWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion
    NS_SWIFT_NAME(getAccount(requestData:completion:));
- (void)getAccountResourceWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion
    NS_SWIFT_NAME(getAccountResource(requestData:completion:));
- (void)createTransactionWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion
    NS_SWIFT_NAME(createTransaction(requestData:completion:));
- (void)broadcastTransactionWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion
    NS_SWIFT_NAME(broadcastTransaction(requestData:completion:));
- (void)transferAssetWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion
    NS_SWIFT_NAME(transferAsset(requestData:completion:));
- (void)triggerContractWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion
    NS_SWIFT_NAME(triggerContract(requestData:completion:));
- (void)freezeBalanceWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion
    NS_SWIFT_NAME(freezeBalance(requestData:completion:));
- (void)unfreezeBalanceWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion
    NS_SWIFT_NAME(unfreezeBalance(requestData:completion:));

@end

NS_ASSUME_NONNULL_END

#import "TRXSDKGRPCClient.h"

#import <grpc/byte_buffer.h>
#import <grpc/byte_buffer_reader.h>
#import <grpc/credentials.h>
#import <grpc/grpc.h>
#import <grpc/slice.h>
#import <grpc/support/time.h>

static NSString *const TRXSDKGRPCErrorDomain = @"TRXSDKGRPCError";
static const int64_t TRXSDKGRPCTimeoutSeconds = 30;

@interface TRXSDKGRPCClient ()

@property(nonatomic, copy) NSString *host;
@property(nonatomic) grpc_channel *channel;
@property(nonatomic) dispatch_queue_t queue;

@end

@implementation TRXSDKGRPCClient

- (instancetype)initWithHost:(NSString *)host {
    self = [super init];
    if (self) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            grpc_init();
        });

        _host = [host copy];
        _queue = dispatch_queue_create("com.trxsdk.grpc-node-client", DISPATCH_QUEUE_SERIAL);

        grpc_channel_credentials *credentials = grpc_insecure_credentials_create();
        _channel = grpc_channel_create(host.UTF8String, credentials, NULL);
        grpc_channel_credentials_release(credentials);
    }
    return self;
}

- (void)dealloc {
    if (_channel != NULL) {
        grpc_channel_destroy(_channel);
    }
}

- (void)getAccountWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion {
    [self performMethod:@"/protocol.Wallet/GetAccount" requestData:requestData completion:completion];
}

- (void)getAccountResourceWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion {
    [self performMethod:@"/protocol.Wallet/GetAccountResource" requestData:requestData completion:completion];
}

- (void)createTransactionWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion {
    [self performMethod:@"/protocol.Wallet/CreateTransaction" requestData:requestData completion:completion];
}

- (void)broadcastTransactionWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion {
    [self performMethod:@"/protocol.Wallet/BroadcastTransaction" requestData:requestData completion:completion];
}

- (void)transferAssetWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion {
    [self performMethod:@"/protocol.Wallet/TransferAsset2" requestData:requestData completion:completion];
}

- (void)triggerContractWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion {
    [self performMethod:@"/protocol.Wallet/TriggerContract" requestData:requestData completion:completion];
}

- (void)freezeBalanceWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion {
    [self performMethod:@"/protocol.Wallet/FreezeBalance2" requestData:requestData completion:completion];
}

- (void)unfreezeBalanceWithRequestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion {
    [self performMethod:@"/protocol.Wallet/UnfreezeBalance2" requestData:requestData completion:completion];
}

#pragma mark - Raw unary call

- (void)performMethod:(NSString *)method requestData:(NSData *)requestData completion:(TRXSDKGRPCDataCompletion)completion {
    dispatch_async(self.queue, ^{
        NSError *error = nil;
        NSData *responseData = [self blockingUnaryMethod:method requestData:requestData error:&error];
        completion(responseData, error);
    });
}

- (NSData *)blockingUnaryMethod:(NSString *)method requestData:(NSData *)requestData error:(NSError **)error {
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(TRXSDKGRPCTimeoutSeconds, GPR_TIMESPAN)
    );

    grpc_completion_queue *completionQueue = grpc_completion_queue_create_for_next(NULL);
    grpc_slice methodSlice = grpc_slice_from_copied_string(method.UTF8String);
    grpc_call *call = grpc_channel_create_call(
        self.channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        completionQueue,
        methodSlice,
        NULL,
        deadline,
        NULL
    );
    grpc_slice_unref(methodSlice);

    if (call == NULL) {
        grpc_completion_queue_shutdown(completionQueue);
        grpc_completion_queue_destroy(completionQueue);
        if (error != NULL) {
            *error = [self errorWithCode:-1 reason:@"Unable to create gRPC call"];
        }
        return nil;
    }

    grpc_slice requestSlice = grpc_slice_from_copied_buffer(requestData.bytes, requestData.length);
    grpc_byte_buffer *requestBuffer = grpc_raw_byte_buffer_create(&requestSlice, 1);
    grpc_slice_unref(requestSlice);

    grpc_metadata_array initialMetadata;
    grpc_metadata_array trailingMetadata;
    grpc_metadata_array_init(&initialMetadata);
    grpc_metadata_array_init(&trailingMetadata);

    grpc_byte_buffer *responseBuffer = NULL;
    grpc_status_code status = GRPC_STATUS_UNKNOWN;
    grpc_slice statusDetails = grpc_empty_slice();

    grpc_op operations[6];
    memset(operations, 0, sizeof(operations));
    operations[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    operations[0].data.send_initial_metadata.count = 0;
    operations[1].op = GRPC_OP_SEND_MESSAGE;
    operations[1].data.send_message.send_message = requestBuffer;
    operations[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    operations[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    operations[3].data.recv_initial_metadata.recv_initial_metadata = &initialMetadata;
    operations[4].op = GRPC_OP_RECV_MESSAGE;
    operations[4].data.recv_message.recv_message = &responseBuffer;
    operations[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    operations[5].data.recv_status_on_client.trailing_metadata = &trailingMetadata;
    operations[5].data.recv_status_on_client.status = &status;
    operations[5].data.recv_status_on_client.status_details = &statusDetails;

    grpc_call_error callError = grpc_call_start_batch(call, operations, 6, (__bridge void *)self, NULL);
    grpc_byte_buffer_destroy(requestBuffer);

    NSData *responseData = nil;
    if (callError != GRPC_CALL_OK) {
        if (error != NULL) {
            *error = [self errorWithCode:callError reason:@"Unable to start gRPC call"];
        }
    } else {
        grpc_event event = grpc_completion_queue_next(completionQueue, deadline, NULL);
        if (event.type != GRPC_OP_COMPLETE || !event.success) {
            if (error != NULL) {
                *error = [self errorWithCode:-2 reason:@"gRPC call did not complete"];
            }
        } else if (status != GRPC_STATUS_OK) {
            if (error != NULL) {
                *error = [self errorWithCode:status reason:[self stringWithSlice:statusDetails]];
            }
        } else if (responseBuffer == NULL) {
            if (error != NULL) {
                *error = [self errorWithCode:-3 reason:@"Missing gRPC response message"];
            }
        } else {
            responseData = [self dataWithByteBuffer:responseBuffer];
        }
    }

    if (responseBuffer != NULL) {
        grpc_byte_buffer_destroy(responseBuffer);
    }
    grpc_slice_unref(statusDetails);
    grpc_metadata_array_destroy(&initialMetadata);
    grpc_metadata_array_destroy(&trailingMetadata);
    grpc_call_unref(call);
    grpc_completion_queue_shutdown(completionQueue);
    grpc_completion_queue_destroy(completionQueue);

    return responseData;
}

- (NSData *)dataWithByteBuffer:(grpc_byte_buffer *)byteBuffer {
    NSMutableData *data = [NSMutableData data];
    grpc_byte_buffer_reader reader;
    if (!grpc_byte_buffer_reader_init(&reader, byteBuffer)) {
        return data;
    }

    grpc_slice slice;
    while (grpc_byte_buffer_reader_next(&reader, &slice)) {
        [data appendBytes:GRPC_SLICE_START_PTR(slice) length:GRPC_SLICE_LENGTH(slice)];
        grpc_slice_unref(slice);
    }
    grpc_byte_buffer_reader_destroy(&reader);
    return data;
}

- (NSString *)stringWithSlice:(grpc_slice)slice {
    if (GRPC_SLICE_LENGTH(slice) == 0) {
        return @"gRPC call failed";
    }
    return [[NSString alloc] initWithBytes:GRPC_SLICE_START_PTR(slice)
                                    length:GRPC_SLICE_LENGTH(slice)
                                  encoding:NSUTF8StringEncoding] ?: @"gRPC call failed";
}

- (NSError *)errorWithCode:(NSInteger)code reason:(NSString *)reason {
    return [NSError errorWithDomain:TRXSDKGRPCErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: reason}];
}

@end

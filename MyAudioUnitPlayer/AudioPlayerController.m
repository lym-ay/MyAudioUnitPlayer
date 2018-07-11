//
//  AudioPlayerController.m
//  MusicDemo
//
//  Created by olami on 2018/7/10.
//  Copyright © 2018年 VIA Technologies, Inc. & OLAMI Team. All rights reserved.
//

#import "AudioPlayerController.h"
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AFNetworking.h"
#import "MusicData.h"



static void YMAudioFileStreamPropertyListener(void* inClientData,
                                            AudioFileStreamID inAudioFileStream,
                                            AudioFileStreamPropertyID inPropertyID,
                                            UInt32* ioFlags);
static void YMAudioFileStreamPacketsCallBack(void* inClientData,
                                             UInt32 inNumberBytes,
                                             UInt32 inNumberPackets,
                                             const void* inInputData,
                                             AudioStreamPacketDescription *inPacketDescriptions);
static OSStatus YMPlayerAURenderCallback(void *userData,
                                         AudioUnitRenderActionFlags *ioActionFlags,
                                         const AudioTimeStamp *inTimeStamp,
                                         UInt32 inBusNumber,
                                         UInt32 inNumberFrames,
                                         AudioBufferList *ioData);
static OSStatus YMPlayerConverterFiller(AudioConverterRef inAudioConverter,
                                        UInt32* ioNUmberDataPackets,
                                        AudioBufferList *ioData,
                                        AudioStreamPacketDescription **outDataPacketDescription,
                                        void *inUserData);

static AudioStreamBasicDescription YMSignedIntLinearPCMStreamDescription();

@interface AudioPlayerController(){
    AudioComponentDescription outputUnitDescription;
    AUGraph audioGraph;
    AudioUnit mixerUnit;
    AudioUnit EQUnit;
    AudioUnit outputUnit;
    
    AudioFileStreamID audioFileStreamID;
    AudioStreamBasicDescription streamDescription;
    AudioConverterRef converter;
    AudioBufferList *renderBufferList;
    UInt32 renderBufferSize;
    
    NSMutableArray *packets;
    size_t readHead;
    
    NSURLConnection *URLConnection;
    double elcipseTime;
    UInt64 downloadBytes;//当前下载的数据的量
    
   
}
@property (nonatomic ,assign) double duration;
@property (nonatomic ,assign) UInt64 audioDataByteCount;
@property (nonatomic ,assign) UInt32 bitRate;
@property (nonatomic, strong) NSTimer *timer;

@end

AudioStreamBasicDescription YMSignedIntLinearPCMStreamDescription(){
    AudioStreamBasicDescription desFormat;
    memset(&desFormat, 0, sizeof(AudioStreamBasicDescription));
    
    desFormat.mSampleRate = 44100;
    desFormat.mFormatID = kAudioFormatLinearPCM;
    desFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    desFormat.mFramesPerPacket= 1;
    desFormat.mBitsPerChannel = 16;
    desFormat.mChannelsPerFrame = 2;
    desFormat.mBytesPerFrame = desFormat.mBitsPerChannel/8 *desFormat.mChannelsPerFrame;
    desFormat.mBytesPerPacket = desFormat.mBytesPerFrame *desFormat.mFramesPerPacket;
    desFormat.mReserved = 0;
    return desFormat;
}

@implementation AudioPlayerController
- (void)buildOutput{
    OSStatus status = NewAUGraph(&audioGraph);
    status = AUGraphOpen(audioGraph);
    
    //create mixerNode
    AudioComponentDescription mixerUnitDescription;
    mixerUnitDescription.componentType = kAudioUnitType_Mixer;
    mixerUnitDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixerUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    mixerUnitDescription.componentFlags = 0;
    mixerUnitDescription.componentFlagsMask = 0;
    AUNode mixerNode;
    status = AUGraphAddNode(audioGraph, &mixerUnitDescription, &mixerNode);
    
    //create EQNode
    AudioComponentDescription EQUnitDescription;
    EQUnitDescription.componentType = kAudioUnitType_Effect;
    EQUnitDescription.componentSubType = kAudioUnitSubType_AUiPodEQ;
    EQUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    EQUnitDescription.componentFlags = 0;
    EQUnitDescription.componentFlagsMask = 0;
    AUNode EQNode;
    status = AUGraphAddNode(audioGraph, &EQUnitDescription, &EQNode);
    
    
    //creat remote IO node;
    AudioComponentDescription outputUnitDescription;
    memset(&outputUnitDescription, 0, sizeof(AudioComponentDescription));
    outputUnitDescription.componentType = kAudioUnitType_Output;
    outputUnitDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    outputUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    outputUnitDescription.componentFlagsMask = 0;
    outputUnitDescription.componentFlags = 0;
    AUNode outputNode;
    status = AUGraphAddNode(audioGraph, &outputUnitDescription, &outputNode);
    
    //连接node
    status = AUGraphConnectNodeInput(audioGraph, mixerNode, 0, EQNode, 0);
    status = AUGraphConnectNodeInput(audioGraph, EQNode, 0, outputNode, 0);
    
    //生成unit
    status = AUGraphNodeInfo(audioGraph, mixerNode, &mixerUnitDescription, &mixerUnit);
    status = AUGraphNodeInfo(audioGraph, EQNode, &EQUnitDescription, &EQUnit);
    status = AUGraphNodeInfo(audioGraph, outputNode, &outputUnitDescription, &outputUnit);
    
    //设置mixnode的输入输出格式
    AudioStreamBasicDescription audioFormat = YMSignedIntLinearPCMStreamDescription();
    status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &audioFormat, sizeof(audioFormat));
     status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &audioFormat, sizeof(audioFormat));
    
    //设置EQNode的输入输出属性
    status = AudioUnitSetProperty(EQUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &audioFormat, sizeof(audioFormat));
    status = AudioUnitSetProperty(EQUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &audioFormat, sizeof(audioFormat));
    
    //设置Remote IO node的输出属性
    status = AudioUnitSetProperty(outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &audioFormat, sizeof(audioFormat));
    
    // 設定 maxFPS
    UInt32 maxFPS = 4096;
    status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0,&maxFPS, sizeof(maxFPS));
    NSAssert(noErr == status, @"We need to set the maximum FPS to the mixer node. %d", (int)status);
    status = AudioUnitSetProperty(EQUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0,&maxFPS, sizeof(maxFPS));
    NSAssert(noErr == status, @"We need to set the maximum FPS to the EQ effect node. %d", (int)status);
    status = AudioUnitSetProperty(outputUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0,&maxFPS, sizeof(maxFPS));
    NSAssert(noErr == status, @"We need to set the maximum FPS to the EQ effect node. %d", (int)status);
    
    //设置render callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    callbackStruct.inputProc =  YMPlayerAURenderCallback;
    status = AUGraphSetNodeInputCallback(audioGraph, mixerNode, 0, &callbackStruct);
    
    status = AUGraphInitialize(audioGraph);
    
    //设置converter要使用的buffer list;
    UInt32 bufferSize = 4096*4;
    renderBufferSize = bufferSize;
    renderBufferList = (AudioBufferList*)calloc(1, sizeof(UInt32)+sizeof(AudioBuffer));
    renderBufferList->mNumberBuffers = 1;
    renderBufferList->mBuffers[0].mData = calloc(1, bufferSize);
    renderBufferList->mBuffers[0].mDataByteSize = bufferSize;
    renderBufferList->mBuffers[0].mNumberChannels = 2;
    
    CAShow(audioGraph);
}

- (id)init{
    if (self = [super init]) {
       _songStatus =  StopStatus;
        self.audioDataByteCount = 0;
    }
    
    return self;
}

- (void)playIndex:(NSUInteger) index{
    if (URLConnection) {
        [self freeData];
    }
    
    MusicData *data = self.musicDataArray[index];
   
    _index = index;
    [self buildOutput];
    packets = [[NSMutableArray alloc] init];
    AudioFileStreamOpen((__bridge void * _Nullable)(self), YMAudioFileStreamPropertyListener, YMAudioFileStreamPacketsCallBack, kAudioFileMP3Type, &audioFileStreamID);
    
    URLConnection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:data.songUrl] delegate:self];
    
   
    
  
}



- (void)play{
    OSStatus status = AUGraphStart(audioGraph);
    status = AudioOutputUnitStart(outputUnit);
    _songStatus = PlayStatus;
}



- (void)setMusicDataArray:(NSArray *)musicDataArray{
    _musicDataArray = [musicDataArray copy];
}



#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        if ([(NSHTTPURLResponse *)response statusCode] != 200) {
            NSLog(@"HTTP code:%ld", [(NSHTTPURLResponse *)response statusCode]);
            [connection cancel];
            _songStatus = StopStatus;
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
//     第二步：抓到了部分檔案，就交由 Audio Parser 開始 parse 出 data
//     stream 中的 packet。
    AudioFileStreamParseBytes(audioFileStreamID, (UInt32)[data length], [data bytes], 0);
    downloadBytes += (UInt64)[data length];
    if (self.audioDataByteCount != 0) {
        self.duration = self.audioDataByteCount *8/self.bitRate;
        NSTimeInterval progress = downloadBytes/self.audioDataByteCount;
        [self.delegate updatePrograssBar:progress];
    }
 
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"Complete loading data");
    //playerStatus.loaded = YES;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Failed to load data: %@", [error localizedDescription]);
    _songStatus = StopStatus;
}


- (double)packetsPerSecond{
    if (streamDescription.mFramesPerPacket) {
        return streamDescription.mSampleRate / streamDescription.mFramesPerPacket;
    }
    return 44100.0/1152.0;
}

- (void)freeData{
    readHead = 0;
    
    AUGraphUninitialize(audioGraph);
    AUGraphClose(audioGraph);
    DisposeAUGraph(audioGraph);
    audioGraph = NULL;
    
    mixerUnit = NULL;
    EQUnit = NULL;
    outputUnit = NULL;
    
    AudioFileStreamClose(audioFileStreamID);
    AudioConverterDispose(converter);
    converter = NULL;
    free(renderBufferList->mBuffers[0].mData);
    free(renderBufferList);
    renderBufferList = NULL;
    
    [packets removeAllObjects];
    
    [URLConnection cancel];
    URLConnection = nil;
    
    _songStatus = StopStatus;
    
    memset(&streamDescription, 0, sizeof(AudioStreamBasicDescription));
    
    [self.timer invalidate];
    self.timer = nil;
    elcipseTime = 0.0f;
    
    downloadBytes = 0;
}

- (void)dealloc
{
    [self freeData];
}

void YMAudioFileStreamPropertyListener(void* inClientData,
                                              AudioFileStreamID inAudioFileStream,
                                              AudioFileStreamPropertyID inPropertyID,
                                              UInt32* ioFlags){
    AudioPlayerController *self = (__bridge AudioPlayerController *)(inClientData);
    NSLog(@"inPropertyID is %u",inPropertyID);
    
    if (inPropertyID == kAudioFileStreamProperty_FileFormat) {
        NSLog(@"1");
        
    }else if (inPropertyID == kAudioFileStreamProperty_FormatList){
           NSLog(@"2");
    }else if (inPropertyID == kAudioFileStreamProperty_MagicCookieData){
           NSLog(@"3");
    }else if (inPropertyID == kAudioFileStreamProperty_AudioDataPacketCount){
           NSLog(@"4");
    }else if (inPropertyID == kAudioFileStreamProperty_MaximumPacketSize){
           NSLog(@"5");
    }else if (inPropertyID == kAudioFileStreamProperty_DataOffset){
           NSLog(@"6");
    }else if (inPropertyID == kAudioFileStreamProperty_ChannelLayout){
           NSLog(@"7");
    }else if (inPropertyID == kAudioFileStreamProperty_PacketToFrame){
           NSLog(@"8");
    }else if (inPropertyID == kAudioFileStreamProperty_FrameToPacket){
           NSLog(@"9");
    }else if (inPropertyID == kAudioFileStreamProperty_PacketToByte){
           NSLog(@"10");
    }else if (inPropertyID == kAudioFileStreamProperty_ByteToPacket){
           NSLog(@"11");
    }else if (inPropertyID == kAudioFileStreamProperty_PacketTableInfo){
           NSLog(@"12");
    }else if (inPropertyID == kAudioFileStreamProperty_PacketSizeUpperBound){
           NSLog(@"13");
    }else if (inPropertyID == kAudioFileStreamProperty_AverageBytesPerPacket){
           NSLog(@"14");
    }else if (inPropertyID == kAudioFileStreamProperty_InfoDictionary){
           NSLog(@"15");
    }else if (inPropertyID == kAudioFileStreamProperty_DataFormat) {
        NSLog(@"16");
        UInt32 dataSize=0;
        OSStatus status = 0;
        AudioStreamBasicDescription audioStreamDescription;
        Boolean wirteable = false;
        status = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &dataSize, &wirteable);
        status = AudioFileStreamGetProperty(inAudioFileStream, inPropertyID, &dataSize, &audioStreamDescription);
//        NSLog(@"mSampleRate: %f", audioStreamDescription.mSampleRate);
//        NSLog(@"mFormatID: %u", audioStreamDescription.mFormatID);
//        NSLog(@"mFormatFlags: %u", audioStreamDescription.mFormatFlags);
//        NSLog(@"mBytesPerPacket: %u", audioStreamDescription.mBytesPerPacket);
//        NSLog(@"mFramesPerPacket: %u", audioStreamDescription.mFramesPerPacket);
//        NSLog(@"mBytesPerFrame: %u", audioStreamDescription.mBytesPerFrame);
//        NSLog(@"mChannelsPerFrame: %u", audioStreamDescription.mChannelsPerFrame);
//        NSLog(@"mBitsPerChannel: %u", audioStreamDescription.mBitsPerChannel);
//        NSLog(@"mReserved: %u", audioStreamDescription.mReserved);
        
        [self _createAudioQueueWithAudioStreamDescription:&audioStreamDescription];
        
    }else if(inPropertyID == kAudioFileStreamProperty_BitRate){
           NSLog(@"17");
        UInt32 bitRate;
        UInt32 bitRateSize = sizeof(bitRate);
        OSStatus status = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_BitRate, &bitRateSize, &bitRate);
        if (status != noErr) {
            
        }else{
             self.bitRate = bitRate;
        }
        
       
    }else if(inPropertyID == kAudioFileStreamProperty_AudioDataByteCount){
           NSLog(@"18");
        UInt64 audioDataByteCount;
        UInt32 byteCountSize = sizeof(audioDataByteCount);
        OSStatus status = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_AudioDataByteCount, &byteCountSize, &audioDataByteCount);
        if (status != noErr)
        {
            //错误处理
        }else {
            self.audioDataByteCount = audioDataByteCount;
        }
    }else if (inPropertyID == kAudioFileStreamProperty_ReadyToProducePackets){
        NSLog(@"19");
    }
    
}

- (void)_createAudioQueueWithAudioStreamDescription:(AudioStreamBasicDescription *)audioStreamBasicDescription
{
   
    memcpy(&streamDescription, audioStreamBasicDescription, sizeof(AudioStreamBasicDescription));
    AudioStreamBasicDescription destFormat = YMSignedIntLinearPCMStreamDescription();
    AudioConverterNew(&streamDescription, &destFormat, &converter);
}



void YMAudioFileStreamPacketsCallBack(void* inClientData,
                                             UInt32 inNumberBytes,
                                             UInt32 inNumberPackets,
                                             const void* inInputData,
                                             AudioStreamPacketDescription *inPacketDescriptions){
 
    AudioPlayerController *self =  (__bridge AudioPlayerController *)(inClientData);
    [self _storePacketsWithNumberOfBytes:inNumberBytes numberOfPackets:inNumberPackets inputData:inInputData packetDescriptions:inPacketDescriptions];
    
}

- (void)_storePacketsWithNumberOfBytes:(UInt32)inNumberBytes
                       numberOfPackets:(UInt32)inNumberPackets
                             inputData:(const void *)inInputData
                    packetDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions
{
    
    
    for (int i = 0; i < inNumberPackets; ++i) {
        SInt64 packetStart = inPacketDescriptions[i].mStartOffset;
        UInt32 packetSize = inPacketDescriptions[i].mDataByteSize;
        assert(packetSize > 0);
        NSData *packet = [NSData dataWithBytes:inInputData + packetStart length:packetSize];
        [packets addObject:packet];
    }
    NSLog(@"packets count is %lu",(unsigned long)packets.count);
    //  第五步，因為 parse 出來的 packets 夠多，緩衝內容夠大，因此開始
    //  播放
    
    if (readHead == 0 && [packets count] > (int)([self packetsPerSecond] * 3)) {
        if (_songStatus == StopStatus) {
            [self play];
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(addone) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:UITrackingRunLoopMode];
        }
    }
}

- (void)addone{
    
    [self.delegate setCurrentTime:elcipseTime++ duration:self.duration];
}

OSStatus YMPlayerAURenderCallback(void *userData,
                                         AudioUnitRenderActionFlags *ioActionFlags,
                                         const AudioTimeStamp *inTimeStamp,
                                         UInt32 inBusNumber,
                                         UInt32 inNumberFrames,
                                         AudioBufferList *ioData){
 
    AudioPlayerController *self = (__bridge AudioPlayerController *)(userData);
    OSStatus status = [self callbackWithNumberOfFrames:inNumberFrames ioData:ioData busNumber:inBusNumber];
    if (status != noErr) {
        ioData->mNumberBuffers = 0;
        *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
    }
    
    return status;
    
}

- (OSStatus)callbackWithNumberOfFrames:(UInt32)inNumberOfFrames
                                ioData:(AudioBufferList  *)inIoData busNumber:(UInt32)inBusNumber
{
    @synchronized(self) {
        if (readHead < [packets count]) {
            @autoreleasepool {
                UInt32 packetSize = inNumberOfFrames;
                // 第七步： Remote IO node 的 render callback 中，呼叫 converter 將 packet 轉成 LPCM
                OSStatus status =
                AudioConverterFillComplexBuffer(converter,
                                                YMPlayerConverterFiller,
                                                (__bridge void *)(self),
                                                &packetSize, renderBufferList, NULL);
                
                if (noErr != status) {
                    [self pause];
                    return -1;
                }
                else if (!packetSize) {
                    inIoData->mNumberBuffers = 0;
                }
                else {
                    inIoData->mNumberBuffers = 1;
                    inIoData->mBuffers[0].mNumberChannels = 2;
                    inIoData->mBuffers[0].mDataByteSize = renderBufferList->mBuffers[0].mDataByteSize;
                   
                    inIoData->mBuffers[0].mData = renderBufferList->mBuffers[0].mData;
                    renderBufferList->mBuffers[0].mDataByteSize = renderBufferSize;
                }
            }
        }
        else {
            inIoData->mNumberBuffers = 0;
            return -1;
        }
    }
    
    return noErr;
}

OSStatus YMPlayerConverterFiller(AudioConverterRef inAudioConverter,
                                        UInt32* ioNUmberDataPackets,
                                        AudioBufferList *ioData,
                                        AudioStreamPacketDescription** outDataPacketDescription,
                                        void *inUserData){
    AudioPlayerController *self = (__bridge AudioPlayerController *)(inUserData);
    OSStatus status = [self _fillConverterBufferWithBufferlist:ioData packetDescription:outDataPacketDescription];
    return status;
}

- (OSStatus)_fillConverterBufferWithBufferlist:(AudioBufferList *)ioData
                             packetDescription:(AudioStreamPacketDescription** )outDataPacketDescription
{
    static AudioStreamPacketDescription aspdesc;
    
    if (readHead >= [packets count]) {
        return 0;
    }
    
    ioData->mNumberBuffers = 1;
    NSData *packet = packets[readHead];
    void const *data = [packet bytes];
    UInt32 length = (UInt32)[packet length];
    ioData->mBuffers[0].mData = (void *)data;
    ioData->mBuffers[0].mDataByteSize = length;
    
    *outDataPacketDescription = &aspdesc;
    aspdesc.mDataByteSize = length;
    aspdesc.mStartOffset = 0;
    aspdesc.mVariableFramesInPacket = 1;
    
    readHead++;
    return 0;
}


- (void)pause{
    
}
- (void)stop{
    
}
- (void)prevSong{
    if (_index == 0) {
        //如果是第一首，就播放最后一首
        _index = _musicDataArray.count -1;
    }else{
        _index--;
    }
    
    [self playIndex:_index];
}

- (void)nextSong{
    if (_index == _musicDataArray.count -1) {
        //如果是最后一首，播放第一首
        _index = 0;
    }else{
        _index++;
    }
    [self playIndex:_index];
}

- (void)seekToTime:(NSTimeInterval)time{
     elcipseTime = time;
    double packDuration = streamDescription.mFramesPerPacket/streamDescription.mSampleRate;
    size_t seekToPacket = time/packDuration;
    readHead = seekToPacket;
}
- (void)seekStart{
    [self.timer setFireDate:[NSDate distantFuture]];
}
- (void)seekEnd{
    [self.timer setFireDate:[NSDate distantPast]];
}

@end

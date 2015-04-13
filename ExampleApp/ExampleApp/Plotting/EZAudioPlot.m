//
//  EZAudioPlot.m
//  EZAudio
//
//  Created by Syed Haris Ali on 9/2/13.
//  Copyright (c) 2013 Syed Haris Ali. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "EZAudioPlot.h"
#import <AudioToolbox/AudioToolbox.h>

@interface EZAudioPlot () {
    //  BOOL             _hasData;
    //  TPCircularBuffer _historyBuffer;
    
    // Rolling History
    BOOL    _setMaxLength;
    float   *_scrollHistory;
    int     _scrollHistoryIndex;
    UInt32  _scrollHistoryLength;
    BOOL    _changingHistorySize;
}
@end

@implementation EZAudioPlot
@synthesize backgroundColor = _backgroundColor;
@synthesize color           = _color;
@synthesize gain            = _gain;
@synthesize plotType        = _plotType;
@synthesize shouldFill      = _shouldFill;
@synthesize shouldMirror    = _shouldMirror;

#pragma mark - Initialization

-(id)init {
    self = [super init];
    if(self){
        [self initPlot];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self){
        [self initPlot];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frameRect {
    self = [super initWithFrame:frameRect];
    if(self){
        [self initPlot];
    }
    return self;
}

-(void)initPlot {
    self.backgroundColor = [UIColor blackColor];
    self.color           = [UIColor whiteColor];
    self.gain            = 2.0;
    self.plotType        = EZPlotTypeRolling;
    self.shouldMirror    = NO;
    self.shouldFill      = NO;
    plotData             = NULL;
    _scrollHistory       = NULL;
    _scrollHistoryLength = kEZAudioPlotDefaultHistoryBufferLength;
}

#pragma mark - Setter Methods

-(void)setBackgroundColor:(id)backgroundColor {
    _backgroundColor = backgroundColor;
    [self _refreshDisplay];
}

-(void)setColor:(id)color {
    _color = color;
    [self _refreshDisplay];
}

-(void)setGain:(float)gain {
    _gain = gain;
    [self _refreshDisplay];
}

-(void)setPlotType:(EZPlotType)plotType {
    _plotType = plotType;
    [self _refreshDisplay];
}

-(void)setShouldFill:(BOOL)shouldFill {
    _shouldFill = shouldFill;
    [self _refreshDisplay];
}

-(void)setShouldMirror:(BOOL)shouldMirror {
    _shouldMirror = shouldMirror;
    [self _refreshDisplay];
}

-(void)_refreshDisplay {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsDisplay];
    });
}

#pragma mark - Get Data

-(void)setSampleData:(float *)data
              length:(int)length {
    if( plotData != nil ){
        free(plotData);
    }
    
    plotData   = (CGPoint *)calloc(sizeof(CGPoint),length);
    plotLength = length;
    
    for(int i = 0; i < length; i++) {
        data[i]     = i == 0 ? 0 : data[i];
        plotData[i] = CGPointMake(i,data[i] * _gain);
//        printf("X:%f     Y:%f\n",plotData[i].x,plotData[i].y);
    }
    
    [self _refreshDisplay];
}

#pragma mark - Update

-(void)updateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize
{
    
//    for (int i = 0; i< bufferSize; i++) {
//        printf("%f   \n",buffer[i]);
//    }
    
    if( _plotType == EZPlotTypeRolling ){
        
        // Update the scroll history datasource
        [EZAudioPlot updateScrollHistory:&_scrollHistory
                          withLength:_scrollHistoryLength
                             atIndex:&_scrollHistoryIndex
                          withBuffer:buffer
                      withBufferSize:bufferSize
                isResolutionChanging:&_changingHistorySize];
        
        //
        [self setSampleData:_scrollHistory
                     length:(!_setMaxLength?kEZAudioPlotMaxHistoryBufferLength:_scrollHistoryLength)];
        _setMaxLength = YES;
        
    }
    else if( _plotType == EZPlotTypeBuffer ){
        
        [self setSampleData:buffer
                     length:bufferSize];
        
    }
    else {
        
        // Unknown plot type
        
    }
}


- (void)drawRect:(CGRect)rect
{
//    NSLog(@"DrawRect Called");
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGRect frame = self.bounds;
    
    // Set the background color
    [(UIColor*)self.backgroundColor set];
    UIRectFill(frame);
    // Set the waveform line color
    [(UIColor*)self.color set];
    
    if(plotLength > 0) {
        
        plotData[plotLength-1] = CGPointMake(plotLength-1,0.0f);
        
        CGMutablePathRef halfPath = CGPathCreateMutable();
        CGPathAddLines(halfPath,
                       NULL,
                       plotData,
                       plotLength);
        CGMutablePathRef path = CGPathCreateMutable();
        
        double xscale = (frame.size.width) / (float)plotLength;
        double halfHeight = floor( frame.size.height / 2.0 );
        
        // iOS drawing origin is flipped by default so make sure we account for that
        int deviceOriginFlipped = 1;
        deviceOriginFlipped = -1;
        
        CGAffineTransform xf = CGAffineTransformIdentity;
        xf = CGAffineTransformTranslate( xf, frame.origin.x , halfHeight + frame.origin.y );
        xf = CGAffineTransformScale( xf, xscale, deviceOriginFlipped*halfHeight );
        CGPathAddPath( path, &xf, halfPath );
        
        if( self.shouldMirror ){
            xf = CGAffineTransformIdentity;
            xf = CGAffineTransformTranslate( xf, frame.origin.x , halfHeight + frame.origin.y);
            xf = CGAffineTransformScale( xf, xscale, -deviceOriginFlipped*(halfHeight));
            CGPathAddPath( path, &xf, halfPath );
        }
        CGPathRelease( halfPath );
        
        // Now, path contains the full waveform path.
        CGContextAddPath(ctx, path);
        
        // Make this color customizable
        if( self.shouldFill ){
            CGContextFillPath(ctx);
        }
        else {
            CGContextStrokePath(ctx);
        }
        CGPathRelease(path);
    }
    
    CGContextRestoreGState(ctx);
}

#pragma mark - Adjust Resolution

-(int)setRollingHistoryLength:(int)historyLength
{
    historyLength = MIN(historyLength,kEZAudioPlotMaxHistoryBufferLength);
    size_t floatByteSize = sizeof(float);
    _changingHistorySize = YES;
    if( _scrollHistoryLength != historyLength ){
        _scrollHistoryLength = historyLength;
    }
    _scrollHistory = realloc(_scrollHistory,_scrollHistoryLength*floatByteSize);
    if( _scrollHistoryIndex < _scrollHistoryLength ){
        memset(&_scrollHistory[_scrollHistoryIndex],
               0,
               (_scrollHistoryLength-_scrollHistoryIndex)*floatByteSize);
    }
    else {
        _scrollHistoryIndex = _scrollHistoryLength;
    }
    _changingHistorySize = NO;
    return historyLength;
}

-(int)rollingHistoryLength {
    return _scrollHistoryLength;
}

-(void)dealloc {
    if( plotData ){
        free(plotData);
    }
}


#pragma mark - Utility methods


+(void)updateScrollHistory:(float **)scrollHistory
                withLength:(int)scrollHistoryLength
                   atIndex:(int*)index
                withBuffer:(float *)buffer
            withBufferSize:(int)bufferSize
      isResolutionChanging:(BOOL*)isChanging {
    
    //
    size_t floatByteSize = sizeof(float);
    
    //
    if( *scrollHistory == NULL ){
        // Create the history buffer
        *scrollHistory = (float*)calloc(kEZAudioPlotMaxHistoryBufferLength,floatByteSize);
    }
    
    //
    if( !*isChanging ){
        float rms = [EZAudioPlot RMS:buffer length:bufferSize];
        if( *index < scrollHistoryLength ){
            float *hist = *scrollHistory;
            hist[*index] = rms;
            (*index)++;
        }
        else {
            [EZAudioPlot appendValue:rms
                 toScrollHistory:*scrollHistory
           withScrollHistorySize:scrollHistoryLength];
        }
    }
    
}

+(void)    appendValue:(float)value
       toScrollHistory:(float*)scrollHistory
 withScrollHistorySize:(int)scrollHistoryLength {
    float val[1]; val[0] = value;
    [EZAudioPlot appendBufferAndShift:val
                withBufferSize:1
               toScrollHistory:scrollHistory
         withScrollHistorySize:scrollHistoryLength];
}


+(void)appendBufferAndShift:(float*)buffer
             withBufferSize:(int)bufferLength
            toScrollHistory:(float*)scrollHistory
      withScrollHistorySize:(int)scrollHistoryLength {
    NSAssert(scrollHistoryLength>=bufferLength,@"Scroll history array length must be greater buffer length");
    NSAssert(scrollHistoryLength>0,@"Scroll history array length must be greater than 0");
    NSAssert(bufferLength>0,@"Buffer array length must be greater than 0");
    int    shiftLength    = scrollHistoryLength - bufferLength;
    size_t floatByteSize  = sizeof(float);
    size_t shiftByteSize  = shiftLength  * floatByteSize;
    size_t bufferByteSize = bufferLength * floatByteSize;
    memmove(&scrollHistory[0],
            &scrollHistory[bufferLength],
            shiftByteSize);
    memmove(&scrollHistory[shiftLength],
            &buffer[0],
            bufferByteSize);
}

+(float)RMS:(float *)buffer
     length:(int)bufferSize {
    float sum = 0.0;
    for(int i = 0; i < bufferSize; i++)
        sum += buffer[i] * buffer[i];
    
    return sqrtf( sum / bufferSize );
}


@end

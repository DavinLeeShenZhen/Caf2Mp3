//
//  ViewController.m
//  Caf2Mp3
//
//  Created by lidapeng on 16/2/2.
//  Copyright © 2016年 lidapeng. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "lame.h"

@interface ViewController ()

//语音
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;            //音频录音机
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;                //音频播放器，用于播放录音文件
@property (nonatomic, copy) NSString *voiceSavePath;                     //录音路径
@property (nonatomic, copy) NSString *voicePlayerPath;                   //播放路径

@property (nonatomic, strong) AVAudioPlayer *player;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setAudioSession];
    
}

//设置音频会话
-(void)setAudioSession{
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    //设置为播放和录音状态，以便可以在录制完之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
}


- (IBAction)recordBtn:(UIButton *)sender {
    
    if (!sender.selected) {
        
        //1.1URL 是录音文件保存的地址
        //音频文件保存在沙盒 document/20150228171912.caf
        //        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        //        dateFormatter.dateFormat = @"yyyyMMddHHmmss";
        //        NSString *timeStr = [dateFormatter stringFromDate:[NSDate date]];
        
        //音频文件名
        NSString *audioName = [@"test" stringByAppendingString:@".caf"];
        
        //doc目录 (路径)
        NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *fileURL = [doc stringByAppendingPathComponent:audioName];
        self.voiceSavePath = fileURL;
        NSLog(@"%@",fileURL);
        
        /*
         //setting 录音时的设置
         NSMutableDictionary *settings = [NSMutableDictionary dictionary];
         //音频编码格式
         settings[AVFormatIDKey] = @(kAudioFormatAppleIMA4); //音频采样频率
         settings[AVSampleRateKey] = @(44100.0);
         //音频频道
         settings[AVNumberOfChannelsKey] = @(1);
         //音频线性音频的位深度
         settings[AVLinearPCMBitDepthKey] = @(8);*/
        
        
        NSDictionary *recordSettings = [NSDictionary
                                        dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:AVAudioQualityMin],
                                        AVEncoderAudioQualityKey,
                                        [NSNumber numberWithInt:16],
                                        AVEncoderBitRateKey,
                                        [NSNumber numberWithInt: 2],
                                        AVNumberOfChannelsKey,
                                        [NSNumber numberWithFloat:44100.0],
                                        AVSampleRateKey,
                                        nil];
        
        
        
        self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:fileURL] settings:recordSettings error:nil];
        
        //录音的准备
        [self.audioRecorder prepareToRecord];
        
        //录音
        [self.audioRecorder record];
        
        
    } else {
        
        [self.audioRecorder stop];
        
    }
    
    sender.selected = !sender.selected;
    
}


- (IBAction)convertMp3:(UIButton *)sender {
    
    [self doChangeMP3];
    
}


- (IBAction)playAcf:(UIButton *)sender {
    
    NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fileURL = [doc stringByAppendingPathComponent:@"test.caf"];
    
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:fileURL] error:nil];
    [_player play];
    
}


- (IBAction)playMp3:(UIButton *)sender {
    
    NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fileURL = [doc stringByAppendingPathComponent:@"test.mp3"];
    
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:fileURL] error:nil];
    [_player play];
    
}


- (void)doChangeMP3{
    
    
    
    //    NSString *fileName = _cafName;
    //
    //
    //    fileName = [fileName stringByAppendingString:@".caf"];
    //
    //    NSString *cafFilePath = [self.tmpCAFPath stringByAppendingPathComponent:fileName];//caf文件地址
    //
    //    NSString * mp3FileName = _cafName;
    //
    //    mp3FileName = [mp3FileName stringByAppendingString:@".mp3"];
    //
    //    NSString *mp3FilePath = [self.tmpMp3Path stringByAppendingPathComponent:mp3FileName];
    
    NSString *fileName = @"test";
    
    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *outputPath = [NSString stringWithFormat:@"%@/%@.mp3", documentPath, fileName];
    NSString *sourceFilePath = [NSString stringWithFormat:@"%@/%@.caf", documentPath, fileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:sourceFilePath isDirectory:NO]) {
        NSLog(@"exist");
    }
    
    @try {
        
        int read, write;
        
        
        
        FILE *pcm = fopen([sourceFilePath cStringUsingEncoding:1], "rb");//被转换的文件
        
        FILE *mp3 = fopen([outputPath cStringUsingEncoding:1], "wb");//转换后文件的存放位置
        
        
        
        const int PCM_SIZE = 8192;
        
        const int MP3_SIZE = 8192;
        
        short int pcm_buffer[PCM_SIZE*2];
        
        unsigned char mp3_buffer[MP3_SIZE];
        
        
        
        lame_t lame = lame_init();
        
        lame_set_in_samplerate(lame, 44100);
        
        lame_set_VBR(lame, vbr_default);
        
        lame_init_params(lame);
        
        
        
        do {
            
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            
            if (read == 0)
                
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            
            else
                
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            
            
            fwrite(mp3_buffer, write, 1, mp3);
            
            
            
        } while (read != 0);
        
        
        
        lame_close(lame);
        
        fclose(mp3);
        
        fclose(pcm);
        
    }
    
    @catch (NSException *exception) {
        
        NSLog(@"%@",[exception description]);
        
    }
    
    @finally {
        
        
        
        
        
    }
    
    //    if (self.mp3Path) {
    //        
    //        self.mp3Path(mp3FilePath);//MP3
    //        
    //    }
    
}


@end

//
//  ViewController.m
//  Download
//
//  Created by lanou on 16/7/9.
//  Copyright © 2016年 lanou. All rights reserved.
//

#import "ViewController.h"
#import "TYDownloadSessionManager.h"
#import "TYDownloadUtility.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()<TYDownloadDelegate>

@property (strong, nonatomic) IBOutlet UIButton *button;

@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UILabel *progressLabel;

@property (nonatomic, strong) TYDownloadModel *downloadModel;

@end

static NSString * const downloadUrl = @"http://baobab.wdjcdn.com/1455888619273255747085_x264.mp4";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    
    [TYDownloadSessionManager manager].delegate = self;
    [self refreshDownloadInfo];
}

- (void)refreshDownloadInfo
{
    // manager 里面是否有这个 model 是正在下载
    _downloadModel = [[TYDownloadSessionManager manager] downLoadingModelForURLString:downloadUrl];
    if (_downloadModel) {
        [self startDownload];
        return;
    }
    TYDownloadModel *model = [[TYDownloadModel alloc] initWithURLString:downloadUrl];
    [self.button setTitle:[[TYDownloadSessionManager manager] isDownloadCompletedWithDownloadModel:model] ? @"下载完成,重新下载":@"开始" forState:(UIControlStateNormal)];
    _downloadModel = model;
    if (!_downloadModel.task && [[TYDownloadSessionManager manager] backgroundSessionTasksWithDownloadModel:_downloadModel]) {
        [self startAction:nil];
    }
}
- (void)startDownload
{
    TYDownloadSessionManager *manager = [TYDownloadSessionManager manager];
    __weak typeof(self) weakSelf = self;
    [manager startWithDownloadModel:_downloadModel progress:^(TYDownloadProgress *progress) {
        weakSelf.progressView.progress = progress.progress;
        weakSelf.progressLabel.text = [weakSelf detailTextForDownloadProgress:progress];
    } state:^(TYDownloadState state, NSString *filePath, NSError *error) {
        if (state == TYDownloadStateCompleted) {
            weakSelf.progressView.progress = 1.0;
            weakSelf.progressLabel.text = [NSString stringWithFormat:@"progress %.2f",weakSelf.progressView.progress];
        }
        [weakSelf.button setTitle:[weakSelf stateTitleWithState:state] forState:(UIControlStateNormal)];
    }];
}


- (IBAction)startAction:(id)sender {
    TYDownloadSessionManager *manager = [TYDownloadSessionManager manager];
    if (_downloadModel.state == TYDownloadStateReadying) {
        [manager cancleWithDownloadModel:_downloadModel];
        return;
    }
    if ([manager isDownloadCompletedWithDownloadModel:_downloadModel]) {
        [manager deleteFileWithDownloadModel:_downloadModel];
    }
    if (_downloadModel.state == TYDownloadStateRunning) {
        [manager suspendWithDownloadModel:_downloadModel];
        return;
    }
    [self startDownload];
}

- (NSString *)detailTextForDownloadProgress:(TYDownloadProgress *)progress
{
    NSString *fileSizeInUnits = [NSString stringWithFormat:@"%.2f %@",[TYDownloadUtility calculateFileSizeInUnit:(unsigned long long)progress.totalBytesExpectedToWrite],[TYDownloadUtility calculateUnit:(unsigned long long)progress.totalBytesExpectedToWrite]];
    NSMutableString *detailLabelText = [NSMutableString stringWithFormat:@"FileSize: %@\nDownload: %.2f %@ (%.2f%%)\nSpeed: %.2f %@/sec\nLeftTime: %dsec",fileSizeInUnits,[TYDownloadUtility calculateFileSizeInUnit:(unsigned long long)progress.totalBytesWritten],[TYDownloadUtility calculateUnit:(unsigned long long)progress.totalBytesWritten],progress.progress*100,[TYDownloadUtility calculateFileSizeInUnit:(unsigned long long)progress.speed],[TYDownloadUtility calculateUnit:(unsigned long long)progress.speed],progress.remainingTime];
    return detailLabelText;
}
- (NSString *)stateTitleWithState:(TYDownloadState)state
{
    switch (state) {
        case TYDownloadStateReadying:
            return @"等待下载";
            break;
        case TYDownloadStateRunning:
            return @"暂停下载";
            break;
        case TYDownloadStateFailed:
            return @"下载失败";
            break;
        case TYDownloadStateCompleted:
            return @"下载完成,重新下载";
            break;
        default:
            return @"开始下载";
            break;
    }
}

#pragma mark -- 
- (void)downloadModel:(TYDownloadModel *)downloadModel didUpdateProgress:(TYDownloadProgress *)progress
{
    NSLog(@"delegate progress %.3f",progress.progress);
}
- (void)downloadModel:(TYDownloadModel *)downloadModel didChangeState:(TYDownloadState)state filePath:(NSString *)filePath error:(NSError *)error
{
    NSLog(@"delegate state %ld error%@ filePath%@",state,error,filePath);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

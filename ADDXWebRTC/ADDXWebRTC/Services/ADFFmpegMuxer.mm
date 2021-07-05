//
//  ADFFmpegMuxer.m
//  WebRTC-Demo
//
//  Created by Hao Shen on 6/9/20.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

#import "ADFFmpegMuxer.h"

using namespace std;
 extern "C"
 {
     #include "ffmpeg/include/libavformat/avformat.h"
 };

static ADFFmpegMuxer *_instance;

@implementation ADFFmpegMuxer

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone ];
    });
    return _instance;
}

+ (instancetype)sharedInstance {
    if (_instance == nil) {
        _instance = [[super alloc] init];
    }
    return _instance;
}

- (id)copyWithZone:(NSZone *)zone {
    return _instance;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return _instance;
}

+ (BOOL)muxerMP4File:(NSString *)mp4file withH264File:(NSString *)h264File codecName:(NSString *)codecName {
    NSLog(@"input file %@",h264File);
    NSLog(@"output file %@",mp4file);
    int result = h26xToMp4(h264File.UTF8String, mp4file.UTF8String, codecName.UTF8String);
    if (result != 0) {
        return NO;
    }
    return YES;
}

// 视频转换（OC）凹
+ (BOOL)turnMp4Video:(NSString *)inputPath outputPath:(NSString *)outputPath {
    //NSString *inputPath1 = [[NSBundle mainBundle] pathForResource:@"test01.mp4" ofType:nil];
    NSString *commandStr = [NSString stringWithFormat:@"ffmpeg %@ %@",outputPath,inputPath];
    NSArray *argv_array = [commandStr componentsSeparatedByString:(@" ")];
    int argc = (int)argv_array.count;
    char** argv = (char**)malloc(sizeof(char*)*argc);
    for(int i=0; i < argc; i++) {
        argv[i] = (char*)malloc(sizeof(char)*1024);
        stpcpy(argv[i],[[argv_array objectAtIndex:i] UTF8String]);
    }
    int ret = ffmpeg_main(argc,argv);
    NSLog(@"-------------> ret:%d",ret);
    if(ret == 0) {
        return YES;
    }
    return NO;
}

- (BOOL)ts2Mp4:(NSString *)inputPath outputPath:(NSString *)outputPath {
    __weak typeof(self) weakSelf = self;
    KMMediaAsset *tsAsset = [KMMediaAsset assetWithURL:[NSURL URLWithString: inputPath] withFormat: KMMediaFormatTS];
    
    NSString *mp4FileName = outputPath;
    NSURL *mp4FileURL = [NSURL URLWithString:mp4FileName];
    
    KMMediaAsset *mp4Asset = [KMMediaAsset assetWithURL:mp4FileURL withFormat:KMMediaFormatMP4];
    
    ADMediaAssetExportSession *tsToMP4ExportSession = [[ADMediaAssetExportSession alloc] initWithInputAssets:@[tsAsset]];
    tsToMP4ExportSession.outputAssets = @[mp4Asset];
    
    
    [tsToMP4ExportSession exportAsynchronouslyWithCompletionHandler:^{
        /*
         KMMediaAssetExportSessionStatusWaiting 导出会话等待执行操作
         KMMediaAssetExportSessionStatusExporting 导出会话操作执行
         KMMediaAssetExportSessionStatusCompleted 导出会话操作成功完成
         KMMediaAssetExportSessionStatusFailed 导出会话操作失败
         KMMediaAssetExportSessionStatusCanceled 取消出口会话操作
         */
        if (tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted)
        {
            NSLog(@"1====%@",mp4FileName);
            [weakSelf.adFFmpegMuxerDelegate ts2Mp4Result: tsToMP4ExportSession.status outputPath: outputPath];
            //return YES;
            //self.infoLabel.text = [NSString stringWithFormat:@"Export of %@ completed",mp4FileName];
        } else {
            NSLog(@"2====%@",mp4FileName);
            [weakSelf.adFFmpegMuxerDelegate ts2Mp4Result: tsToMP4ExportSession.status outputPath: outputPath];
            //return  NO;
            //self.infoLabel.text = [NSString stringWithFormat:@"Export of %@ failed",mp4FileName];
        }
    }];
    return true;
}

// 视频转换(ffmpeg) 凹
int ffmpeg_main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("%s: infile outfile\n", argv[0]);
        return -1;
    }
    return transformat(argv[2], argv[1]);
}

// 打印信息（调试可用）
static void dump_codecpar(const char *prefix, AVCodecParameters *codecpar) {
    av_log(NULL, AV_LOG_INFO,
           "%s  "
           "codec_type: 0x%x  codec_id: 0x%x codec_tag: %u\n"
           "extradata: %p  extradata_size: %d format: %d\n"
           "bitrate: %lld  bits_per_coded_sample: %d\n"
           "bits_per_raw_sample: %d\n"
           "profile: %d level: %d\n"
           "width: %d height: %d\n"
           "sample_aspect_ration: %d/%d\n"
           "field_order: 0x%x\n"
           "color_range: 0x%x\n"
           "color_primaries: 0x%x\n"
           "color_trc: 0x%x\n"
           "color_space: 0x%x\n"
           "chroma_location: 0x%x\n"
           "video_delay: %d channel_layout: %llu\n"
           "channels: %d  sample_rate: %d\n"
           "block_align: %d frame_size: %d\n"
           "initial_padding: %d trailing_padding: %d\n"
           "seek_preroll: %d\n",
           prefix,
           codecpar->codec_type,
           codecpar->codec_id,
           codecpar->codec_tag,
           codecpar->extradata,
           codecpar->extradata_size,
           codecpar->format,
           codecpar->bit_rate,
           codecpar->bits_per_coded_sample,
           codecpar->bits_per_raw_sample,
           codecpar->profile,
           codecpar->level,
           codecpar->width,
           codecpar->height,
           codecpar->sample_aspect_ratio.num,
           codecpar->sample_aspect_ratio.den,
           codecpar->field_order,
           codecpar->color_range,
           codecpar->color_primaries,
           codecpar->color_trc,
           codecpar->color_space,
           codecpar->chroma_location,
           codecpar->video_delay,
           codecpar->channel_layout,
           codecpar->channels,
           codecpar->sample_rate,
           codecpar->block_align,
           codecpar->frame_size,
           codecpar->initial_padding,
           codecpar->trailing_padding,
           codecpar->seek_preroll
        );
    av_hex_dump_log(NULL, AV_LOG_INFO, codecpar->extradata, codecpar->extradata_size);
}

// 转换视频格式
int transformat(const char *inputFath, const char *outPutPath) {
    int ret = 0;
    
    FILE *pfile = nullptr;
    FILE *outFile = nullptr;
    
    do {
        pfile = fopen(inputFath, "rb");
        if (pfile == nullptr) {
            ret = -1;
            break;
        }
        
        outFile = fopen(outPutPath, "wb");
        if (outFile == nullptr) {
            ret = -2;
            break;
        }
        
        const int codec_size = 5;
        const int avcc_size = 4;
        uint8_t avcc[avcc_size] = {0x61, 0x76, 0x63, 0x43};
        uint8_t newavcc[codec_size] = {0x01, 0x64, 0x00, 0x29, 0xff};
        const int remain = codec_size + 4;
        char hbuf[remain] = {0};
        int in = 0;
        bool bFind = false;
        static const int max_read_size = 1024*4;
        int readSize = max_read_size;
        char *unit = new char[readSize];
        
        do {
            readSize = max_read_size;
            
            int rlen = fread(unit + in, 1, readSize - in, pfile);
            if (rlen <= 0) {
                fprintf(stderr, "fread rlen <= 0 \n", rlen);
                break;
            }
            
            readSize = rlen + in < readSize ? rlen + in : readSize;
            //fprintf(stdout, "read len=%d, in=%d \n", rlen, in);
            
            //已经找到并替换，接下来的内容直接写入另一文件
            if (bFind) {
                fwrite(unit + in, 1, readSize - in, outFile);
                continue;
            }
            
            //
            for (int i = 0; i < readSize - avcc_size; i++) {
                if (unit[i] == avcc[0] && unit[i + 1] == avcc[1] &&
                    unit[i + 2] == avcc[2] && unit[i + 3] == avcc[3]) {
                    //
                    if (readSize - i < remain) {
                        //fprintf(stdout, "readSize -i < 5+4, left=%d \n", readSize - i);
                        
                        //修改codec_size的部分为newavcc
                        memcpy(unit + i + avcc_size, newavcc, (readSize - i) - 4);
                        fwrite(unit + in, 1, readSize - in, outFile);
                        
                        //
                        int rem = remain - (readSize - i) - 4;
                        fwrite(newavcc + (readSize - i) - 4, 1, rem, outFile);
                        //更改读指针
                        fseek(pfile, rem, SEEK_CUR);
                        
                        in = 0;
                        bFind = true;
                        break;
                        
                    } else {
                        //fprintf(stdout, " readSize - i > reamain, left=%d \n",
                        //        readSize - i);
                        
                        memcpy(unit + i + avcc_size, newavcc, codec_size);
                        fwrite(unit + in, 1, readSize - in, outFile);
                        
                        bFind = true;
                        in = 0;
                        break;
                    }
                }
            }
            
            if (bFind) {
                continue;
            }
            
            //未找到，则unit全部写入新file
            fwrite(unit + in, 1, readSize - in, outFile);
            
            //倒查，需要把头上4字节保存下来，下次取判断使用
            in = 4;
            memcpy(unit, unit + readSize - in, in);
            
        } while (true);
        
        if (unit != nullptr) {
            delete[] unit;
            unit = nullptr;
        }
        
        if (pfile) {
            fclose(pfile);
        }
        
        if (outFile) {
            fclose(outFile);
        }
        
    } while (0);
    
    return ret;
}

//int transformat(const char *inputFath, const char *outPutPath) {
//    AVOutputFormat *ofmt      = NULL;
//    AVFormatContext *ifmt_ctx = NULL, *ofmt_ctx = NULL;
//    AVPacket pkt;
//    int i, ret;
//    av_register_all();
//    if ((ret = avformat_open_input(&ifmt_ctx, inputFath, NULL, NULL)) < 0) {
//        av_log(NULL, AV_LOG_ERROR, "avformat_open_input %s failed: %s\n", inputFath,
//               av_err2str(ret));
//        goto failed;
//    }
//    if (avformat_find_stream_info(ifmt_ctx, NULL) < 0) {
//        av_log(ifmt_ctx, AV_LOG_ERROR, "avformat_find_stream_info failed\n");
//        goto failed;
//    }
//    /* av_dump_format(ifmt_ctx, 0, in, 0); */
//    if (avformat_alloc_output_context2(&ofmt_ctx, NULL, NULL, outPutPath) < 0) {
//        av_log(NULL, AV_LOG_ERROR, "avformat_alloc_output_context2 failed\n");
//        goto failed;
//    }
//    if (ofmt_ctx == NULL) {
//        av_log(NULL, AV_LOG_ERROR, "ofmt_ctx is NULL\n");
//        goto failed;
//    }
//
//    av_log(NULL, AV_LOG_INFO, "in flags: 0x%x  out flags: 0x%x\n",
//           ifmt_ctx->iformat->flags, ofmt_ctx->oformat->flags);
//    /* ofmt_ctx->oformat->flags |= AVFMT_GLOBALHEADER; */
//    ofmt = ofmt_ctx->oformat;
//    for (i = 0; i < ifmt_ctx->nb_streams; i++) {
//        AVStream *out_stream;
//        AVStream *in_stream = ifmt_ctx->streams[i];
//
//        out_stream = avformat_new_stream(ofmt_ctx, NULL);
//        if (out_stream == NULL) {
//            av_log(NULL, AV_LOG_ERROR, "avforamt_new_stream failed\n");
//            goto failed;
//        }
//
//        if (ofmt->flags & AVFMT_GLOBALHEADER) {
//            /* cctx->flags |= AV_CODEC_FLAG_GLOBAL_HEADER; */
//            /* out_stream->codec->flags |= AV_CODEC_FLAG_GLOBAL_HEADER; */
//            av_log(ofmt_ctx, AV_LOG_INFO, "#### AV_CODEC_FLAG_GLOBAL_HEADER\n");
//        }
//        if (avcodec_parameters_copy(out_stream->codecpar,
//                                    in_stream->codecpar) < 0) {
//            av_log(NULL, AV_LOG_ERROR, "avcodec_parameters_copy failed\n");
//            goto failed;
//
//        }
//#if 1
//        if (in_stream->codecpar->codec_id == AV_CODEC_ID_H264) {
//            static uint8_t extradata[] = {
//                0x01, 0x64, 0x00, 0x29, 0xff, 0xe1, 0x00, 0x26, 0x27, 0x64, 0x00,
//                0x29, 0xad, 0x00, 0xce, 0x80, 0x78, 0x02, 0x27, 0xe5, 0x9a, 0x80,
//                0x80, 0x80, 0xf8, 0x00, 0x00, 0x03, 0x00, 0x08, 0x00, 0x00, 0x03,
//                0x00, 0xf1, 0xa8, 0x00, 0x53, 0x40, 0x00, 0x3e, 0x70, 0x6f, 0xff,
//                0xe0, 0x50, 0x01, 0x00, 0x04, 0x28, 0xee, 0x3c, 0xb0, 0xfd, 0xf8,
//                0xf8, 0x00
//            };
//
//            if (out_stream->codecpar->extradata) {
//                av_free(out_stream->codecpar->extradata);
//            }
//            out_stream->codecpar->extradata = (uint8_t *)av_mallocz(57 + AV_INPUT_BUFFER_PADDING_SIZE);
//            if (out_stream->codecpar->extradata == NULL) {
//                av_log(NULL, AV_LOG_ERROR, "av_mallocz failed\n");
//                goto failed;
//            }
//            memcpy(out_stream->codecpar->extradata, extradata, 57);
//            out_stream->codecpar->extradata_size = 57;
//        }
//#endif
//
//        out_stream->codecpar->codec_tag = 0;
//        //dump_codecpar("in_stream ", in_stream->codecpar);
//        //dump_codecpar("out_stream ", out_stream->codecpar);
//    }
//    /* av_dump_format(ofmt_ctx, 0, out, 1); */
//    if (!(ofmt->flags & AVFMT_NOFILE)) {
//        if (avio_open(&ofmt_ctx->pb, outPutPath, AVIO_FLAG_WRITE) < 0) {
//            av_log(ofmt_ctx, AV_LOG_ERROR, "avio_open failed\n");
//            goto failed;
//        }
//    }
//    if (avformat_write_header(ofmt_ctx, NULL) < 0) {
//        av_log(ofmt_ctx, AV_LOG_ERROR, "avformat_write_header failed\n");
//        goto failed;
//    }
//
//    while (av_read_frame(ifmt_ctx, &pkt) >= 0) {
//        AVStream *in_stream, *out_stream;
//        in_stream = ifmt_ctx->streams[pkt.stream_index];
//        if (in_stream == NULL) {
//            av_log(ofmt_ctx, AV_LOG_INFO, "in_stream is NULL\n");
//            continue;
//        }
//        out_stream = ofmt_ctx->streams[pkt.stream_index];
//        if (out_stream == NULL) {
//            av_log(ofmt_ctx, AV_LOG_INFO, "out_stream is NULL\n");
//            continue;
//        }
//
//        av_packet_rescale_ts(&pkt, in_stream->time_base, out_stream->time_base);
//        pkt.pos = -1;
//
//        if (av_interleaved_write_frame(ofmt_ctx, &pkt) < 0) {
//            av_log(ofmt_ctx, AV_LOG_INFO, "av_interleaved_write_frame faild\n");
//            continue;
//        }
//        av_packet_unref(&pkt);
//    }
//    av_write_trailer(ofmt_ctx);
//
//    if (ifmt_ctx != NULL) {
//        avformat_close_input(&ifmt_ctx);
//    }
//
//    if (ofmt_ctx) {
//        if (!(ofmt->flags & AVFMT_NOFILE)) {
//            avio_closep(&ofmt_ctx->pb);
//        }
//        avformat_free_context(ofmt_ctx);
//    }
//    av_log(NULL, AV_LOG_INFO, "%s --> %s sucess\n", inputFath, outPutPath);
//    return 0;
//
//failed:
//    if (ifmt_ctx != NULL) {
//        avformat_close_input(&ifmt_ctx);
//    }
//
//    if (ofmt_ctx) {
//        if (!(ofmt->flags & AVFMT_NOFILE)) {
//            avio_closep(&ofmt_ctx->pb);
//        }
//        avformat_free_context(ofmt_ctx);
//    }
//
//    av_log(NULL, AV_LOG_INFO, "%s --> %s failed\n", inputFath, outPutPath);
//    return -1;
//}


int h26xToMp4(const char *in_filename,const char *out_filename, const char* codecName){
    AVOutputFormat *ofmt = NULL;
    //创建输入AVFormatContext对象和输出AVFormatContext对象
    AVFormatContext *ifmt_ctx = NULL, *ofmt_ctx = NULL;
    AVPacket pkt;

    int ret, i;
    int stream_index = 0;
    int *stream_mapping = NULL;
    int stream_mapping_size = 0;
    
    //ffmpeg-3.x版本必须加
    av_register_all();
    
    //打开视频文件
    if ((ret = avformat_open_input(&ifmt_ctx, in_filename, 0, 0)) < 0) {
        printf("打开视频流失败,errcode=%d,errstr=%s\n",ret, av_err2str(ret));
        return -1;
    }
    //获取视频文件信息
    if ((ret = avformat_find_stream_info(ifmt_ctx, 0)) < 0) {
        printf("获取视频流信息失败 %d\n",ret);
        return -1;
    }

    //打印信息
    //av_dump_format(ifmt_ctx, 0, in_filename, 0);

    //输出文件分配空间
    ret = avformat_alloc_output_context2(&ofmt_ctx, NULL, NULL, out_filename);
    if (!ofmt_ctx) {
        printf("输出文件分配空间分配失败 err=%d, errstr=%s\n",ret, av_err2str(ret));
        return -1;
    }

    stream_mapping_size = ifmt_ctx->nb_streams;
    stream_mapping = (int *)av_mallocz_array(stream_mapping_size, sizeof(*stream_mapping));
    if (!stream_mapping) {
        printf("获取mapping失败\n");
        return -1;
    }

    ofmt = ofmt_ctx->oformat;

    for (i = 0; i < ifmt_ctx->nb_streams; i++) {
        AVStream *out_stream;
        AVStream *in_stream = ifmt_ctx->streams[i];
        AVCodecParameters *in_codecpar = in_stream->codecpar;

        if (in_codecpar->codec_type != AVMEDIA_TYPE_AUDIO &&
            in_codecpar->codec_type != AVMEDIA_TYPE_VIDEO &&
            in_codecpar->codec_type != AVMEDIA_TYPE_SUBTITLE) {
            stream_mapping[i] = -1;
            continue;
        }

        stream_mapping[i] = stream_index++;

        out_stream = avformat_new_stream(ofmt_ctx, NULL);
        if (!out_stream) {
            printf("分配流对象失败\n");
            return -1;
        }

        ret = avcodec_parameters_copy(out_stream->codecpar, in_codecpar);
        if (ret < 0) {
            printf("拷贝视频code失败 %d\n",ret);
            return -1;
        }
        
        if (strcmp(codecName, "h265") == 0) {
          out_stream->codecpar->codec_tag = MKTAG('h', 'v', 'c', '1');
        } else {
          out_stream->codecpar->codec_tag = 0;
        }
    }

    //打开文件
    if (!(ofmt->flags & AVFMT_NOFILE)) {
        ret = avio_open(&ofmt_ctx->pb, out_filename, AVIO_FLAG_WRITE);
        if (ret < 0) {
            printf("打开输出文件失败 %d\n",ret);
            return -1;
        }
    }
    //开始写入文件头
    ret = avformat_write_header(ofmt_ctx, NULL);
    if (ret < 0) {
        printf("写入文件头失败 %d\n",ret);
        return -1;
    }
    int m_frame_index = 0;
    //开始读取视频流，并获取pkt信息
    while (1) {
        AVStream *in_stream, *out_stream;

        ret = av_read_frame(ifmt_ctx, &pkt);
        if (ret < 0)
            break;

        in_stream  = ifmt_ctx->streams[pkt.stream_index];
        in_stream->r_frame_rate.num = 15;
        if (pkt.stream_index >= stream_mapping_size ||
            stream_mapping[pkt.stream_index] < 0) {
            av_packet_unref(&pkt);
            continue;
        }

        pkt.stream_index = stream_mapping[pkt.stream_index];
        out_stream = ofmt_ctx->streams[pkt.stream_index];

        //从摄像头直接保存的h264文件，重新编码时得自己加时间戳，不然转换出来的是没有时间的
        if(pkt.pts==AV_NOPTS_VALUE){
            //Write PTS
            AVRational time_base1=in_stream->time_base;
            //Duration between 2 frames (us)
            int64_t calc_duration=(double)AV_TIME_BASE/av_q2d(in_stream->r_frame_rate);
            //Parameters
            pkt.pts=(double)(m_frame_index*calc_duration)/(double)(av_q2d(time_base1)*AV_TIME_BASE);
            pkt.dts=pkt.pts;
            pkt.duration=(double)calc_duration/(double)(av_q2d(time_base1)*AV_TIME_BASE);
        }

        /* copy packet */
        pkt.pts = av_rescale_q_rnd(pkt.pts, in_stream->time_base, out_stream->time_base, (AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
        pkt.dts = av_rescale_q_rnd(pkt.dts, in_stream->time_base, out_stream->time_base, (AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
        pkt.duration = av_rescale_q(pkt.duration, in_stream->time_base, out_stream->time_base);
        pkt.pos = -1;

        ret = av_interleaved_write_frame(ofmt_ctx, &pkt);
        if (ret < 0) {
            break;
        }
        av_packet_unref(&pkt);
        m_frame_index++;
    }

    av_write_trailer(ofmt_ctx);

    avformat_close_input(&ifmt_ctx);

    // close output
    if (ofmt_ctx && !(ofmt->flags & AVFMT_NOFILE))
        avio_closep(&ofmt_ctx->pb);
    avformat_free_context(ofmt_ctx);

    av_freep(&stream_mapping);
    
    printf("======testffmpeg SUCC \n");
    return 0;
}
@end

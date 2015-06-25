//
//  HWWaterFlowView.h
//  瀑布流2
//
//  Created by 黄伟 on 15/6/23.
//  Copyright (c) 2015年 huangwei. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HWWaterFlowView,HWWaterFlowCell;
typedef enum{
    HWWaterFlowMarginTop,    //顶部间距
    HWWaterFlowMarginLeft,   //左边间距
    HWWaterFlowMarginBottom, //底部间距
    HWWaterFlowMarginRight,  //右边间距
    HWWaterFlowMarginColomn, //列间距
    HWWaterFlowMarginRow,    //行间距
}HWWaterFlowMargin;

//数据源方法
@protocol HWWaterFlowViewDataSource<NSObject>
@required

//一共有几个cell
-(NSInteger)numberOfCellsInWaterFlow:(HWWaterFlowView *)waterFlow;

//每一个cell长什么样
-(HWWaterFlowCell *)waterFlow:(HWWaterFlowView *)waterFlow cellAtIndex:(NSInteger)index;
@optional

//列数
-(NSInteger)columnsInWaterFlow:(HWWaterFlowView *)waterFlow;
@end

//代理方法
@protocol HWWaterFlowViewDeleagte<NSObject,UIScrollViewDelegate>
@optional

//某个位置上cell的高度
-(CGFloat)waterFlow:(HWWaterFlowView *)waterFlow cellHeightAtIndex:(NSInteger)index;

//选中某个cell后要执行的操作
-(void)waterFlow:(HWWaterFlowView *)waterFlow didSelectCellAtIndex:(NSInteger)index;

//设置不同位置的间距
-(CGFloat)waterFlow:(HWWaterFlowView *)waterFlow marginAccrodingToMarginType:(HWWaterFlowMargin)marginType;

//头部可以放置一个view
-(UIView *)waterFlowHeaderView:(HWWaterFlowView *)waterFlow;
@end

@interface HWWaterFlowView : UIScrollView

//数据源
@property(nonatomic,weak) id<HWWaterFlowViewDataSource> dataSource;

//代理
@property(nonatomic,weak) id<HWWaterFlowViewDeleagte> waterDeleagte;

//刷新数据
-(void)reloadData;

//cell的宽度，有时需要通过cell 的宽度去计算cell的高度以保证一些素材宽高比例一致
-(CGFloat)cellWidth;

//根据重用标识符去缓存池查找有没有可以用的cell
- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier;
@end

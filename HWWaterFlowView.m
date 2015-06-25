//
//  HWWaterFlowView.m
//  瀑布流2
//
//  Created by 黄伟 on 15/6/23.
//  Copyright (c) 2015年 huangwei. All rights reserved.
//

#import "HWWaterFlowView.h"
#import "HWWaterFlowCell.h"
#define ColumnNumber 3
#define MarginDefault 10
#define CellHeightDefault 70

@interface HWWaterFlowView()

//存放所有cell的frame
@property(nonatomic,strong) NSMutableArray *cellFrames;

//存放当前显示在屏幕上的cell
@property(nonatomic,strong) NSMutableDictionary *displayingCells;

//缓存池,因为从缓存池取的时候不是按照顺序取的，所以用NSSet就行
@property(nonatomic,strong) NSMutableSet *reuseCells;

//头部的view
@property(nonatomic,strong) UIView *headerView;
@end
@implementation HWWaterFlowView
-(NSMutableArray *)cellFrames{
    if (_cellFrames == nil) {
        _cellFrames = [NSMutableArray array];
    }
    return _cellFrames;
}
-(NSMutableDictionary *)displayingCells{
    if (_displayingCells == nil) {
        _displayingCells = [NSMutableDictionary dictionary];
    }
    return _displayingCells;
}
-(NSMutableSet *)reuseCells{
    if (_reuseCells == nil) {
        _reuseCells = [NSMutableSet set];
    }
    return _reuseCells;
}
#pragma mark -公共方法

-(void)reloadData{
    
    //每次重新加载数据，就把之前存的所有东西全部清除
    [self.displayingCells.allValues makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.displayingCells removeAllObjects];
    [self.reuseCells removeAllObjects];
    [self.cellFrames removeAllObjects];
    
    //cell总数
    NSInteger cellNumber = [self.dataSource numberOfCellsInWaterFlow:self];
    
    //cell宽度
    CGFloat cellWidth = [self cellWidth];
    
    CGFloat topM = [self marginWithMarginType:HWWaterFlowMarginTop];
    CGFloat leftM = [self marginWithMarginType:HWWaterFlowMarginLeft];
    CGFloat bottomM = [self marginWithMarginType:HWWaterFlowMarginBottom];
    CGFloat columnM = [self marginWithMarginType:HWWaterFlowMarginColomn];
    CGFloat rowM = [self marginWithMarginType:HWWaterFlowMarginRow];
    
    //列数
    NSInteger columns = [self numberOfColums];
    
    //创建一个C的数组，存每一列当前最大的Y值，这样用来在最短的地方去放下一个cell
    CGFloat maxYOfColumns[columns];
    for (NSInteger i = 0; i < columns; i++) {
        maxYOfColumns[i] = 0.0;
    }
    for (NSInteger i = 0; i < cellNumber; i ++) {
        
        //cell的高度
        CGFloat cellHeigth = [self heightOfCellAtIndex:i];
        
        //cell将要放置的列
        NSInteger cellAtColumn = 0;
        
        //cell即将放置的那一列的最大Y值，默认是第0列，
        CGFloat maxY = maxYOfColumns[cellAtColumn];
        
        //通过遍历，找到数组中的最小值，这个最小值决定了cell即将放置的位置
        for (NSInteger j = 1; j < columns; j++) {
            if (maxYOfColumns[j] < maxY) {
                cellAtColumn = j;
                maxY = maxYOfColumns[j];
            }
        }
        CGFloat cellY = 0;
        
        //计算cell 的y值，如果是第一行，即cell所在列的最大Y值＝0，那么cell的y就是顶部间距
        if (maxY == 0) {
            cellY = topM +[self topMargin];
        }else{//如果不是第一行，那么cell 的y值就是所在列的最大Y加上行间距
            cellY = maxY + rowM;
        }
        
        //cell 的X值
        CGFloat cellX = leftM + (cellWidth + columnM)*cellAtColumn;
        CGRect cellFrame = CGRectMake(cellX, cellY, cellWidth, cellHeigth);
        [self.cellFrames addObject:[NSValue valueWithCGRect:cellFrame]];
        
        //更新cell所在列的最大Y值
        maxYOfColumns[cellAtColumn] = CGRectGetMaxY(cellFrame);
    }
    
    //继承UIScrollView，滑动就要设置contentSize
    CGFloat max = maxYOfColumns[0];
    for (NSInteger j = 1; j < columns; j++) {
        if (max < maxYOfColumns[j]) {
            max = maxYOfColumns[j];
        }
    }
    self.contentSize = CGSizeMake(0, max + bottomM);
}

-(CGFloat)cellWidth{
    CGFloat columnM = [self marginWithMarginType:HWWaterFlowMarginColomn];
    CGFloat leftM = [self marginWithMarginType:HWWaterFlowMarginLeft];
    CGFloat rightM = [self marginWithMarginType:HWWaterFlowMarginRight];
    NSInteger columns = [self numberOfColums];
    return (self.frame.size.width- leftM - columnM * (columns-1) - rightM)/columns;
}

-(id)dequeueReusableCellWithIdentifier:(NSString *)identifier{
    __block HWWaterFlowCell *reuseCell = nil;
    
    //从缓存池中找有没有对应标识符的cell
    [self.reuseCells enumerateObjectsUsingBlock:^(HWWaterFlowCell *cell, BOOL *stop) {
        if ([cell.reuseIdentifier isEqualToString:identifier]) {//如果有
            //就是它
            reuseCell = cell;
        }
        //从缓存池中移除这个cell
        [self.reuseCells removeObject:cell];
        *stop = YES;
    }];
    
    return reuseCell;
}
#pragma mark -私有方法
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    
    //如果代理不执行代理方法，那么直接返回
    if (![self.waterDeleagte respondsToSelector:@selector(waterFlow:didSelectCellAtIndex:)]) return;
    UITouch *touch = [touches anyObject];
    
    //找到触摸点
    CGPoint touchPoint = [touch locationInView:self];
    
    //遍历所有的显示在屏幕上的cell，
    [self.displayingCells enumerateKeysAndObjectsUsingBlock:^(NSNumber *index, HWWaterFlowCell *displayingCell, BOOL *stop) {
        
        //如果触摸点落在了这个cell上
        if (CGRectContainsPoint(displayingCell.frame, touchPoint)) {
            
            //让代理执行代理方法，index就是这个cell存在字典里所对应的key
            [self.waterDeleagte waterFlow:self didSelectCellAtIndex:index.longValue];
            
            //停止遍历
            *stop = YES;
        }
        
    }];
}

//view即将被显示的时候，刷新一下数据
-(void)willMoveToSuperview:(UIView *)newSuperview{
    [self reloadData];
}

//一开始布局子控件，每次滚动时都会调用这个方法
-(void)layoutSubviews{
    for (NSInteger i = 0; i < self.cellFrames.count; i++) {
        CGRect cellFrame = [self.cellFrames[i] CGRectValue];
        
        //首先看这个cell原来在不在屏幕上，
        HWWaterFlowCell *cell = self.displayingCells[@(i)];
        
        //这个尺寸的cell在屏幕上经过滑动后还在屏幕上，那么没必要新建
        if ([self cellIsVisualOnScreen:cellFrame]) {
            
            if (cell == nil) {//如果cell原本不在屏幕上，经过滑动到了屏幕上，那么要新建，问数据源要
                cell = [self.dataSource waterFlow:self cellAtIndex:i];
                cell.frame = cellFrame;
                [self addSubview:cell];
                
                //把这个cell存起来
                self.displayingCells[@(i)] = cell;
            }
        }else{//这个尺寸的cell不在屏幕上
            
            if (cell) {//如果这个cell原来在屏幕上，经过滑动不在屏幕上
                
                //从view上移除
                [cell removeFromSuperview];
                
                //从存放显示在屏幕上的cell的字典中移除
                [self.displayingCells removeObjectForKey:@(i)];
                
                //放到缓存池中
                [self.reuseCells addObject:cell];
            }
        }
    }
    
    if ([self cellIsVisualOnScreen:self.headerView.frame]) {//头部在不在屏幕上
        
        //如果在屏幕上，就要添加上去
        [self addSubview:self.headerView];
    }else{
        
        //如果不在，就要从view上移除
        [self.headerView removeFromSuperview];
    }
}

//头部距离，根据头部有没有放置View去判断
-(CGFloat)topMargin{
    //如果代理设置了头部的view
    if ([self.waterDeleagte respondsToSelector:@selector(waterFlowHeaderView:)]) {
        UIView * view = [self.waterDeleagte waterFlowHeaderView:self];
        
        //把这个view缓存起来
        self.headerView = view;
        
        //返回这个view的高度，相当于预留了这个view的高度
        return view.frame.size.height;
    }else{
        
        //如果代理没有设置头部，那么返回0
        return 0;
    }
}
//列数，如果数据源不返回值，那么默认是3列
-(NSInteger)numberOfColums{
    if ([self.dataSource respondsToSelector:@selector(columnsInWaterFlow:)]) {
        return [self.dataSource columnsInWaterFlow:self];
    }else{
        return ColumnNumber;
    }
}
//返回间隙的值，如果代理不返回值，那么默认值是所有的间隙都是10
-(CGFloat)marginWithMarginType:(HWWaterFlowMargin)marginType{
    if ([self.waterDeleagte respondsToSelector:@selector(waterFlow:marginAccrodingToMarginType:)]) {
        return [self.waterDeleagte waterFlow:self marginAccrodingToMarginType:marginType];
    }else{
        return MarginDefault;
    }
}
//返回cell的高度，如果代理不返回，那么默认高度70；
-(CGFloat)heightOfCellAtIndex:(NSInteger)index{
    if ([self.waterDeleagte respondsToSelector:@selector(waterFlow:cellHeightAtIndex:)]) {
        return [self.waterDeleagte waterFlow:self cellHeightAtIndex:index];
    }else{
        return CellHeightDefault;
    }
}
//通过cell的frame去判断这个cell在不在屏幕上
-(BOOL)cellIsVisualOnScreen:(CGRect)cellFrame{
    return (CGRectGetMaxY(cellFrame) > self.contentOffset.y && CGRectGetMinY(cellFrame)< self.contentOffset.y+self.frame.size.height);
}
@end

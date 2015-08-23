//
//  DTCollectionViewController+VerifyItem.m
//  DTCollectionViewManagerExample
//
//  Created by Denys Telezhkin on 21.07.13.
//  Copyright (c) 2013 Denys Telezhkin. All rights reserved.
//

#import "DTCollectionViewController+VerifyItem.h"
#import "DTModelTransfer.h"

@implementation DTCollectionViewController (Verify)

-(BOOL)verifyCollectionItem:(id)item atIndexPath:(NSIndexPath *)path
{
    id itemDatasource = [self.memoryStorage itemAtIndexPath:path];
    id itemCollection = [(id <DTModelTransfer>)[self collectionView:self.collectionView cellForItemAtIndexPath:path] model];
    
    if (![item isEqual:itemDatasource])
        return NO;
    
    if (![item isEqual:itemCollection])
        return NO;
    
    // ALL 3 are equal
    return YES;
}

-(void)raiseInvalidSectionException
{
    NSException * exception = [NSException exceptionWithName:@""
                                                      reason:@"wrong section items"
                                                    userInfo:nil];
    [exception raise];
}

-(void)verifySection:(NSArray *)section withSectionNumber:(NSInteger)sectionNumber
{
    for (int itemNumber = 0; itemNumber < [section count]; itemNumber++)
    {
        if (![self verifyCollectionItem:section[itemNumber]
                            atIndexPath:[NSIndexPath indexPathForItem:itemNumber
                                                            inSection:sectionNumber]])
        {
            [self raiseInvalidSectionException];
        }
    }
    NSInteger itemsInSection = [self.collectionView numberOfItemsInSection:sectionNumber];
    if (itemsInSection!=[section count])
    {
        [self raiseInvalidSectionException];
    }
}

@end

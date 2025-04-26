import React from 'react';
import {Skeleton} from "moti/skeleton";

function CommonSkeletonView({
                                width=100,
    height=16
                            }) {
    return (
        <Skeleton.Group show={true}>
            <Skeleton show={true} width={width}
                      radius={4}
                      height={height}
                      colorMode="light" colors={['#dcdcdc', '#cccccc', '#dcdcdc']}  />
        </Skeleton.Group>
    );
}

export default CommonSkeletonView;

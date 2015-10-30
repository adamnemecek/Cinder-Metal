//
//  RenderEncoder.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/16/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalGeom.h"
#include "Pipeline.h"
#include "Buffer.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class RenderEncoder> RenderEncoderRef;
    
    class RenderEncoder
    {

        friend class CommandBuffer;
        
    public:

        virtual ~RenderEncoder(){}
        
        void pushDebugGroup( const std::string & groupName);
        void popDebugGroup();

        void setPipeline( PipelineRef pipeline );
        void setBufferAtIndex( BufferRef buffer, size_t bufferIndex , size_t bytesOffset = 0 );
        // A convenience method for setBuffer that takes the inflight buffer index instead of an offset
        template <typename BufferType>
        void setBufferForInflightIndex( BufferRef buffer, size_t inflightBufferIndex, size_t bufferIndex )
        {
            uint offset = (sizeof(BufferType) * inflightBufferIndex);
            this->setBufferAtIndex( buffer, bufferIndex, offset);
        }

        void draw( ci::mtl::geom::Primitive primitive, size_t vertexStart, size_t vertexCount, size_t instanceCount );
        
    protected:

        static RenderEncoderRef create( void * mtlRenderCommandEncoder ); // <MTLRenderCommandEncoder>
        
        RenderEncoder( void * mtlRenderCommandEncoder );
        
        void * mImpl;
    };
    
} }
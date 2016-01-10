//
//  Pipeline.cpp
//  Cinder-Metal
//
//  Created by William Lindmeier on 10/13/15.
//
//

#include "RenderPipelineState.h"
#include "RendererMetalImpl.h"
#import "cinder/cocoa/CinderCocoa.h"

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

RenderPipelineState::RenderPipelineState( const std::string & vertShaderName,
                                          const std::string & fragShaderName,
                                          Format format,
                                          void * mtlLibrary ) :
mFormat(format)
,mImpl(nullptr)
{
    
    id <MTLDevice> device = [RendererMetalImpl sharedRenderer].device;
    id <MTLLibrary> library = (__bridge id<MTLLibrary>)mtlLibrary;
    if ( library == nullptr )
    {
        library = [RendererMetalImpl sharedRenderer].library;
    }
    else
    {
        // Make sure the user passed in a valid library
        assert( [library conformsToProtocol:@protocol(MTLLibrary)] );
    }
    
    // Load the fragment program from the library
    id <MTLFunction> fragmentProgram = [library newFunctionWithName:
                                        [NSString stringWithUTF8String:fragShaderName.c_str()]];
    assert(fragmentProgram != nil);
    
    // Load the vertex program from the library
    id <MTLFunction> vertexProgram = [library newFunctionWithName:
                                      [NSString stringWithUTF8String:vertShaderName.c_str()]];
    assert(vertexProgram != nil);
    
    // Create a reusable pipeline state
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = [NSString stringWithUTF8String:mFormat.getLabel().c_str()];
    [pipelineStateDescriptor setSampleCount: mFormat.getSampleCount()];
    [pipelineStateDescriptor setVertexFunction:vertexProgram];
    [pipelineStateDescriptor setFragmentFunction:fragmentProgram];
    
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = (MTLPixelFormat)mFormat.getPixelFormat();
    pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float; // this is the only depth format

    MTLRenderPipelineColorAttachmentDescriptor *renderbufferAttachment = pipelineStateDescriptor.colorAttachments[0];
    renderbufferAttachment.blendingEnabled = mFormat.getBlendingEnabled();
    renderbufferAttachment.rgbBlendOperation = (MTLBlendOperation)mFormat.getColorBlendOperation();
    renderbufferAttachment.alphaBlendOperation = (MTLBlendOperation)mFormat.getAlphaBlendOperation();
    renderbufferAttachment.sourceRGBBlendFactor = (MTLBlendFactor)mFormat.getSrcColorBlendFactor();
    renderbufferAttachment.sourceAlphaBlendFactor = (MTLBlendFactor)mFormat.getSrcAlphaBlendFactor();
    renderbufferAttachment.destinationRGBBlendFactor = (MTLBlendFactor)mFormat.getDstColorBlendFactor();
    renderbufferAttachment.destinationAlphaBlendFactor = (MTLBlendFactor)mFormat.getDstAlphaBlendFactor();
    
    NSError* error = NULL;
    mImpl = (__bridge_retained void *)[device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if ( error )
    {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
}

RenderPipelineState::RenderPipelineState( void * mtlRenderPipelineStateRef ) :
mImpl( mtlRenderPipelineStateRef )
{
    assert(mImpl != NULL);
    assert([(__bridge id)mImpl conformsToProtocol:@protocol(MTLRenderPipelineState)]);
    CFRetain(mImpl);
}

RenderPipelineState::~RenderPipelineState()
{
    if ( mImpl )
    {
        CFRelease(mImpl);
    }
}
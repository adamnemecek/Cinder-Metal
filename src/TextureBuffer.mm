//
//  TextureBuffer.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/30/15.
//
//

#include "TextureBuffer.h"
#include "RendererMetalImpl.h"
#include "cinder/Log.h"
#include "cinder/cocoa/CinderCocoa.h"
#include "ImageHelpers.h"

using namespace std;
using namespace cinder;
using namespace cinder::mtl;

#define IMPL ((__bridge id <MTLTexture>)mImpl)

#pragma mark - Constructors

TextureBuffer::TextureBuffer( const ImageSourceRef & imageSource, Format format ) :
mFormat(format)
{
    CGImageRef imageRef = cocoa::createCgImage( imageSource, ImageTarget::Options() );

    MTLPixelFormat pxFormat = (MTLPixelFormat)mFormat.getPixelFormat();
    
    mChannelOrder = imageSource->getChannelOrder();
    mDataType = imageSource->getDataType();
    mColorModel = imageSource->getColorModel();
    
    if ( pxFormat == MTLPixelFormatInvalid )
    {
        pxFormat = mtlPixelFormatFromChannelOrder(mChannelOrder, mDataType);
        mFormat.setPixelFormat((PixelFormat)pxFormat);
    }
    
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    // Get the image data
    mBytesPerRow = CGImageGetBytesPerRow(imageRef);
    // NOTE: channelOrderNumChannels can return the wrong number of channels.
    // int numChannels = ImageIo::channelOrderNumChannels( mChannelOrder );
    long numCalculatedChannels = mBytesPerRow / width / dataSizeForType(mDataType);
    if ( numCalculatedChannels == 3 )
    {
        // Add another channel to the byte size.
        mBytesPerRow += mBytesPerRow / 3;
    }

    MTLTextureDescriptor *desc = [[MTLTextureDescriptor alloc] init];
    desc.textureType = (MTLTextureType)mFormat.getTextureType();
    desc.pixelFormat = pxFormat;
    desc.width = width;
    desc.height = height;
    desc.depth = mFormat.getDepth();
    desc.arrayLength = mFormat.getArrayLength();
    desc.usage = mFormat.getUsage();
    desc.mipmapLevelCount = mFormat.getMipmapLevel();
    desc.sampleCount = mFormat.getSampleCount();

    // Does this need to be CFRetained?
    mImpl = (__bridge_retained void *)[[RendererMetalImpl sharedRenderer].device newTextureWithDescriptor:desc];
    
    updateWidthCGImage( imageRef );
    
    CFRelease(imageRef);
}

TextureBuffer::~TextureBuffer()
{
    if ( mImpl )
    {
        CFRelease(mImpl);
    }
}

#pragma mark - Getting data

ImageSourceRef TextureBuffer::createSource()
{
    return ImageSourceRef( new ImageSourceTextureBuffer( *this ) );
}

void TextureBuffer::getPixelData( void *pixelBytes )
{
     // TODO: Account for cubes and arrays
    [IMPL getBytes:pixelBytes
       bytesPerRow:mBytesPerRow
     bytesPerImage:mBytesPerRow * getHeight()
        fromRegion:MTLRegionMake2D(0, 0, getWidth(), getHeight())
       mipmapLevel:0
             slice:0];
}

#pragma mark - Setting Data

void TextureBuffer::update( const ImageSourceRef & imageSource )
{
    CGImageRef imageRef = cocoa::createCgImage( imageSource, ImageTarget::Options() );
    assert(mChannelOrder == imageSource->getChannelOrder());
    assert(mDataType == imageSource->getDataType());
    assert(mColorModel == imageSource->getColorModel());
    updateWidthCGImage( imageRef );
    CFRelease(imageRef);
}

void TextureBuffer::updateWidthCGImage( void * imageRef ) // CGImageRef
{
    NSUInteger width = CGImageGetWidth((CGImageRef)imageRef);
    NSUInteger height = CGImageGetHeight((CGImageRef)imageRef);
    assert(width == getWidth());
    assert(height == getHeight());
    
    CFDataRef imgData = CGDataProviderCopyData( CGImageGetDataProvider( (CGImageRef)imageRef ) );
    
    uint8_t *rawData = (uint8_t *) CFDataGetBytePtr(imgData);
    bool shouldFreeData = false;
    
    long bytesPerImageRow = CGImageGetBytesPerRow((CGImageRef)imageRef);
    long numCalculatedChannels = bytesPerImageRow / width / dataSizeForType(mDataType);
    if ( numCalculatedChannels == 3 )
    {
        uint8_t *newRawData = createFourChannelFromThreeChannel( ivec2(width, height), mDataType, rawData);
        CFRelease(imgData); // nee free( rawData );
        shouldFreeData = true;
        rawData = newRawData;
    }
    
    setPixelData(rawData);
    
    if ( shouldFreeData )
    {
        delete [] rawData;
    }
    else
    {
        CFRelease(imgData);
    }
    
    if ( [IMPL mipmapLevelCount] > 1 )
    {
        generateMipmap();
    }
}

void TextureBuffer::generateMipmap()
{
    id<MTLDevice> device = [RendererMetalImpl sharedRenderer].device;
    id<MTLCommandQueue> commandQueue = [device newCommandQueue];
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> commandEncoder = [commandBuffer blitCommandEncoder];
    [commandEncoder generateMipmapsForTexture:IMPL];
    [commandEncoder endEncoding];
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull) {
        NSLog(@"mipmap generation complete");
    }];
    [commandBuffer commit];
}

void TextureBuffer::setPixelData( void *pixelBytes )
{
    ivec2 size = getSize();
    assert( size.x > 0 );
    assert( size.y > 0 );

    [IMPL replaceRegion:MTLRegionMake2D(0, 0, size.x, size.y)
            mipmapLevel:0
                  slice:0
              withBytes:pixelBytes
            bytesPerRow:mBytesPerRow
          bytesPerImage:mBytesPerRow * size.y];
}

#pragma mark - Accessors

TextureBuffer::Format TextureBuffer::getFormat() const
{
    return mFormat;
}

long TextureBuffer::getWidth() const
{
    return [IMPL width];
}

long TextureBuffer::getHeight() const
{
    return [IMPL height];
}

long TextureBuffer::getDepth() const
{
    return [IMPL depth];
}

long TextureBuffer::getMipmapLevelCount()
{
    return [IMPL mipmapLevelCount];
}

long TextureBuffer::getSampleCount()
{
    return [IMPL sampleCount];
}

long TextureBuffer::getArrayLength()
{
    return [IMPL arrayLength];
}

bool TextureBuffer::getFramebufferOnly()
{
    return [IMPL isFramebufferOnly];
}

int TextureBuffer::getUsage() // AKA MTLTextureUsage
{
    return (int)[IMPL usage];
}

// Not implemented
// rootResource


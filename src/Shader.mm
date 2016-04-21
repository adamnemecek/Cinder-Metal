//
//  Shader.cpp
//  StockShader
//
//  Created by William Lindmeier on 4/18/16.
//
//

#include "Shader.h"
#include "RendererMetalImpl.h"
#include "cinder/Log.h"

using namespace std;

namespace cinder { namespace mtl {
    
#pragma mark - ShaderDef
    
    ShaderDef::ShaderDef()
    :
    mTextureMapping( false )
    //,mTextureMappingRectangle( false )
    ,mColor( false )
    ,mLambert( false )
    ,mPoints( false )
    ,mTextureArray( false )
    ,mBillboard( false )
    ,mUniformBasedPosAndTexCoord( false )
    {
//        mTextureSwizzleMask[0] = GL_RED;
//        mTextureSwizzleMask[1] = GL_GREEN;
//        mTextureSwizzleMask[2] = GL_BLUE;
//        mTextureSwizzleMask[3] = GL_ALPHA;
    }
    
    ShaderDef& ShaderDef::texture() // const TextureBufferRef &texture )
    {
        mTextureMapping = true;
//        if( texture && ( ! TextureBase::supportsHardwareSwizzle() ) )
//        mTextureSwizzleMask = texture->getSwizzleMask();
        return *this;
    }
    
    ShaderDef& ShaderDef::uniformBasedPosAndTexCoord()
    {
        mUniformBasedPosAndTexCoord = true;
        return *this;
    }
    
    ShaderDef& ShaderDef::color()
    {
        mColor = true;
        return *this;
    }
    
    ShaderDef& ShaderDef::lambert()
    {
        mLambert = true;
        return *this;
    }
    
    ShaderDef& ShaderDef::points()
    {
        mPoints = true;
        return *this;
    }

    ShaderDef& ShaderDef::textureArray()
    {
        mTextureMapping = true;
        mTextureArray = true;
        return *this;
    }

    ShaderDef& ShaderDef::billboard()
    {
        mBillboard = true;
        return *this;
    }

//    bool ShaderDef::isTextureSwizzleDefault() const
//    {
//        return mTextureSwizzleMask[0] == GL_RED &&
//        mTextureSwizzleMask[1] == GL_GREEN &&
//        mTextureSwizzleMask[2] == GL_BLUE &&
//        mTextureSwizzleMask[3] == GL_ALPHA;
//    }
//    
//    // this only works with RGBA values
//    std::string ShaderDef::getTextureSwizzleString() const
//    {
//        string result;
//        for( int i = 0; i < 4; ++i ) {
//            if( mTextureSwizzleMask[i] == GL_RED )
//            result += "r";
//            else if( mTextureSwizzleMask[i] == GL_GREEN )
//            result += "g";
//            else if( mTextureSwizzleMask[i] == GL_BLUE )
//            result += "b";
//            else
//            result += "a";
//        }
//        
//        return result;
//    }
    
    
    bool ShaderDef::operator<( const ShaderDef &rhs ) const
    {
        if( rhs.mTextureMapping != mTextureMapping )
        {
            return rhs.mTextureMapping;
        }

        if( rhs.mUniformBasedPosAndTexCoord != mUniformBasedPosAndTexCoord )
        {
            return rhs.mUniformBasedPosAndTexCoord;
        }
        
        if( rhs.mColor != mColor )
        {
            return rhs.mColor;
        }
//        else if( rhs.mTextureSwizzleMask[0] != mTextureSwizzleMask[0] )
//        return mTextureSwizzleMask[0] < rhs.mTextureSwizzleMask[0];
//        else if( rhs.mTextureSwizzleMask[1] != mTextureSwizzleMask[1] )
//        return mTextureSwizzleMask[1] < rhs.mTextureSwizzleMask[1];	
//        else if( rhs.mTextureSwizzleMask[2] != mTextureSwizzleMask[2] )
//        return mTextureSwizzleMask[2] < rhs.mTextureSwizzleMask[2];	
//        else if( rhs.mTextureSwizzleMask[3] != mTextureSwizzleMask[3] )
//        return mTextureSwizzleMask[3] < rhs.mTextureSwizzleMask[3];	

        if( rhs.mLambert != mLambert )
        {
            return rhs.mLambert;
        }
        
        if ( rhs.mBillboard != mBillboard )
        {
            return rhs.mBillboard;
        }
        
        if ( rhs.mTextureArray != mTextureArray )
        {
            return rhs.mTextureArray;
        }
        
        if ( rhs.mPoints )
        {
            return rhs.mPoints;
        }
        
        return false;
    }
    
#pragma mark Shader Builder
    
    
    std::string	PipelineBuilder::generateMetalLibrary( const ShaderDef &shader )
    {
        
        string library = ""
        "#include <metal_stdlib>\n"
        "#include <simd/simd.h>\n"
        "#include \"/Users/bill/Tools/cinder_master/blocks/Cinder-Metal/include/InstanceTypes.h\"\n"
        "#include \"/Users/bill/Tools/cinder_master/blocks/Cinder-Metal/include/ShaderUtils.h\"\n"
        "#include \"/Users/bill/Tools/cinder_master/blocks/Cinder-Metal/include/MetalConstants.h\"\n"
        "\n"
        "using namespace metal;\n"
        "using namespace cinder;\n"
        "using namespace cinder::mtl;\n"
        "\n"
        "typedef struct\n"
        "{\n"
        "    metal::packed_float4 ciPosition;\n";
        if ( shader.mLambert )
        {
            library += "    metal::packed_float3 ciNormal;\n";
        }
        if ( shader.mColor )
        {
            library += "    metal::packed_float4 ciColor;\n";
        }
        if ( shader.mTextureMapping )
        {
            library += "    metal::packed_float2 ciTexCoord0;\n";
        }
        library +=
        "} ciVertexIn_t;\n"
        "\n"
        "typedef struct\n"
        "{\n"
        "    float4 position [[position]];\n";
        if ( shader.mPoints )
        {
            library += "    float pointSize [[point_size]];\n";
        }
        if ( shader.mLambert )
        {
            library += "    float4 normal;\n";
        }

        library += "    float4 color;\n";
        
        if ( shader.mTextureMapping )
        {
            library +=
            "    float2 texCoords;\n"
            "    int texIndex;\n";
        }
        library +=
        "} ciVertexOut_t;\n"
        "\n";
        
        library += PipelineBuilder::generateVertexShader(shader);
        library += "";
        library +=  PipelineBuilder::generateFragmentShader(shader);
        return library;
    }

    std::string	PipelineBuilder::generateVertexShader( const ShaderDef &shader )
    {
        std::string s;
        
        s +=
        "vertex ciVertexOut_t ci_generated_vert(device const ciVertexIn_t* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],\n"
        "                                       device const uint* ciIndices [[ buffer(ciBufferIndexIndicies) ]],\n"
        "                                       device const Instance* instances [[ buffer(ciBufferIndexInstanceData) ]],\n"
        "                                       constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],\n";

        // TODO: Should these be in ciUniforms_t?
        if( shader.mUniformBasedPosAndTexCoord )
        {
            s += "                                       constant float3 ciPositionOffset;\n"
                 "                                       constant float3 ciPositionScale;\n";
            if( shader.mTextureMapping )
            {
                s+= "                                       constant float2 ciTexCoordOffset;\n"
                    "                                       constant float2 ciTexCoordScale;\n";
            }
        }
        s +=
        "                                       unsigned int vid [[ vertex_id ]],\n"
        "                                       uint i [[ instance_id ]] )\n"
        "{\n"
        "   ciVertexOut_t out;\n";
        
        s +=
        "   unsigned int vertIndex = ciIndices[vid];\n"
        "   ciVertexIn_t v = ciVerts[vertIndex];\n"
        "   matrix_float4x4 modelMat = ciUniforms.ciModelMatrix * instances[i].modelMatrix;\n";

        if ( shader.mBillboard )
        {
            // Billboard the texture.
            // NOTE: This only really works if the instance geometry is flat in the first place.
            s += "   modelMat = modelMat * rotationMatrix(ciUniforms.ciModelViewInverse);\n";
        }
        s += "   matrix_float4x4 mvpMat = ciUniforms.ciViewProjection * modelMat;\n";
        s += "   float4 pos = float4(v.ciPosition[0], v.ciPosition[1], v.ciPosition[2], 1.0f);\n";
        
        if ( shader.mUniformBasedPosAndTexCoord )
        {
            s += "   pos = float4( ciPositionOffset, 0 ) + float4( uPositionScale, 1 ) * pos;\n";
        }

        s += "   out.position = mvpMat * pos;\n";
        s += "   out.color = instances[i].color * ciUniforms.ciColor;\n";
        
        if ( shader.mColor )
        {
            s += "   out.color *= v.ciColor;\n";
        }
        
        if( shader.mTextureMapping )
        {
            s +=
            "   float texWidth = instances[i].texCoordRect[2] - instances[i].texCoordRect[0];\n"
            "   float texHeight = instances[i].texCoordRect[3] - instances[i].texCoordRect[1];\n"
            "   float2 texCoord(v.ciTexCoord0);\n"
            "   float2 instanceTexCoord(instances[i].texCoordRect[0] + texCoord.x * texWidth,\n"
            "                           instances[i].texCoordRect[1] + texCoord.y * texHeight);\n";

            if( shader.mUniformBasedPosAndTexCoord )
            {
                s += "   out.texCoords = ciTexCoordOffset + ciTexCoordScale * instanceTexCoord;\n";
            }
            else
            {
                s += "   out.texCoords = instanceTexCoord;\n";
            }
            
            if ( shader.mTextureArray )
            {
                 s += "   out.texIndex = instances[i].textureSlice;\n";
            }
        }
        
        if( shader.mLambert )
        {
            s += "   out.normal = ciUniforms.ciNormalMatrix4x4 * float4(v.ciNormal, 0.0);\n";
        }
        
        if( shader.mPoints )
        {
            s += "   out.pointSize = instances[i].scale;\n";
        }
        
        if( shader.mTextureMapping )
        {
            s += "   out.texIndex = instances[i].textureSlice;\n";
        }
        
        s +=
            "   return out;\n"
            "}\n\n";
        
        return s;
    }
    
    std::string	PipelineBuilder::generateFragmentShader( const ShaderDef &shader )
    {
        std::string s;
        
        // Default sampler
        if( shader.mTextureMapping )
        {
            s += "constexpr sampler ci_shader_sampler( coord::normalized,\n"
                 "                                     address::repeat,\n"
                 "                                     filter::linear,\n"
                 "                                     mip_filter::linear );\n";
        }
        
        s += "fragment float4 ci_generated_frag( ciVertexOut_t in [[ stage_in ]]";
        
        if( shader.mTextureMapping )
        {
            if ( shader.mTextureArray )
            {
                s += ",\n                               texture2d_array<float> texture [[ texture(ciTextureIndex0) ]]";
            }
            else
            {
                s += ",\n                               texture2d<float> texture [[ texture(ciTextureIndex0) ]]";
            }
            
            if ( shader.mPoints )
            {
                s += ",\n                               float2 pointCoord [[point_coord]],";
            }
        }
        s += " )\n"
        "{\n"
        "   float4 oColor = in.color;\n";

        if( shader.mTextureMapping )
        {
            if ( shader.mPoints )
            {
                if ( shader.mTextureArray )
                {
                    s += "   float4 texColor = texture.sample(ci_shader_sampler, pointCoord, in.texIndex);\n";
                }
                else
                {
                    s += "   float4 texColor = texture.sample(ci_shader_sampler, pointCoord);\n";
                }
            }
            else
            {
                if ( shader.mTextureArray )
                {
                    s += "   float4 texColor = texture.sample(ci_shader_sampler, in.texCoords, in.texIndex);\n";
                }
                else
                {
                    s += "   float4 texColor = texture.sample(ci_shader_sampler, in.texCoords);\n";
                }
            }
            s += "   oColor *= texColor;\n";
        }

        if( shader.mLambert )
        {
            s +=
            "   float3 L = float3( 0, 0, 1 );\n"
            "   float3 N = normalize( in.normal.xyz );\n"
            "   float lambert = max( 0.0, dot( N, L ) );\n"
            "   oColor *= float4( float3( lambert ), 1.0 );\n";
        }

        s +=
        "   return oColor;\n"
        "}\n\n";
        
        return s;
    }
    
    ci::mtl::RenderPipelineStateRef	PipelineBuilder::buildPipeline( const ShaderDef &shader,
                                                                    mtl::RenderPipelineState::Format format )
    {
        id<MTLDevice> device = [RendererMetalImpl sharedRenderer].device;
        std::string librarySource = PipelineBuilder::generateMetalLibrary(shader);
        CI_LOG_V("Generated Library:\n" << librarySource);
        NSError *compileError = nil;
        // Does this stick around or do we have to store it somewhere?
        id<MTLLibrary> library = [device newLibraryWithSource:[NSString stringWithUTF8String:librarySource.c_str()]
                                                      options:0
                                                        error:&compileError];
        
        if ( compileError )
        {
            NSLog(@"ERROR building pipeline:\n %@", compileError);
        }
        RenderPipelineStateRef pipeline = RenderPipelineState::create( "ci_generated_vert", "ci_generated_frag", format, (__bridge void *)library );
        return pipeline;
    }
    
} } // namespace cinder::mtl
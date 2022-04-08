Shader "Clouds"
{
    Properties
    {
        Vector4_6907abe1f48d448598e9887735512855("Rotate Projection", Vector) = (1, 0, 0, 0)
        Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3("Noise Scale", Float) = 10
        Vector1_0c5b2428ddeb4c708933467cb9580017("Noise Speed", Float) = 0.1
        Vector1_86ae0fb22a1244f8b69d3b42ff49b41a("Noise Height", Float) = 1
        Vector4_dc4c83d9566a45f6a3b8c3688391bd70("Noise Remap", Vector) = (0, 1, -1, 1)
        Color_120fc609838a435d8fe294e7d04829e3("Color Peak", Color) = (1, 1, 1, 0)
        Color_7e0753a0635d4fe2945b8613b3b2d68a("Color Valley", Color) = (0, 0, 0, 0)
        Vector1_9683eea605a8441b89e3928be702704c("Noise Edge 1", Float) = 0
        Vector1_233d60e2b1bc411295c2b1bca813c931("Noise Edge 2", Float) = 1
        Vector1_a2dc52ccdaac402eaf54facdf81d1596("Noise Power", Float) = 2
        Vector1_e449e13e054a412ab15ee135c6581db2("Base Scale", Float) = 5
        Vector1_859a120ac6334375bd98a7c7afbb5097("Base Speed", Float) = 0.2
        Vector1_17418c2f9aaa45169207c00473f07c3a("Base Strength", Float) = 2
        Vector1_a1f35636aba142d0a03f16713ea4c9eb("Emission Strength", Float) = 2
        Vector1_6c406c08666447a78de5a04b804e634c("Curvature Radius", Float) = 1
        Vector1_8525812ee2384c1496b3fea754ed232c("Fresnel Power", Float) = 1
        Vector1_a80a5eacd29347beb9cfab614bc57381("Fresnel Opacity", Float) = 1
        Vector1_d7e720a141434077b1ee0a63fed89079("Fade Depth", Float) = 100
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "UniversalMaterialType" = "Lit"
            "Queue"="Transparent"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_FORWARD
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpaceNormal;
            float3 TangentSpaceNormal;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if defined(LIGHTMAP_ON)
            float2 interp4 : TEXCOORD4;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp5 : TEXCOORD5;
            #endif
            float4 interp6 : TEXCOORD6;
            float4 interp7 : TEXCOORD7;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp5.xyz =  input.sh;
            #endif
            output.interp6.xyzw =  input.fogFactorAndVertexLight;
            output.interp7.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp4.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp5.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp6.xyzw;
            output.shadowCoord = input.interp7.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_6907abe1f48d448598e9887735512855;
        float Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
        float Vector1_0c5b2428ddeb4c708933467cb9580017;
        float Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
        float4 Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
        float4 Color_120fc609838a435d8fe294e7d04829e3;
        float4 Color_7e0753a0635d4fe2945b8613b3b2d68a;
        float Vector1_9683eea605a8441b89e3928be702704c;
        float Vector1_233d60e2b1bc411295c2b1bca813c931;
        float Vector1_a2dc52ccdaac402eaf54facdf81d1596;
        float Vector1_e449e13e054a412ab15ee135c6581db2;
        float Vector1_859a120ac6334375bd98a7c7afbb5097;
        float Vector1_17418c2f9aaa45169207c00473f07c3a;
        float Vector1_a1f35636aba142d0a03f16713ea4c9eb;
        float Vector1_6c406c08666447a78de5a04b804e634c;
        float Vector1_8525812ee2384c1496b3fea754ed232c;
        float Vector1_a80a5eacd29347beb9cfab614bc57381;
        float Vector1_d7e720a141434077b1ee0a63fed89079;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }

        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2);
            float _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0 = Vector1_6c406c08666447a78de5a04b804e634c;
            float _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2;
            Unity_Divide_float(_Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2, _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0, _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2);
            float _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2;
            Unity_Power_float(_Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2, 3, _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2);
            float3 _Multiply_691eb89021f547149374b45d891926fc_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2.xxx), _Multiply_691eb89021f547149374b45d891926fc_Out_2);
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float3 _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxx), _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2);
            float _Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0 = Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
            float3 _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2;
            Unity_Multiply_float(_Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2, (_Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0.xxx), _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2);
            float3 _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2);
            float3 _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            Unity_Add_float3(_Multiply_691eb89021f547149374b45d891926fc_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2, _Add_e84e1e7818474c478f879c76ac9b3455_Out_2);
            description.Position = _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_777475a6159b40c3b874ac3efe0cd620_Out_0 = Color_7e0753a0635d4fe2945b8613b3b2d68a;
            float4 _Property_74acdd1923b8439f8fff4d9104247134_Out_0 = Color_120fc609838a435d8fe294e7d04829e3;
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float4 _Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3;
            Unity_Lerp_float4(_Property_777475a6159b40c3b874ac3efe0cd620_Out_0, _Property_74acdd1923b8439f8fff4d9104247134_Out_0, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxxx), _Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3);
            float _Property_e8bec31f90cb415a85ea06f885bd7825_Out_0 = Vector1_8525812ee2384c1496b3fea754ed232c;
            float _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e8bec31f90cb415a85ea06f885bd7825_Out_0, _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3);
            float _Multiply_3bab79466b3b42bcb191285659709df7_Out_2;
            Unity_Multiply_float(_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2, _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3, _Multiply_3bab79466b3b42bcb191285659709df7_Out_2);
            float _Property_5d4314c3a1a3450d9e7743a8f7209946_Out_0 = Vector1_a80a5eacd29347beb9cfab614bc57381;
            float _Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2;
            Unity_Multiply_float(_Multiply_3bab79466b3b42bcb191285659709df7_Out_2, _Property_5d4314c3a1a3450d9e7743a8f7209946_Out_0, _Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2);
            float4 _Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2;
            Unity_Add_float4(_Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3, (_Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2.xxxx), _Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2);
            float _Property_761228832e8043d2aedc6546e51c6453_Out_0 = Vector1_a1f35636aba142d0a03f16713ea4c9eb;
            float4 _Multiply_5b5ed6ab87f44ed689510f156042d6aa_Out_2;
            Unity_Multiply_float(_Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2, (_Property_761228832e8043d2aedc6546e51c6453_Out_0.xxxx), _Multiply_5b5ed6ab87f44ed689510f156042d6aa_Out_2);
            float _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1);
            float4 _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0 = IN.ScreenPosition;
            float _Split_699bef9782054726bb90aafc54be8546_R_1 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[0];
            float _Split_699bef9782054726bb90aafc54be8546_G_2 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[1];
            float _Split_699bef9782054726bb90aafc54be8546_B_3 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[2];
            float _Split_699bef9782054726bb90aafc54be8546_A_4 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[3];
            float _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2;
            Unity_Subtract_float(_Split_699bef9782054726bb90aafc54be8546_A_4, 1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2);
            float _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2;
            Unity_Subtract_float(_SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2, _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2);
            float _Property_33b554743b964c10989a3aec2986f0f2_Out_0 = Vector1_d7e720a141434077b1ee0a63fed89079;
            float _Divide_f93a6d607f794925a18775c763f5147a_Out_2;
            Unity_Divide_float(_Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2, _Property_33b554743b964c10989a3aec2986f0f2_Out_0, _Divide_f93a6d607f794925a18775c763f5147a_Out_2);
            float _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            Unity_Saturate_float(_Divide_f93a6d607f794925a18775c763f5147a_Out_2, _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1);
            surface.BaseColor = (_Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2.xyz);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Emission = (_Multiply_5b5ed6ab87f44ed689510f156042d6aa_Out_2.xyz);
            surface.Metallic = 0;
            surface.Smoothness = 0;
            surface.Occlusion = 0;
            surface.Alpha = _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);


            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
        #pragma multi_compile _ _GBUFFER_NORMALS_OCT
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_GBUFFER
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpaceNormal;
            float3 TangentSpaceNormal;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if defined(LIGHTMAP_ON)
            float2 interp4 : TEXCOORD4;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp5 : TEXCOORD5;
            #endif
            float4 interp6 : TEXCOORD6;
            float4 interp7 : TEXCOORD7;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp5.xyz =  input.sh;
            #endif
            output.interp6.xyzw =  input.fogFactorAndVertexLight;
            output.interp7.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp4.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp5.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp6.xyzw;
            output.shadowCoord = input.interp7.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_6907abe1f48d448598e9887735512855;
        float Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
        float Vector1_0c5b2428ddeb4c708933467cb9580017;
        float Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
        float4 Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
        float4 Color_120fc609838a435d8fe294e7d04829e3;
        float4 Color_7e0753a0635d4fe2945b8613b3b2d68a;
        float Vector1_9683eea605a8441b89e3928be702704c;
        float Vector1_233d60e2b1bc411295c2b1bca813c931;
        float Vector1_a2dc52ccdaac402eaf54facdf81d1596;
        float Vector1_e449e13e054a412ab15ee135c6581db2;
        float Vector1_859a120ac6334375bd98a7c7afbb5097;
        float Vector1_17418c2f9aaa45169207c00473f07c3a;
        float Vector1_a1f35636aba142d0a03f16713ea4c9eb;
        float Vector1_6c406c08666447a78de5a04b804e634c;
        float Vector1_8525812ee2384c1496b3fea754ed232c;
        float Vector1_a80a5eacd29347beb9cfab614bc57381;
        float Vector1_d7e720a141434077b1ee0a63fed89079;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }

        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2);
            float _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0 = Vector1_6c406c08666447a78de5a04b804e634c;
            float _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2;
            Unity_Divide_float(_Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2, _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0, _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2);
            float _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2;
            Unity_Power_float(_Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2, 3, _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2);
            float3 _Multiply_691eb89021f547149374b45d891926fc_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2.xxx), _Multiply_691eb89021f547149374b45d891926fc_Out_2);
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float3 _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxx), _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2);
            float _Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0 = Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
            float3 _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2;
            Unity_Multiply_float(_Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2, (_Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0.xxx), _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2);
            float3 _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2);
            float3 _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            Unity_Add_float3(_Multiply_691eb89021f547149374b45d891926fc_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2, _Add_e84e1e7818474c478f879c76ac9b3455_Out_2);
            description.Position = _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_777475a6159b40c3b874ac3efe0cd620_Out_0 = Color_7e0753a0635d4fe2945b8613b3b2d68a;
            float4 _Property_74acdd1923b8439f8fff4d9104247134_Out_0 = Color_120fc609838a435d8fe294e7d04829e3;
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float4 _Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3;
            Unity_Lerp_float4(_Property_777475a6159b40c3b874ac3efe0cd620_Out_0, _Property_74acdd1923b8439f8fff4d9104247134_Out_0, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxxx), _Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3);
            float _Property_e8bec31f90cb415a85ea06f885bd7825_Out_0 = Vector1_8525812ee2384c1496b3fea754ed232c;
            float _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e8bec31f90cb415a85ea06f885bd7825_Out_0, _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3);
            float _Multiply_3bab79466b3b42bcb191285659709df7_Out_2;
            Unity_Multiply_float(_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2, _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3, _Multiply_3bab79466b3b42bcb191285659709df7_Out_2);
            float _Property_5d4314c3a1a3450d9e7743a8f7209946_Out_0 = Vector1_a80a5eacd29347beb9cfab614bc57381;
            float _Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2;
            Unity_Multiply_float(_Multiply_3bab79466b3b42bcb191285659709df7_Out_2, _Property_5d4314c3a1a3450d9e7743a8f7209946_Out_0, _Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2);
            float4 _Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2;
            Unity_Add_float4(_Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3, (_Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2.xxxx), _Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2);
            float _Property_761228832e8043d2aedc6546e51c6453_Out_0 = Vector1_a1f35636aba142d0a03f16713ea4c9eb;
            float4 _Multiply_5b5ed6ab87f44ed689510f156042d6aa_Out_2;
            Unity_Multiply_float(_Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2, (_Property_761228832e8043d2aedc6546e51c6453_Out_0.xxxx), _Multiply_5b5ed6ab87f44ed689510f156042d6aa_Out_2);
            float _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1);
            float4 _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0 = IN.ScreenPosition;
            float _Split_699bef9782054726bb90aafc54be8546_R_1 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[0];
            float _Split_699bef9782054726bb90aafc54be8546_G_2 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[1];
            float _Split_699bef9782054726bb90aafc54be8546_B_3 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[2];
            float _Split_699bef9782054726bb90aafc54be8546_A_4 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[3];
            float _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2;
            Unity_Subtract_float(_Split_699bef9782054726bb90aafc54be8546_A_4, 1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2);
            float _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2;
            Unity_Subtract_float(_SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2, _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2);
            float _Property_33b554743b964c10989a3aec2986f0f2_Out_0 = Vector1_d7e720a141434077b1ee0a63fed89079;
            float _Divide_f93a6d607f794925a18775c763f5147a_Out_2;
            Unity_Divide_float(_Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2, _Property_33b554743b964c10989a3aec2986f0f2_Out_0, _Divide_f93a6d607f794925a18775c763f5147a_Out_2);
            float _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            Unity_Saturate_float(_Divide_f93a6d607f794925a18775c763f5147a_Out_2, _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1);
            surface.BaseColor = (_Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2.xyz);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Emission = (_Multiply_5b5ed6ab87f44ed689510f156042d6aa_Out_2.xyz);
            surface.Metallic = 0;
            surface.Smoothness = 0;
            surface.Occlusion = 0;
            surface.Alpha = _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);


            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRGBufferPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_SHADOWCASTER
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_6907abe1f48d448598e9887735512855;
        float Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
        float Vector1_0c5b2428ddeb4c708933467cb9580017;
        float Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
        float4 Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
        float4 Color_120fc609838a435d8fe294e7d04829e3;
        float4 Color_7e0753a0635d4fe2945b8613b3b2d68a;
        float Vector1_9683eea605a8441b89e3928be702704c;
        float Vector1_233d60e2b1bc411295c2b1bca813c931;
        float Vector1_a2dc52ccdaac402eaf54facdf81d1596;
        float Vector1_e449e13e054a412ab15ee135c6581db2;
        float Vector1_859a120ac6334375bd98a7c7afbb5097;
        float Vector1_17418c2f9aaa45169207c00473f07c3a;
        float Vector1_a1f35636aba142d0a03f16713ea4c9eb;
        float Vector1_6c406c08666447a78de5a04b804e634c;
        float Vector1_8525812ee2384c1496b3fea754ed232c;
        float Vector1_a80a5eacd29347beb9cfab614bc57381;
        float Vector1_d7e720a141434077b1ee0a63fed89079;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2);
            float _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0 = Vector1_6c406c08666447a78de5a04b804e634c;
            float _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2;
            Unity_Divide_float(_Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2, _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0, _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2);
            float _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2;
            Unity_Power_float(_Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2, 3, _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2);
            float3 _Multiply_691eb89021f547149374b45d891926fc_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2.xxx), _Multiply_691eb89021f547149374b45d891926fc_Out_2);
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float3 _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxx), _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2);
            float _Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0 = Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
            float3 _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2;
            Unity_Multiply_float(_Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2, (_Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0.xxx), _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2);
            float3 _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2);
            float3 _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            Unity_Add_float3(_Multiply_691eb89021f547149374b45d891926fc_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2, _Add_e84e1e7818474c478f879c76ac9b3455_Out_2);
            description.Position = _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1);
            float4 _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0 = IN.ScreenPosition;
            float _Split_699bef9782054726bb90aafc54be8546_R_1 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[0];
            float _Split_699bef9782054726bb90aafc54be8546_G_2 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[1];
            float _Split_699bef9782054726bb90aafc54be8546_B_3 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[2];
            float _Split_699bef9782054726bb90aafc54be8546_A_4 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[3];
            float _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2;
            Unity_Subtract_float(_Split_699bef9782054726bb90aafc54be8546_A_4, 1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2);
            float _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2;
            Unity_Subtract_float(_SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2, _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2);
            float _Property_33b554743b964c10989a3aec2986f0f2_Out_0 = Vector1_d7e720a141434077b1ee0a63fed89079;
            float _Divide_f93a6d607f794925a18775c763f5147a_Out_2;
            Unity_Divide_float(_Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2, _Property_33b554743b964c10989a3aec2986f0f2_Out_0, _Divide_f93a6d607f794925a18775c763f5147a_Out_2);
            float _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            Unity_Saturate_float(_Divide_f93a6d607f794925a18775c763f5147a_Out_2, _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1);
            surface.Alpha = _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHONLY
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_6907abe1f48d448598e9887735512855;
        float Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
        float Vector1_0c5b2428ddeb4c708933467cb9580017;
        float Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
        float4 Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
        float4 Color_120fc609838a435d8fe294e7d04829e3;
        float4 Color_7e0753a0635d4fe2945b8613b3b2d68a;
        float Vector1_9683eea605a8441b89e3928be702704c;
        float Vector1_233d60e2b1bc411295c2b1bca813c931;
        float Vector1_a2dc52ccdaac402eaf54facdf81d1596;
        float Vector1_e449e13e054a412ab15ee135c6581db2;
        float Vector1_859a120ac6334375bd98a7c7afbb5097;
        float Vector1_17418c2f9aaa45169207c00473f07c3a;
        float Vector1_a1f35636aba142d0a03f16713ea4c9eb;
        float Vector1_6c406c08666447a78de5a04b804e634c;
        float Vector1_8525812ee2384c1496b3fea754ed232c;
        float Vector1_a80a5eacd29347beb9cfab614bc57381;
        float Vector1_d7e720a141434077b1ee0a63fed89079;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2);
            float _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0 = Vector1_6c406c08666447a78de5a04b804e634c;
            float _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2;
            Unity_Divide_float(_Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2, _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0, _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2);
            float _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2;
            Unity_Power_float(_Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2, 3, _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2);
            float3 _Multiply_691eb89021f547149374b45d891926fc_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2.xxx), _Multiply_691eb89021f547149374b45d891926fc_Out_2);
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float3 _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxx), _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2);
            float _Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0 = Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
            float3 _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2;
            Unity_Multiply_float(_Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2, (_Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0.xxx), _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2);
            float3 _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2);
            float3 _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            Unity_Add_float3(_Multiply_691eb89021f547149374b45d891926fc_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2, _Add_e84e1e7818474c478f879c76ac9b3455_Out_2);
            description.Position = _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1);
            float4 _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0 = IN.ScreenPosition;
            float _Split_699bef9782054726bb90aafc54be8546_R_1 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[0];
            float _Split_699bef9782054726bb90aafc54be8546_G_2 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[1];
            float _Split_699bef9782054726bb90aafc54be8546_B_3 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[2];
            float _Split_699bef9782054726bb90aafc54be8546_A_4 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[3];
            float _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2;
            Unity_Subtract_float(_Split_699bef9782054726bb90aafc54be8546_A_4, 1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2);
            float _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2;
            Unity_Subtract_float(_SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2, _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2);
            float _Property_33b554743b964c10989a3aec2986f0f2_Out_0 = Vector1_d7e720a141434077b1ee0a63fed89079;
            float _Divide_f93a6d607f794925a18775c763f5147a_Out_2;
            Unity_Divide_float(_Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2, _Property_33b554743b964c10989a3aec2986f0f2_Out_0, _Divide_f93a6d607f794925a18775c763f5147a_Out_2);
            float _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            Unity_Saturate_float(_Divide_f93a6d607f794925a18775c763f5147a_Out_2, _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1);
            surface.Alpha = _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 TangentSpaceNormal;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_6907abe1f48d448598e9887735512855;
        float Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
        float Vector1_0c5b2428ddeb4c708933467cb9580017;
        float Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
        float4 Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
        float4 Color_120fc609838a435d8fe294e7d04829e3;
        float4 Color_7e0753a0635d4fe2945b8613b3b2d68a;
        float Vector1_9683eea605a8441b89e3928be702704c;
        float Vector1_233d60e2b1bc411295c2b1bca813c931;
        float Vector1_a2dc52ccdaac402eaf54facdf81d1596;
        float Vector1_e449e13e054a412ab15ee135c6581db2;
        float Vector1_859a120ac6334375bd98a7c7afbb5097;
        float Vector1_17418c2f9aaa45169207c00473f07c3a;
        float Vector1_a1f35636aba142d0a03f16713ea4c9eb;
        float Vector1_6c406c08666447a78de5a04b804e634c;
        float Vector1_8525812ee2384c1496b3fea754ed232c;
        float Vector1_a80a5eacd29347beb9cfab614bc57381;
        float Vector1_d7e720a141434077b1ee0a63fed89079;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2);
            float _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0 = Vector1_6c406c08666447a78de5a04b804e634c;
            float _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2;
            Unity_Divide_float(_Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2, _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0, _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2);
            float _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2;
            Unity_Power_float(_Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2, 3, _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2);
            float3 _Multiply_691eb89021f547149374b45d891926fc_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2.xxx), _Multiply_691eb89021f547149374b45d891926fc_Out_2);
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float3 _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxx), _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2);
            float _Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0 = Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
            float3 _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2;
            Unity_Multiply_float(_Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2, (_Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0.xxx), _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2);
            float3 _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2);
            float3 _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            Unity_Add_float3(_Multiply_691eb89021f547149374b45d891926fc_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2, _Add_e84e1e7818474c478f879c76ac9b3455_Out_2);
            description.Position = _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 NormalTS;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1);
            float4 _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0 = IN.ScreenPosition;
            float _Split_699bef9782054726bb90aafc54be8546_R_1 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[0];
            float _Split_699bef9782054726bb90aafc54be8546_G_2 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[1];
            float _Split_699bef9782054726bb90aafc54be8546_B_3 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[2];
            float _Split_699bef9782054726bb90aafc54be8546_A_4 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[3];
            float _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2;
            Unity_Subtract_float(_Split_699bef9782054726bb90aafc54be8546_A_4, 1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2);
            float _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2;
            Unity_Subtract_float(_SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2, _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2);
            float _Property_33b554743b964c10989a3aec2986f0f2_Out_0 = Vector1_d7e720a141434077b1ee0a63fed89079;
            float _Divide_f93a6d607f794925a18775c763f5147a_Out_2;
            Unity_Divide_float(_Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2, _Property_33b554743b964c10989a3aec2986f0f2_Out_0, _Divide_f93a6d607f794925a18775c763f5147a_Out_2);
            float _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            Unity_Saturate_float(_Divide_f93a6d607f794925a18775c763f5147a_Out_2, _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Alpha = _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);



            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // Render State
            Cull Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_META
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float3 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.viewDirectionWS = input.interp2.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_6907abe1f48d448598e9887735512855;
        float Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
        float Vector1_0c5b2428ddeb4c708933467cb9580017;
        float Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
        float4 Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
        float4 Color_120fc609838a435d8fe294e7d04829e3;
        float4 Color_7e0753a0635d4fe2945b8613b3b2d68a;
        float Vector1_9683eea605a8441b89e3928be702704c;
        float Vector1_233d60e2b1bc411295c2b1bca813c931;
        float Vector1_a2dc52ccdaac402eaf54facdf81d1596;
        float Vector1_e449e13e054a412ab15ee135c6581db2;
        float Vector1_859a120ac6334375bd98a7c7afbb5097;
        float Vector1_17418c2f9aaa45169207c00473f07c3a;
        float Vector1_a1f35636aba142d0a03f16713ea4c9eb;
        float Vector1_6c406c08666447a78de5a04b804e634c;
        float Vector1_8525812ee2384c1496b3fea754ed232c;
        float Vector1_a80a5eacd29347beb9cfab614bc57381;
        float Vector1_d7e720a141434077b1ee0a63fed89079;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }

        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2);
            float _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0 = Vector1_6c406c08666447a78de5a04b804e634c;
            float _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2;
            Unity_Divide_float(_Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2, _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0, _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2);
            float _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2;
            Unity_Power_float(_Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2, 3, _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2);
            float3 _Multiply_691eb89021f547149374b45d891926fc_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2.xxx), _Multiply_691eb89021f547149374b45d891926fc_Out_2);
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float3 _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxx), _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2);
            float _Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0 = Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
            float3 _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2;
            Unity_Multiply_float(_Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2, (_Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0.xxx), _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2);
            float3 _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2);
            float3 _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            Unity_Add_float3(_Multiply_691eb89021f547149374b45d891926fc_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2, _Add_e84e1e7818474c478f879c76ac9b3455_Out_2);
            description.Position = _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_777475a6159b40c3b874ac3efe0cd620_Out_0 = Color_7e0753a0635d4fe2945b8613b3b2d68a;
            float4 _Property_74acdd1923b8439f8fff4d9104247134_Out_0 = Color_120fc609838a435d8fe294e7d04829e3;
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float4 _Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3;
            Unity_Lerp_float4(_Property_777475a6159b40c3b874ac3efe0cd620_Out_0, _Property_74acdd1923b8439f8fff4d9104247134_Out_0, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxxx), _Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3);
            float _Property_e8bec31f90cb415a85ea06f885bd7825_Out_0 = Vector1_8525812ee2384c1496b3fea754ed232c;
            float _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e8bec31f90cb415a85ea06f885bd7825_Out_0, _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3);
            float _Multiply_3bab79466b3b42bcb191285659709df7_Out_2;
            Unity_Multiply_float(_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2, _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3, _Multiply_3bab79466b3b42bcb191285659709df7_Out_2);
            float _Property_5d4314c3a1a3450d9e7743a8f7209946_Out_0 = Vector1_a80a5eacd29347beb9cfab614bc57381;
            float _Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2;
            Unity_Multiply_float(_Multiply_3bab79466b3b42bcb191285659709df7_Out_2, _Property_5d4314c3a1a3450d9e7743a8f7209946_Out_0, _Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2);
            float4 _Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2;
            Unity_Add_float4(_Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3, (_Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2.xxxx), _Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2);
            float _Property_761228832e8043d2aedc6546e51c6453_Out_0 = Vector1_a1f35636aba142d0a03f16713ea4c9eb;
            float4 _Multiply_5b5ed6ab87f44ed689510f156042d6aa_Out_2;
            Unity_Multiply_float(_Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2, (_Property_761228832e8043d2aedc6546e51c6453_Out_0.xxxx), _Multiply_5b5ed6ab87f44ed689510f156042d6aa_Out_2);
            float _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1);
            float4 _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0 = IN.ScreenPosition;
            float _Split_699bef9782054726bb90aafc54be8546_R_1 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[0];
            float _Split_699bef9782054726bb90aafc54be8546_G_2 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[1];
            float _Split_699bef9782054726bb90aafc54be8546_B_3 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[2];
            float _Split_699bef9782054726bb90aafc54be8546_A_4 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[3];
            float _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2;
            Unity_Subtract_float(_Split_699bef9782054726bb90aafc54be8546_A_4, 1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2);
            float _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2;
            Unity_Subtract_float(_SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2, _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2);
            float _Property_33b554743b964c10989a3aec2986f0f2_Out_0 = Vector1_d7e720a141434077b1ee0a63fed89079;
            float _Divide_f93a6d607f794925a18775c763f5147a_Out_2;
            Unity_Divide_float(_Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2, _Property_33b554743b964c10989a3aec2986f0f2_Out_0, _Divide_f93a6d607f794925a18775c763f5147a_Out_2);
            float _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            Unity_Saturate_float(_Divide_f93a6d607f794925a18775c763f5147a_Out_2, _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1);
            surface.BaseColor = (_Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2.xyz);
            surface.Emission = (_Multiply_5b5ed6ab87f44ed689510f156042d6aa_Out_2.xyz);
            surface.Alpha = _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);


            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph


            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            // Name: <None>
            Tags
            {
                "LightMode" = "Universal2D"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_2D
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float3 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.viewDirectionWS = input.interp2.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_6907abe1f48d448598e9887735512855;
        float Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
        float Vector1_0c5b2428ddeb4c708933467cb9580017;
        float Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
        float4 Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
        float4 Color_120fc609838a435d8fe294e7d04829e3;
        float4 Color_7e0753a0635d4fe2945b8613b3b2d68a;
        float Vector1_9683eea605a8441b89e3928be702704c;
        float Vector1_233d60e2b1bc411295c2b1bca813c931;
        float Vector1_a2dc52ccdaac402eaf54facdf81d1596;
        float Vector1_e449e13e054a412ab15ee135c6581db2;
        float Vector1_859a120ac6334375bd98a7c7afbb5097;
        float Vector1_17418c2f9aaa45169207c00473f07c3a;
        float Vector1_a1f35636aba142d0a03f16713ea4c9eb;
        float Vector1_6c406c08666447a78de5a04b804e634c;
        float Vector1_8525812ee2384c1496b3fea754ed232c;
        float Vector1_a80a5eacd29347beb9cfab614bc57381;
        float Vector1_d7e720a141434077b1ee0a63fed89079;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }

        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2);
            float _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0 = Vector1_6c406c08666447a78de5a04b804e634c;
            float _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2;
            Unity_Divide_float(_Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2, _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0, _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2);
            float _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2;
            Unity_Power_float(_Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2, 3, _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2);
            float3 _Multiply_691eb89021f547149374b45d891926fc_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2.xxx), _Multiply_691eb89021f547149374b45d891926fc_Out_2);
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float3 _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxx), _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2);
            float _Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0 = Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
            float3 _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2;
            Unity_Multiply_float(_Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2, (_Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0.xxx), _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2);
            float3 _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2);
            float3 _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            Unity_Add_float3(_Multiply_691eb89021f547149374b45d891926fc_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2, _Add_e84e1e7818474c478f879c76ac9b3455_Out_2);
            description.Position = _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_777475a6159b40c3b874ac3efe0cd620_Out_0 = Color_7e0753a0635d4fe2945b8613b3b2d68a;
            float4 _Property_74acdd1923b8439f8fff4d9104247134_Out_0 = Color_120fc609838a435d8fe294e7d04829e3;
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float4 _Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3;
            Unity_Lerp_float4(_Property_777475a6159b40c3b874ac3efe0cd620_Out_0, _Property_74acdd1923b8439f8fff4d9104247134_Out_0, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxxx), _Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3);
            float _Property_e8bec31f90cb415a85ea06f885bd7825_Out_0 = Vector1_8525812ee2384c1496b3fea754ed232c;
            float _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e8bec31f90cb415a85ea06f885bd7825_Out_0, _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3);
            float _Multiply_3bab79466b3b42bcb191285659709df7_Out_2;
            Unity_Multiply_float(_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2, _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3, _Multiply_3bab79466b3b42bcb191285659709df7_Out_2);
            float _Property_5d4314c3a1a3450d9e7743a8f7209946_Out_0 = Vector1_a80a5eacd29347beb9cfab614bc57381;
            float _Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2;
            Unity_Multiply_float(_Multiply_3bab79466b3b42bcb191285659709df7_Out_2, _Property_5d4314c3a1a3450d9e7743a8f7209946_Out_0, _Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2);
            float4 _Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2;
            Unity_Add_float4(_Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3, (_Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2.xxxx), _Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2);
            float _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1);
            float4 _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0 = IN.ScreenPosition;
            float _Split_699bef9782054726bb90aafc54be8546_R_1 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[0];
            float _Split_699bef9782054726bb90aafc54be8546_G_2 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[1];
            float _Split_699bef9782054726bb90aafc54be8546_B_3 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[2];
            float _Split_699bef9782054726bb90aafc54be8546_A_4 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[3];
            float _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2;
            Unity_Subtract_float(_Split_699bef9782054726bb90aafc54be8546_A_4, 1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2);
            float _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2;
            Unity_Subtract_float(_SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2, _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2);
            float _Property_33b554743b964c10989a3aec2986f0f2_Out_0 = Vector1_d7e720a141434077b1ee0a63fed89079;
            float _Divide_f93a6d607f794925a18775c763f5147a_Out_2;
            Unity_Divide_float(_Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2, _Property_33b554743b964c10989a3aec2986f0f2_Out_0, _Divide_f93a6d607f794925a18775c763f5147a_Out_2);
            float _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            Unity_Saturate_float(_Divide_f93a6d607f794925a18775c763f5147a_Out_2, _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1);
            surface.BaseColor = (_Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2.xyz);
            surface.Alpha = _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);


            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph


            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

            ENDHLSL
        }
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "UniversalMaterialType" = "Lit"
            "Queue"="Transparent"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_FORWARD
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpaceNormal;
            float3 TangentSpaceNormal;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if defined(LIGHTMAP_ON)
            float2 interp4 : TEXCOORD4;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp5 : TEXCOORD5;
            #endif
            float4 interp6 : TEXCOORD6;
            float4 interp7 : TEXCOORD7;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp5.xyz =  input.sh;
            #endif
            output.interp6.xyzw =  input.fogFactorAndVertexLight;
            output.interp7.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp4.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp5.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp6.xyzw;
            output.shadowCoord = input.interp7.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_6907abe1f48d448598e9887735512855;
        float Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
        float Vector1_0c5b2428ddeb4c708933467cb9580017;
        float Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
        float4 Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
        float4 Color_120fc609838a435d8fe294e7d04829e3;
        float4 Color_7e0753a0635d4fe2945b8613b3b2d68a;
        float Vector1_9683eea605a8441b89e3928be702704c;
        float Vector1_233d60e2b1bc411295c2b1bca813c931;
        float Vector1_a2dc52ccdaac402eaf54facdf81d1596;
        float Vector1_e449e13e054a412ab15ee135c6581db2;
        float Vector1_859a120ac6334375bd98a7c7afbb5097;
        float Vector1_17418c2f9aaa45169207c00473f07c3a;
        float Vector1_a1f35636aba142d0a03f16713ea4c9eb;
        float Vector1_6c406c08666447a78de5a04b804e634c;
        float Vector1_8525812ee2384c1496b3fea754ed232c;
        float Vector1_a80a5eacd29347beb9cfab614bc57381;
        float Vector1_d7e720a141434077b1ee0a63fed89079;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }

        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2);
            float _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0 = Vector1_6c406c08666447a78de5a04b804e634c;
            float _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2;
            Unity_Divide_float(_Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2, _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0, _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2);
            float _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2;
            Unity_Power_float(_Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2, 3, _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2);
            float3 _Multiply_691eb89021f547149374b45d891926fc_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2.xxx), _Multiply_691eb89021f547149374b45d891926fc_Out_2);
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float3 _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxx), _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2);
            float _Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0 = Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
            float3 _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2;
            Unity_Multiply_float(_Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2, (_Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0.xxx), _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2);
            float3 _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2);
            float3 _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            Unity_Add_float3(_Multiply_691eb89021f547149374b45d891926fc_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2, _Add_e84e1e7818474c478f879c76ac9b3455_Out_2);
            description.Position = _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_777475a6159b40c3b874ac3efe0cd620_Out_0 = Color_7e0753a0635d4fe2945b8613b3b2d68a;
            float4 _Property_74acdd1923b8439f8fff4d9104247134_Out_0 = Color_120fc609838a435d8fe294e7d04829e3;
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float4 _Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3;
            Unity_Lerp_float4(_Property_777475a6159b40c3b874ac3efe0cd620_Out_0, _Property_74acdd1923b8439f8fff4d9104247134_Out_0, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxxx), _Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3);
            float _Property_e8bec31f90cb415a85ea06f885bd7825_Out_0 = Vector1_8525812ee2384c1496b3fea754ed232c;
            float _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e8bec31f90cb415a85ea06f885bd7825_Out_0, _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3);
            float _Multiply_3bab79466b3b42bcb191285659709df7_Out_2;
            Unity_Multiply_float(_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2, _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3, _Multiply_3bab79466b3b42bcb191285659709df7_Out_2);
            float _Property_5d4314c3a1a3450d9e7743a8f7209946_Out_0 = Vector1_a80a5eacd29347beb9cfab614bc57381;
            float _Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2;
            Unity_Multiply_float(_Multiply_3bab79466b3b42bcb191285659709df7_Out_2, _Property_5d4314c3a1a3450d9e7743a8f7209946_Out_0, _Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2);
            float4 _Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2;
            Unity_Add_float4(_Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3, (_Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2.xxxx), _Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2);
            float _Property_761228832e8043d2aedc6546e51c6453_Out_0 = Vector1_a1f35636aba142d0a03f16713ea4c9eb;
            float4 _Multiply_5b5ed6ab87f44ed689510f156042d6aa_Out_2;
            Unity_Multiply_float(_Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2, (_Property_761228832e8043d2aedc6546e51c6453_Out_0.xxxx), _Multiply_5b5ed6ab87f44ed689510f156042d6aa_Out_2);
            float _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1);
            float4 _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0 = IN.ScreenPosition;
            float _Split_699bef9782054726bb90aafc54be8546_R_1 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[0];
            float _Split_699bef9782054726bb90aafc54be8546_G_2 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[1];
            float _Split_699bef9782054726bb90aafc54be8546_B_3 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[2];
            float _Split_699bef9782054726bb90aafc54be8546_A_4 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[3];
            float _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2;
            Unity_Subtract_float(_Split_699bef9782054726bb90aafc54be8546_A_4, 1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2);
            float _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2;
            Unity_Subtract_float(_SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2, _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2);
            float _Property_33b554743b964c10989a3aec2986f0f2_Out_0 = Vector1_d7e720a141434077b1ee0a63fed89079;
            float _Divide_f93a6d607f794925a18775c763f5147a_Out_2;
            Unity_Divide_float(_Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2, _Property_33b554743b964c10989a3aec2986f0f2_Out_0, _Divide_f93a6d607f794925a18775c763f5147a_Out_2);
            float _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            Unity_Saturate_float(_Divide_f93a6d607f794925a18775c763f5147a_Out_2, _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1);
            surface.BaseColor = (_Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2.xyz);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Emission = (_Multiply_5b5ed6ab87f44ed689510f156042d6aa_Out_2.xyz);
            surface.Metallic = 0;
            surface.Smoothness = 0;
            surface.Occlusion = 0;
            surface.Alpha = _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);


            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_SHADOWCASTER
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_6907abe1f48d448598e9887735512855;
        float Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
        float Vector1_0c5b2428ddeb4c708933467cb9580017;
        float Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
        float4 Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
        float4 Color_120fc609838a435d8fe294e7d04829e3;
        float4 Color_7e0753a0635d4fe2945b8613b3b2d68a;
        float Vector1_9683eea605a8441b89e3928be702704c;
        float Vector1_233d60e2b1bc411295c2b1bca813c931;
        float Vector1_a2dc52ccdaac402eaf54facdf81d1596;
        float Vector1_e449e13e054a412ab15ee135c6581db2;
        float Vector1_859a120ac6334375bd98a7c7afbb5097;
        float Vector1_17418c2f9aaa45169207c00473f07c3a;
        float Vector1_a1f35636aba142d0a03f16713ea4c9eb;
        float Vector1_6c406c08666447a78de5a04b804e634c;
        float Vector1_8525812ee2384c1496b3fea754ed232c;
        float Vector1_a80a5eacd29347beb9cfab614bc57381;
        float Vector1_d7e720a141434077b1ee0a63fed89079;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2);
            float _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0 = Vector1_6c406c08666447a78de5a04b804e634c;
            float _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2;
            Unity_Divide_float(_Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2, _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0, _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2);
            float _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2;
            Unity_Power_float(_Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2, 3, _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2);
            float3 _Multiply_691eb89021f547149374b45d891926fc_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2.xxx), _Multiply_691eb89021f547149374b45d891926fc_Out_2);
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float3 _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxx), _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2);
            float _Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0 = Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
            float3 _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2;
            Unity_Multiply_float(_Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2, (_Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0.xxx), _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2);
            float3 _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2);
            float3 _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            Unity_Add_float3(_Multiply_691eb89021f547149374b45d891926fc_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2, _Add_e84e1e7818474c478f879c76ac9b3455_Out_2);
            description.Position = _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1);
            float4 _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0 = IN.ScreenPosition;
            float _Split_699bef9782054726bb90aafc54be8546_R_1 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[0];
            float _Split_699bef9782054726bb90aafc54be8546_G_2 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[1];
            float _Split_699bef9782054726bb90aafc54be8546_B_3 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[2];
            float _Split_699bef9782054726bb90aafc54be8546_A_4 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[3];
            float _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2;
            Unity_Subtract_float(_Split_699bef9782054726bb90aafc54be8546_A_4, 1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2);
            float _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2;
            Unity_Subtract_float(_SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2, _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2);
            float _Property_33b554743b964c10989a3aec2986f0f2_Out_0 = Vector1_d7e720a141434077b1ee0a63fed89079;
            float _Divide_f93a6d607f794925a18775c763f5147a_Out_2;
            Unity_Divide_float(_Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2, _Property_33b554743b964c10989a3aec2986f0f2_Out_0, _Divide_f93a6d607f794925a18775c763f5147a_Out_2);
            float _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            Unity_Saturate_float(_Divide_f93a6d607f794925a18775c763f5147a_Out_2, _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1);
            surface.Alpha = _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHONLY
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_6907abe1f48d448598e9887735512855;
        float Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
        float Vector1_0c5b2428ddeb4c708933467cb9580017;
        float Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
        float4 Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
        float4 Color_120fc609838a435d8fe294e7d04829e3;
        float4 Color_7e0753a0635d4fe2945b8613b3b2d68a;
        float Vector1_9683eea605a8441b89e3928be702704c;
        float Vector1_233d60e2b1bc411295c2b1bca813c931;
        float Vector1_a2dc52ccdaac402eaf54facdf81d1596;
        float Vector1_e449e13e054a412ab15ee135c6581db2;
        float Vector1_859a120ac6334375bd98a7c7afbb5097;
        float Vector1_17418c2f9aaa45169207c00473f07c3a;
        float Vector1_a1f35636aba142d0a03f16713ea4c9eb;
        float Vector1_6c406c08666447a78de5a04b804e634c;
        float Vector1_8525812ee2384c1496b3fea754ed232c;
        float Vector1_a80a5eacd29347beb9cfab614bc57381;
        float Vector1_d7e720a141434077b1ee0a63fed89079;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2);
            float _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0 = Vector1_6c406c08666447a78de5a04b804e634c;
            float _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2;
            Unity_Divide_float(_Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2, _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0, _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2);
            float _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2;
            Unity_Power_float(_Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2, 3, _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2);
            float3 _Multiply_691eb89021f547149374b45d891926fc_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2.xxx), _Multiply_691eb89021f547149374b45d891926fc_Out_2);
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float3 _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxx), _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2);
            float _Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0 = Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
            float3 _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2;
            Unity_Multiply_float(_Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2, (_Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0.xxx), _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2);
            float3 _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2);
            float3 _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            Unity_Add_float3(_Multiply_691eb89021f547149374b45d891926fc_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2, _Add_e84e1e7818474c478f879c76ac9b3455_Out_2);
            description.Position = _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1);
            float4 _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0 = IN.ScreenPosition;
            float _Split_699bef9782054726bb90aafc54be8546_R_1 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[0];
            float _Split_699bef9782054726bb90aafc54be8546_G_2 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[1];
            float _Split_699bef9782054726bb90aafc54be8546_B_3 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[2];
            float _Split_699bef9782054726bb90aafc54be8546_A_4 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[3];
            float _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2;
            Unity_Subtract_float(_Split_699bef9782054726bb90aafc54be8546_A_4, 1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2);
            float _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2;
            Unity_Subtract_float(_SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2, _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2);
            float _Property_33b554743b964c10989a3aec2986f0f2_Out_0 = Vector1_d7e720a141434077b1ee0a63fed89079;
            float _Divide_f93a6d607f794925a18775c763f5147a_Out_2;
            Unity_Divide_float(_Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2, _Property_33b554743b964c10989a3aec2986f0f2_Out_0, _Divide_f93a6d607f794925a18775c763f5147a_Out_2);
            float _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            Unity_Saturate_float(_Divide_f93a6d607f794925a18775c763f5147a_Out_2, _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1);
            surface.Alpha = _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 TangentSpaceNormal;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_6907abe1f48d448598e9887735512855;
        float Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
        float Vector1_0c5b2428ddeb4c708933467cb9580017;
        float Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
        float4 Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
        float4 Color_120fc609838a435d8fe294e7d04829e3;
        float4 Color_7e0753a0635d4fe2945b8613b3b2d68a;
        float Vector1_9683eea605a8441b89e3928be702704c;
        float Vector1_233d60e2b1bc411295c2b1bca813c931;
        float Vector1_a2dc52ccdaac402eaf54facdf81d1596;
        float Vector1_e449e13e054a412ab15ee135c6581db2;
        float Vector1_859a120ac6334375bd98a7c7afbb5097;
        float Vector1_17418c2f9aaa45169207c00473f07c3a;
        float Vector1_a1f35636aba142d0a03f16713ea4c9eb;
        float Vector1_6c406c08666447a78de5a04b804e634c;
        float Vector1_8525812ee2384c1496b3fea754ed232c;
        float Vector1_a80a5eacd29347beb9cfab614bc57381;
        float Vector1_d7e720a141434077b1ee0a63fed89079;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2);
            float _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0 = Vector1_6c406c08666447a78de5a04b804e634c;
            float _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2;
            Unity_Divide_float(_Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2, _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0, _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2);
            float _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2;
            Unity_Power_float(_Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2, 3, _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2);
            float3 _Multiply_691eb89021f547149374b45d891926fc_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2.xxx), _Multiply_691eb89021f547149374b45d891926fc_Out_2);
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float3 _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxx), _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2);
            float _Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0 = Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
            float3 _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2;
            Unity_Multiply_float(_Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2, (_Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0.xxx), _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2);
            float3 _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2);
            float3 _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            Unity_Add_float3(_Multiply_691eb89021f547149374b45d891926fc_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2, _Add_e84e1e7818474c478f879c76ac9b3455_Out_2);
            description.Position = _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 NormalTS;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1);
            float4 _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0 = IN.ScreenPosition;
            float _Split_699bef9782054726bb90aafc54be8546_R_1 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[0];
            float _Split_699bef9782054726bb90aafc54be8546_G_2 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[1];
            float _Split_699bef9782054726bb90aafc54be8546_B_3 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[2];
            float _Split_699bef9782054726bb90aafc54be8546_A_4 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[3];
            float _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2;
            Unity_Subtract_float(_Split_699bef9782054726bb90aafc54be8546_A_4, 1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2);
            float _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2;
            Unity_Subtract_float(_SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2, _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2);
            float _Property_33b554743b964c10989a3aec2986f0f2_Out_0 = Vector1_d7e720a141434077b1ee0a63fed89079;
            float _Divide_f93a6d607f794925a18775c763f5147a_Out_2;
            Unity_Divide_float(_Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2, _Property_33b554743b964c10989a3aec2986f0f2_Out_0, _Divide_f93a6d607f794925a18775c763f5147a_Out_2);
            float _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            Unity_Saturate_float(_Divide_f93a6d607f794925a18775c763f5147a_Out_2, _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Alpha = _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);



            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // Render State
            Cull Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_META
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float3 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.viewDirectionWS = input.interp2.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_6907abe1f48d448598e9887735512855;
        float Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
        float Vector1_0c5b2428ddeb4c708933467cb9580017;
        float Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
        float4 Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
        float4 Color_120fc609838a435d8fe294e7d04829e3;
        float4 Color_7e0753a0635d4fe2945b8613b3b2d68a;
        float Vector1_9683eea605a8441b89e3928be702704c;
        float Vector1_233d60e2b1bc411295c2b1bca813c931;
        float Vector1_a2dc52ccdaac402eaf54facdf81d1596;
        float Vector1_e449e13e054a412ab15ee135c6581db2;
        float Vector1_859a120ac6334375bd98a7c7afbb5097;
        float Vector1_17418c2f9aaa45169207c00473f07c3a;
        float Vector1_a1f35636aba142d0a03f16713ea4c9eb;
        float Vector1_6c406c08666447a78de5a04b804e634c;
        float Vector1_8525812ee2384c1496b3fea754ed232c;
        float Vector1_a80a5eacd29347beb9cfab614bc57381;
        float Vector1_d7e720a141434077b1ee0a63fed89079;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }

        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2);
            float _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0 = Vector1_6c406c08666447a78de5a04b804e634c;
            float _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2;
            Unity_Divide_float(_Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2, _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0, _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2);
            float _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2;
            Unity_Power_float(_Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2, 3, _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2);
            float3 _Multiply_691eb89021f547149374b45d891926fc_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2.xxx), _Multiply_691eb89021f547149374b45d891926fc_Out_2);
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float3 _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxx), _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2);
            float _Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0 = Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
            float3 _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2;
            Unity_Multiply_float(_Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2, (_Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0.xxx), _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2);
            float3 _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2);
            float3 _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            Unity_Add_float3(_Multiply_691eb89021f547149374b45d891926fc_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2, _Add_e84e1e7818474c478f879c76ac9b3455_Out_2);
            description.Position = _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_777475a6159b40c3b874ac3efe0cd620_Out_0 = Color_7e0753a0635d4fe2945b8613b3b2d68a;
            float4 _Property_74acdd1923b8439f8fff4d9104247134_Out_0 = Color_120fc609838a435d8fe294e7d04829e3;
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float4 _Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3;
            Unity_Lerp_float4(_Property_777475a6159b40c3b874ac3efe0cd620_Out_0, _Property_74acdd1923b8439f8fff4d9104247134_Out_0, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxxx), _Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3);
            float _Property_e8bec31f90cb415a85ea06f885bd7825_Out_0 = Vector1_8525812ee2384c1496b3fea754ed232c;
            float _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e8bec31f90cb415a85ea06f885bd7825_Out_0, _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3);
            float _Multiply_3bab79466b3b42bcb191285659709df7_Out_2;
            Unity_Multiply_float(_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2, _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3, _Multiply_3bab79466b3b42bcb191285659709df7_Out_2);
            float _Property_5d4314c3a1a3450d9e7743a8f7209946_Out_0 = Vector1_a80a5eacd29347beb9cfab614bc57381;
            float _Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2;
            Unity_Multiply_float(_Multiply_3bab79466b3b42bcb191285659709df7_Out_2, _Property_5d4314c3a1a3450d9e7743a8f7209946_Out_0, _Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2);
            float4 _Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2;
            Unity_Add_float4(_Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3, (_Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2.xxxx), _Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2);
            float _Property_761228832e8043d2aedc6546e51c6453_Out_0 = Vector1_a1f35636aba142d0a03f16713ea4c9eb;
            float4 _Multiply_5b5ed6ab87f44ed689510f156042d6aa_Out_2;
            Unity_Multiply_float(_Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2, (_Property_761228832e8043d2aedc6546e51c6453_Out_0.xxxx), _Multiply_5b5ed6ab87f44ed689510f156042d6aa_Out_2);
            float _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1);
            float4 _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0 = IN.ScreenPosition;
            float _Split_699bef9782054726bb90aafc54be8546_R_1 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[0];
            float _Split_699bef9782054726bb90aafc54be8546_G_2 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[1];
            float _Split_699bef9782054726bb90aafc54be8546_B_3 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[2];
            float _Split_699bef9782054726bb90aafc54be8546_A_4 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[3];
            float _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2;
            Unity_Subtract_float(_Split_699bef9782054726bb90aafc54be8546_A_4, 1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2);
            float _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2;
            Unity_Subtract_float(_SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2, _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2);
            float _Property_33b554743b964c10989a3aec2986f0f2_Out_0 = Vector1_d7e720a141434077b1ee0a63fed89079;
            float _Divide_f93a6d607f794925a18775c763f5147a_Out_2;
            Unity_Divide_float(_Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2, _Property_33b554743b964c10989a3aec2986f0f2_Out_0, _Divide_f93a6d607f794925a18775c763f5147a_Out_2);
            float _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            Unity_Saturate_float(_Divide_f93a6d607f794925a18775c763f5147a_Out_2, _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1);
            surface.BaseColor = (_Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2.xyz);
            surface.Emission = (_Multiply_5b5ed6ab87f44ed689510f156042d6aa_Out_2.xyz);
            surface.Alpha = _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);


            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph


            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            // Name: <None>
            Tags
            {
                "LightMode" = "Universal2D"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_2D
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float3 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.viewDirectionWS = input.interp2.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_6907abe1f48d448598e9887735512855;
        float Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
        float Vector1_0c5b2428ddeb4c708933467cb9580017;
        float Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
        float4 Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
        float4 Color_120fc609838a435d8fe294e7d04829e3;
        float4 Color_7e0753a0635d4fe2945b8613b3b2d68a;
        float Vector1_9683eea605a8441b89e3928be702704c;
        float Vector1_233d60e2b1bc411295c2b1bca813c931;
        float Vector1_a2dc52ccdaac402eaf54facdf81d1596;
        float Vector1_e449e13e054a412ab15ee135c6581db2;
        float Vector1_859a120ac6334375bd98a7c7afbb5097;
        float Vector1_17418c2f9aaa45169207c00473f07c3a;
        float Vector1_a1f35636aba142d0a03f16713ea4c9eb;
        float Vector1_6c406c08666447a78de5a04b804e634c;
        float Vector1_8525812ee2384c1496b3fea754ed232c;
        float Vector1_a80a5eacd29347beb9cfab614bc57381;
        float Vector1_d7e720a141434077b1ee0a63fed89079;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }

        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2);
            float _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0 = Vector1_6c406c08666447a78de5a04b804e634c;
            float _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2;
            Unity_Divide_float(_Distance_d706b9cd6191449a976ac69f9f05dcc8_Out_2, _Property_45a6b97c772a411bb0c8d638fd2daca0_Out_0, _Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2);
            float _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2;
            Unity_Power_float(_Divide_e1482d87fec94e07bae96f14f3e6f575_Out_2, 3, _Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2);
            float3 _Multiply_691eb89021f547149374b45d891926fc_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_27f327aacf234aec9bc7f8a8c7d3affd_Out_2.xxx), _Multiply_691eb89021f547149374b45d891926fc_Out_2);
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float3 _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxx), _Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2);
            float _Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0 = Vector1_86ae0fb22a1244f8b69d3b42ff49b41a;
            float3 _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2;
            Unity_Multiply_float(_Multiply_b665c4ea627d42318ec392aa2bcf8ca3_Out_2, (_Property_9ab5040094884ec3aa5c1bda1e3f1f26_Out_0.xxx), _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2);
            float3 _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_1063ee6d2f4241d0bf8e59d2d6678a29_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2);
            float3 _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            Unity_Add_float3(_Multiply_691eb89021f547149374b45d891926fc_Out_2, _Add_eac4a34b4dbe4e4ca5820cfa473f538a_Out_2, _Add_e84e1e7818474c478f879c76ac9b3455_Out_2);
            description.Position = _Add_e84e1e7818474c478f879c76ac9b3455_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_777475a6159b40c3b874ac3efe0cd620_Out_0 = Color_7e0753a0635d4fe2945b8613b3b2d68a;
            float4 _Property_74acdd1923b8439f8fff4d9104247134_Out_0 = Color_120fc609838a435d8fe294e7d04829e3;
            float _Property_10c98146b24241ceb320776b64aa178a_Out_0 = Vector1_9683eea605a8441b89e3928be702704c;
            float _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0 = Vector1_233d60e2b1bc411295c2b1bca813c931;
            float4 _Property_11e533c6674c49d695e9a216ee95bf62_Out_0 = Vector4_6907abe1f48d448598e9887735512855;
            float _Split_105416c433c34e76a8c9a10426ecb0ad_R_1 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[0];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_G_2 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[1];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_B_3 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[2];
            float _Split_105416c433c34e76a8c9a10426ecb0ad_A_4 = _Property_11e533c6674c49d695e9a216ee95bf62_Out_0[3];
            float3 _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_11e533c6674c49d695e9a216ee95bf62_Out_0.xyz), _Split_105416c433c34e76a8c9a10426ecb0ad_A_4, _RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3);
            float _Property_9503579a04f04b50907a02ec06f385aa_Out_0 = Vector1_0c5b2428ddeb4c708933467cb9580017;
            float _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9503579a04f04b50907a02ec06f385aa_Out_0, _Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2);
            float2 _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_14f5d38775e243e49bd6591fe4e7cbda_Out_2.xx), _TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3);
            float _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0 = Vector1_5f3329fd8c1a4b2f9c5bb7dc5b54c3f3;
            float _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9cc4edab6ccf4ae99dc42f6a6eb5ab0b_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2);
            float2 _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3);
            float _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_890d6da85ce24a85b3f68a93a4cd7c6d_Out_3, _Property_b0b52e5bef524a10b61d4dcf50d4de5e_Out_0, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2);
            float _Add_8b2c33f747884f6a95a593a80b932f06_Out_2;
            Unity_Add_float(_GradientNoise_c7ce48457a654d78bcca1433a163ff89_Out_2, _GradientNoise_b55b315ca0534a58a31bda5732194ce5_Out_2, _Add_8b2c33f747884f6a95a593a80b932f06_Out_2);
            float _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2;
            Unity_Divide_float(_Add_8b2c33f747884f6a95a593a80b932f06_Out_2, 2, _Divide_b27098ef93e344a1843ff0830ce6498b_Out_2);
            float _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1;
            Unity_Saturate_float(_Divide_b27098ef93e344a1843ff0830ce6498b_Out_2, _Saturate_d6c291e702cf4279a7da4256d210150d_Out_1);
            float _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0 = Vector1_a2dc52ccdaac402eaf54facdf81d1596;
            float _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2;
            Unity_Power_float(_Saturate_d6c291e702cf4279a7da4256d210150d_Out_1, _Property_8b3ecc6a04914899acc9046bfcadfd98_Out_0, _Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2);
            float4 _Property_25c2a6dda0bb4139b149dab709f70259_Out_0 = Vector4_dc4c83d9566a45f6a3b8c3688391bd70;
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_R_1 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[0];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[1];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_B_3 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[2];
            float _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4 = _Property_25c2a6dda0bb4139b149dab709f70259_Out_0[3];
            float4 _Combine_7ccaefaa563f477391957580674a158f_RGBA_4;
            float3 _Combine_7ccaefaa563f477391957580674a158f_RGB_5;
            float2 _Combine_7ccaefaa563f477391957580674a158f_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_R_1, _Split_1a5c3faa2de1472c9fa3169f42308db5_G_2, 0, 0, _Combine_7ccaefaa563f477391957580674a158f_RGBA_4, _Combine_7ccaefaa563f477391957580674a158f_RGB_5, _Combine_7ccaefaa563f477391957580674a158f_RG_6);
            float4 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4;
            float3 _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5;
            float2 _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6;
            Unity_Combine_float(_Split_1a5c3faa2de1472c9fa3169f42308db5_B_3, _Split_1a5c3faa2de1472c9fa3169f42308db5_A_4, 0, 0, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGBA_4, _Combine_5c6186c319d2470fa4647707ed1a1a65_RGB_5, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6);
            float _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3;
            Unity_Remap_float(_Power_f7b68944ce1b43a7b025e3b1bfabcdbf_Out_2, _Combine_7ccaefaa563f477391957580674a158f_RG_6, _Combine_5c6186c319d2470fa4647707ed1a1a65_RG_6, _Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3);
            float _Absolute_660ec9d1dd4242f595a877934282a881_Out_1;
            Unity_Absolute_float(_Remap_f2e9abdb1afd4ff592b89b6bc86cb2a8_Out_3, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1);
            float _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3;
            Unity_Smoothstep_float(_Property_10c98146b24241ceb320776b64aa178a_Out_0, _Property_1c5cafc6b3a6444ba7c00f7f42609cf0_Out_0, _Absolute_660ec9d1dd4242f595a877934282a881_Out_1, _Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3);
            float _Property_ddae5ad5960f449e9142965b27886276_Out_0 = Vector1_859a120ac6334375bd98a7c7afbb5097;
            float _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_ddae5ad5960f449e9142965b27886276_Out_0, _Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2);
            float2 _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_ffdf8926f59b47ce95084b690b2a5d2d_Out_3.xy), float2 (1, 1), (_Multiply_4856c9d827f04b09a5b9427ce0b8198c_Out_2.xx), _TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3);
            float _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0 = Vector1_e449e13e054a412ab15ee135c6581db2;
            float _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7dd527646b5b4547b9facb177f7ced67_Out_3, _Property_683c31eb57764627bd89b66bf09ee0a9_Out_0, _GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2);
            float _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0 = Vector1_17418c2f9aaa45169207c00473f07c3a;
            float _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2;
            Unity_Multiply_float(_GradientNoise_908f74d7366b45d684e6e525006dae89_Out_2, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2);
            float _Add_926075c7e62649f08d5252c35378a485_Out_2;
            Unity_Add_float(_Smoothstep_ba4e729d25cf434b9f204d4cdbdaa932_Out_3, _Multiply_53281e2b6a5c4b6c91e36773a15f80ba_Out_2, _Add_926075c7e62649f08d5252c35378a485_Out_2);
            float _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2;
            Unity_Add_float(1, _Property_ea340c2e162c4fcda86ec58539fcc24b_Out_0, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2);
            float _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2;
            Unity_Divide_float(_Add_926075c7e62649f08d5252c35378a485_Out_2, _Add_523d1604abde4cbdb42e81c36ce6747f_Out_2, _Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2);
            float4 _Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3;
            Unity_Lerp_float4(_Property_777475a6159b40c3b874ac3efe0cd620_Out_0, _Property_74acdd1923b8439f8fff4d9104247134_Out_0, (_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2.xxxx), _Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3);
            float _Property_e8bec31f90cb415a85ea06f885bd7825_Out_0 = Vector1_8525812ee2384c1496b3fea754ed232c;
            float _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e8bec31f90cb415a85ea06f885bd7825_Out_0, _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3);
            float _Multiply_3bab79466b3b42bcb191285659709df7_Out_2;
            Unity_Multiply_float(_Divide_7cc51c9a9e094daab891b4d7c8f635a2_Out_2, _FresnelEffect_faa7b4bc89d74570a83a85eea30fb659_Out_3, _Multiply_3bab79466b3b42bcb191285659709df7_Out_2);
            float _Property_5d4314c3a1a3450d9e7743a8f7209946_Out_0 = Vector1_a80a5eacd29347beb9cfab614bc57381;
            float _Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2;
            Unity_Multiply_float(_Multiply_3bab79466b3b42bcb191285659709df7_Out_2, _Property_5d4314c3a1a3450d9e7743a8f7209946_Out_0, _Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2);
            float4 _Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2;
            Unity_Add_float4(_Lerp_da2aed6ca96444c19b2c433a8c5e4e98_Out_3, (_Multiply_3f986da11bc7420dbee553bbae5c72b0_Out_2.xxxx), _Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2);
            float _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1);
            float4 _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0 = IN.ScreenPosition;
            float _Split_699bef9782054726bb90aafc54be8546_R_1 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[0];
            float _Split_699bef9782054726bb90aafc54be8546_G_2 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[1];
            float _Split_699bef9782054726bb90aafc54be8546_B_3 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[2];
            float _Split_699bef9782054726bb90aafc54be8546_A_4 = _ScreenPosition_3aaa4ff20bb049c880d0073781fc6bdd_Out_0[3];
            float _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2;
            Unity_Subtract_float(_Split_699bef9782054726bb90aafc54be8546_A_4, 1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2);
            float _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2;
            Unity_Subtract_float(_SceneDepth_d70f946ac79c410ea2983c1b7883faef_Out_1, _Subtract_f3002067961d440d9df2b53b3944ef28_Out_2, _Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2);
            float _Property_33b554743b964c10989a3aec2986f0f2_Out_0 = Vector1_d7e720a141434077b1ee0a63fed89079;
            float _Divide_f93a6d607f794925a18775c763f5147a_Out_2;
            Unity_Divide_float(_Subtract_378c97fd7abe445eb61ed05768bc2899_Out_2, _Property_33b554743b964c10989a3aec2986f0f2_Out_0, _Divide_f93a6d607f794925a18775c763f5147a_Out_2);
            float _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            Unity_Saturate_float(_Divide_f93a6d607f794925a18775c763f5147a_Out_2, _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1);
            surface.BaseColor = (_Add_af9606ba7d3948d4b0f2f9d0f0abcc12_Out_2.xyz);
            surface.Alpha = _Saturate_cbafa1771d214e6c937ae44c1690c858_Out_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);


            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph


            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

            ENDHLSL
        }
    }
    CustomEditor "ShaderGraph.PBRMasterGUI"
    FallBack "Hidden/Shader Graph/FallbackError"
}
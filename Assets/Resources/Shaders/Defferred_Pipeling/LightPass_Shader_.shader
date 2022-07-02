Shader "Custom/LightPass_Shader_"
{
    Properties
    {
        _LightSmooth ("Light Smooth", Range(0, 1)) = 0.15
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _ShadowColor ("Shadow Color", Color) = (0.5, 0.45, 0.4, 1)
        _OuterShadowColor ("Outer Shadow Color", Color) = (0.8, 0.7, 0.7)
        _OutlineColor ("Outline Color", Color) = (1, 1, 1, 1)
        _OutlineStrength ("Outline Strength", Range(0, 1)) = 0.1
        _EdgeLightStrength ("Edge Light Strength", Range(0, 1)) = 1.0
        _BloomStrength ("Bloom Strength", Range(0.9, 1.0)) = 1.0
        _FaceShadowRange ("Shadow Range", Range(0.01, 1)) = 0.0
        _LegSkinColor ("Leg Skin Color", Color) = (0, 0, 0, 1)
        _TightsFresnel ("Tights Fresnel", Range(0, 1)) = 0.0
        _ThicknessWeight ("Thickness Weight", Range(1, 30)) = 5
        _ThicknessRange ("Thickness Range", Range(0, 0.5)) = 0.0
    }
    SubShader
    {
        Tags { "LightMode"="LightPass" }
        Cull Off
        ZTest Off
        ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define FACE_SHADINGMODEL 1
            #define HAIR_SHADINGMODEL 2
            #define CLOTH_SHADINGMODEL 3
            #define SKIN_SHADINGMODEL 4
            #define TIGHTS_SHADINGMODEL 5
            #define REFLECTION_SHADINGMODEL 6

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _GT0;
            sampler2D _GT1;
            sampler2D _GT2;
            sampler2D _GT3;
            sampler2D _gDepth;
            float _LightSmooth;
            float4 _BaseColor;
            float4 _ShadowColor;
            float4 _OuterShadowColor;
            float4 _OutlineColor;
            float _OutlineStrength;
            float _EdgeLightStrength;
            float _BloomStrength;
            float4 _LightDir;
            float4 _LightCol;
            float _FaceShadowRange;
            float4 _LegSkinColor;
            float _TightsFresnel;
            float _ThicknessWeight;
            float _ThicknessRange;
            float2 TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 FaceLighting(float3 albedo, float threshold, float3 normal, float3 pos, float3 lightDir)
            {
                //float3 lLerp = lerp(_ShadowColor, _BaseColor, visibility);
                float3 frontDir = mul(UNITY_MATRIX_M, float3(0.0f, 0.0f, 1.0f));
                float2 light_dir = normalize(lightDir.xz);
                float3 right = normalize(cross(frontDir, float3(0.0f, 1.0f, 0.0f)));
                float LoL = dot(normalize(-right.xz), light_dir);
                float RoL = dot(normalize(right.xz), light_dir);
                float FoL = dot(normalize(frontDir.xz), light_dir);
                float visibility = max((RoL >= 0.0) * smoothstep(threshold + _FaceShadowRange, threshold - _FaceShadowRange, (1.0 - FoL)), (LoL >= 0.0) * smoothstep(threshold - _FaceShadowRange, threshold + _FaceShadowRange, FoL));

                float3 lLerp = lerp(lerp(_ShadowColor, _OuterShadowColor, saturate(visibility * 5.0)), _BaseColor, saturate((visibility - 0.8) * 10.0));
                float3 V = normalize(lightDir - pos);
                float sss = saturate(dot(-normalize(lightDir + normal), V));
                return float4(albedo * lLerp, 1.0);
            }

            float4 HairLighting(float3 albedo, float NoV, float3 normal, float3 heighlightColor, float emission, float3 lightDir)
            {
                float NoL = saturate(dot(lightDir, normal));
                float3 heighlight = heighlightColor * (1.0 - NoV) * NoL;
                NoL = smoothstep(0.0f, _LightSmooth, NoL);
                float3 lLerp = lerp(lerp(_ShadowColor, _OuterShadowColor, saturate(NoL * 5.0)), _BaseColor, saturate((NoL - 0.8) * 5.0));
                return float4(albedo * lLerp + heighlight, 1.0f);
            }

            float4 ClothLighting(float3 albedo, float3 normal, float3 lightDir)
            {
                float NoL = saturate(dot(lightDir, normal));
                NoL = smoothstep(0.0f, _LightSmooth, NoL);
                float3 lLerp = lerp(lerp(_ShadowColor, _OuterShadowColor, saturate(NoL * 5.0)), _BaseColor, saturate((NoL - 0.8) * 5.0));
                return float4(albedo * lLerp, 1.0);
            }

            float4 SkinLighting(float3 albedo, float3 normal, float3 lightDir)
            {
                float NoL = saturate(dot(lightDir, normal));
                NoL = smoothstep(0.0f, _LightSmooth, NoL);
                float3 lLerp = lerp(lerp(_ShadowColor, _OuterShadowColor, saturate(NoL * 5.0)), _BaseColor, saturate((NoL - 0.8) * 5.0));
                return float4(albedo * lLerp, 1.0f);
            }

            float4 TightsLighting(float3 albedo, float3 normal, float3 lightDir, float3 pos, float thickness)
            {
                float3 N = normalize(normal);
                float3 V = _WorldSpaceCameraPos.xyz - pos;
                float2 H = normalize(V.xz + lightDir.xz);
                float3 viewFront = -normalize(UNITY_MATRIX_V[2].xyz);

                float distance = length(V);

                float NoL = saturate(dot(lightDir, normal));
                NoL = smoothstep(0.0f, _LightSmooth, NoL);
                float NoV = saturate(dot(normalize(V.xz), normalize(normal.xz)));
                float NoH = saturate(dot(normalize(N.xz), H));
                float F = _TightsFresnel + (1.0 - _TightsFresnel) * (pow(1.0 - NoV, 5));
                float3 highlight = (_LightCol.rgb * 0.5f) * pow(NoH, 128);
                float3 lLerp = lerp(lerp(_ShadowColor, _OuterShadowColor, saturate(NoL * 5.0)), _BaseColor, saturate((NoL - 0.8) * 5.0));
                // return float4(albedo * lLerp, 1.0f);
                float Tlerp = smoothstep(0.5 - _ThicknessRange, 0.5 + _ThicknessRange, thickness * _ThicknessWeight);
                return float4(lerp(albedo, _LegSkinColor, Tlerp) * (1.0f - F) * lLerp + lerp(float3(0, 0, 0), F * highlight, Tlerp * 0.5), 1.0f);
            }

            float4 ReflectionLighting(float3 normal, float depth)
            {
                return float4(1.0f, 1.0f, 1.0f, 1.0f);
            }

            void frag (v2f i,
                       out float4 color : SV_Target0,
                       out float4 light : SV_Target1)
            {
                color = float4(0.0f, 0.0f, 0.0f, 1.0f);
                float3 lightDir = normalize(_LightDir.xyz);

                float4 dataGT0 = tex2D(_GT0, i.uv);
                float4 dataGT1 = tex2D(_GT1, i.uv);
                float4 dataGT2 = tex2D(_GT2, i.uv);
                float4 dataGT3 = tex2D(_GT3, i.uv);
                int shadingModel = int(dataGT3.a);

                float SobelGX[9] = 
                {
                    -1.0f, -2.0f, -1.0f,
                    0.0f, 0.0f, 0.0f,
                    1.0f, 2.0f, 1.0f
                };

                float SobelGY[9] = 
                {
                    -1.0f, 0.0f, 1.0f,
                    -2.0f, 0.0f, 2.0f,
                    -1.0f, 0.0f, 1.0f
                };

                int UVoffset[3] = {-1, 0, 1};
                
                float depth_sum_x = 0.0f;
                float depth_sum_y = 0.0f;
                for(uint id = 0; id < 9; ++id)
                {
                    float tmp = 1.0f;
                    if(id != 4)
                    {
                        float2 new_uv = float2(i.uv.x + float(UVoffset[id % 3] * TexelSize.x), i.uv.y + float(UVoffset[id / 3] * TexelSize.y));
                        tmp = tex2D(_GT1, new_uv).a;
                    }
                    else
                    {
                        tmp = dataGT1.a;
                    }
                    depth_sum_x += (tmp * SobelGX[id]);
                    depth_sum_y += (tmp * SobelGY[id]);
                }
                float depth_sum = max(abs(depth_sum_x), abs(depth_sum_y));
                int isOutline = 0;
                if((depth_sum / dataGT1.a) > _OutlineStrength)isOutline = 1;
                if(isOutline == 0 && dot(normalize(dataGT1.rgb), lightDir) > 0.0 && (depth_sum / dataGT1.a) > _EdgeLightStrength)isOutline = 2;

                if(shadingModel == FACE_SHADINGMODEL)
                {
                    color = FaceLighting(dataGT0.rgb, dataGT0.a, dataGT1.rgb, dataGT2.rgb, lightDir);
                }
                else if(shadingModel == HAIR_SHADINGMODEL)
                {
                    color = HairLighting(dataGT0.rgb, dataGT0.a, dataGT1.rgb, dataGT2.rgb, dataGT2.a, lightDir);
                }
                else if(shadingModel == CLOTH_SHADINGMODEL)
                {
                    color = ClothLighting(dataGT0.rgb, dataGT1.rgb, lightDir);
                }
                else if(shadingModel == SKIN_SHADINGMODEL)
                {
                    color = SkinLighting(dataGT0.rgb, dataGT1.rgb, lightDir);
                }
                else if(shadingModel == TIGHTS_SHADINGMODEL)
                {
                    color = TightsLighting(dataGT0.rgb, dataGT1.rgb, lightDir, dataGT2.rgb, abs(dataGT2.a - dataGT3.r));
                }

                if(isOutline == 2)color = color * _LightCol * 2.0f;
                float L = 0.3f * color.r + 0.59f * color.g + 0.11f * color.b;
                if(L > _BloomStrength)
                {
                    light = float4(color.rgb, 1.0f);
                }
                else
                {
                    light = float4(0.0f, 0.0f, 0.0f, 1.0f);
                    if(isOutline == 1)
                        color.rgb = color.rgb / 2.0f;
                } 
            }
            ENDHLSL
        }
        
    }
    Fallback off
}

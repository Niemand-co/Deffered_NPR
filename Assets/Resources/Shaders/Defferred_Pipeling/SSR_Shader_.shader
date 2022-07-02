Shader "Custom/SSR_Shader_"
{
    Properties
    {
        _StepNum ("Step Num", int) = 100
        _HitBias ("Hit Bias", float) = 0.01
        _StepSize ("Step Size", Range(0, 1)) = 0.0
    }
    SubShader
    {
        Tags { "LightMode"="PostProcess" }
        ZTest Off
        ZWrite Off
        Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

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

            sampler2D _GT1;
            sampler2D _GT3;
            sampler2D _colorBuffer;
            int _StepNum;
            float _HitBias;
            float _StepSize;
            float4x4 _ViewProjectionMatrix;
            float4x4 _InverseViewProjectionMatrix;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float3 ScreenPosToWorldPos(float3 ScreenPos)
            {
                float4 NDCPos = float4(ScreenPos.xy * 2.0f - 1.0f, ScreenPos.z * -2.0f + 1.0f, 1.0f);
                float4 worldPos = mul(_InverseViewProjectionMatrix, NDCPos);
                return worldPos.xyz / worldPos.w;
            }

            void frag (v2f i,
                      out float4 color : SV_Target0)
            {
                int isReflection = int(tex2D(_GT3, i.uv).a);
                float4 dataColor = tex2D(_colorBuffer, i.uv);
                color = dataColor;
                if(isReflection != 6)return;

                float4 dataGT1 = tex2D(_GT1, i.uv);
                float depth = dataGT1.a;
                float3 N = dataGT1.xyz;
                
                float3 ScreenPos = float3(i.uv, depth);
                float3 worldPos = ScreenPosToWorldPos(ScreenPos);
                float3 V = normalize(worldPos - _WorldSpaceCameraPos.xyz);
                float3 R = normalize(reflect(V, N));
                float3 worldPosS = worldPos + R;
                float4 ScreenPosS = mul(_ViewProjectionMatrix, float4(worldPosS, 1.0f));
                ScreenPosS.xyz /= ScreenPosS.w;
                ScreenPosS.xy = ScreenPosS.xy * 0.5f + 0.5f;
                ScreenPosS.z = ScreenPosS.z * - 0.5 + 0.5;
                float3 stepDir = normalize(ScreenPosS.xyz - ScreenPos);

                float3 sampleUVz = ScreenPos;
                // color = float4(worldPosS, 1.0f);
                // return;
                for(int s = 0; s < _StepNum; ++s)
                {
                    sampleUVz += stepDir * _StepSize;
                    if(sampleUVz.z < 0.0f || sampleUVz.z > 1.0f)return;
                    float pixelDepth = tex2Dlod(_GT1, float4(sampleUVz.xy, 0.0f, 0.0f)).a;
                    if(abs(pixelDepth - sampleUVz.z) < _HitBias)
                    {
                        float3 reflectColor = tex2Dlod(_colorBuffer, float4(sampleUVz.xy, 0.0f, 0.0f)).rgb;
                        color = float4(reflectColor, 1.0f);
                        return;
                    }
                }
            }
            ENDHLSL
        }
    }
}

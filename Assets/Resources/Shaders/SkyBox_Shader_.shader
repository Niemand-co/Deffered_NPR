Shader "Custom/SkyBox_Shader_"
{
    Properties
    {
        _DayTopColor ("Day Top Color", Color) = (1, 1, 1, 1)
        _DayBottomColor ("Day Bottom Color", Color) = (1, 1, 1, 1)
        _DayEarthColor ("Day Earth Color", Color) = (1, 1, 1, 1)
        _DawnRange ("Dawn Range", Range(0, 0.3)) = 0.0
        _DuskTopColor ("Dusk Top Color", Color) = (1, 1, 1, 1)
        _DuskBottomColor ("Dusk Bottom Color", Color) = (1, 1, 1, 1)
        _DuskEarthColor ("Dusk Earth Color", Color) = (1, 1, 1, 1)
        _DuskRange ("Dusk Range", Range(0, 0.3)) = 0.0
        _NightTopColor ("Night Top Color", Color) = (1, 1, 1, 1)
        _NightBottomColor ("Night Bottom Color", Color) = (1, 1, 1, 1)
        _NightEarthColor ("Night Earth Color", Color) = (1, 1, 1, 1)
        _SunHaloColor ("Sun Halo Color", Color) = (1, 1, 1, 1)
        _SunHaloRadius ("Sun Halo Radius", Range(0.02, 0.08)) = 0.005
        _HorizonHaloColor ("Horizon Halo Color", Color) = (1, 1, 1, 1)
        _HorizonHaloRange ("Horizon Halo Range", Range(0.0, 1.0)) = 0.0
        _HorizonHaloStrength ("Horizon Halo Strength", Range(0.0, 1.0)) = 0.0
        _BloomRange ("Bloom Range", Range(1.0, 3.0)) = 1.5
        _SunRadius ("Sun Radius", Range(0.0005, 0.005)) = 0.0005
    }
    SubShader
    {
        Tags { "LightMode"="SkyBox" }
        ZTest LEqual
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
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            float4 _DayTopColor;
            float4 _DayBottomColor;
            float4 _DayEarthColor;
            float _DawnRange;
            float4 _DuskTopColor;
            float4 _DuskBottomColor;
            float4 _DuskEarthColor;
            float _DuskRange;
            float4 _NightTopColor;
            float4 _NightBottomColor;
            float4 _NightEarthColor;
            float4 _SunHaloColor;
            float _SunHaloRadius;
            float4 _HorizonHaloColor;
            float _HorizonHaloRange;
            float _HorizonHaloStrength;
            float _SunRadius;
            float _BloomRange;
            float4 _LightDir;

            v2f vert (appdata v)
            {
                v2f o;
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex).xyz;
                float3 viewPos = mul((float3x3)UNITY_MATRIX_V, o.worldPos);
                o.vertex = mul(UNITY_MATRIX_P, float4(viewPos, 1.0f));
                o.vertex.z = o.vertex.w;
                return o;
            }

            void frag (v2f i,
                       out float4 color : SV_Target0,
                       out float4 light : SV_Target1,
                       out float depth : SV_DEPTH) 
            {
                depth = 0.0f;
                light = float4(0.0f, 0.0f, 0.0f, 1.0f);
                float3 lightDir = normalize(_LightDir.xyz);
                float3 posVector = normalize(i.worldPos);
                float sunAngel = dot(posVector, lightDir);
                if(posVector.y > 0.0f && (1.0f - sunAngel) < _SunRadius)
                {
                    color = float4(2.0f, 2.0f, 2.0f, 1.0f);
                    light = color;
                    return;
                }
                float heightGradient = dot(posVector, float3(0.0f, 1.0f, 0.0f));
                float timeGradient = dot(lightDir, float3(0.0f, 1.0f, 0.0));
                fixed3 DayCol = lerp(_DayEarthColor.rgb, lerp(_DayBottomColor.rgb, _DayTopColor.rgb, saturate(heightGradient)), heightGradient >= 0.0f);
                fixed3 DuskCol = lerp(_DuskEarthColor.rgb, lerp(_DuskBottomColor.rgb, _DuskTopColor.rgb, saturate(heightGradient)), heightGradient >= 0.0f);
                fixed3 NightCol = lerp(_NightEarthColor.rgb, lerp(_NightBottomColor.rgb, _NightTopColor.rgb, saturate(heightGradient)), heightGradient >= 0.0f);
                float3 halo = float3(0, 0, 0);
                if(posVector.y > 0.0f && (1.0f - sunAngel) < _SunHaloRadius)
                {
                    halo += (_SunHaloColor.rgb * smoothstep(_SunHaloRadius, _SunRadius, 1.0f - sunAngel));
                }
                float horizon = saturate(dot(posVector, normalize(float3(posVector.x, 0.0f, posVector.z))));
                float cosTheta = saturate(dot(normalize(posVector.xz), normalize(lightDir.xz)));
                float horizonHaloArea = (1.0f - _HorizonHaloRange) * cosTheta * cosTheta + (2.0f * _HorizonHaloRange - 2.0f) * cosTheta + 1.0f;
                halo = saturate(halo + _HorizonHaloColor.rgb * smoothstep(horizonHaloArea, 1.0f, horizon) * _HorizonHaloStrength * horizonHaloArea);
                DuskCol += halo;

                fixed3 col = lerp(NightCol, lerp(DuskCol, DayCol, smoothstep(0.3f - _DawnRange, 0.3f + _DawnRange, timeGradient)), smoothstep(-0.3f - _DuskRange, -0.3f + _DuskRange, timeGradient));

                color = float4(col, 1.0f);
                float L = 0.3f * color.r + 0.59f * color.g + 0.11f * color.b;
                if(L > _BloomRange)light = color;
            }
            ENDHLSL
        }
    }
}

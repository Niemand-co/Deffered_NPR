Shader "Custom/Plane_Shader_"
{
    Properties
    {
        _StepNum ("Step Num", int) = 100
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode"="BasePass" }
            Cull Off
            ZTest Always

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            void frag (v2f i,
                      out float4 _GT0 : SV_Target0,
                      out float4 _GT1 : SV_Target1,
                      out float4 _GT3 : SV_Target3)
            {
                _GT0 = float4(1.0f, 1.0f, 1.0f, 1.0f);
                _GT1 = float4(normalize(i.normal), i.vertex.z);
                _GT3.a = 6.0f;
            }
            ENDHLSL
        }
    }
}

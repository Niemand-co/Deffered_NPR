Shader "Custom/Face_BasePass_Shader"
{
    Properties
    {
         _MainTex ("Texture", 2D) = "white" {}
         _ShadowMap ("Shadow Map", 2D) = "White" {}
         _Ramp ("Ramp", 2D) = "White" {}
    }
    SubShader
    {
        Tags { "LightMode"="BasePass" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define PI 3.1415926535

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 WorldPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _ShadowMap;
            float4 _ShadowMap_ST;
            sampler2D _Ramp;

            v2f vert (appdata v)
            {
                v2f o;
                o.WorldPos = mul(UNITY_MATRIX_M, v.vertex);
                o.vertex = mul(UNITY_MATRIX_VP, float4(o.WorldPos, 1.0f));
                o.uv = v.uv;
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            void frag (v2f i,
                        out float4 GT0 : SV_Target0,
                        out float4 GT1 : SV_Target1,
                        out float4 GT2 : SV_Target2,
                        out float4 GT3 : SV_Target3)
            {
                float3 col = tex2D(_MainTex, i.uv).rgb;
                float3 normal = normalize(i.normal);
                float threshold = tex2D(_ShadowMap, i.uv).r;

                GT0 = float4(col, threshold);
                GT1 = float4(normal, i.vertex.z);
                GT2 = float4(i.WorldPos, 0);
                GT3 = float4(0, 0, 0, 1.0);
            }
            ENDCG
        }
    }
}

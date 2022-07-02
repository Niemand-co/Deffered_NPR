Shader "Custom/Tights_BasePass_Shader"
{
    Properties
    {
         _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode"="BackPass" }
            Cull Front
            ZWrite Off
            ZTest Off

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
                float3 ObjectPos : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.ObjectPos = v.vertex.xyz;
                return o;
            }

            void frag (v2f i,
                       out float4 GT2 : SV_Target2)
            {
                GT2.a = i.ObjectPos.z;
            }

            ENDHLSL
        }

        Pass
        {
            Tags { "LightMode"="BasePass" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

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
                float3 WorldPos : TEXCOORD1;
                float3 ObjectPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.WorldPos = mul(UNITY_MATRIX_M, v.vertex);
                o.vertex = mul(UNITY_MATRIX_VP, float4(o.WorldPos, 1.0f));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.ObjectPos = v.vertex.xyz;
                return o;
            }

            void frag (v2f i,
                        out float4 GT0 : SV_Target0,
                        out float4 GT1 : SV_Target1,
                        out float4 GT2 : SV_Target2,
                        out float4 GT3 : SV_Target3)
            {
                float3 col = tex2D(_MainTex, i.uv).rgb;

                float3 normal = i.normal;
                GT0 = float4(col, 1.0);
                GT1 = float4(normal, i.vertex.z);
                GT2.rgb = i.WorldPos;
                GT3 = float4(i.ObjectPos.z, 0, 0, 5);
            }
            ENDHLSL
        }
    }
}

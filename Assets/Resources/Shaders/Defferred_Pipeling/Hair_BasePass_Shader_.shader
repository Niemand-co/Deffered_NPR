Shader "Custom/Hair_BasePass_Shader"
{
    Properties
    {
         _MainTex ("Main Texture", 2D) = "white" {}
         _Highlight ("Hightlight", 2D) = "white" {}
         _GodsEye ("God's Eye", 2D) = "White" {}
    }
    SubShader
    {
        Tags { "LightMode"="BasePass" }

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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 WorldPos : TEXCOORD1;
                float3 normal : NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Highlight;
            sampler2D _GodsEye;

            v2f vert (appdata v)
            {
                v2f o;
                o.WorldPos = mul(UNITY_MATRIX_M, v.vertex);
                o.vertex = mul(UNITY_MATRIX_VP, float4(o.WorldPos, 1.0));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            void frag (v2f i,
                        out float4 GT0 : SV_Target0,
                        out float4 GT1 : SV_Target1,
                        out float4 GT2 : SV_Target2,
                        out float4 GT3 : SV_Target3)
            {
                float4 BaseColor = tex2D(_MainTex, i.uv);
                float3 HeighlightColor = tex2D(_Highlight, i.uv).rgb;
                float3 normal = normalize(i.normal);
                float Nov = saturate(dot(normalize(_WorldSpaceCameraPos - i.WorldPos), normal));
                float3 emission = tex2D(_GodsEye, i.uv).rgb;

                GT0 = float4(BaseColor.rgb, Nov);
                GT1 = float4(normal, i.vertex.z);
                GT2 = float4(HeighlightColor, 0.0f);
                GT3 = float4(0, 0, 0, 2);
            }
            ENDHLSL
        }
    }
}

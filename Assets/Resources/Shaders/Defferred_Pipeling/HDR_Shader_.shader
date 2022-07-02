Shader "Custom/HDR_Shader_"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "LightMode"="PostProcess" }
        ZWrite Off
        ZTest Off
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

            sampler2D _ColorBuffer;
            sampler2D _BloomBuffer;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            void frag (v2f i,
                       out float4 color : SV_Target)
            {
                float3 col = tex2D(_ColorBuffer, i.uv).rgb;
                float3 bloom = tex2D(_BloomBuffer, i.uv).rgb;
                col += bloom;
                color = float4(col, 1.0f);
            }
            ENDHLSL
        }
    }
}

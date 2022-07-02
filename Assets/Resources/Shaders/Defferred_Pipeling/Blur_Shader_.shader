Shader "Custom/Blur_Shader_"
{
    Properties
    {
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
            
            sampler2D _ColorBuffer;
            int _Horizontal;
            float2 TexelSize;

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
                float weight[5] = {0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216};

                float3 col = tex2D(_ColorBuffer, i.uv).rgb * weight[0];

                if(_Horizontal == 1)
                {
                    for(int id = 1; id < 5; ++id)
                    {
                        col += (tex2D(_ColorBuffer, i.uv + float2(float(id) * TexelSize.x, 0.0f)).rgb * weight[id]);
                        col += (tex2D(_ColorBuffer, i.uv - float2(float(id) * TexelSize.x, 0.0f)).rgb * weight[id]);
                    }
                    color = float4(col, 1.0f);
                }
                else
                {
                    for(int id = 1; id < 5; ++id)
                    {
                        col += (tex2D(_ColorBuffer, i.uv + float2(0.0f, float(id) * TexelSize.y)).rgb * weight[id]);
                        col += (tex2D(_ColorBuffer, i.uv - float2(0.0f, float(id) * TexelSize.y)).rgb * weight[id]);
                    }
                    color = float4(col, 1.0f);
                }
            }
            ENDHLSL
        }
    }
}

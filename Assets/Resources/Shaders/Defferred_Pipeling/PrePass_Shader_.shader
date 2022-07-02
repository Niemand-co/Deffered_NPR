Shader "Custom/PrePass_Shader_"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="PrePass" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 Position : POSITION;
            };

            struct v2f
            {
                float4 ClipPos : SV_POSITION;
                float3 WorldPos : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.ClipPos = UnityObjectToClipPos(v.Position);
                o.WorldPos = mul(UNITY_MATRIX_M, v.Position);
                return o;
            }

            float4 pack(float depth)
            {
                float4 bitShift = float4(1.0, 256.0, 256.0 * 256.0, 256.0 * 256.0 * 256.0);
                float4 bitMask = float4(1.0 / 256.0, 1.0 / 256.0, 1.0 / 256.0, 0.0);
                float4 rgbaDepth = frac(depth * bitShift);
                rgbaDepth -= rgbaDepth.gbaa * bitMask;
                return rgbaDepth;
            }

            void frag (v2f i,
                        out float4 depth : SV_Target0)
            {
                float distance = length(_WorldSpaceCameraPos - i.WorldPos);
                distance /= _ProjectionParams.z;
                depth = pack(distance);
            }
            ENDCG
        }
    }
}

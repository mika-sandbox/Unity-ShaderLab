Shader "Mochizuki/Multiply"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2g
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2g vert (appdata v)
            {
                v2g o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            // 3 vertex to 6 vertex
            [maxvertexcount(6)]
            void geom(triangle v2g input[3], inout TriangleStream<v2g> stream)
            {
                v2g o = (v2g) 0;

                // original triangle
                for (int i = 0; i < 3; i++)
                {
                    o.uv = input[i].uv;
                    o.vertex = input[i].vertex;
                    
                    stream.Append(o);
                }

                stream.RestartStrip();

                // alter ego triangle
                for (int j = 0; j < 3; j++)
                {
                    o.uv = input[j].uv;
                    o.vertex = input[j].vertex + float4(1.5, 0, 0, 0);

                    stream.Append(o);
                }

                stream.RestartStrip();
            }

            fixed4 frag (v2g i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}

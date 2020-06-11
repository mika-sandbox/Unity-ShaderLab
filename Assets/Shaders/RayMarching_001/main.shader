Shader "Mochizuki/RayMarching 001"
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
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 pos : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            struct f2o
            {
                fixed4 color : SV_TARGET;
                float depth : SV_DEPTH;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata_full v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos = v.vertex.xyz;
                o.uv = v.texcoord;
                return o;
            }

            float box(float3 p, float3 q, float r)
            {
                float3 a = abs(p) - q;
                return length(max(a, float3(0, 0, 0)));
            }

            float2 rotation(float2 p, float a)
            {
                return float2(
                    p.x * cos(a) - p.y * sin(a),
                    p.x * sin(a) + p.y * cos(a)
                );
            }

            float map(float3 p) {
                float3 q = p;

                q.xy = rotation(q.xy, _Time.y);
                q.xz = rotation(q.xz, _Time.y);

                return box(q, float3(.1, .1, .1), 1);
            }

            float3 calcNormal(float3 position) {
                float2 xy = float2(0.001, 0);
                return normalize(
                    float3(
                        map(position + xy.xyy) - map(position - xy.xyy),
                        map(position + xy.yxy) - map(position - xy.yxy),
                        map(position + xy.yyx) - map(position - xy.yyx)
                    )
                );
            }

            f2o frag (v2f i) : SV_Target
            {
                const float2 position = 2 * i.uv - 1;
                const float3 rayOrigin = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1)).xyz;
                const float  fov = 1; // - dot(position, position);
                const float3 rayDir = normalize(float3(i.pos.xy, fov) - rayOrigin);

                float3 color = float3(0, 0, 0);
                float3 ray = rayOrigin;
                float  distance;
                float3 normal;
                int    k;
                float3 p;

                for (int j = 0; j < 192; j++)
                {
                    distance = map(ray);
                    if (distance < 0.001) {
                        normal = calcNormal(ray);
                        break;
                    }

                    k = j;
                    ray += distance * rayDir;
                    p = rayOrigin * ray;
                }
                
                if (k == 191) {
                    discard;
                }

                color += (float) k / 192;
                color += max(0, dot(normal, normalize(float3(0.5, 0.75, 0.25))));

                const float4 projection = UnityObjectToClipPos(float4(p, 1.0));

                f2o o = (f2o) 0;
                o.color = fixed4(color, 1.0);
                o.depth = projection.z / projection.w;

                return o;
            }
            ENDCG
        }
    }
}

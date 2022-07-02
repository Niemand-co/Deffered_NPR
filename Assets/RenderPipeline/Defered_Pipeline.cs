using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;
using Unity.Collections;

[ExecuteInEditMode]
public class Defered_Pipeline : RenderPipeline
{
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        Camera camera = cameras[0];
        context.SetupCameraProperties(camera);

        BasePass(context, camera);
        LightPass(context, camera);
        DrawSky(context, camera);
        PostProcess(context, camera);

        
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "Mapping";
        cmd.Clear();
        cmd.Blit(ScreenBuffer, BuiltinRenderTextureType.CameraTarget);
        context.ExecuteCommandBuffer(cmd);
        context.DrawSkybox(camera);
        context.Submit();
        cmd.Release();

    }

    private void BasePass(ScriptableRenderContext context, Camera camera)
    {
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "BasePass";

        cmd.SetRenderTarget(gbufferID, gdepth);
        cmd.ClearRenderTarget(true, true, new Vector4(0.0f, 0.0f, 0.0f, 0.0f));
        context.ExecuteCommandBuffer(cmd);

        camera.TryGetCullingParameters(out var cullingParameters);
        var cullingResults = context.Cull(ref cullingParameters);

        Lights = cullingResults.visibleLights;

        ShaderTagId shaderTagId = new ShaderTagId("BasePass");
        ShaderTagId backShader = new ShaderTagId("BackPass");
        SortingSettings srt = new SortingSettings(camera);
        DrawingSettings drs = new DrawingSettings(shaderTagId, srt);
        DrawingSettings backDr = new DrawingSettings(backShader, srt);
        FilteringSettings fils = FilteringSettings.defaultValue;

        context.DrawRenderers(cullingResults, ref drs, ref fils);
        context.DrawRenderers(cullingResults, ref backDr, ref fils);
        context.Submit();
    }

    private void LightPass(ScriptableRenderContext context, Camera camera)
    {
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "LightPass";
        cmd.SetGlobalTexture("_gDepth", gdepth);


        foreach(VisibleLight light in Lights)
        {
            Material mat = Resources.Load<Material>("Materials/LightPass_Material_");
            if(light.lightType == LightType.Directional)
            {
                MainLight = light;
                Vector4 lightDir = -light.localToWorldMatrix.GetColumn(2);

                mat.SetVector("_LightDir", lightDir);
                mat.SetVector("_LightCol", light.finalColor);
            }
            for(int i = 0; i < 4; ++i)
                mat.SetTexture("_GT" + i, gbuffers[i]);

            mat.SetVector("TexelSize", new Vector2(1.0f / Screen.width, 1.0f / Screen.height));
            cmd.SetRenderTarget(colorBufferID, gdepth);
            cmd.ClearRenderTarget(false, true, new Vector4(0, 0, 0, 1.0f));
            cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
            cmd.DrawMesh(quad, Matrix4x4.identity, mat, 0, 0);
            context.ExecuteCommandBuffer(cmd);
            context.Submit();
        }

        
    }

    private void DrawSky(ScriptableRenderContext context, Camera camera)
    {
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "Draw Sky";

        Material mat = Resources.Load<Material>("Materials/SkyBox_Material_");
        mat.SetVector("_LightDir", -MainLight.localToWorldMatrix.GetColumn(2));
        cmd.SetRenderTarget(colorBufferID, gdepth);
        cmd.SetViewProjectionMatrices(camera.worldToCameraMatrix, camera.projectionMatrix);
        cmd.DrawMesh(background, Matrix4x4.identity, mat, 0, 0);
        context.ExecuteCommandBuffer(cmd);
        context.Submit();
    }

    private void PostProcess(ScriptableRenderContext context, Camera camera)
    {
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "PostProcess";

        Material SSRMat = Resources.Load<Material>("Materials/SSR_Material_");
        SSRMat.SetTexture("_GT1", gbuffers[1]);
        SSRMat.SetTexture("_GT3", gbuffers[3]);
        SSRMat.SetTexture("_colorBuffer", colorBuffers[0]);
        Matrix4x4 VP = camera.projectionMatrix * camera.worldToCameraMatrix;
        SSRMat.SetMatrix("_ViewProjectionMatrix", VP);
        SSRMat.SetMatrix("_InverseViewProjectionMatrix", VP.inverse);
        cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
        cmd.SetRenderTarget(colorBufferID[2], gdepth);
        cmd.DrawMesh(quad, Matrix4x4.identity, SSRMat, 0, 0);
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        context.Submit();
        
        Material BloomMat = Resources.Load<Material>("Materials/Blur_Material_");
        BloomMat.SetVector("TexelSize", new Vector2(1.0f / Screen.width, 1.0f / Screen.height));
        cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        for(int i = 0; i < 20; ++i)
        {
            BloomMat.SetTexture("_ColorBuffer", colorBuffers[(i + 1) % 2]);
            BloomMat.SetInt("_Horizontal", (i % 2));
            cmd.SetRenderTarget(colorBufferID[i % 2]);
            cmd.DrawMesh(quad, Matrix4x4.identity, BloomMat, 0, 0);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            context.Submit();
        }

        Material HDRMat = Resources.Load<Material>("Materials/HDR_Material_");
        HDRMat.SetTexture("_ColorBuffer", colorBuffers[2]);
        HDRMat.SetTexture("_BloomBuffer", colorBuffers[0]);
        cmd.SetRenderTarget(ScreenBuffer);
        cmd.ClearRenderTarget(false, true, Color.black);
        cmd.DrawMesh(quad, Matrix4x4.identity, HDRMat, 0, 0);
        context.ExecuteCommandBuffer(cmd);
        context.Submit();
    }

    public Defered_Pipeline()
    {
        width = Screen.width;
        height = Screen.height;

        gdepth  = new RenderTexture(width, height, 24, RenderTextureFormat.Depth, RenderTextureReadWrite.Linear);
        
        gbuffers[0] = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        gbuffers[1] = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        gbuffers[2] = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        gbuffers[3] = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);

        colorBuffers[0] = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        colorBuffers[1] = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        colorBuffers[2] = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);

        ScreenBuffer = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);

        for(int i = 0; i < 4; ++i)
            gbufferID[i] = gbuffers[i];
        for(int i = 0; i < 3; ++i)
            colorBufferID[i] = colorBuffers[i];
            
        Vector3[] quadVertices = new Vector3[] {
            new Vector3(-1.0f, -1.0f, -1.0f),
            new Vector3(1.0f, -1.0f, -1.0f),
            new Vector3(1.0f, 1.0f, -1.0f),
            new Vector3(-1.0f, 1.0f, -1.0f)
        };
        Vector2[] quadUV = new Vector2[] {
            new Vector2(0.0f, 0.0f),
            new Vector2(1.0f, 0.0f),
            new Vector2(1.0f, 1.0f),
            new Vector2(0.0f, 1.0f)
        };
        int[] quadIndices = new int[6] {
            0, 1, 2,
            2, 3, 0
        };

        Vector3[] backgroundVertices = new Vector3[] {
            new Vector3(-1.0f, -1.0f, -1.0f),
            new Vector3(1.0f, -1.0f, -1.0f),
            new Vector3(1.0f, -1.0f, 1.0f),
            new Vector3(-1.0f, -1.0f, 1.0f),
            new Vector3(-1.0f, 1.0f, -1.0f),
            new Vector3(1.0f, 1.0f, -1.0f),
            new Vector3(1.0f, 1.0f, 1.0f),
            new Vector3(-1.0f, 1.0f, 1.0f)
        };
        int[] backgroundIndices = new int[] {
            3, 2, 1, 1, 0, 3,
            0, 1, 5, 5, 4, 0,
            1, 2, 6, 6, 5, 1,
            2, 3, 7, 7, 6, 2,
            3, 0, 4, 4, 7, 3,
            4, 5, 6, 6, 7, 4
        };

        Vector3[] PlaneVertices = new Vector3[] {
            new Vector3(-1000.0f, 1.5f, -1000.0f),
            new Vector3(1000.0f, 1.5f, -1000.0f),
            new Vector3(1000.0f, 1.5f, 1000.0f),
            new Vector3(-1000.0f, 1.5f, 1000.0f)
        };

        int[] PlaneIndices = new int[] {
            0, 1, 2,
            2, 3, 0
        };

        quad.vertices = quadVertices;
        quad.uv = quadUV;
        quad.triangles = quadIndices;

        background.vertices = backgroundVertices;
        background.triangles = backgroundIndices;

        plane.vertices = PlaneVertices;
        plane.triangles = PlaneIndices;
    }

    Mesh quad = new Mesh();
    Mesh background = new Mesh();
    Mesh plane = new Mesh();

    RenderTexture gdepth;
    RenderTexture[] gbuffers = new RenderTexture[4];
    RenderTargetIdentifier[] gbufferID = new RenderTargetIdentifier[4];
    RenderTexture[] colorBuffers = new RenderTexture[3];
    RenderTargetIdentifier[] colorBufferID = new RenderTargetIdentifier[3];
    RenderTexture ScreenBuffer;

    NativeArray<VisibleLight> Lights;
    VisibleLight MainLight;

    int width, height;

}

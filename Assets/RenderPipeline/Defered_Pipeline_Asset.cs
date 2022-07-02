using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Render/Defered_Pipeline")]
public class Defered_Pipeline_Asset : RenderPipelineAsset
{
    protected override RenderPipeline CreatePipeline()
    {
        return new Defered_Pipeline();
    }
}

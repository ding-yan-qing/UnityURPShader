using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public abstract class DingVolumeComponentBase : VolumeComponent, IPostProcessComponent
{
    public BoolParameter isRender = new BoolParameter(false);
    public abstract bool IsActive();
    public abstract bool IsTileCompatible();

}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ProceduralTextureGeneration : MonoBehaviour
{
    public Material material = null;

    #region Material properties 
    //仅用于组织代码
    [SerializeField, SetProperty("textureWidth")]
    //实现私有变量的序列号
    //SetProperty(）作者介绍的开源插件，需要下载安装，参考：https://zhuanlan.zhihu.com/p/37128524
    private int m_textureWidth = 512;
    //材质大小
    public int textureWidth {
        get{
            return m_textureWidth;

        }
        //get用于读取属性
        set{
            m_textureWidth = value;
            _UpdateMaterial();
        }
        //set用于设置（写入）属性
        //即set get 常用于私有变量的读写操作，并且可以通过if实现读写限定与控制
    }

	[SerializeField, SetProperty("backgroundColor")]
	private Color m_backgroundColor = Color.white;
    //背景颜色
	public Color backgroundColor {
		get {
			return m_backgroundColor;
		}
		set {
			m_backgroundColor = value;
			_UpdateMaterial();
		}
	}

	[SerializeField, SetProperty("circleColor")]
	private Color m_circleColor = Color.yellow;
    //圆圈颜色
	public Color circleColor {
		get {
			return m_circleColor;
		}
		set {
			m_circleColor = value;
			_UpdateMaterial();
		}
	}

	[SerializeField, SetProperty("blurFactor")]
	private float m_blurFactor = 2.0f;
    //模糊因子
	public float blurFactor {
		get {
			return m_blurFactor;
		}
		set {
			m_blurFactor = value;
			_UpdateMaterial();
		}
	}
	#endregion
    //仅用于区分代码块

    private Texture2D m_generatedTexture = null;
    //存放生成的纹理

    void Start()
    {
        if (material == null){
            Renderer renderer = gameObject.GetComponent<Renderer>();
            if (renderer == null){
                Debug.LogWarning("Cannot find a Renderer.");
                return;
            }
            material = renderer.sharedMaterial;
        }
    }
    //检查并获得材质球

    private void _UpdateMaterial(){
        if(material != null){
            //先确保材质不为空
            m_generatedTexture = _GenerateProcedureTexture();
            //自定义用于生成贴图的函数
            material.SetTexture("_BaseMap", m_generatedTexture);
            //给材质参数赋贴图的函数
        }
    }
    //用于实时更新材质贴图参数

    private Texture2D _GenerateProcedureTexture(){
        Texture2D proceduralTexture = new Texture2D(textureWidth,textureWidth);
        //生成一张2D纹理贴图
        float circleInterval = textureWidth / 4.0f;
        //定义圆心之间的距离
        float radius = textureWidth / 10.0f;
        //定义圆的半径
        float edgeBlur = 1.0f / blurFactor;
        //用模糊因子控制模糊效果

        for (int w = 0; w < textureWidth; w++){
            for (int h = 0; h < textureWidth; h++){
                Color pixel = backgroundColor;
                //遍历每个像素的颜色值

                for (int i = 0; i < 3; i++){
                    for (int j = 0; j < 3; j++){
                        Vector2 circleCenter = new Vector2(circleInterval * (i + 1), circleInterval * (j + 1));
                        //在二维平面书依次画九个圆，并确定圆心位置（行列数乘圆心间距离）
                        float dist = Vector2.Distance(new Vector2(w,h), circleCenter) - radius;
                        //计算像素与圆圈的距离
                        Color color = _MixColor(circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f), Mathf.SmoothStep(0.0f, 1.0f, dist * edgeBlur));
                        //调用下面定义的颜色插值混合函数
                        //SmoothStep（）函数可以实现形参1到形参2的平滑过度，类似clamp（）函数，并且可以把两个SmoothStep（）相减得到起伏的过度效果
                        pixel = _MixColor(pixel, color, color.a);
                        //进行颜色混合，得到最终的pixel颜色
                    }
                }

                proceduralTexture.SetPixel(w, h, pixel);
                //SetPixel()函数用于将坐标（w,h）位置设置为指定颜色
            }
        }
        proceduralTexture.Apply();
        //Texture2D.Apply()是写入像素的操作，代价较高，一般最后操作

        return proceduralTexture;
    }

    private Color _MixColor(Color color0, Color color1, float mixFactor){
        Color mixColor = Color.white;
        mixColor.r = Mathf.Lerp(color0.r, color1.r, mixFactor);
        mixColor.g = Mathf.Lerp(color0.g, color1.g, mixFactor);
        mixColor.b = Mathf.Lerp(color0.b, color1.b, mixFactor);
        mixColor.a = Mathf.Lerp(color0.a, color1.a, mixFactor);

        return mixColor;
    }
    //运用简单的插值函数获得一个混合颜色的函数
}

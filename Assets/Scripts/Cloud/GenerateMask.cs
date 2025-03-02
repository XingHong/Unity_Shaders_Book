using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteInEditMode]
public class GenerateMask : MonoBehaviour
{
    public int maskWidth;
    public int maskHeight;
    public int blockSize;
    //public Material blurMaterial;
    private Texture2D maskTexture2D;

    private Material material;

    private Color32[] blockColors;

    // Blur iterations - larger number means more blur.
    [Range(0, 4)]
    public int iterations = 3;

    // Blur spread for each iteration - larger value means more blur
    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;

    [Range(1, 8)]
    public int downSample = 2;

    [Range(0.0f, 4.0f)]
    public float luminanceThreshold = 0.6f;

    public Material bloomMaterial;

    public RenderTexture showexture2D;

    public Texture2D test2d;

    // Start is called before the first frame update
    void Start()
    {
        blockColors = new Color32[blockSize * blockSize];
        for (int i = 0; i < blockSize; ++i)
        {
            for (int j = 0; j < blockSize; ++j)
            {
                blockColors[i + j * blockSize] = new Color32(255, 255, 255, 255);
            }
        }
        material = GetComponent<MeshRenderer>().sharedMaterial;

        Texture2D tempMaskTexture2D = new Texture2D(maskWidth * blockSize, maskHeight * blockSize, TextureFormat.ARGB32, false);
        for (int y = 0; y < maskHeight * blockSize; y++)
        {
            for (int x = 0; x < maskWidth * blockSize; x++)
            {
                tempMaskTexture2D.SetPixel(x, y, new Color(0, 0, 0, 0)); //默认黑色              
                //tempMaskTexture2D.SetPixel(x, y, Color.red); //默认黑色
            }
        }
        tempMaskTexture2D.Apply();
        maskTexture2D = tempMaskTexture2D;
        material.SetTexture("_MaskTex", maskTexture2D);
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit;
            if (Physics.Raycast(ray, out hit, 10000, LayerMask.GetMask("Water")))
            {
                Vector2 uv = hit.textureCoord;
                Vector2 localPos = new Vector2(uv.x * maskWidth, uv.y * maskHeight);
                //取整拿到x,y
                int x = Mathf.FloorToInt(localPos.x);
                int y = Mathf.FloorToInt(localPos.y);
                Debug.Log("点击到物体:" + hit.collider.gameObject + ",uv:" + uv + ", 位置:" + localPos + $",(x,y):({x},{y})");
                maskTexture2D.SetPixels32(x * blockSize, y * blockSize, blockSize, blockSize, blockColors);
                maskTexture2D.Apply();
                //maskTexture2D = ProcessBlur(maskTexture2D);
                var targetTex = new Texture2D(maskWidth * blockSize, maskHeight * blockSize, TextureFormat.ARGB32, false);
                SSEDTGenerator.GenerateSDF(maskTexture2D, targetTex);
                test2d = targetTex;
            }
        }
    }

    public Texture2D ProcessBlur(Texture2D sourceTexture)
    {
        int width = maskWidth * blockSize / downSample;
        int height = maskHeight * blockSize / downSample;
        // 创建临时RenderTexture
        RenderTexture bloomRT = RenderTexture.GetTemporary(
            width,
            height,
            0,
            RenderTextureFormat.ARGB32
        );


        bloomMaterial.SetFloat("_LuminanceThreshold", luminanceThreshold);

        RenderTexture buffer0 = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGB32);
        //buffer0.filterMode = FilterMode.Bilinear;

        Graphics.Blit(sourceTexture, buffer0, bloomMaterial, 0);



        for (int i = 0; i < iterations; i++)
        {
            bloomMaterial.SetFloat("_BlurSize", 1.0f + i * blurSpread);

            RenderTexture buffer1 = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGB32);

            // Render the vertical pass
            Graphics.Blit(buffer0, buffer1, bloomMaterial, 1);

            RenderTexture.ReleaseTemporary(buffer0);
            buffer0 = buffer1;
            buffer1 = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGB32);

            // Render the horizontal pass
            Graphics.Blit(buffer0, buffer1, bloomMaterial, 2);

            RenderTexture.ReleaseTemporary(buffer0);
            buffer0 = buffer1;
        }

        RenderTexture tmp = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGB32);
        Graphics.Blit(buffer0, tmp);

        showexture2D = tmp;

        bloomMaterial.SetTexture("_Bloom", buffer0);
        Graphics.Blit(sourceTexture, bloomRT, bloomMaterial, 3);

        RenderTexture.ReleaseTemporary(buffer0);

        RenderTexture.active = bloomRT;
        sourceTexture.ReadPixels(new Rect(0, 0, bloomRT.width, bloomRT.height), 0, 0);       
        sourceTexture.Apply();

        // 释放资源
        RenderTexture.ReleaseTemporary(bloomRT);
        RenderTexture.active = null;
        
        return sourceTexture;
    }
}
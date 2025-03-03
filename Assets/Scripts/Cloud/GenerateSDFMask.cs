using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// 云雾方案2：使用有效距离场来实现云雾效果
[ExecuteInEditMode]
public class GenerateSDFMask : MonoBehaviour
{
    //注意：要构造一个128*128的遮罩贴图，配合sdf算法，不然生成的sdf贴图有可能是黑色，下面是根据参数特意构造的贴图
    [Tooltip("横向格子数")]
    public int maskWidth = 8;
    [Tooltip("竖向格子数")]
    public int maskHeight = 8;
    [Tooltip("格子像素大小")]
    public int blockSize = 16;
    
    private Texture2D maskTexture2D;
    private Texture2D sdfTexture2D;

    private Material material;

    private Color32[] blockColors;

    // Start is called before the first frame update
    void Start()
    {
        int totalWidth = maskWidth * blockSize;
        int totalHeight = maskHeight * blockSize;
        blockColors = new Color32[blockSize * blockSize];
        for (int i = 0; i < blockSize; ++i)
        {
            for (int j = 0; j < blockSize; ++j)
            {
                blockColors[i + j * blockSize] = new Color32(255, 255, 255, 255);
            }
        }
        material = GetComponent<MeshRenderer>().sharedMaterial;

        var tempMaskTexture2D = CreateTexture(totalWidth, totalHeight, new Color(0, 0, 0, 0));
        maskTexture2D = tempMaskTexture2D;
        //sdf贴图大小是原始遮罩的四份之一，这样关联，采样的时候也贴合正式噪声图
        tempMaskTexture2D = CreateTexture(totalWidth / 2, totalHeight / 2, new Color(0, 0, 0, 0));
        sdfTexture2D = tempMaskTexture2D;
        material.SetTexture("_MaskTex", sdfTexture2D);
    }

    private Texture2D CreateTexture(int width, int height, Color color)
    {
        Texture2D res = new Texture2D(width, height, TextureFormat.ARGB32, false);
        for (int y = 0; y < width; y++)
        {
            for (int x = 0; x < height; x++)
            {
                res.SetPixel(x, y, color); //默认黑色              

            }
        }
        res.Apply();
        return res;
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
                sdfTexture2D = UnityDistanceFieldGenerator.GenerateSDF(maskTexture2D, sdfTexture2D);
            }
        }
    }
}
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteInEditMode]
public class GenerateMask : MonoBehaviour
{
    public int maskWidth;
    public int maskHeight;
    public int blockSize;
    private Texture2D maskTexture2D;

    private Material material;

    private Color32[] blockColors;

    // Start is called before the first frame update
    void Start()
    {
        blockColors = new Color32[blockSize * blockSize];
        for (int i = 0; i < blockSize; ++i)
        {
            for (int j = 0; j < blockSize; ++j)
            {
                blockColors[i + j * blockSize] = new Color(0, 1,1,1);
            }
        }
        material = GetComponent<MeshRenderer>().sharedMaterial;

        Texture2D tempMaskTexture2D = new Texture2D(maskWidth * blockSize, maskHeight * blockSize, TextureFormat.RGB24, false);
        for (int y = 0; y < maskHeight * blockSize; y++)
        {
            for (int x = 0; x < maskWidth * blockSize; x++)
            {
                tempMaskTexture2D.SetPixel(x, y, new Color(1, 1, 1, 1)); //默认全遮罩R为1                
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
            }
        }
    }
}
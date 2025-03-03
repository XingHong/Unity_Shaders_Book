using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class SdfCoverWindow : EditorWindow
{
    public Texture2D sourceTex;
    public Texture2D targetTex;
    [MenuItem("MyTools/SdfCoverWindow")]
    public static void ShowWindow()
    {
        // 显示现有窗口实例，如果没有，则创建一个新的
        var window = EditorWindow.GetWindow(typeof(SdfCoverWindow));
        window.position = new Rect(0, 0, 400, 200);
    }

    public void OnGUI()
    {
        sourceTex = (Texture2D)EditorGUI.ObjectField(new Rect(3, 3, 200, 40),
        "Add a Texture:",
        sourceTex,
        typeof(Texture2D), true);

        GUILayout.Space(45);
        if (sourceTex != null && GUILayout.Button("Cover"))
        {
            targetTex = new Texture2D(64, 64, TextureFormat.ARGB32, false);
            targetTex = UnityDistanceFieldGenerator.GenerateSDF(sourceTex, targetTex);
        }

        if (sourceTex)
        { 
            EditorGUI.PrefixLabel(new Rect(25, 45, 100, 20), 0, new GUIContent("Preview:"));
            EditorGUI.DrawPreviewTexture(new Rect(25, 80, 100, 100), sourceTex);
        }

        if (targetTex)
        {
            EditorGUI.DrawPreviewTexture(new Rect(140, 80, 100, 100), targetTex);
        }
    }
}

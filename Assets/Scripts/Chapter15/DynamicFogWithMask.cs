//动态雾，不会以视图uv为基准
using UnityEngine;
using System.Collections;

public class DynamicFogWithMask : PostEffectsBase {

	public Shader fogShader;
	private Material fogMaterial = null;

	public Material material {  
		get {
			fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
			return fogMaterial;
		}  
	}
	
	private Camera myCamera;
	public new Camera camera {
		get {
			if (myCamera == null) {
				myCamera = GetComponent<Camera>();
			}
			return myCamera;
		}
	}

	private Transform myCameraTransform;
	public Transform cameraTransform {
		get {
			if (myCameraTransform == null) {
				myCameraTransform = camera.transform;
			}
			
			return myCameraTransform;
		}
	}

	[Range(0.1f, 3.0f)]
	public float fogDensity = 1.0f;

	public Color fogColor = Color.white;

	public float fogStart = 0.0f;
	public float fogEnd = 2.0f;

	public Texture noiseTexture;

	public float noiseAmount = 25f;

	[Range(-0.5f, 0.5f)]
	public float fogSpeed = 0.1f;

	[Header("遮罩设置")]
	public Vector3 maskCenter = Vector3.one;    // 遮罩中心参考对象
	public float radius = 5f;       // 遮罩半径
	public float feather = 1f;      // 羽化范围

	[Header("调试")]
	public bool drawGizmos = true;


	void OnEnable() {
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
	}

	void OnDrawGizmos()
	{
		if (drawGizmos)
		{
			Gizmos.color = Color.cyan;
			Gizmos.DrawWireSphere(maskCenter, radius);
			Gizmos.color = Color.blue;
			Gizmos.DrawWireSphere(maskCenter, radius + feather);
		}
	}

	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			Matrix4x4 frustumCorners = Matrix4x4.identity;
			
			float fov = camera.fieldOfView;
			float near = camera.nearClipPlane;
			float aspect = camera.aspect;
			
			float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
			Vector3 toRight = cameraTransform.right * halfHeight * aspect;
			Vector3 toTop = cameraTransform.up * halfHeight;
			
			Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
			float scale = topLeft.magnitude / near;
			
			topLeft.Normalize();
			topLeft *= scale;
			
			Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
			topRight.Normalize();
			topRight *= scale;
			
			Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
			bottomLeft.Normalize();
			bottomLeft *= scale;
			
			Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
			bottomRight.Normalize();
			bottomRight *= scale;
			
			frustumCorners.SetRow(0, bottomLeft);
			frustumCorners.SetRow(1, bottomRight);
			frustumCorners.SetRow(2, topRight);
			frustumCorners.SetRow(3, topLeft);

            material.SetMatrix("_FrustumCornersRay", frustumCorners);

            material.SetFloat("_FogDensity", fogDensity);
			material.SetColor("_FogColor", fogColor);
			material.SetFloat("_FogStart", fogStart);
			material.SetFloat("_FogEnd", fogEnd);

			material.SetTexture("_NoiseTex", noiseTexture);
			material.SetFloat("_NoiseAmount", noiseAmount);
			
			material.SetFloat("_FogSpeed", fogSpeed);

			material.SetVector("_MaskCenter", maskCenter);
			material.SetFloat("_MaskRadius", radius);
			material.SetFloat("_Feather", feather);

			Graphics.Blit (src, dest, material);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}

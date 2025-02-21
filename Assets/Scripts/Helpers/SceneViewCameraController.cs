using UnityEngine;

[RequireComponent(typeof(Camera))]
public class SceneViewCameraController : MonoBehaviour
{
    [Header("移动设置")]
    public float moveSpeed = 10f;         // 基础移动速度
    public float shiftMultiplier = 2f;    // Shift加速倍数

    [Header("旋转设置")]
    public float rotateSpeed = 50f;      // 旋转灵敏度
    public float maxVerticalAngle = 360f;  // 最大俯仰角度

    [Header("缩放设置")]
    public float zoomSpeed = 5f;          // 缩放速度
    public float minZoomDistance = 1f;    // 最近缩放距离
    public float maxZoomDistance = 100f;  // 最远缩放距离

    private Vector3 _targetPosition;      // 当前观察目标点
    private Vector3 _lastMousePosition;   // 上一帧鼠标位置
    private bool _isRightClick;             // 是否按右键

    void Start()
    {
        // 初始化目标点为摄像机前方10米位置
        _targetPosition = transform.position + transform.forward * 10f;
    }

    void Update()
    {
        HandleKeyboardMovement();
        HandleRotation();
        HandlePan();
        HandleZoom();
    }

    /// <summary>
    /// 处理右键旋转
    /// </summary>
    void HandleRotation()
    {
        // 右键按下开始旋转
        if (Input.GetMouseButtonDown(1))
        {
            _isRightClick = true;
            _lastMousePosition = Input.mousePosition;
            Cursor.visible = false;
            Cursor.lockState = CursorLockMode.Confined;
        }

        // 右键释放结束旋转
        if (Input.GetMouseButtonUp(1))
        {
            _isRightClick = false;
            Cursor.visible = true;
            Cursor.lockState = CursorLockMode.None;
        }

        if (_isRightClick)
        {
            Vector3 delta = Input.mousePosition - _lastMousePosition;

            // 计算旋转角度（考虑加速）
            float actualSpeed = rotateSpeed * (Input.GetKey(KeyCode.LeftShift) ? shiftMultiplier : 1f);
            float horizontal = delta.x * actualSpeed * Time.deltaTime;
            float vertical = -delta.y * actualSpeed * Time.deltaTime;

            float lastZ = transform.eulerAngles.z;
            // 水平旋转（围绕世界Y轴）
            transform.RotateAround(_targetPosition, Vector3.up, horizontal);
            transform.RotateAround(_targetPosition, Vector3.right, vertical);
            transform.eulerAngles = new Vector3(transform.eulerAngles.x, transform.eulerAngles.y, lastZ);

            _lastMousePosition = Input.mousePosition;
        }
    }

    /// <summary>
    /// 处理中键平移
    /// </summary>
    void HandlePan()
    {
        // 中键或Alt+左键平移
        if (Input.GetMouseButton(2) || (Input.GetMouseButton(0) && Input.GetKey(KeyCode.LeftAlt)))
        {
            Vector3 delta = Input.mousePosition - _lastMousePosition;

            // 计算实际移动速度
            float actualSpeed = moveSpeed * (Input.GetKey(KeyCode.LeftShift) ? shiftMultiplier : 1f);

            // 在摄像机坐标系下计算移动方向
            Vector3 move = new Vector3(-delta.x, -delta.y, 0) * actualSpeed * Time.deltaTime;
            Vector3 worldMove = transform.TransformDirection(move);

            // 同步更新摄像机位置和目标点
            transform.position += worldMove;
            _targetPosition += worldMove;

            _lastMousePosition = Input.mousePosition;
        }
    }

    /// <summary>
    /// 新增：处理键盘WASD移动
    /// </summary>
    void HandleKeyboardMovement()
    {
        Vector3 input = new Vector3(
            Input.GetKey(KeyCode.D) ? 1 : Input.GetKey(KeyCode.A) ? -1 : 0,
            0,
            Input.GetKey(KeyCode.W) ? 1 : Input.GetKey(KeyCode.S) ? -1 : 0
        );

        if (input.magnitude > 0.1f)
        {
            // 获取摄像机在XZ平面的前方向和右方向
            Vector3 forward = transform.forward;
            //forward.y = 0;
            forward.Normalize();

            Vector3 right = transform.right;
            //right.y = 0;
            right.Normalize();

            // 计算实际移动方向
            Vector3 moveDirection = (forward * input.z + right * input.x).normalized;

            // 计算实际速度（考虑Shift加速）
            float actualSpeed = moveSpeed * (Input.GetKey(KeyCode.LeftShift) ? shiftMultiplier : 1f);
            Vector3 movement = moveDirection * actualSpeed * Time.deltaTime;

            // 同步移动摄像机和目标点
            transform.position += movement;
            _targetPosition += movement;
        }
    }


    /// <summary>
    /// 处理滚轮缩放
    /// </summary>
    void HandleZoom()
    {
        float scroll = Input.GetAxis("Mouse ScrollWheel");
        if (Mathf.Abs(scroll) > 0.01f)
        {
            // 计算缩放方向
            Vector3 zoomDirection = transform.forward * scroll * zoomSpeed;

            // 限制缩放范围
            float newDistance = Vector3.Distance(transform.position + zoomDirection, _targetPosition);
            if (newDistance > minZoomDistance && newDistance < maxZoomDistance)
            {
                transform.position += zoomDirection;
            }
        }
    }
}
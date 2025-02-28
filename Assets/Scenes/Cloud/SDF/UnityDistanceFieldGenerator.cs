using UnityEngine;

public class SSEDTGenerator
{
    private struct Point
    {
        public int dx, dy;
        public int DistSq => dx * dx + dy * dy;

        public Point(int x, int y)
        {
            dx = x;
            dy = y;
        }

        public static Point operator +(Point a, Point b) => new Point(a.dx + b.dx, a.dy + b.dy);
    }

    public static Texture2D Generate(Texture2D source, int maxDistance = 64)
    {
        int width = source.width;
        int height = source.height;

        // 获取原始像素数据并进行二值化处理
        Color32[] pixels = source.GetPixels32();
        bool[,] binary = new bool[width, height];
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                Color32 c = pixels[y * width + x];
                binary[x, y] = (c.r + c.g + c.b) > 384; // 简化亮度计算
            }
        }

        // 初始化网格
        Point[,] grid = InitializeGrid(width, height, binary, maxDistance);

        // 生成距离场
        GenerateSEDT(grid, width, height, maxDistance);

        // 创建输出纹理
        return CreateOutputTexture(grid, width, height, maxDistance);
    }

    private static Point[,] InitializeGrid(int width, int height, bool[,] binary, int maxDistance)
    {
        Point[,] grid = new Point[width, height];

        // 初始化：边界点设为(0,0)，内部点设为最大距离
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                grid[x, y] = binary[x, y] ?
                    new Point(0, 0) :
                    new Point(maxDistance, maxDistance);
            }
        }
        return grid;
    }

    private static void GenerateSEDT(Point[,] grid, int width, int height, int maxDistance)
    {
        // 第一遍扫描：左上到右下
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                Compare(ref grid[x, y], GetPoint(grid, x, y, -1, -1, maxDistance) + new Point(1, 1));
                Compare(ref grid[x, y], GetPoint(grid, x, y, -1, 0, maxDistance) + new Point(1, 0));
                Compare(ref grid[x, y], GetPoint(grid, x, y, -1, 1, maxDistance) + new Point(1, -1));
                Compare(ref grid[x, y], GetPoint(grid, x, y, 0, -1, maxDistance) + new Point(0, 1));
            }
        }

        // 第二遍扫描：右下到左上
        for (int y = height - 1; y >= 0; y--)
        {
            for (int x = width - 1; x >= 0; x--)
            {
                Compare(ref grid[x, y], GetPoint(grid, x, y, 1, 0, maxDistance) + new Point(-1, 0));
                Compare(ref grid[x, y], GetPoint(grid, x, y, 1, 1, maxDistance) + new Point(-1, -1));
                Compare(ref grid[x, y], GetPoint(grid, x, y, 1, -1, maxDistance) + new Point(-1, 1));
                Compare(ref grid[x, y], GetPoint(grid, x, y, 0, 1, maxDistance) + new Point(0, -1));
            }
        }
    }

    private static Point GetPoint(Point[,] grid, int x, int y, int dx, int dy, int maxDistance)
    {
        int nx = x + dx;
        int ny = y + dy;
        if (nx >= 0 && nx < grid.GetLength(0) && ny >= 0 && ny < grid.GetLength(1))
            return grid[nx, ny];
        return new Point(maxDistance, maxDistance);
    }

    private static void Compare(ref Point current, Point candidate)
    {
        if (candidate.DistSq < current.DistSq)
            current = candidate;
    }

    private static Texture2D CreateOutputTexture(Point[,] grid, int width, int height, int maxDistance)
    {
        Texture2D tex = new Texture2D(width, height, TextureFormat.RGBA32, false);
        float[] distances = new float[width * height];

        float scale = 1.0f / maxDistance;

        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                float dist = Mathf.Sqrt(grid[x, y].DistSq) * scale;
                distances[y * width + x] = dist;
            }
        }

        tex.SetPixelData(distances, 0);
        tex.Apply();
        return tex;
    }
}
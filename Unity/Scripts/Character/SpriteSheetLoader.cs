using System.Collections;
using UnityEngine;
using UnityEngine.Networking;

namespace KingdomCome.Character
{
    /// <summary>
    /// Downloads sprite sheets from Supabase storage at runtime,
    /// slices into frames based on column/row grid, feeds to CharacterAnimator.
    /// </summary>
    [RequireComponent(typeof(CharacterAnimator))]
    public class SpriteSheetLoader : MonoBehaviour
    {
        [Header("Supabase sprite sheet URLs")]
        public string urlDown;
        public string urlUp;
        public string urlLeft;
        public string urlRight;

        [Header("Grid Layout")]
        public int columns = 5;
        public int rows    = 6;

        CharacterAnimator anim;

        void Start()
        {
            anim = GetComponent<CharacterAnimator>();
            StartCoroutine(LoadAll());
        }

        IEnumerator LoadAll()
        {
            yield return Load(urlDown,  frames => anim.framesDown  = frames);
            yield return Load(urlUp,    frames => anim.framesUp    = frames);
            yield return Load(urlLeft,  frames => anim.framesLeft  = frames);
            yield return Load(urlRight, frames => anim.framesRight = frames);
            anim.ShowIdleFrame();
        }

        IEnumerator Load(string url, System.Action<Sprite[]> onDone)
        {
            if (string.IsNullOrEmpty(url)) yield break;

            var req = UnityWebRequest.Get(url);
            yield return req.SendWebRequest();

            if (req.result != UnityWebRequest.Result.Success)
            {
                Debug.LogError($"[SpriteSheetLoader] Failed: {req.error}");
                req.Dispose();
                yield break;
            }

            var tex = new Texture2D(2, 2, TextureFormat.RGBA32, false);
            tex.filterMode = FilterMode.Point;
            tex.LoadImage(req.downloadHandler.data);
            req.Dispose();

            int frameW = tex.width  / columns;
            int frameH = tex.height / rows;
            Debug.Log($"[SpriteSheetLoader] {tex.width}x{tex.height} → frame {frameW}x{frameH} ({columns}x{rows} grid)");

            var frames = new Sprite[columns * rows];
            for (int row = rows - 1; row >= 0; row--)
            for (int col = 0; col < columns; col++)
            {
                int i    = (rows - 1 - row) * columns + col;
                var rect = new Rect(col * frameW, row * frameH, frameW, frameH);
                frames[i] = Sprite.Create(tex, rect,
                    new Vector2(0.5f, 0.5f), Mathf.Max(frameW, frameH));
            }
            onDone(frames);
        }
    }
}

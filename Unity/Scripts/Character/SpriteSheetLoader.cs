using System.Collections;
using UnityEngine;
using UnityEngine.Networking;

namespace KingdomCome.Character
{
    [RequireComponent(typeof(CharacterAnimator))]
    public class SpriteSheetLoader : MonoBehaviour
    {
        [Header("Supabase sprite sheet URLs")]
        public string urlDown;
        public string urlUp;
        public string urlLeft;
        public string urlRight;

        [Header("Grid Layout")]
        public int columns  = 5;
        public int rows     = 6;

        [Header("Which rows to use (0 = top row)")]
        public int startRow = 0;
        public int useRows  = 1;

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
            tex.filterMode = FilterMode.Bilinear;
            tex.LoadImage(req.downloadHandler.data);
            req.Dispose();

            int frameW = tex.width  / columns;
            int frameH = tex.height / rows;
            int count  = columns * useRows;
            Debug.Log($"[SpriteSheetLoader] {tex.width}x{tex.height} → cell {frameW}x{frameH}, using row {startRow}–{startRow+useRows-1} ({count} frames)");

            var frames = new Sprite[count];
            for (int r = 0; r < useRows; r++)
            for (int c = 0; c < columns; c++)
            {
                int i      = r * columns + c;
                int texRow = rows - 1 - (startRow + r);   // flip: Unity UV is bottom-up
                var rect   = new Rect(c * frameW, texRow * frameH, frameW, frameH);
                frames[i]  = Sprite.Create(tex, rect, new Vector2(0.5f, 0.5f), 100f);
            }
            onDone(frames);
        }
    }
}

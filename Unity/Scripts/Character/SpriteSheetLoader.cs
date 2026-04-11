using System.Collections;
using UnityEngine;
using UnityEngine.Networking;

namespace KingdomCome.Character
{
    /// <summary>
    /// Downloads a sprite sheet from Supabase storage at runtime,
    /// slices it into 256x256 frames, and feeds them to CharacterAnimator.
    /// </summary>
    [RequireComponent(typeof(CharacterAnimator))]
    public class SpriteSheetLoader : MonoBehaviour
    {
        public const int FrameSize = 256;

        [Header("Supabase sprite sheet URLs")]
        public string urlDown;
        public string urlUp;
        public string urlLeft;
        public string urlRight;

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
        }

        IEnumerator Load(string url, System.Action<Sprite[]> onDone)
        {
            if (string.IsNullOrEmpty(url)) yield break;

            using var req = UnityWebRequestTexture.GetTexture(url);
            yield return req.SendWebRequest();

            if (req.result != UnityWebRequest.Result.Success)
            {
                Debug.LogError($"[SpriteSheetLoader] Failed: {url}\n{req.error}");
                yield break;
            }

            var tex    = DownloadHandlerTexture.GetContent(req);
            tex.filterMode = FilterMode.Point;  // crisp pixel art

            int cols   = tex.width  / FrameSize;
            int rows   = tex.height / FrameSize;
            var frames = new Sprite[cols * rows];

            for (int row = rows - 1; row >= 0; row--)      // Unity UV: bottom-up
            for (int col = 0; col < cols; col++)
            {
                int i  = (rows - 1 - row) * cols + col;
                var rect = new Rect(col * FrameSize, row * FrameSize, FrameSize, FrameSize);
                frames[i] = Sprite.Create(tex, rect,
                    new Vector2(0.5f, 0.5f), FrameSize);
            }

            onDone(frames);
        }
    }
}
